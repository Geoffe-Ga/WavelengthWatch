import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("PrimaryEmotionSelectionView Tests")
@MainActor
struct PrimaryEmotionSelectionViewTests {
  private func makeSampleCatalog() -> CatalogResponseModel {
    let medicinal = CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Confident")
    let toxic = CatalogCurriculumEntryModel(id: 2, dosage: .toxic, expression: "Aggressive")
    let strategy = CatalogStrategyModel(id: 3, strategy: "Cold Shower", color: "Blue")

    let phase = CatalogPhaseModel(
      id: 1,
      name: "Rising",
      medicinal: [medicinal],
      toxic: [toxic],
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

  @Test("view shows title")
  func view_showsTitle() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // View should have "Primary Emotion" in navigation title
    // This will be tested via FlowCoordinatorView integration
    #expect(viewModel.currentStep == .primaryEmotion)
  }

  @Test("view shows only emotion layers")
  func view_showsOnlyEmotionLayers() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // filteredLayers should exclude layer 0 when in primaryEmotion step
    let filtered = viewModel.filteredLayers
    #expect(filtered.count == 1)
    #expect(filtered.first?.id == 3) // Only emotion layer
  }

  @Test("view does not show strategy layer")
  func view_doesNotShowStrategyLayer() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    let filtered = viewModel.filteredLayers
    let hasStrategyLayer = filtered.contains { $0.id == 0 }
    #expect(hasStrategyLayer == false)
  }

  @Test("select dosage stores curriculum ID")
  func selectDosage_storesCurriculumID() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    viewModel.selectPrimaryCurriculum(id: 1)

    #expect(viewModel.primaryCurriculumID == 1)
  }

  @Test("select medicine advances to next step")
  func selectMedicine_advancesToNextStep() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    #expect(viewModel.currentStep == .primaryEmotion)

    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep()

    #expect(viewModel.currentStep == .secondaryEmotion)
  }

  @Test("empty phase with no dosage options")
  func emptyPhase_showsFallbackMessage() {
    // Create catalog with phase that has no medicinal or toxic entries
    let emptyPhase = CatalogPhaseModel(
      id: 1,
      name: "Empty",
      medicinal: [],
      toxic: [],
      strategies: []
    )

    let layer = CatalogLayerModel(
      id: 3,
      color: "Red",
      title: "RED",
      subtitle: "(Power)",
      phases: [emptyPhase]
    )

    let catalog = CatalogResponseModel(
      phaseOrder: ["Empty"],
      layers: [layer]
    )

    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // Verify the view model can handle empty phases
    #expect(viewModel.filteredLayers.count == 1)
    #expect(viewModel.filteredLayers.first?.phases.first?.medicinal.isEmpty == true)
    #expect(viewModel.filteredLayers.first?.phases.first?.toxic.isEmpty == true)
  }

  // TODO: UI Testing - Sheet Presentation and Interaction
  // The following behaviors require UI testing (ViewInspector or integration tests):
  // - Tapping phase card presents dosage picker sheet
  // - Cancel button dismisses sheet without storing selection
  // - Selecting dosage dismisses sheet and stores curriculum ID
  // - Rapid selection then dismissal cancels pending advancement
  // - Empty phase displays "No dosage options available" message
  //
  // Current unit tests verify view model state management only.
  // See Phase 6.3 (#89) for integration test implementation.
}
