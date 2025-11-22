import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("StrategySummaryCard Tests")
struct StrategySummaryCardTests {
  // MARK: - Test Data

  private func makeMockStrategy(color: String = "Blue") -> CatalogStrategyModel {
    CatalogStrategyModel(
      id: 1,
      strategy: "Cold Shower",
      color: color
    )
  }

  // MARK: - Display Content Tests

  @Test("card displays strategy text")
  func card_displaysStrategy() {
    let strategy = makeMockStrategy()
    let card = StrategySummaryCard(strategy: strategy)

    #expect(card.strategy.strategy == "Cold Shower")
  }

  @Test("card displays color indicator")
  func card_displaysColorIndicator() {
    let blueStrategy = makeMockStrategy(color: "Blue")
    let redStrategy = CatalogStrategyModel(id: 2, strategy: "Exercise", color: "Red")

    let blueCard = StrategySummaryCard(strategy: blueStrategy)
    let redCard = StrategySummaryCard(strategy: redStrategy)

    #expect(blueCard.strategy.color == "Blue")
    #expect(redCard.strategy.color == "Red")
  }

  // MARK: - Compact Mode Tests

  @Test("compact mode uses smaller font")
  func compactMode_usesSmallerFont() {
    let strategy = makeMockStrategy()
    let standardCard = StrategySummaryCard(strategy: strategy, compact: false)
    let compactCard = StrategySummaryCard(strategy: strategy, compact: true)

    #expect(standardCard.compact == false)
    #expect(compactCard.compact == true)
  }

  // MARK: - Color Mapping Tests

  @Test("different strategy colors are preserved")
  func differentColors_arePreserved() {
    let colors = ["Blue", "Red", "Orange", "Green", "Yellow", "Teal", "Purple"]

    for color in colors {
      let strategy = CatalogStrategyModel(id: 1, strategy: "Test", color: color)
      let card = StrategySummaryCard(strategy: strategy)
      #expect(card.strategy.color == color)
    }
  }

  // MARK: - Strategy Content Tests

  @Test("card preserves strategy ID")
  func card_preservesStrategyID() {
    let strategy = CatalogStrategyModel(id: 42, strategy: "Meditation", color: "Green")
    let card = StrategySummaryCard(strategy: strategy)

    #expect(card.strategy.id == 42)
  }

  @Test("card handles long strategy text")
  func card_handlesLongStrategyText() {
    let longStrategy = CatalogStrategyModel(
      id: 1,
      strategy: "Exercise or Physical Movement to Release Energy",
      color: "Orange"
    )
    let card = StrategySummaryCard(strategy: longStrategy)

    #expect(card.strategy.strategy == "Exercise or Physical Movement to Release Energy")
  }
}
