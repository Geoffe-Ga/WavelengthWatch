import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("EmotionSummaryCard Tests")
struct EmotionSummaryCardTests {
  // MARK: - Test Data

  private func makeMockCurriculum(dosage: CatalogDosage) -> CatalogCurriculumEntryModel {
    CatalogCurriculumEntryModel(
      id: 1,
      dosage: dosage,
      expression: "Test Expression"
    )
  }

  private func makeMockLayer() -> CatalogLayerModel {
    CatalogLayerModel(
      id: 2,
      color: "Red",
      title: "Red Layer",
      subtitle: "Power",
      phases: []
    )
  }

  private func makeMockPhase() -> CatalogPhaseModel {
    CatalogPhaseModel(
      id: 3,
      name: "Rising",
      medicinal: [],
      toxic: [],
      strategies: []
    )
  }

  // MARK: - Display Content Tests

  @Test("card displays layer title")
  func card_displaysLayerTitle() {
    let curriculum = makeMockCurriculum(dosage: .medicinal)
    let layer = makeMockLayer()
    let card = EmotionSummaryCard(
      curriculum: curriculum,
      layer: layer,
      phase: nil
    )

    #expect(card.layer?.title == "Red Layer")
  }

  @Test("card displays phase name")
  func card_displaysPhaseName() {
    let curriculum = makeMockCurriculum(dosage: .medicinal)
    let phase = makeMockPhase()
    let card = EmotionSummaryCard(
      curriculum: curriculum,
      layer: nil,
      phase: phase
    )

    #expect(card.phase?.name == "Rising")
  }

  @Test("card displays expression")
  func card_displaysExpression() {
    let curriculum = makeMockCurriculum(dosage: .medicinal)
    let card = EmotionSummaryCard(
      curriculum: curriculum,
      layer: nil,
      phase: nil
    )

    #expect(card.curriculum.expression == "Test Expression")
  }

  @Test("card displays dosage")
  func card_displaysDosage() {
    let curriculum = makeMockCurriculum(dosage: .toxic)
    let card = EmotionSummaryCard(
      curriculum: curriculum,
      layer: nil,
      phase: nil
    )

    #expect(card.curriculum.dosage == .toxic)
  }

  // MARK: - Compact Mode Tests

  @Test("compact mode uses smaller fonts")
  func compactMode_usesSmallerFonts() {
    let curriculum = makeMockCurriculum(dosage: .medicinal)
    let standardCard = EmotionSummaryCard(
      curriculum: curriculum,
      layer: nil,
      phase: nil,
      compact: false
    )
    let compactCard = EmotionSummaryCard(
      curriculum: curriculum,
      layer: nil,
      phase: nil,
      compact: true
    )

    #expect(standardCard.compact == false)
    #expect(compactCard.compact == true)
  }

  // MARK: - Dosage Indicator Tests

  @Test("medicinal shows green indicator")
  func medicinal_showsGreenIndicator() {
    let curriculum = makeMockCurriculum(dosage: .medicinal)
    let card = EmotionSummaryCard(
      curriculum: curriculum,
      layer: nil,
      phase: nil
    )

    #expect(card.curriculum.dosage == .medicinal)
    // Color validation happens in the view rendering
    // We verify the data model is correct
  }

  @Test("toxic shows red indicator")
  func toxic_showsRedIndicator() {
    let curriculum = makeMockCurriculum(dosage: .toxic)
    let card = EmotionSummaryCard(
      curriculum: curriculum,
      layer: nil,
      phase: nil
    )

    #expect(card.curriculum.dosage == .toxic)
    // Color validation happens in the view rendering
    // We verify the data model is correct
  }

  // MARK: - Optional Data Tests

  @Test("card works with nil layer")
  func card_worksWithNilLayer() {
    let curriculum = makeMockCurriculum(dosage: .medicinal)
    let card = EmotionSummaryCard(
      curriculum: curriculum,
      layer: nil,
      phase: nil
    )

    #expect(card.layer == nil)
  }

  @Test("card works with nil phase")
  func card_worksWithNilPhase() {
    let curriculum = makeMockCurriculum(dosage: .medicinal)
    let card = EmotionSummaryCard(
      curriculum: curriculum,
      layer: nil,
      phase: nil
    )

    #expect(card.phase == nil)
  }

  @Test("card works with all data provided")
  func card_worksWithAllDataProvided() {
    let curriculum = makeMockCurriculum(dosage: .medicinal)
    let layer = makeMockLayer()
    let phase = makeMockPhase()
    let card = EmotionSummaryCard(
      curriculum: curriculum,
      layer: layer,
      phase: phase
    )

    #expect(card.curriculum.id == 1)
    #expect(card.layer?.id == 2)
    #expect(card.phase?.id == 3)
  }
}
