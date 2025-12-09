import Testing
@testable import WavelengthWatch_Watch_App

/// Tests for FlowCoordinator state management
///
/// FlowCoordinator manages the emotion logging flow state machine without any UI logic.
/// It controls ContentViewModel.layerFilterMode and tracks user selections.
@MainActor
struct FlowCoordinatorTests {
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

  // MARK: - Initialization Tests

  @Test("FlowCoordinator initializes with idle state")
  func initialization_setsIdleState() async {
    let (_, coordinator, _) = await createTestSetup()

    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
    #expect(coordinator.selections.primary == nil)
    #expect(coordinator.selections.secondary == nil)
    #expect(coordinator.selections.strategy == nil)
  }

  // MARK: - Start Flow Tests

  @Test("startPrimarySelection sets emotionsOnly filter and selectingPrimary state")
  func startPrimarySelection_setsEmotionsOnlyFilter() async {
    let (viewModel, coordinator, _) = await createTestSetup()

    coordinator.startPrimarySelection()

    #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.selectingPrimary)
  }

  // MARK: - Capture Selection Tests

  @Test("capturePrimary stores selection and advances to confirmingPrimary")
  func capturePrimary_storesSelectionAndAdvances() async {
    let (_, coordinator, catalog) = await createTestSetup()

    let emotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(emotion)

    #expect(coordinator.selections.primary == emotion)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingPrimary)
  }

  @Test("captureSecondary stores selection and advances to confirmingSecondary")
  func captureSecondary_storesSelectionAndAdvances() async {
    let (_, coordinator, catalog) = await createTestSetup()

    let secondaryEmotion = catalog.layers[2].phases[0].medicinal[0]
    coordinator.captureSecondary(secondaryEmotion)

    #expect(coordinator.selections.secondary == secondaryEmotion)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingSecondary)
  }

  @Test("captureSecondary with nil advances to confirmingSecondary with no selection")
  func captureSecondary_withNil_advancesWithoutSelection() async {
    let (_, coordinator, _) = await createTestSetup()

    coordinator.captureSecondary(nil as CatalogCurriculumEntryModel?)

    #expect(coordinator.selections.secondary == nil)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingSecondary)
  }

  @Test("captureStrategy stores selection and advances to confirmingStrategy")
  func captureStrategy_storesSelectionAndAdvances() async {
    let (_, coordinator, catalog) = await createTestSetup()

    let strategy = catalog.layers[0].phases[0].strategies[0]
    coordinator.captureStrategy(strategy)

    #expect(coordinator.selections.strategy == strategy)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingStrategy)
  }

  @Test("captureStrategy with nil advances to confirmingStrategy with no selection")
  func captureStrategy_withNil_advancesWithoutSelection() async {
    let (_, coordinator, _) = await createTestSetup()

    coordinator.captureStrategy(nil as CatalogStrategyModel?)

    #expect(coordinator.selections.strategy == nil)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingStrategy)
  }

  // MARK: - Navigation Tests

  @Test("promptForSecondary sets emotionsOnly filter and selectingSecondary state")
  func promptForSecondary_setsEmotionsOnlyFilter() async {
    let (viewModel, coordinator, _) = await createTestSetup()

    coordinator.promptForSecondary()

    #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.selectingSecondary)
  }

  @Test("promptForStrategy sets strategiesOnly filter and selectingStrategy state")
  func promptForStrategy_setsStrategiesOnlyFilter() async {
    let (viewModel, coordinator, _) = await createTestSetup()

    coordinator.promptForStrategy()

    #expect(viewModel.layerFilterMode == LayerFilterMode.strategiesOnly)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.selectingStrategy)
  }

