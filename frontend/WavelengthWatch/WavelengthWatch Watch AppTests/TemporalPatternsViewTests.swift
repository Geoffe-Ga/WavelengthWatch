import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

struct TemporalPatternsViewTests {
  // MARK: - Test Helpers

  static let samplePhases: [CatalogPhaseModel] = [
    CatalogPhaseModel(id: 1, name: "Rising", medicinal: [], toxic: [], strategies: []),
    CatalogPhaseModel(id: 2, name: "Peaking", medicinal: [], toxic: [], strategies: []),
    CatalogPhaseModel(id: 3, name: "Falling", medicinal: [], toxic: [], strategies: []),
    CatalogPhaseModel(id: 4, name: "Resting", medicinal: [], toxic: [], strategies: []),
  ]

  // MARK: - Basic Initialization Tests

  @Test("view initializes with empty data")
  func view_initializesWithEmptyData() {
    let view = TemporalPatternsView(
      patterns: TemporalPatterns(hourlyDistribution: []),
      phases: Self.samplePhases
    )

    #expect(view.patterns.hourlyDistribution.isEmpty)
  }

  @Test("view initializes with pattern data")
  func view_initializesWithData() {
    let distribution = [
      HourlyDistributionItem(hour: 9, count: 5),
      HourlyDistributionItem(hour: 14, count: 3),
      HourlyDistributionItem(hour: 20, count: 7),
    ]

    let view = TemporalPatternsView(
      patterns: TemporalPatterns(hourlyDistribution: distribution),
      phases: Self.samplePhases
    )

    #expect(view.patterns.hourlyDistribution.count == 3)
  }

  // MARK: - Hour Label Tests

  @Test("hourLabel formats hours correctly")
  func hourLabel_formatsHoursCorrectly() {
    #expect(TemporalPatternsView.hourLabel(0) == "12 AM")
    #expect(TemporalPatternsView.hourLabel(1) == "1 AM")
    #expect(TemporalPatternsView.hourLabel(9) == "9 AM")
    #expect(TemporalPatternsView.hourLabel(12) == "12 PM")
    #expect(TemporalPatternsView.hourLabel(13) == "1 PM")
    #expect(TemporalPatternsView.hourLabel(20) == "8 PM")
    #expect(TemporalPatternsView.hourLabel(23) == "11 PM")
  }

  // MARK: - Hourly Summary Tests

  @Test("hourlySummaries includes phase name when available")
  func hourlySummaries_includesPhaseNameWhenAvailable() {
    let distribution = [
      HourlyDistributionItem(hour: 9, count: 5, dominantPhaseId: 1, dominantDosage: "Medicinal"),
    ]

    let view = TemporalPatternsView(
      patterns: TemporalPatterns(hourlyDistribution: distribution),
      phases: Self.samplePhases
    )

    let summaries = view.hourlySummaries
    #expect(summaries.count == 1)
    #expect(summaries[0].hourLabel == "9 AM")
    #expect(summaries[0].phaseName == "Rising")
    #expect(summaries[0].dosage == "Medicinal")
    #expect(summaries[0].count == 5)
  }

  @Test("hourlySummaries handles nil phase and dosage")
  func hourlySummaries_handlesNilPhaseAndDosage() {
    let distribution = [
      HourlyDistributionItem(hour: 14, count: 3),
    ]

    let view = TemporalPatternsView(
      patterns: TemporalPatterns(hourlyDistribution: distribution),
      phases: Self.samplePhases
    )

    let summaries = view.hourlySummaries
    #expect(summaries.count == 1)
    #expect(summaries[0].phaseName == nil)
    #expect(summaries[0].dosage == nil)
  }

  @Test("hourlySummaries handles unknown phase ID")
  func hourlySummaries_handlesUnknownPhaseId() {
    let distribution = [
      HourlyDistributionItem(hour: 9, count: 2, dominantPhaseId: 99, dominantDosage: "Toxic"),
    ]

    let view = TemporalPatternsView(
      patterns: TemporalPatterns(hourlyDistribution: distribution),
      phases: Self.samplePhases
    )

    let summaries = view.hourlySummaries
    #expect(summaries.count == 1)
    #expect(summaries[0].phaseName == nil)
    #expect(summaries[0].dosage == "Toxic")
  }

  @Test("hourlySummaries calculates percentage correctly")
  func hourlySummaries_calculatesPercentageCorrectly() {
    let distribution = [
      HourlyDistributionItem(hour: 9, count: 3, dominantPhaseId: 1, dominantDosage: "Medicinal"),
      HourlyDistributionItem(hour: 14, count: 6, dominantPhaseId: 2, dominantDosage: "Toxic"),
      HourlyDistributionItem(hour: 20, count: 1, dominantPhaseId: 4, dominantDosage: "Medicinal"),
    ]

    let view = TemporalPatternsView(
      patterns: TemporalPatterns(hourlyDistribution: distribution),
      phases: Self.samplePhases
    )

    let summaries = view.hourlySummaries
    #expect(summaries.count == 3)
    #expect(summaries[0].percentage == 30.0)
    #expect(summaries[1].percentage == 60.0)
    #expect(summaries[2].percentage == 10.0)
  }

  @Test("hourlySummaries returns empty for empty distribution")
  func hourlySummaries_returnsEmptyForEmptyDistribution() {
    let view = TemporalPatternsView(
      patterns: TemporalPatterns(hourlyDistribution: []),
      phases: Self.samplePhases
    )

    #expect(view.hourlySummaries.isEmpty)
  }

  // MARK: - Dosage Color Tests

  @Test("dosageColor returns green for Medicinal")
  func dosageColor_returnsGreenForMedicinal() {
    #expect(TemporalPatternsView.dosageColor(for: "Medicinal") == .green)
  }

  @Test("dosageColor returns secondary for Toxic")
  func dosageColor_returnsSecondaryForToxic() {
    #expect(TemporalPatternsView.dosageColor(for: "Toxic") == .secondary)
  }

  @Test("dosageColor returns purple as default")
  func dosageColor_returnsPurpleAsDefault() {
    #expect(TemporalPatternsView.dosageColor(for: nil) == .purple)
  }

  // MARK: - Integration Tests

  @Test("integration test with mixed phase and dosage data")
  func integrationTest_withMixedPhaseAndDosageData() {
    let distribution = [
      HourlyDistributionItem(hour: 8, count: 4, dominantPhaseId: 1, dominantDosage: "Medicinal"),
      HourlyDistributionItem(hour: 12, count: 6, dominantPhaseId: 2, dominantDosage: "Toxic"),
      HourlyDistributionItem(hour: 18, count: 3, dominantPhaseId: 3, dominantDosage: "Medicinal"),
      HourlyDistributionItem(hour: 22, count: 2, dominantPhaseId: 4, dominantDosage: "Medicinal"),
    ]

    let view = TemporalPatternsView(
      patterns: TemporalPatterns(hourlyDistribution: distribution),
      phases: Self.samplePhases
    )

    let summaries = view.hourlySummaries
    #expect(summaries.count == 4)
    #expect(summaries[0].phaseName == "Rising")
    #expect(summaries[0].dosage == "Medicinal")
    #expect(summaries[1].phaseName == "Peaking")
    #expect(summaries[1].dosage == "Toxic")
    #expect(summaries[2].phaseName == "Falling")
    #expect(summaries[3].phaseName == "Resting")
  }
}
