import SwiftUI

/// Three "Are you sure?" alerts that drive the journal flow's
/// confirmation steps (primary emotion → secondary → strategy).
///
/// Each alert is gated on the matching `FlowCoordinator.Step` and offers
/// a small set of "next step" buttons. The two submit-capable steps
/// (`.confirmingPrimary`, `.confirmingSecondary`) route through the
/// caller-supplied async closures so the alert layer doesn't need to
/// know about journal persistence, queueing, or feedback rendering.
struct FlowConfirmationAlertsModifier: ViewModifier {
  @ObservedObject var flowCoordinator: FlowCoordinator
  let onPrimarySubmit: @MainActor () async -> Void
  let onSecondarySubmit: @MainActor () async -> Void

  func body(content: Content) -> some View {
    content
      .alert(
        "Primary emotion selected",
        isPresented: Self.presenter(for: .confirmingPrimary, coordinator: flowCoordinator)
      ) {
        Button("Add Secondary Emotion") { flowCoordinator.promptForSecondary() }
        Button("Add Strategy") { flowCoordinator.promptForStrategy() }
        // Known race deferred to the Phase 2b coordinator-owned submit: a
        // swipe-dismiss right after Done lets the presenter binding fire
        // cancel() alongside the still-running submit Task.
        Button("Done") { Task { await onPrimarySubmit() } }
        Button("Cancel", role: .cancel) { flowCoordinator.cancel() }
      } message: {
        if let primary = flowCoordinator.selections.primary {
          Text("You selected \"\(primary.expression)\". What would you like to do next?")
        }
      }
      .alert(
        "Secondary emotion selected",
        isPresented: Self.presenter(for: .confirmingSecondary, coordinator: flowCoordinator)
      ) {
        Button("Add Strategy") { flowCoordinator.promptForStrategy() }
        Button("Done") { Task { await onSecondarySubmit() } }
        Button("Cancel", role: .cancel) { flowCoordinator.cancel() }
      } message: {
        // A nil secondary is the legitimate "user skipped it" path, not a bug.
        if let secondary = flowCoordinator.selections.secondary {
          Text("You selected \"\(secondary.expression)\". What would you like to do next?")
        } else {
          Text("What would you like to do next?")
        }
      }
      .alert(
        "Strategy selected",
        isPresented: Self.presenter(for: .confirmingStrategy, coordinator: flowCoordinator)
      ) {
        Button("Continue to Review") { flowCoordinator.showReview() }
        Button("Cancel", role: .cancel) { flowCoordinator.cancel() }
      } message: {
        // A nil strategy is the legitimate "user skipped it" path, not a bug.
        if let strategy = flowCoordinator.selections.strategy {
          Text("You selected \"\(strategy.strategy)\". Continue to review?")
        } else {
          Text("Continue to review?")
        }
      }
  }

  /// Binding whose value tracks whether the coordinator is in `step`.
  /// Action buttons (Done / Continue / Cancel / etc.) transition the
  /// coordinator out of the step explicitly. A swipe-down or tap-outside
  /// dismissal writes `false` into the binding, which is treated as an
  /// implicit cancel — without this, `.constant()` would silently ignore
  /// the system dismissal and the alert would immediately re-present
  /// because `currentStep == step` is still true.
  ///
  /// `static` taking an explicit `coordinator` so the binding's get/set
  /// contract is unit-testable without rendering the modifier.
  static func presenter(
    for step: FlowCoordinator.FlowStep,
    coordinator: FlowCoordinator
  ) -> Binding<Bool> {
    Binding(
      get: { coordinator.currentStep == step },
      set: { isPresented in
        if !isPresented, coordinator.currentStep == step {
          coordinator.cancel()
        }
      }
    )
  }
}

extension View {
  /// Attaches the journal-flow confirmation alerts to the receiver.
  /// See `FlowConfirmationAlertsModifier` for the per-alert contract.
  func flowConfirmationAlerts(
    flowCoordinator: FlowCoordinator,
    onPrimarySubmit: @escaping @MainActor () async -> Void,
    onSecondarySubmit: @escaping @MainActor () async -> Void
  ) -> some View {
    modifier(FlowConfirmationAlertsModifier(
      flowCoordinator: flowCoordinator,
      onPrimarySubmit: onPrimarySubmit,
      onSecondarySubmit: onSecondarySubmit
    ))
  }
}
