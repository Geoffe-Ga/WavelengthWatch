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
  private func makeMockMedicinalEntry(id: Int = 1, expression: String = "Grounded") -> CatalogCurriculumEntryModel {
    CatalogCurriculumEntryModel(id: id, dosage: .medicinal, expression: expression)
  }

  private func makeMockToxicEntry(id: Int = 2, expression: String = "Numb") -> CatalogCurriculumEntryModel {
    CatalogCurriculumEntryModel(id: id, dosage: .toxic, expression: expression)
  }

  // MARK: - CurriculumCard

  @Test("CurriculumCard stores its title")
  func curriculumCard_storesTitle() {
    let card = CurriculumCard(
      title: "Medicinal",
      expression: "Commitment",
      accent: .red,
      actionTitle: "Log",
      entry: makeMockMedicinalEntry(id: 10, expression: "Commitment")
    )

    #expect(card.title == "Medicinal")
    #expect(card.actionTitle == "Log")
  }

  @Test("CurriculumCard stores its expression")
  func curriculumCard_storesExpression() {
    let card = CurriculumCard(
      title: "Medicinal",
      expression: "Commitment",
      accent: .red,
      actionTitle: "Log",
      entry: makeMockMedicinalEntry(id: 10, expression: "Commitment")
    )

    #expect(card.expression == "Commitment")
  }

  @Test("CurriculumCard stores its entry")
  func curriculumCard_storesEntry() {
    let card = CurriculumCard(
      title: "Toxic",
      expression: "Overcommitment",
      accent: .red,
      actionTitle: "Log",
      entry: makeMockToxicEntry(id: 11, expression: "Overcommitment")
    )

    #expect(card.entry.id == 11)
    #expect(card.entry.dosage == .toxic)
  }

  // MARK: - StrategyCard

  @Test("StrategyCard stores its strategy")
  func strategyCard_storesStrategy() {
    let strategy = CatalogStrategyModel(id: 5, strategy: "Cold Shower", color: "Beige")
    let phase = CatalogPhaseModel(id: 1, name: "Rising", medicinal: [], toxic: [], strategies: [strategy])
    let card = StrategyCard(strategy: strategy, color: .brown, phase: phase)

    #expect(card.strategy.strategy == "Cold Shower")
    #expect(card.strategy.color == "Beige")
  }

  @Test("StrategyCard stores its phase, including curriculum entries")
  func strategyCard_storesPhaseWithCurriculum() {
    // A populated phase is the path where the journal icon is shown
    // (private `primaryID` resolves non-nil); behavioral coverage of that
    // visibility needs a UI-testing layer, so this asserts the stored data.
    let strategy = CatalogStrategyModel(id: 5, strategy: "Cold Shower", color: "Beige")
    let phase = CatalogPhaseModel(
      id: 1,
      name: "Rising",
      medicinal: [makeMockMedicinalEntry(id: 10, expression: "Commitment")],
      toxic: [],
      strategies: [strategy]
    )
    let card = StrategyCard(strategy: strategy, color: .brown, phase: phase)

    #expect(card.phase.name == "Rising")
    #expect(card.phase.medicinal.first?.id == 10)
  }

  // MARK: - StrategyListView

  /// `fallbackCurriculumID` is private and depends on @EnvironmentObject
  /// viewModel.layers, so behavioral coverage requires integration tests; this
  /// asserts the data the list is initialized with.
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

  @Test("ClearLightEmotionCard stores its emotion")
  func clearLightCard_storesEmotion() {
    let emotion = LayeredEmotion(layerId: 3, entry: makeMockMedicinalEntry(id: 20, expression: "Connected"), layerTitle: "PURPLE", layerColor: "Purple")
    let card = ClearLightEmotionCard(emotion: emotion, dosageType: .medicinal)

    #expect(card.emotion.entry.expression == "Connected")
    #expect(card.emotion.layerTitle == "PURPLE")
  }

  @Test("ClearLightEmotionCard stores its dosage type")
  func clearLightCard_storesDosage() {
    let emotion = LayeredEmotion(layerId: 3, entry: makeMockToxicEntry(id: 21, expression: "Dependent"), layerTitle: "PURPLE", layerColor: "Purple")
    let card = ClearLightEmotionCard(emotion: emotion, dosageType: .toxic)

    #expect(card.dosageType == .toxic)
  }

  // MARK: - LayeredEmotion derived logic

  @Test("LayeredEmotion composes a unique id from layer and entry")
  func layeredEmotion_composesID() {
    let emotion = LayeredEmotion(layerId: 3, entry: makeMockMedicinalEntry(id: 20, expression: "Connected"), layerTitle: "PURPLE", layerColor: "Purple")

    #expect(emotion.id == "3-20")
  }

  @Test("LayeredEmotion resolves source color from its layer color name")
  func layeredEmotion_resolvesSourceColor() {
    let purple = LayeredEmotion(layerId: 3, entry: makeMockMedicinalEntry(), layerTitle: "PURPLE", layerColor: "Purple")
    let beige = LayeredEmotion(layerId: 1, entry: makeMockMedicinalEntry(), layerTitle: "BEIGE", layerColor: "Beige")

    #expect(purple.sourceColor == Color(stage: "Purple"))
    #expect(beige.sourceColor == Color(stage: "Beige"))
  }
}
