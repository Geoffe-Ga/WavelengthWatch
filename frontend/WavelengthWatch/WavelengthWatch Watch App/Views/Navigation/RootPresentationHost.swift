import SwiftUI

/// The single root-level presentation host, attached above the
/// NavigationStack push so the presentations it renders are never deferred
/// behind an in-flight navigation transaction.
///
/// In this skeleton (issue #405) the host owns the `storageError` alert —
/// the simplest fully self-contained surface — proving the
/// coordinator-driven host renders end-to-end. The `menu` and `onboarding`
/// sheets are coordinator-driven from this same `PresentationCoordinator`
/// but still presented from `MainContentDialogsModifier` for now; #406 /
/// #407 relocate their content here and fold the publisher-driven journal
/// feedback and flow review onto the host too.
struct RootPresentationHost: ViewModifier {
  @ObservedObject var coordinator: PresentationCoordinator
  @EnvironmentObject private var flowCoordinator: FlowCoordinator
  @EnvironmentObject private var viewModel: ContentViewModel

  func body(content: Content) -> some View {
    content
      .alert(
        "Storage Error",
        isPresented: coordinator.isPresented(for: .storageError)
      ) {
        Button("OK", role: .cancel) {}
      } message: {
        Text("Your journal couldn't be opened, so entries logged this session won't be saved. Please reopen the app; if the problem continues, contact support.")
      }
      // The journal log-confirmation, hoisted above the navigation push so
      // it presents immediately rather than waiting for a back-out (B2).
      .alert(
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

  /// The active log-confirmation request, if one is presented.
  private var logConfirmation: LogConfirmationRequest? {
    if case let .logConfirmation(request) = coordinator.active { return request }
    return nil
  }

  /// Presentation binding for the log-confirmation alert. Any dismissal
  /// (Yes, Cancel, or swipe) writes `false`, which clears the coordinator.
  private var logConfirmationPresented: Binding<Bool> {
    Binding(
      get: { logConfirmation != nil },
      set: { isPresented in
        if !isPresented { coordinator.dismiss() }
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
