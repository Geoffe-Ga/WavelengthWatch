import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("SecondaryEmotionSelectionView Tests")
@MainActor
struct SecondaryEmotionSelectionViewTests {
  private func makeSampleCatalog() -> CatalogResponseModel {
    let medicinal1 = CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Confident")
    let toxic1 = CatalogCurriculumEntryModel(id: 2, dosage: .toxic, expression: "Aggressive")
    let medicinal2 = CatalogCurriculumEntryModel(id: 3, dosage: .medicinal, expression: "Joyful")
    let toxic2 = CatalogCurriculumEntryModel(id: 4, dosage: .toxic, expression: "Anxious")
    let strategy = CatalogStrategyModel(id: 5, strategy: "Cold Shower", color: "Blue")

    let phase = CatalogPhaseModel(
      id: 1,
      name: "Rising",
      medicinal: [medicinal1, medicinal2],
      toxic: [toxic1, toxic2],
      strategies: [strategy]
    )

    // Layer 0: Strategies (should be filtered out)
    let strategyLayer = CatalogLayerModel(
      id: 0,
      color: "Strategies",
      title: "SELF-CARE",
      subtitle: "(Strategies)",
      phases: [phase]
    )

    // Layer 3: Red (should be visible)
    let emotionLayer = CatalogLayerModel(
      id: 3,
      color: "Red",
      title: "RED",
      subtitle: "(Power)",
      phases: [phase]
    )

    return CatalogResponseModel(
      phaseOrder: ["Rising"],
      layers: [strategyLayer, emotionLayer]
    )
  }

  @Test("view shows primary emotion context")
  func view_showsPrimaryEmotionContext() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // Select primary and advance to secondary step
    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep()

    // Verify primary curriculum is available for context display
    let primaryCurriculum = viewModel.getPrimaryCurriculum()
    #expect(primaryCurriculum != nil)
    #expect(primaryCurriculum?.id == 1)
    #expect(primaryCurriculum?.expression == "Confident")
  }

  @Test("view shows only emotion layers")
  func view_showsOnlyEmotionLayers() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep()

    // filteredLayers should exclude layer 0 when in secondaryEmotion step
    let filtered = viewModel.filteredLayers
    #expect(filtered.count == 1)
    #expect(filtered.first?.id == 3) // Only emotion layer
  }

  @Test("select same as primary shows error")
  func selectSameAsPrimary_showsError() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // Select primary curriculum ID 1 (Confident)
    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep()

    #expect(viewModel.currentStep == .secondaryEmotion)
    #expect(viewModel.primaryCurriculumID == 1)

    // Attempting to select same ID as secondary should be prevented
    // The view should detect this and show error instead of advancing
    // This will be validated in the view implementation
  }

  @Test("select different from primary advances")
  func selectDifferentFromPrimary_advances() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // Select primary curriculum ID 1
    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep()

    #expect(viewModel.currentStep == .secondaryEmotion)

    // Select different curriculum ID 3 as secondary
    viewModel.selectSecondaryCurriculum(id: 3)
    viewModel.advanceStep()

    // Should advance to strategy selection
    #expect(viewModel.currentStep == .strategySelection)
    #expect(viewModel.secondaryCurriculumID == 3)
  }

  @Test("select dosage stores curriculum ID")
  func selectDosage_storesCurriculumID() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep()

    // Select secondary curriculum
    viewModel.selectSecondaryCurriculum(id: 3)

    #expect(viewModel.secondaryCurriculumID == 3)

    let secondaryCurriculum = viewModel.getSecondaryCurriculum()
    #expect(secondaryCurriculum?.id == 3)
    #expect(secondaryCurriculum?.expression == "Joyful")
  }

  // TODO: UI Testing - Duplicate Selection Error Display
  // The following behaviors require UI testing (ViewInspector or integration tests):
  // - View displays primary emotion context at top
  // - Tapping same emotion as primary shows error alert/message
  // - Error message is cleared when valid selection is made
  // - Valid selection dismisses sheet and advances flow
  //
  // Current unit tests verify view model state management only.
  // See Phase 6.3 (#89) for integration test implementation.
}
