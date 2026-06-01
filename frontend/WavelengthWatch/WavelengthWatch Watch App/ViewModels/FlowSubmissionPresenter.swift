import Foundation

/// Bridges `FlowCoordinator.submit()` to user-visible journal feedback.
///
/// The two flow-confirmation alerts (primary, secondary) share identical
/// queued / failure handling — only the failure-prefix copy varies.
/// Centralising the logic here keeps `ContentView` focused on view
/// composition and preserves `FlowCoordinator`'s "pure state management,
/// no UI" boundary; this presenter is the explicit seam where flow
/// submission becomes user-visible feedback. Feedback is routed through the
/// `PresentationCoordinator` (#407) so it queues behind interactive
/// presentations rather than racing them.
@MainActor
struct FlowSubmissionPresenter {
  let flowCoordinator: FlowCoordinator
  let presentationCoordinator: PresentationCoordinator

  /// Submits the current flow entry and renders the appropriate feedback.
  /// - Parameter failurePrefix: Copy shown before the underlying error
  ///   description on unrecoverable failure (e.g. `"Failed to log emotion"`
  ///   for primary, `"Failed to log emotions"` for secondary).
  func submit(failurePrefix: String) async {
    do {
      try await flowCoordinator.submit()
      flowCoordinator.reset()
    } catch JournalError.queuedForRetry {
      presentationCoordinator.request(.journalFeedback(.init(
        kind: .queued("Saved offline. Will sync automatically.")
      )))
      flowCoordinator.reset()
    } catch {
      presentationCoordinator.request(.journalFeedback(.init(
        kind: .failure("\(failurePrefix): \(error.localizedDescription)")
      )))
    }
  }
}
