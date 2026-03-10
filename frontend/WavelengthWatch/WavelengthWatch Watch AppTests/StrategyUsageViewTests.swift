import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

struct StrategyUsageViewTests {
  // MARK: - Test Helpers

  static let samplePhases: [CatalogPhaseModel] = [
    CatalogPhaseModel(id: 1, name: "Rising", medicinal: [], toxic: [], strategies: []),
    CatalogPhaseModel(id: 2, name: "Peaking", medicinal: [], toxic: [], strategies: []),
    CatalogPhaseModel(id: 3, name: "Falling", medicinal: [], toxic: [], strategies: []),
    CatalogPhaseModel(id: 5, name: "Integrating", medicinal: [], toxic: [], strategies: []),
    CatalogPhaseModel(id: 6, name: "Deepening", medicinal: [], toxic: [], strategies: []),
  ]

  // MARK: - Basic Initialization Tests

  @Test("view initializes with empty data")
  func view_initializesWithEmptyData() {
    let view = StrategyUsageView(
      analytics: SelfCareAnalytics(
        topStrategies: [],
        diversityScore: 0.0,
        totalStrategyEntries: 0
      ),
      phases: Self.samplePhases
    )

    #expect(view.analytics.topStrategies.isEmpty)
    #expect(view.analytics.diversityScore == 0.0)
  }

  @Test("view initializes with strategy data")
  func view_initializesWithData() {
    let strategies = [
      TopStrategyItem(strategyId: 1, strategy: "Deep breathing", count: 10, percentage: 50.0),
      TopStrategyItem(strategyId: 2, strategy: "Meditation", count: 5, percentage: 25.0),
    ]

    let view = StrategyUsageView(
      analytics: SelfCareAnalytics(
        topStrategies: strategies,
        diversityScore: 66.7,
        totalStrategyEntries: 15
      ),
      phases: Self.samplePhases
    )

    #expect(view.analytics.topStrategies.count == 2)
    #expect(view.analytics.diversityScore == 66.7)
    #expect(view.analytics.totalStrategyEntries == 15)
  }

  // MARK: - Phase Group Tests

  @Test("phaseGroups resolves phase names correctly")
  func phaseGroups_resolvesPhaseNamesCorrectly() {
    let groups = [
      PhaseStrategyGroup(
        phaseId: 5,
        strategies: [
          TopStrategyItem(strategyId: 1, strategy: "Breathwork", count: 3, percentage: 60.0),
        ],
        diversityScore: 50.0,
        totalEntries: 5
      ),
    ]

    let view = StrategyUsageView(
      analytics: SelfCareAnalytics(
        topStrategies: [],
        diversityScore: 0.0,
        totalStrategyEntries: 0,
        strategyGroups: groups
      ),
      phases: Self.samplePhases
    )

    let resolved = view.phaseGroups
    #expect(resolved.count == 1)
    #expect(resolved[0].phaseName == "Integrating")
    #expect(resolved[0].strategies.count == 1)
    #expect(resolved[0].diversityScore == 50.0)
  }

  @Test("phaseGroups handles unknown phase ID")
  func phaseGroups_handlesUnknownPhaseId() {
    let groups = [
      PhaseStrategyGroup(
        phaseId: 99,
        strategies: [
          TopStrategyItem(strategyId: 1, strategy: "Walking", count: 2, percentage: 100.0),
        ],
        diversityScore: 100.0,
        totalEntries: 2
      ),
    ]

    let view = StrategyUsageView(
      analytics: SelfCareAnalytics(
        topStrategies: [],
        diversityScore: 0.0,
        totalStrategyEntries: 0,
        strategyGroups: groups
      ),
      phases: Self.samplePhases
    )

    let resolved = view.phaseGroups
    #expect(resolved.count == 1)
    #expect(resolved[0].phaseName == "Phase 99")
  }

