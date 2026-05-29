import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

/// Stored-property / display-data tests for the Curriculum card views.
///
/// These views drive their journal-logging behavior through `@EnvironmentObject`
/// (ContentViewModel / FlowCoordinator), which isn't resolved at construction
/// time, so the unit-testable surface is the data each card is initialized with
/// and the values it will render — mirroring `EmotionSummaryCardTests`.
struct CurriculumCardTests {
  private func medicinal(_ id: Int = 1, _ expression: String = "Grounded") -> CatalogCurriculumEntryModel {
    CatalogCurriculumEntryModel(id: id, dosage: .medicinal, expression: expression)
  }

  private func toxic(_ id: Int = 2, _ expression: String = "Numb") -> CatalogCurriculumEntryModel {
    CatalogCurriculumEntryModel(id: id, dosage: .toxic, expression: expression)
  }

  // MARK: - CurriculumCard

  @Test("CurriculumCard stores its display data")
  func curriculumCard_storesData() {
    let entry = medicinal(10, "Commitment")
    let card = CurriculumCard(
      title: "Medicinal",
      expression: "Commitment",
      accent: .red,
      actionTitle: "Log",
      entry: entry
    )

    #expect(card.title == "Medicinal")
    #expect(card.expression == "Commitment")
    #expect(card.actionTitle == "Log")
    #expect(card.entry.id == 10)
    #expect(card.entry.dosage == .medicinal)
  }

  // MARK: - StrategyCard

  @Test("StrategyCard stores strategy and phase")
  func strategyCard_storesData() {
    let strategy = CatalogStrategyModel(id: 5, strategy: "Cold Shower", color: "Beige")
    let phase = CatalogPhaseModel(id: 1, name: "Rising", medicinal: [medicinal()], toxic: [toxic()], strategies: [strategy])
    let card = StrategyCard(strategy: strategy, color: .brown, phase: phase)

    #expect(card.strategy.strategy == "Cold Shower")
    #expect(card.strategy.color == "Beige")
    #expect(card.phase.name == "Rising")
  }

  // MARK: - StrategyListView

  @Test("StrategyListView stores phase and exposes its strategies")
  func strategyListView_storesPhase() {
    let strategies = [
      CatalogStrategyModel(id: 1, strategy: "Deep Breathing", color: "Blue"),
      CatalogStrategyModel(id: 2, strategy: "Jogging", color: "Red"),
    ]
    let phase = CatalogPhaseModel(id: 1, name: "Peaking", medicinal: [], toxic: [], strategies: strategies)
    let view = StrategyListView(phase: phase, color: .blue)

    #expect(view.phase.name == "Peaking")
    #expect(view.phase.strategies.count == 2)
  }

  // MARK: - ClearLightEmotionCard

  @Test("ClearLightEmotionCard stores emotion and dosage")
  func clearLightCard_storesData() {
    let emotion = LayeredEmotion(layerId: 3, entry: medicinal(20, "Connected"), layerTitle: "PURPLE", layerColor: "Purple")
    let card = ClearLightEmotionCard(emotion: emotion, dosageType: .medicinal)

    #expect(card.emotion.entry.expression == "Connected")
    #expect(card.emotion.layerTitle == "PURPLE")
    #expect(card.dosageType == .medicinal)
  }

  // MARK: - LayeredEmotion derived logic

  @Test("LayeredEmotion composes a unique id from layer and entry")
  func layeredEmotion_composesID() {
    let emotion = LayeredEmotion(layerId: 3, entry: medicinal(20, "Connected"), layerTitle: "PURPLE", layerColor: "Purple")

    #expect(emotion.id == "3-20")
  }

  @Test("LayeredEmotion resolves source color from its layer color name")
  func layeredEmotion_resolvesSourceColor() {
    let purple = LayeredEmotion(layerId: 3, entry: medicinal(), layerTitle: "PURPLE", layerColor: "Purple")
    let beige = LayeredEmotion(layerId: 1, entry: medicinal(), layerTitle: "BEIGE", layerColor: "Beige")

    #expect(purple.sourceColor == Color(stage: "Purple"))
    #expect(beige.sourceColor == Color(stage: "Beige"))
  }
}
