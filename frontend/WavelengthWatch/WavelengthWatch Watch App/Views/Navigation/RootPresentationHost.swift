import SwiftUI

/// The single root-level presentation host, attached above the
/// NavigationStack push so the presentations it renders are never deferred
/// behind an in-flight navigation transaction.
///
/// The host renders the `storageError` alert, the journal log-confirmation
/// (#406, B2), the journal feedback alert, and the flow review sheet — all
/// driven by the coordinator's single `active` slot. Two bridges keep the
/// coordinator in sync with state that still lives on its original owner:
/// `ContentViewModel.journalFeedback` (the direct-log path) and
/// `FlowCoordinator.currentStep == .review`.
struct RootPresentationHost: ViewModifier {
  @ObservedObject var coordinator: PresentationCoordinator
  @EnvironmentObject private var flowCoordinator: FlowCoordinator
  @EnvironmentObject private var viewModel: ContentViewModel

  /// The presentation chain is staged through `some View` helpers: each
  /// erases the upstream modifier complexity so Swift's type-checker can
  /// resolve the body without timing out (same approach as RootShellView).
  func body(content: Content) -> some View {
    let withStorage = storageErrorAlert(content)
    let withLog = logConfirmationAlert(withStorage)
    let withFeedback = journalFeedbackAlert(withLog)
    let withReview = flowReviewSheet(withFeedback)
    return bridges(withReview)
  }

  // MARK: - Presentation surfaces

  private func storageErrorAlert(_ view: some View) -> some View {
    view.alert(
      "Storage Error",
      isPresented: storageErrorPresented
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(Self.storageErrorMessage(reason: storageErrorReason))
    }
  }

  /// The active storage-error's open-failure reason, if one is presented.
  private var storageErrorReason: String? {
    if case let .storageError(reason) = coordinator.active {
      return reason
    }
    return nil
  }

  /// Presentation binding for the storage-error alert. The `.storageError`
  /// case carries an associated reason, so a plain `isPresented(for:)` can't
  /// match it reason-agnostically — this binding reads `true` for any
  /// storage error and dismisses on write-`false`.
  private var storageErrorPresented: Binding<Bool> {
    Binding(
      get: {
        if case .storageError = coordinator.active {
          return true
        }
        return false
      },
      set: { isPresented in
        if !isPresented {
          coordinator.dismiss()
        }
      }
    )
  }

  /// Builds the storage-error alert copy. The user guidance is always shown;
  /// when an open-failure `reason` is known it is appended verbatim so the
  /// exact failing SQLite step is legible straight off the watch screen
  /// (#457 storage RCA). `static` and pure so it's unit-testable without
  /// rendering the host.
  static func storageErrorMessage(reason: String?) -> String {
    let guidance = "Your journal couldn't be opened, so entries logged this session won't be saved. Please reopen the app; if the problem continues, contact support."
    guard let reason, !reason.isEmpty else { return guidance }
    return guidance + "\n\nDetails: \(reason)"
  }

  /// The journal log-confirmation, hoisted above the navigation push so it
  /// presents immediately rather than waiting for a back-out (B2).
  private func logConfirmationAlert(_ view: some View) -> some View {
    view.alert(
      logConfirmation?.alertTitle ?? "",
      isPresented: logConfirmationPresented
    ) {
      Button("Yes") {
        if let action = logConfirmation?.action {
          Task { await handler.perform(action) }
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text(logConfirmation?.message ?? "")
    }
  }

  /// Journal feedback (success / queued / failure), queued behind any
  /// interactive presentation by the coordinator's priority policy.
  private func journalFeedbackAlert(_ view: some View) -> some View {
    view.alert(item: journalFeedbackItem) { feedback in
      JournalFeedbackAlert.make(feedback) { coordinator.dismiss() }
    }
  }

  /// The flow review sheet, driven by the coordinator.
  private func flowReviewSheet(_ view: some View) -> some View {
    view.sheet(isPresented: flowReviewPresented) {
      FlowReviewSheet(flowCoordinator: flowCoordinator)
    }
  }

  // MARK: - Coordinator bridges

  /// Keeps the coordinator in sync with ContentViewModel's direct-log feedback
  /// (consumed one-shot, since ContentViewModel must not depend on the
  /// coordinator). The flow-review step is driven from RootShellView's single
  /// flow-step observer (#428).
  private func bridges(_ view: some View) -> some View {
    view
      .onChange(of: viewModel.journalFeedback) { _, newValue in
        if let feedback = newValue {
          coordinator.request(.journalFeedback(feedback))
          viewModel.journalFeedback = nil
        }
      }
  }

  /// The active log-confirmation request, if one is presented.
  private var logConfirmation: LogConfirmationRequest? {
    if case let .logConfirmation(request) = coordinator.active {
      return request
    }
    return nil
  }

  /// Presentation binding for the log-confirmation alert. Any dismissal
  /// (Yes, Cancel, or swipe) writes `false`, which clears the coordinator.
  private var logConfirmationPresented: Binding<Bool> {
    Binding(
      get: { logConfirmation != nil },
      set: { isPresented in
        if !isPresented {
          coordinator.dismiss()
        }
      }
    )
  }

  /// Optional binding for the journal-feedback `.alert(item:)`. Reads the
  /// active feedback; clearing it (alert dismissed) advances the coordinator.
  private var journalFeedbackItem: Binding<ContentViewModel.JournalFeedback?> {
    Binding(
      get: {
        if case let .journalFeedback(feedback) = coordinator.active {
          return feedback
        }
        return nil
      },
      set: { newValue in
        if newValue == nil, case .journalFeedback = coordinator.active {
          coordinator.dismiss()
        }
      }
    )
  }

  private var flowReviewPresented: Binding<Bool> {
    Self.flowReviewPresented(coordinator: coordinator, flowCoordinator: flowCoordinator)
  }

  /// Presentation binding for the flow review sheet. A swipe-dismiss cancels
  /// the flow, mirroring the prior `MainContentDialogsModifier.flowReviewPresenter`
  /// behavior; the sheet's own buttons transition `currentStep` explicitly,
  /// and the `currentStep` bridge then dismisses this presentation. `static`
  /// with explicit dependencies so the get/set contract is unit-testable
  /// without rendering the host.
  static func flowReviewPresented(
    coordinator: PresentationCoordinator,
    flowCoordinator: FlowCoordinator
  ) -> Binding<Bool> {
    Binding(
      get: { coordinator.active == .flowReview },
      set: { isPresented in
        guard !isPresented else { return }
        coordinator.dismiss()
        if flowCoordinator.currentStep == .review {
          flowCoordinator.cancel()
        }
      }
    )
  }

  private var handler: LogConfirmationHandler {
    LogConfirmationHandler(flowCoordinator: flowCoordinator, viewModel: viewModel)
  }
}

extension View {
  /// Attaches the root presentation host. See `RootPresentationHost`.
  func rootPresentationHost(coordinator: PresentationCoordinator) -> some View {
    modifier(RootPresentationHost(coordinator: coordinator))
  }
}
