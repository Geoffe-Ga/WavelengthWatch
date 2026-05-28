import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

struct EmotionExpressionCardTests {
  @Test("card stores label")
  func card_storesLabel() {
    let card = EmotionExpressionCard(
      label: "Primary Emotion",
      expression: "Gratitude",
      dosage: .medicinal
    )

    #expect(card.label == "Primary Emotion")
  }

  @Test("card stores expression")
  func card_storesExpression() {
    let card = EmotionExpressionCard(
      label: "Secondary Emotion",
      expression: "Resentment",
      dosage: .toxic
    )

    #expect(card.expression == "Resentment")
  }

  @Test("card stores medicinal dosage")
  func card_storesMedicinalDosage() {
    let card = EmotionExpressionCard(
      label: "Primary Emotion",
      expression: "Gratitude",
      dosage: .medicinal
    )

    #expect(card.dosage == .medicinal)
  }

  @Test("card stores toxic dosage")
  func card_storesToxicDosage() {
    let card = EmotionExpressionCard(
      label: "Primary Emotion",
      expression: "Resentment",
      dosage: .toxic
    )

    #expect(card.dosage == .toxic)
  }
}
