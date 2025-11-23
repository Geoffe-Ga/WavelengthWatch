import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("StrategySelectionView Tests")
@MainActor
struct StrategySelectionViewTests {
  private func makeSampleCatalog() -> CatalogResponseModel {
    let medicinal = CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Confident")
    let toxic = CatalogCurriculumEntryModel(id: 2, dosage: .toxic, expression: "Anxious")
    let strategy1 = CatalogStrategyModel(id: 10, strategy: "Deep Breathing", color: "Blue")
    let strategy2 = CatalogStrategyModel(id: 11, strategy: "Cold Shower", color: "Cyan")

    let risingPhase = CatalogPhaseModel(
      id: 1,
      name: "Rising",
      medicinal: [medicinal],
      toxic: [toxic],
      strategies: [strategy1]
    )

    let peakingPhase = CatalogPhaseModel(
      id: 2,
      name: "Peaking",
      medicinal: [],
      toxic: [],
      strategies: [strategy2]
    )

    // Layer 0: Strategies (should be the ONLY layer visible)
    let strategyLayer = CatalogLayerModel(
      id: 0,
      color: "Strategies",
      title: "SELF-CARE",
      subtitle: "(Strategies)",
      phases: [risingPhase, peakingPhase]
    )

    // Layer 3: Red (should be filtered out)
    let emotionLayer = CatalogLayerModel(
      id: 3,
      color: "Red",
      title: "RED",
      subtitle: "(Power)",
      phases: [risingPhase]
    )

    return CatalogResponseModel(
      phaseOrder: ["Rising", "Peaking"],
      layers: [strategyLayer, emotionLayer]
    )
  }

  @Test("view shows only layer zero")
  func view_showsOnlyLayerZero() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // Select primary and advance to strategy step
    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep() // to secondaryEmotion
    viewModel.advanceStep() // to strategySelection

    #expect(viewModel.currentStep == .strategySelection)

    // filteredLayers should show ONLY layer 0
    let filtered = viewModel.filteredLayers
    #expect(filtered.count == 1)
    #expect(filtered.first?.id == 0)
  }

  @Test("view does not show emotion layers")
  func view_doesNotShowEmotionLayers() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep()
    viewModel.advanceStep()

    let filtered = viewModel.filteredLayers
    let hasEmotionLayers = filtered.contains { $0.id != 0 }
    #expect(hasEmotionLayers == false)
  }

  @Test("view initial phase matches primary emotion")
  func view_initialPhaseMatchesPrimaryEmotion() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // Select primary from "Rising" phase
    viewModel.selectPrimaryCurriculum(id: 1) // Confident from Rising
    viewModel.advanceStep()
    viewModel.advanceStep()

    // The view should determine initial phase based on primary curriculum
    let primaryCurriculum = viewModel.getPrimaryCurriculum()
    #expect(primaryCurriculum != nil)
    // View will need to look up which phase this curriculum belongs to
  }

  @Test("view shows primary emotion context")
  func view_showsPrimaryEmotionContext() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep()
    viewModel.advanceStep()

    // Verify primary curriculum is available for context display
    let primaryCurriculum = viewModel.getPrimaryCurriculum()
    #expect(primaryCurriculum != nil)
    #expect(primaryCurriculum?.expression == "Confident")
  }

  @Test("tap strategy shows confirmation")
  func tapStrategy_showsConfirmation() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep()
    viewModel.advanceStep()

    #expect(viewModel.currentStep == .strategySelection)
    // View will show confirmation sheet/picker when strategy card is tapped
  }

  @Test("select strategy stores strategy ID")
  func selectStrategy_storesStrategyID() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep()
    viewModel.advanceStep()

    // Select a strategy
    viewModel.selectStrategy(id: 10)

    #expect(viewModel.strategyID == 10)

    let strategy = viewModel.getStrategy()
    #expect(strategy?.id == 10)
    #expect(strategy?.strategy == "Deep Breathing")
  }

  @Test("continue without strategy advances to review")
  func continueWithoutStrategy_advancesToReview() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep()
    viewModel.advanceStep()

    #expect(viewModel.currentStep == .strategySelection)

    // Skip strategy selection (it's optional)
    viewModel.advanceStep()

    #expect(viewModel.currentStep == .review)
    #expect(viewModel.strategyID == nil)
  }

  // TODO: UI Testing - Strategy Selection Sheet
  // The following behaviors require UI testing (ViewInspector or integration tests):
  // - View displays primary/secondary emotion context at top
  // - Initial phase scroll position matches primary emotion's phase
  // - Tapping strategy card shows confirmation sheet
  // - Confirmation sheet displays strategy details
  // - Selecting strategy advances to review step
  //
  // Current unit tests verify view model state management only.
  // See Phase 6.3 (#89) for integration test implementation.
}
