import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("SecondaryEmotionPromptView Tests")
@MainActor
struct SecondaryEmotionPromptViewTests {
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
    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep() // Move to secondaryEmotion step

    // View should be in secondary emotion step
    #expect(viewModel.currentStep == .secondaryEmotion)
  }

  @Test("view shows primary emotion")
  func view_showsPrimaryEmotion() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)
    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep()

    // Verify primary curriculum is stored
    let primaryCurriculum = viewModel.getPrimaryCurriculum()
    #expect(primaryCurriculum != nil)
    #expect(primaryCurriculum?.id == 1)
    #expect(primaryCurriculum?.expression == "Confident")
  }

  @Test("add secondary button advances to secondary selection")
  func addSecondaryButton_advancesToSecondarySelection() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)
    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep()

    #expect(viewModel.currentStep == .secondaryEmotion)

    // Simulate user staying on secondaryEmotion step (will select secondary emotion)
    // The view will stay in secondaryEmotion step until user completes selection
    #expect(viewModel.filterMode == .emotionsOnly)
  }

  @Test("skip button advances to strategy selection")
  func skipButton_advancesToStrategySelection() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)
    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep()

    #expect(viewModel.currentStep == .secondaryEmotion)

    // Simulate skip - advance without selecting secondary
    viewModel.advanceStep()

    #expect(viewModel.currentStep == .strategySelection)
    #expect(viewModel.secondaryCurriculumID == nil)
  }

  @Test("primary emotion displays correctly")
  func primaryEmotion_displaysCorrectly() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // Select a toxic emotion
    viewModel.selectPrimaryCurriculum(id: 2)
    viewModel.advanceStep()

    let primaryCurriculum = viewModel.getPrimaryCurriculum()
    #expect(primaryCurriculum != nil)
    #expect(primaryCurriculum?.id == 2)
    #expect(primaryCurriculum?.expression == "Aggressive")
    #expect(primaryCurriculum?.dosage == .toxic)
  }

  // TODO: UI Testing - Button Interaction
  // The following behaviors require UI testing (ViewInspector or integration tests):
  // - View displays title "Add another emotion?"
  // - View shows primary emotion expression text
  // - Tapping "Add Secondary" button triggers correct navigation
  // - Tapping "Skip" button triggers correct navigation
  //
  // Current unit tests verify view model state management only.
  // See Phase 6.3 (#89) for integration test implementation.
}
