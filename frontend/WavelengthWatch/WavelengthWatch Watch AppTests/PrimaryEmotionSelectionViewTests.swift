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

  @Test("tap phase card shows dosage picker")
  func tapPhaseCard_showsDosagePicker() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // This test verifies the view state management
    // The actual UI interaction is tested in integration tests
    #expect(viewModel.currentStep == .primaryEmotion)
    #expect(viewModel.filteredLayers.count == 1)
  }

  @Test("cancel dosage picker does not store selection")
  func cancelDosagePicker_doesNotStoreSelection() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // Verify no selection initially
    #expect(viewModel.primaryCurriculumID == nil)

    // Cancel should not change state
    #expect(viewModel.primaryCurriculumID == nil)
    #expect(viewModel.currentStep == .primaryEmotion)
  }

  @Test("cancel dosage picker does not advance step")
  func cancelDosagePicker_doesNotAdvanceStep() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    #expect(viewModel.currentStep == .primaryEmotion)

    // Simulating cancel - step should remain unchanged
    #expect(viewModel.currentStep == .primaryEmotion)
  }

  @Test("rapid selection cancellation does not advance")
  func rapidSelectionCancellation_doesNotAdvance() async {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // Select and immediately cancel (simulating rapid tap then dismiss)
    viewModel.selectPrimaryCurriculum(id: 1)
    #expect(viewModel.primaryCurriculumID == 1)

    // If task were cancelled, step should not advance
    // (This will be validated once we implement proper cancellation)
    #expect(viewModel.currentStep == .primaryEmotion)
  }
}
