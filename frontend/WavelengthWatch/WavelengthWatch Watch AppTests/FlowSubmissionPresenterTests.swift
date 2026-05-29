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

  @Test("successful submit resets the flow to idle")
  func submit_success_resetsFlow() async {
    let (viewModel, coordinator) = await makeSetup()
    let presenter = FlowSubmissionPresenter(flowCoordinator: coordinator, viewModel: viewModel)

    await presenter.submit(failurePrefix: "Failed to log emotion")

    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
    #expect(coordinator.selections.primary == nil)
  }

  @Test("queued submit shows queued feedback and resets the flow")
  func submit_queued_showsQueuedFeedbackAndResets() async {
    let (viewModel, coordinator) = await makeSetup(shouldQueue: true)
    let presenter = FlowSubmissionPresenter(flowCoordinator: coordinator, viewModel: viewModel)

    await presenter.submit(failurePrefix: "Failed to log emotion")

    if case .queued = viewModel.journalFeedback?.kind {
      // Reaching this branch is the assertion.
    } else {
      Issue.record("Expected queued feedback, got \(String(describing: viewModel.journalFeedback?.kind))")
    }
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
    #expect(coordinator.selections.primary == nil)
  }

  @Test("failed submit shows prefixed failure feedback and preserves state for retry")
  func submit_failure_showsFailureAndPreservesState() async {
    let (viewModel, coordinator) = await makeSetup(shouldFail: true)
    let presenter = FlowSubmissionPresenter(flowCoordinator: coordinator, viewModel: viewModel)

    await presenter.submit(failurePrefix: "Failed to log emotion")

    if case let .failure(message) = viewModel.journalFeedback?.kind {
      #expect(message.contains("Failed to log emotion"))
    } else {
      Issue.record("Expected failure feedback, got \(String(describing: viewModel.journalFeedback?.kind))")
    }
    // On unrecoverable failure the flow is NOT reset, so the user can retry.
    #expect(coordinator.currentStep != FlowCoordinator.FlowStep.idle)
    #expect(coordinator.selections.primary != nil)
  }
}
