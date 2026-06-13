import Testing
@testable import WavelengthWatch_Watch_App

/// Tests for `PresentationCoordinator`'s single-active priority/queue policy
/// (#407, SPEC §11 Q4): informational feedback queues behind interactive
/// presentations; a higher-priority request preempts without dropping the
/// displaced one; `dismiss()` promotes the highest-priority queued item.
@MainActor
struct PresentationPolicyTests {
  private func sampleFeedback() -> ContentViewModel.JournalFeedback {
    ContentViewModel.JournalFeedback(kind: .success)
  }

  private func sampleLogConfirmation() -> PresentationCoordinator.ActivePresentation {
    .logConfirmation(LogConfirmationRequest(
      alertTitle: "Log Strategy",
      message: "Would you like to log \"Deep Breathing\"?",
      action: .strategy(
        strategy: CatalogStrategyModel(id: 1, strategy: "Deep Breathing", color: "Blue"),
        curriculumID: 1
      )
    ))
  }

  @Test("lower-priority feedback queues behind an active confirmation")
  func feedbackQueuesBehindConfirmation() {
    let coordinator = PresentationCoordinator()
    let confirmation = sampleLogConfirmation()
    let feedback = sampleFeedback()

    coordinator.request(confirmation)
    coordinator.request(.journalFeedback(feedback))

    #expect(coordinator.active == confirmation) // confirmation stays up
    coordinator.dismiss()
    #expect(coordinator.active == .journalFeedback(feedback)) // queued feedback surfaces
    coordinator.dismiss()
    #expect(coordinator.active == .idle)
  }

  @Test("higher-priority storage error preempts active feedback without dropping it")
  func storageErrorPreemptsFeedback() {
    let coordinator = PresentationCoordinator()
    let feedback = sampleFeedback()

    coordinator.request(.journalFeedback(feedback))
    coordinator.request(.storageError(reason: nil))

    #expect(coordinator.active == .storageError(reason: nil)) // higher priority shown immediately
    coordinator.dismiss()
    #expect(coordinator.active == .journalFeedback(feedback)) // displaced feedback resurfaces
  }

  @Test("dismiss promotes the highest-priority queued presentation first")
  func dismissPromotesHighestPriority() {
    let coordinator = PresentationCoordinator()
    let feedback = sampleFeedback()

    coordinator.request(.menu) // active (priority 1)
    coordinator.request(.journalFeedback(feedback)) // queued (priority 0)
    coordinator.request(.storageError(reason: nil)) // preempts menu (priority 2); menu queued

    #expect(coordinator.active == .storageError(reason: nil))
    coordinator.dismiss()
    #expect(coordinator.active == .menu) // priority 1 beats queued feedback (0)
    coordinator.dismiss()
    #expect(coordinator.active == .journalFeedback(feedback))
    coordinator.dismiss()
    #expect(coordinator.active == .idle)
  }

  @Test("requesting idle is ignored")
  func requestingIdleIsIgnored() {
    let coordinator = PresentationCoordinator()
    coordinator.request(.menu)
    coordinator.request(.idle)
    #expect(coordinator.active == .menu)
  }
}
