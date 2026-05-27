import SwiftUI

/// Bundles the two top-level alert surfaces the main shell presents:
///
/// 1. `journalFeedback` — driven by `ContentViewModel`'s journal feedback
///    item, dismissed by clearing the published value.
/// 2. `flowConfirmationAlerts` — the primary / secondary submission
///    confirmation, owned by `FlowCoordinator` and routed through
///    `FlowSubmissionPresenter` so the queued / failure copy lives in
///    one place.
///
/// Extracting both keeps ContentView focused on lifecycle and composition;
/// the modifier is small enough that the alert plumbing reads as one
/// concept rather than two adjacent chains.
struct JournalFlowAlertsModifier: ViewModifier {
  @ObservedObject var viewModel: ContentViewModel
  @ObservedObject var flowCoordinator: FlowCoordinator
  let flowSubmissionPresenter: FlowSubmissionPresenter

  func body(content: Content) -> some View {
    content
      .alert(item: $viewModel.journalFeedback) { feedback in
        JournalFeedbackAlert.make(feedback) { viewModel.journalFeedback = nil }
      }
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
  /// Applies the journal-feedback alert plus the primary/secondary flow
  /// confirmation alerts, routing submission through the supplied
  /// presenter so callers don't repeat the queued/failure copy.
  func journalFlowAlerts(
    viewModel: ContentViewModel,
    flowCoordinator: FlowCoordinator,
    flowSubmissionPresenter: FlowSubmissionPresenter
  ) -> some View {
    modifier(
      JournalFlowAlertsModifier(
        viewModel: viewModel,
        flowCoordinator: flowCoordinator,
        flowSubmissionPresenter: flowSubmissionPresenter
      )
    )
  }
}