  @Test("phaseGroups returns empty for no strategy groups")
  func phaseGroups_returnsEmptyForNoGroups() {
    let view = StrategyUsageView(
      analytics: SelfCareAnalytics(
        topStrategies: [],
        diversityScore: 0.0,
        totalStrategyEntries: 0
      ),
      phases: Self.samplePhases
    )

    #expect(view.phaseGroups.isEmpty)
  }

  @Test("phaseGroups preserves multiple groups with strategies")
  func phaseGroups_preservesMultipleGroups() {
    let groups = [
      PhaseStrategyGroup(
        phaseId: 5,
        strategies: [
          TopStrategyItem(strategyId: 1, strategy: "Breathwork", count: 3, percentage: 60.0),
          TopStrategyItem(strategyId: 2, strategy: "Walking", count: 2, percentage: 40.0),
        ],
        diversityScore: 66.7,
        totalEntries: 5
      ),
      PhaseStrategyGroup(
        phaseId: 6,
        strategies: [
          TopStrategyItem(strategyId: 3, strategy: "Journaling", count: 4, percentage: 100.0),
        ],
        diversityScore: 25.0,
        totalEntries: 4
      ),
    ]

    let view = StrategyUsageView(
      analytics: SelfCareAnalytics(
        topStrategies: [],
        diversityScore: 0.0,
        totalStrategyEntries: 0,
        strategyGroups: groups
      ),
      phases: Self.samplePhases
    )

    let resolved = view.phaseGroups
    #expect(resolved.count == 2)
    #expect(resolved[0].phaseName == "Integrating")
    #expect(resolved[0].strategies.count == 2)
    #expect(resolved[1].phaseName == "Deepening")
    #expect(resolved[1].strategies.count == 1)
    #expect(resolved[1].diversityScore == 25.0)
  }

  // MARK: - Diversity Tagline Tests

  @Test("diversityTagline returns correct description")
  func diversityTagline_returnsCorrectDescription() {
    let view = StrategyUsageView(
      analytics: SelfCareAnalytics(
        topStrategies: [],
        diversityScore: 0.0,
        totalStrategyEntries: 0
      ),
      phases: Self.samplePhases
    )

    let tagline = view.diversityTagline
    #expect(tagline.contains("unique strategies"))
  }

  // MARK: - Integration Tests

  @Test("integration test with realistic grouped data")
  func integrationTest_withRealisticGroupedData() {
    let topStrategies = [
      TopStrategyItem(strategyId: 1, strategy: "Breathwork", count: 8, percentage: 40.0),
      TopStrategyItem(strategyId: 2, strategy: "Walking", count: 6, percentage: 30.0),
      TopStrategyItem(strategyId: 3, strategy: "Journaling", count: 6, percentage: 30.0),
    ]

    let groups = [
      PhaseStrategyGroup(
        phaseId: 5,
        strategies: [
          TopStrategyItem(strategyId: 1, strategy: "Breathwork", count: 5, percentage: 62.5),
          TopStrategyItem(strategyId: 2, strategy: "Walking", count: 3, percentage: 37.5),
        ],
        diversityScore: 50.0,
        totalEntries: 8
      ),
      PhaseStrategyGroup(
        phaseId: 6,
        strategies: [
          TopStrategyItem(strategyId: 3, strategy: "Journaling", count: 6, percentage: 50.0),
          TopStrategyItem(strategyId: 1, strategy: "Breathwork", count: 3, percentage: 25.0),
          TopStrategyItem(strategyId: 2, strategy: "Walking", count: 3, percentage: 25.0),
        ],
        diversityScore: 75.0,
        totalEntries: 12
      ),
    ]

    let view = StrategyUsageView(
      analytics: SelfCareAnalytics(
        topStrategies: topStrategies,
        diversityScore: 60.0,
        totalStrategyEntries: 20,
        strategyGroups: groups
      ),
      phases: Self.samplePhases
    )

    #expect(view.analytics.topStrategies.count == 3)
    #expect(view.phaseGroups.count == 2)
    #expect(view.phaseGroups[0].phaseName == "Integrating")
    #expect(view.phaseGroups[1].phaseName == "Deepening")
  }
}
