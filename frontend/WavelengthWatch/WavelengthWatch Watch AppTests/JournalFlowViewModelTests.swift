import SwiftUI
import Testing

@testable import WavelengthWatch_Watch_App

/// Tests for JournalFlowViewModel managing the multi-step emotion logging flow.
///
/// The flow progresses through these steps:
/// 1. Primary emotion selection (emotions-only filter)
/// 2. Secondary emotion selection (emotions-only filter, optional)
/// 3. Strategy selection (strategies-only filter, optional)
/// 4. Review and submit
@MainActor
struct JournalFlowViewModelTests {
  private func createTestCatalog() -> CatalogResponseModel {
    let phase = CatalogPhaseModel(
      id: 1,
      name: "Rising",
      medicinal: [
        CatalogCurriculumEntryModel(id: 10, dosage: .medicinal, expression: "Joy"),
        CatalogCurriculumEntryModel(id: 11, dosage: .medicinal, expression: "Peace"),
      ],
      toxic: [
        CatalogCurriculumEntryModel(id: 20, dosage: .toxic, expression: "Anger"),
      ],
      strategies: [
        CatalogStrategyModel(id: 100, strategy: "Deep breathing", color: "Blue"),
        CatalogStrategyModel(id: 101, strategy: "Meditation", color: "Green"),
      ]
    )

    let layers = [
      CatalogLayerModel(id: 0, color: "Strategies", title: "SELF-CARE", subtitle: "(Strategies)", phases: [phase]),
      CatalogLayerModel(id: 1, color: "Beige", title: "BEIGE", subtitle: "(Survival)", phases: [phase]),
      CatalogLayerModel(id: 2, color: "Purple", title: "PURPLE", subtitle: "(Tribal)", phases: [phase]),
    ]

    return CatalogResponseModel(phaseOrder: ["Rising"], layers: layers)
  }

  @Test func init_startsAtPrimaryEmotion() async {
    let catalog = createTestCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog)

    #expect(viewModel.currentStep == .primaryEmotion)
  }

  @Test func init_defaultsToSelfInitiated() async {
    let catalog = createTestCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog)

    #expect(viewModel.initiatedBy == .self_initiated)
  }

  @Test func filteredLayers_returnsEmotionsOnly_initially() async {
    let catalog = createTestCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog)

    // Initial step is primary emotion, should filter to emotions only (exclude layer 0)
    let filteredLayers = viewModel.filteredLayers
    #expect(filteredLayers.count == 2)
    #expect(filteredLayers.allSatisfy { $0.id != 0 })
  }

  @Test func canProceed_fromPrimary_requiresSelection() async {
    let catalog = createTestCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog)

    // No selection yet, cannot proceed
    #expect(viewModel.canProceed == false)

    // Select a primary emotion
    viewModel.selectPrimaryCurriculum(id: 10)

    // Now can proceed
    #expect(viewModel.canProceed == true)
  }

  @Test func reset_clearsAllSelections() async {
    let catalog = createTestCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog)

    // Make selections
    viewModel.selectPrimaryCurriculum(id: 10)
    viewModel.advanceStep()
    viewModel.selectSecondaryCurriculum(id: 11)

    #expect(viewModel.primaryCurriculumID != nil)
    #expect(viewModel.secondaryCurriculumID != nil)

    // Reset
    viewModel.reset()

    // All selections cleared and back to start
    #expect(viewModel.primaryCurriculumID == nil)
    #expect(viewModel.secondaryCurriculumID == nil)
    #expect(viewModel.strategyID == nil)
    #expect(viewModel.currentStep == .primaryEmotion)
  }

  @Test func advance_updatesCurrentStep() async {
    let catalog = createTestCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog)

    // Start at primary emotion
    #expect(viewModel.currentStep == .primaryEmotion)

    // Select and advance
    viewModel.selectPrimaryCurriculum(id: 10)
    viewModel.advanceStep()

    // Should be at secondary emotion
    #expect(viewModel.currentStep == .secondaryEmotion)

    // Advance again (skip secondary)
    viewModel.advanceStep()

    // Should be at strategy selection
    #expect(viewModel.currentStep == .strategySelection)

    // Advance again
    viewModel.advanceStep()

    // Should be at review
    #expect(viewModel.currentStep == .review)
  }

  @Test func getPrimaryCurriculum_returnsCurriculum_whenSelected() async {
    let catalog = createTestCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog)

    // No selection yet
    #expect(viewModel.getPrimaryCurriculum() == nil)

    // Select curriculum ID 10 (Joy from Beige layer)
    viewModel.selectPrimaryCurriculum(id: 10)

    // Should return the curriculum entry
    let curriculum = viewModel.getPrimaryCurriculum()
    #expect(curriculum != nil)
    #expect(curriculum?.id == 10)
    #expect(curriculum?.expression == "Joy")
  }
}
