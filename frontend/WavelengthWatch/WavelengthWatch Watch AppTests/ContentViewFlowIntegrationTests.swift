import Testing
@testable import WavelengthWatch_Watch_App

/// Integration tests for ContentView + FlowCoordinator interaction
///
/// These tests verify that ContentView correctly responds to flow state changes,
/// filters layers appropriately, and intercepts log buttons when in flow mode.
@MainActor
struct ContentViewFlowIntegrationTests {
  // MARK: - Test Setup Helper

  private func createTestSetup() async -> (ContentViewModel, FlowCoordinator, CatalogResponseModel) {
    let catalog = CatalogTestHelper.createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journalClient = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journalClient)
    await viewModel.loadCatalog()
    let coordinator = FlowCoordinator(contentViewModel: viewModel)
    return (viewModel, coordinator, catalog)
  }

  // MARK: - Layer Filtering Integration Tests

  @Test("ContentView filters to emotions only when flow starts")
  func startFlow_filtersToEmotionsOnly() async {
    let (viewModel, coordinator, _) = await createTestSetup()

    // Start flow
    coordinator.startPrimarySelection()

    // ContentView should filter to emotions only
    #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)
    #expect(viewModel.filteredLayers.allSatisfy { $0.id >= 1 })
    #expect(viewModel.filteredLayers.count == 2) // Beige, Purple in test catalog
  }

  @Test("ContentView filters to strategies when prompting for strategy")
  func promptStrategy_filtersToStrategiesOnly() async {
    let (viewModel, coordinator, _) = await createTestSetup()

    // Prompt for strategy
    coordinator.promptForStrategy()

    // ContentView should filter to strategies only
    #expect(viewModel.layerFilterMode == LayerFilterMode.strategiesOnly)
    #expect(viewModel.filteredLayers.count == 1)
    #expect(viewModel.filteredLayers[0].id == 0)
  }

  @Test("ContentView shows all layers in normal mode")
  func normalMode_showsAllLayers() async {
    let (viewModel, coordinator, _) = await createTestSetup()

    // Default state (idle)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
    #expect(viewModel.layerFilterMode == LayerFilterMode.all)
    #expect(viewModel.filteredLayers.count == 3) // All 3 layers in test catalog
  }

  @Test("Canceling flow resets filter to all layers")
  func cancelFlow_resetsFilterToAll() async {
    let (viewModel, coordinator, _) = await createTestSetup()

    // Start flow
    coordinator.startPrimarySelection()
    #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)

    // Cancel
    coordinator.cancel()

    // Filter should reset
    #expect(viewModel.layerFilterMode == LayerFilterMode.all)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
  }

  // MARK: - Full Flow Integration Tests

  @Test("Full flow: primary only path")
  func fullFlow_primaryOnly() async {
    let (viewModel, coordinator, catalog) = await createTestSetup()

    // Start flow
    coordinator.startPrimarySelection()
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.selectingPrimary)
    #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)

    // Capture primary
    let emotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(emotion)
    #expect(coordinator.selections.primary == emotion)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingPrimary)

    // Skip to review
    coordinator.showReview()
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.review)

    // Submit
    do {
      try await coordinator.submit()
      // Mimic ContentView behavior: reset after successful submission
      coordinator.reset()
    } catch {
      Issue.record("Submit should not fail: \(error)")
    }

    // Flow should reset on success
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
    #expect(coordinator.selections.primary == nil)
  }

  @Test("Full flow: primary + secondary path")
  func fullFlow_primaryAndSecondary() async {
    let (viewModel, coordinator, catalog) = await createTestSetup()

    // Start flow and select primary
    coordinator.startPrimarySelection()
    let primaryEmotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(primaryEmotion)

    // Prompt for secondary
    coordinator.promptForSecondary()
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.selectingSecondary)
    #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)

    // Capture secondary
    let secondaryEmotion = catalog.layers[2].phases[0].medicinal[0]
    coordinator.captureSecondary(secondaryEmotion)
    #expect(coordinator.selections.secondary == secondaryEmotion)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingSecondary)

    // Skip to review
    coordinator.showReview()
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.review)
  }

  @Test("Full flow: complete path with strategy")
  func fullFlow_completeWithStrategy() async {
    let (viewModel, coordinator, catalog) = await createTestSetup()

    // Select primary
    coordinator.startPrimarySelection()
    let primaryEmotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(primaryEmotion)

    // Select secondary
    coordinator.promptForSecondary()
    let secondaryEmotion = catalog.layers[2].phases[0].medicinal[0]
    coordinator.captureSecondary(secondaryEmotion)

    // Select strategy
    coordinator.promptForStrategy()
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.selectingStrategy)
    #expect(viewModel.layerFilterMode == LayerFilterMode.strategiesOnly)

    let strategy = catalog.layers[0].phases[0].strategies[0]
    coordinator.captureStrategy(strategy)
    #expect(coordinator.selections.strategy == strategy)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingStrategy)

    // Review
    coordinator.showReview()
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.review)
  }

  // MARK: - State Transition Integration Tests

  @Test("Filter mode persists through confirmation steps")
  func filterMode_persistsThroughConfirmations() async {
    let (viewModel, coordinator, catalog) = await createTestSetup()

    // Start with emotions filter
    coordinator.startPrimarySelection()
    #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)

    // Capture primary (moves to confirmingPrimary)
    let emotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(emotion)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingPrimary)

    // Filter should remain emotions only during confirmation
    #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)

    // Prompt for secondary
    coordinator.promptForSecondary()
    #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)
  }

  @Test("Filter mode changes when transitioning between emotion and strategy steps")
  func filterMode_changesCorrectlyBetweenSteps() async {
    let (viewModel, coordinator, catalog) = await createTestSetup()

    // Start with emotions
    coordinator.startPrimarySelection()
    #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)

    // Capture primary
    let emotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(emotion)

    // Transition to strategy
    coordinator.promptForStrategy()
    #expect(viewModel.layerFilterMode == LayerFilterMode.strategiesOnly)

    // Cancel should reset
    coordinator.cancel()
    #expect(viewModel.layerFilterMode == LayerFilterMode.all)
  }

  // MARK: - Edge Case Integration Tests

  @Test("Can skip secondary emotion")
  func skipSecondary_proceedsToStrategy() async {
    let (viewModel, coordinator, catalog) = await createTestSetup()

    // Select primary
    coordinator.startPrimarySelection()
    let emotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(emotion)

    // Prompt for secondary but capture nil (skip)
    coordinator.promptForSecondary()
    coordinator.captureSecondary(nil as CatalogCurriculumEntryModel?)

    #expect(coordinator.selections.secondary == nil)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingSecondary)

    // Can proceed to strategy
    coordinator.promptForStrategy()
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.selectingStrategy)
  }

  @Test("Can skip strategy")
  func skipStrategy_proceedsToReview() async {
    let (_, coordinator, catalog) = await createTestSetup()

    // Select primary
    coordinator.startPrimarySelection()
    let emotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(emotion)

    // Prompt for strategy but capture nil (skip)
    coordinator.promptForStrategy()
    coordinator.captureStrategy(nil as CatalogStrategyModel?)

    #expect(coordinator.selections.strategy == nil)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingStrategy)

    // Can proceed to review
    coordinator.showReview()
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.review)
  }

  @Test("Cancel at any step resets all state")
  func cancelAtAnyStep_resetsAllState() async {
    let (viewModel, coordinator, catalog) = await createTestSetup()

    // Build up state
    coordinator.startPrimarySelection()
    let primaryEmotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(primaryEmotion)
    coordinator.promptForSecondary()
    let secondaryEmotion = catalog.layers[2].phases[0].medicinal[0]
    coordinator.captureSecondary(secondaryEmotion)

    #expect(coordinator.selections.primary != nil)
    #expect(coordinator.selections.secondary != nil)

    // Cancel
    coordinator.cancel()

    // Everything should reset
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
    #expect(coordinator.selections.primary == nil)
    #expect(coordinator.selections.secondary == nil)
    #expect(coordinator.selections.strategy == nil)
    #expect(viewModel.layerFilterMode == LayerFilterMode.all)
  }

  // MARK: - Backend Submission Integration Tests

  @Test("Submit with all selections calls backend correctly")
  func submitWithAllSelections_callsBackendCorrectly() async throws {
    let catalog = CatalogTestHelper.createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journalClient = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journalClient)
    await viewModel.loadCatalog()
    let coordinator = FlowCoordinator(contentViewModel: viewModel)

    // Set up selections
    let primaryEmotion = catalog.layers[1].phases[0].medicinal[0]
    let secondaryEmotion = catalog.layers[2].phases[0].medicinal[0]
    let strategy = catalog.layers[0].phases[0].strategies[0]

    coordinator.selections.primary = primaryEmotion
    coordinator.selections.secondary = secondaryEmotion
    coordinator.selections.strategy = strategy

    // Submit
    try await coordinator.submit()
    // Mimic ContentView behavior: reset after successful submission
    coordinator.reset()

    // Verify backend was called with correct data
    #expect(journalClient.submissions.count == 1)
    let submission = journalClient.submissions[0]
    #expect(submission.0 == primaryEmotion.id)
    #expect(submission.1 == secondaryEmotion.id)
    #expect(submission.2 == strategy.id)

    // Verify state reset
    #expect(coordinator.selections.primary == nil)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
  }

  @Test("Submit with only primary calls backend correctly")
  func submitWithOnlyPrimary_callsBackendCorrectly() async throws {
    let catalog = CatalogTestHelper.createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journalClient = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journalClient)
    await viewModel.loadCatalog()
    let coordinator = FlowCoordinator(contentViewModel: viewModel)

    // Set up only primary
    let primaryEmotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.selections.primary = primaryEmotion

    // Submit
    try await coordinator.submit()

    // Verify backend was called
    #expect(journalClient.submissions.count == 1)
    let submission = journalClient.submissions[0]
    #expect(submission.0 == primaryEmotion.id)
    #expect(submission.1 == nil)
    #expect(submission.2 == nil)
  }

  @Test("Submit without primary throws error")
  func submitWithoutPrimary_throwsError() async {
    let (_, coordinator, _) = await createTestSetup()

    // Attempt to submit with no selections
    do {
      try await coordinator.submit()
      Issue.record("Expected error to be thrown")
    } catch {
      // Expected error
      #expect(error is FlowCoordinator.FlowError)
    }
  }

  @Test("Submit preserves state on network error")
  func submitNetworkError_preservesState() async {
    let catalog = CatalogTestHelper.createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journalClient = JournalClientMock()
    journalClient.shouldFail = true
    let viewModel = ContentViewModel(repository: repository, journalClient: journalClient)
    await viewModel.loadCatalog()
    let coordinator = FlowCoordinator(contentViewModel: viewModel)

    // Go through flow to review step
    coordinator.startPrimarySelection()
    let primaryEmotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(primaryEmotion)
    coordinator.showReview()

    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.review)

    // Attempt to submit - should throw error
    do {
      try await coordinator.submit()
      Issue.record("Expected error to be thrown but submit() succeeded")
    } catch {
      // State should be preserved for retry (not reset)
      #expect(coordinator.selections.primary == primaryEmotion)
      #expect(coordinator.currentStep == FlowCoordinator.FlowStep.review)
    }
  }

  @Test("Submit success resets filter mode to .all")
  func submitSuccess_resetsFilterModeToAll() async throws {
    let (viewModel, coordinator, catalog) = await createTestSetup()

    // Start flow - filter mode changes to .emotionsOnly
    coordinator.startPrimarySelection()
    #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)

    // Complete flow with primary selection
    let emotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(emotion)

    // Submit
    try await coordinator.submit()
    // Mimic ContentView behavior: reset after successful submission
    coordinator.reset()

    // Filter mode should reset to .all
    #expect(viewModel.layerFilterMode == LayerFilterMode.all)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
    #expect(coordinator.selections.primary == nil)
  }

  // MARK: - Auto-Start Flow Tests (#151)

  @Test("Auto-start: Logging from idle auto-starts flow")
  func autoStart_loggingFromIdleAutoStartsFlow() async {
    let (viewModel, coordinator, catalog) = await createTestSetup()

    // Verify starting in idle state
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
    #expect(viewModel.layerFilterMode == LayerFilterMode.all)

    // Simulate user tapping "Log" button in normal browsing mode
    let emotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.startPrimarySelection()
    coordinator.capturePrimary(emotion)

    // Flow should auto-start and transition to confirmingPrimary
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingPrimary)
    #expect(coordinator.selections.primary == emotion)
    #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)
  }

  @Test("Auto-start: Quick logging with Done button")
  func autoStart_quickLoggingWithDoneButton() async throws {
    let catalog = CatalogTestHelper.createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journalClient = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journalClient)
    await viewModel.loadCatalog()
    let coordinator = FlowCoordinator(contentViewModel: viewModel)

    // Auto-start flow with emotion
    let emotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.startPrimarySelection()
    coordinator.capturePrimary(emotion)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingPrimary)

    // User taps "Done" button - immediate submit
    try await coordinator.submit()
    // Mimic ContentView "Done" button behavior: reset after successful submission
    coordinator.reset()

    // Verify backend received submission
    #expect(journalClient.submissions.count == 1)
    let submission = journalClient.submissions[0]
    #expect(submission.0 == emotion.id)
    #expect(submission.1 == nil)
    #expect(submission.2 == nil)

    // Flow should reset
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
    #expect(viewModel.layerFilterMode == LayerFilterMode.all)
  }

  @Test("Auto-start: Complete flow after auto-start")
  func autoStart_completeFlowAfterAutoStart() async throws {
    let catalog = CatalogTestHelper.createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journalClient = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journalClient)
    await viewModel.loadCatalog()
    let coordinator = FlowCoordinator(contentViewModel: viewModel)

    // Auto-start with primary emotion
    let primaryEmotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.startPrimarySelection()
    coordinator.capturePrimary(primaryEmotion)

    // User chooses "Add Secondary Emotion"
    coordinator.promptForSecondary()
    let secondaryEmotion = catalog.layers[2].phases[0].medicinal[0]
    coordinator.captureSecondary(secondaryEmotion)

    // User chooses "Add Strategy"
    coordinator.promptForStrategy()
    let strategy = catalog.layers[0].phases[0].strategies[0]
    coordinator.captureStrategy(strategy)

    // Submit complete entry
    coordinator.showReview()
    try await coordinator.submit()

    // Verify complete submission
    #expect(journalClient.submissions.count == 1)
    let submission = journalClient.submissions[0]
    #expect(submission.0 == primaryEmotion.id)
    #expect(submission.1 == secondaryEmotion.id)
    #expect(submission.2 == strategy.id)
  }

  @Test("Auto-start: Flow maintains state through confirmation steps")
  func autoStart_flowMaintainsStateThroughConfirmations() async {
    let (viewModel, coordinator, catalog) = await createTestSetup()

    // Auto-start flow
    let emotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.startPrimarySelection()
    coordinator.capturePrimary(emotion)

    // Should be in confirmingPrimary state
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingPrimary)
    #expect(coordinator.selections.primary == emotion)

    // Filter mode should remain emotionsOnly during confirmation
    #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)

    // Cancel should reset everything
    coordinator.cancel()
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
    #expect(viewModel.layerFilterMode == LayerFilterMode.all)
    #expect(coordinator.selections.primary == nil)
  }

  @Test("Auto-start: Done button network error preserves flow state")
  func autoStart_doneButtonNetworkErrorPreservesState() async {
    let catalog = CatalogTestHelper.createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journalClient = JournalClientMock()
    journalClient.shouldFail = true
    let viewModel = ContentViewModel(repository: repository, journalClient: journalClient)
    await viewModel.loadCatalog()
    let coordinator = FlowCoordinator(contentViewModel: viewModel)

    // Auto-start flow with emotion
    let emotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.startPrimarySelection()
    coordinator.capturePrimary(emotion)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingPrimary)

    // User taps "Done" button - submission fails
    do {
      try await coordinator.submit()
      Issue.record("Expected error to be thrown but submit() succeeded")
    } catch {
      // State should be preserved for retry (not reset)
      #expect(coordinator.selections.primary == emotion)
      #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingPrimary)
      #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)
    }
  }

  @Test("Auto-start: Done button with secondary emotion handles error")
  func autoStart_doneButtonWithSecondaryHandlesError() async {
    let catalog = CatalogTestHelper.createTestCatalog()
    let repository = CatalogRepositoryMock(cached: catalog, result: .success(catalog))
    let journalClient = JournalClientMock()
    journalClient.shouldFail = true
    let viewModel = ContentViewModel(repository: repository, journalClient: journalClient)
    await viewModel.loadCatalog()
    let coordinator = FlowCoordinator(contentViewModel: viewModel)

    // Auto-start and add secondary
    let primaryEmotion = catalog.layers[1].phases[0].medicinal[0]
    let secondaryEmotion = catalog.layers[2].phases[0].medicinal[0]
    coordinator.startPrimarySelection()
    coordinator.capturePrimary(primaryEmotion)
    coordinator.promptForSecondary()
    coordinator.captureSecondary(secondaryEmotion)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingSecondary)

    // User taps "Done" button - submission fails
    do {
      try await coordinator.submit()
      Issue.record("Expected error to be thrown but submit() succeeded")
    } catch {
      // State should be preserved with both emotions
      #expect(coordinator.selections.primary == primaryEmotion)
      #expect(coordinator.selections.secondary == secondaryEmotion)
      #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingSecondary)
      #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)
    }
  }
}
