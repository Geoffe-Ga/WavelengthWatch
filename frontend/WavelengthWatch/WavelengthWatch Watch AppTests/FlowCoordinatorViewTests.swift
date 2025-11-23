import SwiftUI
import Testing

@testable import WavelengthWatch_Watch_App

/// Tests for FlowCoordinatorView managing the emotion logging flow presentation.
///
/// The coordinator owns the NavigationStack and presents the flow as a sheet,
/// managing the flow's lifecycle from initialization to cancellation.
@MainActor
struct FlowCoordinatorViewTests {
  private class MockJournalClient: JournalClientProtocol {
    func submit(curriculumID: Int, secondaryCurriculumID: Int?, strategyID: Int?, initiatedBy: InitiatedBy) async throws -> JournalResponseModel {
      JournalResponseModel(id: 1, curriculumID: curriculumID, secondaryCurriculumID: secondaryCurriculumID, strategyID: strategyID, initiatedBy: initiatedBy)
    }
  }

  private func createTestCatalog() -> CatalogResponseModel {
    let phase = CatalogPhaseModel(
      id: 1,
      name: "Rising",
      medicinal: [
        CatalogCurriculumEntryModel(id: 10, dosage: .medicinal, expression: "Joy"),
      ],
      toxic: [
        CatalogCurriculumEntryModel(id: 20, dosage: .toxic, expression: "Anger"),
      ],
      strategies: [
        CatalogStrategyModel(id: 100, strategy: "Deep breathing", color: "Blue"),
      ]
    )

    let layers = [
      CatalogLayerModel(id: 0, color: "Strategies", title: "SELF-CARE", subtitle: "(Strategies)", phases: [phase]),
      CatalogLayerModel(id: 1, color: "Beige", title: "BEIGE", subtitle: "(Survival)", phases: [phase]),
    ]

    return CatalogResponseModel(phaseOrder: ["Rising"], layers: layers)
  }

  @Test func init_createsFlowViewModel() async {
    let catalog = createTestCatalog()
    let coordinator = FlowCoordinatorView(catalog: catalog, initiatedBy: .self_initiated, journalClient: MockJournalClient())

    // The coordinator should create a JournalFlowViewModel internally
    // We'll verify this by checking that the view renders without crashing
    #expect(coordinator.catalog.layers.count == 2)
  }

  @Test func cancel_resetsFlow() async {
    let catalog = createTestCatalog()

    // Create a separate flowViewModel to test reset behavior
    let flowViewModel = await JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // Simulate user making a selection
    await flowViewModel.selectPrimaryCurriculum(id: 10)
    await flowViewModel.advanceStep()

    #expect(flowViewModel.currentStep == .secondaryEmotion)
    #expect(flowViewModel.primaryCurriculumID == 10)

    // Reset (simulating what cancel does)
    await flowViewModel.reset()

    // Flow should be reset to beginning
    #expect(flowViewModel.currentStep == .primaryEmotion)
    #expect(flowViewModel.primaryCurriculumID == nil)
  }

  @Test func cancel_dismissesSheet() async {
    let catalog = createTestCatalog()
    var isPresented = true
    let binding = Binding(
      get: { isPresented },
      set: { isPresented = $0 }
    )

    let coordinator = FlowCoordinatorView(
      catalog: catalog,
      initiatedBy: .self_initiated,
      journalClient: MockJournalClient(),
      isPresented: binding
    )

    #expect(isPresented == true)

    // Cancel the flow
    coordinator.cancel()

    // Sheet should be dismissed
    #expect(isPresented == false)
  }

  @Test func currentStepView_showsPrimaryInitially() async {
    let catalog = createTestCatalog()
    let coordinator = FlowCoordinatorView(catalog: catalog, initiatedBy: .self_initiated, journalClient: MockJournalClient())

    // Coordinator should start at primary emotion step
    #expect(coordinator.flowViewModel.currentStep == .primaryEmotion)

    // Filtered layers should be emotions-only
    #expect(coordinator.flowViewModel.filteredLayers.count == 1)
    #expect(coordinator.flowViewModel.filteredLayers.allSatisfy { $0.id != 0 })
  }

  @Test func navigation_preservesFlowViewModel() async {
    let catalog = createTestCatalog()

    // Create a flowViewModel to test state preservation across navigation steps
    let flowViewModel = await JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // Make a selection
    await flowViewModel.selectPrimaryCurriculum(id: 10)

    // Advance to next step
    await flowViewModel.advanceStep()

    // ViewModel state should be preserved across navigation
    #expect(flowViewModel.primaryCurriculumID == 10)
    #expect(flowViewModel.currentStep == .secondaryEmotion)
  }

  @Test func secondaryEmotion_showsPromptInitially() async {
    let catalog = createTestCatalog()
    let flowViewModel = await JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // Advance to secondary emotion step
    await flowViewModel.selectPrimaryCurriculum(id: 10)
    await flowViewModel.advanceStep()

    // Should be in secondary emotion step (where prompt will be shown)
    #expect(flowViewModel.currentStep == .secondaryEmotion)
    #expect(flowViewModel.getPrimaryCurriculum() != nil)
  }

  @Test func secondaryEmotion_skipAdvancesToStrategy() async {
    let catalog = createTestCatalog()
    let flowViewModel = await JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // Advance to secondary emotion step
    await flowViewModel.selectPrimaryCurriculum(id: 10)
    await flowViewModel.advanceStep()

    #expect(flowViewModel.currentStep == .secondaryEmotion)

    // Skip secondary emotion (what prompt's skip button does)
    await flowViewModel.advanceStep()

    // Should advance to strategy selection without secondary emotion
    #expect(flowViewModel.currentStep == .strategySelection)
    #expect(flowViewModel.secondaryCurriculumID == nil)
  }

  @Test func cancel_resetsPickerState() async {
    let catalog = createTestCatalog()
    let flowViewModel = await JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // Advance to secondary emotion step and select primary
    await flowViewModel.selectPrimaryCurriculum(id: 10)
    await flowViewModel.advanceStep()

    #expect(flowViewModel.currentStep == .secondaryEmotion)

    // Reset (simulating what cancel does)
    await flowViewModel.reset()

    // Flow should be reset to beginning
    #expect(flowViewModel.currentStep == .primaryEmotion)
    #expect(flowViewModel.primaryCurriculumID == nil)
    // Note: FlowCoordinatorView's showingSecondaryEmotionPicker would also reset via onChange
  }

  @Test func stepChange_resetsPickerState() async {
    let catalog = createTestCatalog()
    let flowViewModel = await JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // Simulate the flow: primary -> secondary -> strategy -> back to primary (via reset)
    await flowViewModel.selectPrimaryCurriculum(id: 10)
    await flowViewModel.advanceStep()

    #expect(flowViewModel.currentStep == .secondaryEmotion)

    // Skip to strategy
    await flowViewModel.advanceStep()
    #expect(flowViewModel.currentStep == .strategySelection)

    // Reset flow (simulates navigating back or canceling)
    await flowViewModel.reset()

    // Should be back at primary emotion
    #expect(flowViewModel.currentStep == .primaryEmotion)
    // Note: showingSecondaryEmotionPicker is FlowCoordinatorView state that resets via onChange
  }
}
