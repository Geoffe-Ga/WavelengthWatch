import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

struct StrategyExpressionCardTests {
  @Test("card stores strategy")
  func card_storesStrategy() {
    let strategy = CatalogStrategyModel(id: 1, strategy: "Take a deep breath", color: "Blue")
    let card = StrategyExpressionCard(strategy: strategy)

    #expect(card.strategy.strategy == "Take a deep breath")
  }

  @Test("card preserves strategy color name")
  func card_preservesStrategyColor() {
    let strategy = CatalogStrategyModel(id: 2, strategy: "Cold Shower", color: "Beige")
    let card = StrategyExpressionCard(strategy: strategy)

    #expect(card.strategy.color == "Beige")
  }

  @Test("card preserves strategy id")
  func card_preservesStrategyID() {
    let strategy = CatalogStrategyModel(id: 7, strategy: "Jogging", color: "Red")
    let card = StrategyExpressionCard(strategy: strategy)

    #expect(card.strategy.id == 7)
  }
}