  @Test("showReview advances to review state")
  func showReview_advancesToReviewState() async {
    let (_, coordinator, _) = await createTestSetup()

    coordinator.showReview()

    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.review)
  }

  // MARK: - Cancellation Tests

  @Test("cancel resets to idle state and clears selections")
  func cancel_resetsState() async {
    let (viewModel, coordinator, catalog) = await createTestSetup()

    // Set up some state
    let emotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(emotion)
    coordinator.promptForSecondary()

    coordinator.cancel()

    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
    #expect(coordinator.selections.primary == nil)
    #expect(coordinator.selections.secondary == nil)
    #expect(coordinator.selections.strategy == nil)
    #expect(viewModel.layerFilterMode == LayerFilterMode.all)
  }

  @Test("reset clears selections and returns to idle")
  func reset_clearsSelectionsAndReturnsToIdle() async {
    let (_, coordinator, catalog) = await createTestSetup()

    // Set up some state
    let emotion = catalog.layers[1].phases[0].medicinal[0]
    let strategy = catalog.layers[0].phases[0].strategies[0]
    coordinator.capturePrimary(emotion)
    coordinator.captureStrategy(strategy)

    coordinator.reset()

    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
    #expect(coordinator.selections.primary == nil)
    #expect(coordinator.selections.secondary == nil)
    #expect(coordinator.selections.strategy == nil)
  }

  // MARK: - Full Flow Tests

  @Test("full flow: primary only")
  func flowProgression_primaryOnly() async {
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
  }

  @Test("full flow: primary + secondary + strategy")
  func flowProgression_fullFlow() async {
    let (viewModel, coordinator, catalog) = await createTestSetup()

    // Start flow
    coordinator.startPrimarySelection()
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.selectingPrimary)

    // Capture primary
    let primaryEmotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(primaryEmotion)
    #expect(coordinator.selections.primary == primaryEmotion)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingPrimary)

    // Prompt for secondary
    coordinator.promptForSecondary()
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.selectingSecondary)
    #expect(viewModel.layerFilterMode == LayerFilterMode.emotionsOnly)

    // Capture secondary
    let secondaryEmotion = catalog.layers[2].phases[0].medicinal[0]
    coordinator.captureSecondary(secondaryEmotion)
    #expect(coordinator.selections.secondary == secondaryEmotion)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingSecondary)

    // Prompt for strategy
    coordinator.promptForStrategy()
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.selectingStrategy)
    #expect(viewModel.layerFilterMode == LayerFilterMode.strategiesOnly)

    // Capture strategy
    let strategy = catalog.layers[0].phases[0].strategies[0]
    coordinator.captureStrategy(strategy)
    #expect(coordinator.selections.strategy == strategy)
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.confirmingStrategy)

    // Show review
    coordinator.showReview()
    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.review)
  }

  @Test("cancel at any step resets state")
  func flowCancellation_resetsState() async {
    let (viewModel, coordinator, catalog) = await createTestSetup()

    // Start flow and capture primary
    coordinator.startPrimarySelection()
    let emotion = catalog.layers[1].phases[0].medicinal[0]
    coordinator.capturePrimary(emotion)

    // Cancel mid-flow
    coordinator.cancel()

    #expect(coordinator.currentStep == FlowCoordinator.FlowStep.idle)
    #expect(coordinator.selections.primary == nil)
    #expect(viewModel.layerFilterMode == LayerFilterMode.all)
  }
}

// MARK: - Test Helpers

enum CatalogTestHelper {
  static func createTestCatalog() -> CatalogResponseModel {
    CatalogResponseModel(
      phaseOrder: ["Rising", "Peaking", "Falling"],
      layers: [
        // Layer 0: Strategies
        CatalogLayerModel(
          id: 0,
          color: "Strategies",
          title: "SELF-CARE",
          subtitle: "(Strategies)",
          phases: [
            CatalogPhaseModel(
              id: 1,
              name: "Rising",
              medicinal: [],
              toxic: [],
              strategies: [
                CatalogStrategyModel(id: 1, strategy: "Deep Breathing", color: "Blue"),
                CatalogStrategyModel(id: 2, strategy: "Cold Shower", color: "Cyan"),
              ]
            ),
          ]
        ),
        // Layer 1: Beige
        CatalogLayerModel(
          id: 1,
          color: "Beige",
          title: "BEIGE",
          subtitle: "(Survival)",
          phases: [
            CatalogPhaseModel(
              id: 2,
              name: "Rising",
              medicinal: [
                CatalogCurriculumEntryModel(id: 10, dosage: .medicinal, expression: "Grounded"),
              ],
              toxic: [
                CatalogCurriculumEntryModel(id: 11, dosage: .toxic, expression: "Numb"),
              ],
              strategies: []
            ),
          ]
        ),
        // Layer 2: Purple
        CatalogLayerModel(
          id: 2,
          color: "Purple",
          title: "PURPLE",
          subtitle: "(Tribal)",
          phases: [
            CatalogPhaseModel(
              id: 3,
              name: "Rising",
              medicinal: [
                CatalogCurriculumEntryModel(id: 20, dosage: .medicinal, expression: "Connected"),
              ],
              toxic: [
                CatalogCurriculumEntryModel(id: 21, dosage: .toxic, expression: "Dependent"),
              ],
              strategies: []
            ),
          ]
        ),
      ]
    )
  }
}
