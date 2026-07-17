import Testing
@testable import WavelengthWatch_Watch_App

/// Tests for FlowSubmissionPresenter — the seam that turns a flow submission
/// into user-visible feedback and decides whether to reset the flow.
@MainActor
struct FlowSubmissionPresenterTests {
  private func makeSetup(
    shouldQueue: Bool = false,
    shouldFail: Bool = false
  ) async -> (ContentViewModel, FlowCoordinator) {
    let catalog = CatalogTestHelper.createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journalClient = JournalClientMock()
    journalClient.shouldQueue = shouldQueue
    journalClient.shouldFail = shouldFail
    let viewModel = ContentViewModel(
      catalogRepository: repository,
      journalRepository: InMemoryJournalRepository(),
      journalClient: journalClient
    )
    await viewModel.loadCatalog()
    let coordinator = FlowCoordinator(contentViewModel: viewModel)
    // Put the flow in a submittable state with a primary emotion selected.
    let primary = catalog.layers[1].phases[0].medicinal[0]
    coordinator.startPrimarySelection()
    coordinator.capturePrimary(primary)
    return (viewModel, coordinator)
  }

  /// Pulls the `JournalFeedback.Kind` off the coordinator's active
  /// presentation, or nil if the active presentation isn't journal feedback.
  private func feedbackKind(
    _ presentation: PresentationCoordinator
  ) -> ContentViewModel.JournalFeedback.Kind? {
    if case let .journalFeedback(feedback) = presentation.active {
      return feedback.kind
    }
    return nil
  }

  @Test("successful submit resets the flow and surfaces no feedback")
  func submit_success_resetsFlow() async {
    let (_, coordinator) = await makeSetup()
    let presentation = PresentationCoordinator()
    let presenter = FlowSubmissionPresenter(
      flowCoordinator: coordinator,
      presentationCoordinator: presentation
    )

    await presenter.submit(failurePrefix: "Failed to log emotion")

    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
    #expect(coordinator.selections.primary == nil)
    #expect(presentation.active == .idle)
  }

  @Test("queued submit routes queued feedback to the coordinator and resets the flow")
  func submit_queued_showsQueuedFeedbackAndResets() async {
    let (_, coordinator) = await makeSetup(shouldQueue: true)
    let presentation = PresentationCoordinator()
    let presenter = FlowSubmissionPresenter(
      flowCoordinator: coordinator,
      presentationCoordinator: presentation
    )

    await presenter.submit(failurePrefix: "Failed to log emotion")

    if case .queued = feedbackKind(presentation) {
      // Reaching this branch is the assertion.
    } else {
      Issue.record("Expected queued feedback, got \(String(describing: feedbackKind(presentation)))")
    }
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
    #expect(coordinator.selections.primary == nil)
  }

  @Test("failed submit routes prefixed failure feedback and preserves state for retry")
  func submit_failure_showsFailureAndPreservesState() async {
    let (_, coordinator) = await makeSetup(shouldFail: true)
    let presentation = PresentationCoordinator()
    let presenter = FlowSubmissionPresenter(
      flowCoordinator: coordinator,
      presentationCoordinator: presentation
    )

    await presenter.submit(failurePrefix: "Failed to log emotion")

    if case let .failure(message) = feedbackKind(presentation) {
      #expect(message.contains("Failed to log emotion"))
    } else {
      Issue.record("Expected failure feedback, got \(String(describing: feedbackKind(presentation)))")
    }
    // On unrecoverable failure the flow is NOT reset, so the user can retry.
    #expect(coordinator.currentStep != FlowCoordinator.FlowStep.idle)
    #expect(coordinator.selections.primary != nil)
  }
}
