import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("StrategyUsageView Tests")
struct StrategyUsageViewTests {
  @Test("view initializes with empty data")
  func view_initializesWithEmptyData() {
    let view = StrategyUsageView(analytics: SelfCareAnalytics(
      topStrategies: [],
      diversityScore: 0.0,
      totalStrategyEntries: 0
    ))

    #expect(view.analytics.topStrategies.isEmpty)
    #expect(view.analytics.diversityScore == 0.0)
  }

  @Test("view initializes with strategy data")
  func view_initializesWithData() {
    let strategies = [
      TopStrategyItem(strategyId: 1, strategy: "Deep breathing", count: 10, percentage: 50.0),
      TopStrategyItem(strategyId: 2, strategy: "Meditation", count: 5, percentage: 25.0),
    ]

    let view = StrategyUsageView(analytics: SelfCareAnalytics(
      topStrategies: strategies,
      diversityScore: 66.7,
      totalStrategyEntries: 15
    ))

    #expect(view.analytics.topStrategies.count == 2)
    #expect(view.analytics.diversityScore == 66.7)
    #expect(view.analytics.totalStrategyEntries == 15)
  }

  @Test("barChartItems converts strategies correctly")
  func barChartItems_convertsStrategiesCorrectly() {
    let strategies = [
      TopStrategyItem(strategyId: 1, strategy: "Deep breathing", count: 10, percentage: 66.67),
      TopStrategyItem(strategyId: 2, strategy: "Meditation", count: 5, percentage: 33.33),
    ]

    let view = StrategyUsageView(analytics: SelfCareAnalytics(
      topStrategies: strategies,
      diversityScore: 50.0,
      totalStrategyEntries: 15
    ))

    let items = view.barChartItems

    #expect(items.count == 2)
    #expect(items[0].id == "1")
    #expect(items[0].label == "Deep breathing")
    #expect(items[0].percentage == 66.67)
    #expect(items[1].id == "2")
    #expect(items[1].label == "Meditation")
    #expect(items[1].percentage == 33.33)
  }

  @Test("barChartItems handles empty strategies")
  func barChartItems_handlesEmptyStrategies() {
    let view = StrategyUsageView(analytics: SelfCareAnalytics(
      topStrategies: [],
      diversityScore: 0.0,
      totalStrategyEntries: 0
    ))

    let items = view.barChartItems

    #expect(items.isEmpty)
  }

  @Test("barChartItems preserves order")
  func barChartItems_preservesOrder() {
    let strategies = [
      TopStrategyItem(strategyId: 3, strategy: "Walking", count: 8, percentage: 40.0),
      TopStrategyItem(strategyId: 1, strategy: "Breathing", count: 12, percentage: 60.0),
    ]

    let view = StrategyUsageView(analytics: SelfCareAnalytics(
      topStrategies: strategies,
      diversityScore: 50.0,
      totalStrategyEntries: 20
    ))

    let items = view.barChartItems

    #expect(items.count == 2)
    #expect(items[0].id == "3")
    #expect(items[0].label == "Walking")
    #expect(items[1].id == "1")
    #expect(items[1].label == "Breathing")
  }
}
