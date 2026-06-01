import SwiftUI

/// Applies the primary / secondary flow-confirmation alerts, owned by
/// `FlowCoordinator` and routed through `FlowSubmissionPresenter` so the
/// queued / failure copy lives in one place.
///
/// The journal-feedback alert that used to live here moved onto
/// `RootPresentationHost` in #407, where the coordinator's priority policy
/// queues it behind any interactive presentation.
struct JournalFlowAlertsModifier: ViewModifier {
  @ObservedObject var flowCoordinator: FlowCoordinator
  let flowSubmissionPresenter: FlowSubmissionPresenter

  func body(content: Content) -> some View {
    content
      .flowConfirmationAlerts(
        flowCoordinator: flowCoordinator,
        onPrimarySubmit: {
          await flowSubmissionPresenter.submit(failurePrefix: "Failed to log emotion")
        },
        onSecondarySubmit: {
          await flowSubmissionPresenter.submit(failurePrefix: "Failed to log emotions")
        }
      )
  }
}

// MARK: - View Extension

extension View {
  /// Applies the primary/secondary flow confirmation alerts, routing
  /// submission through the supplied presenter so callers don't repeat the
  /// queued/failure copy.
  func journalFlowAlerts(
    flowCoordinator: FlowCoordinator,
    flowSubmissionPresenter: FlowSubmissionPresenter
  ) -> some View {
    modifier(
      JournalFlowAlertsModifier(
        flowCoordinator: flowCoordinator,
        flowSubmissionPresenter: flowSubmissionPresenter
      )
    )
  }
}
