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

  // MARK: - Basic Initialization

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

  // MARK: - Copy (Issue #285)

  @Test("title uses Your Natural Rhythm framing")
  func title_usesNaturalRhythmFraming() {
    #expect(TemporalPatternsView.title == "Your Natural Rhythm")
  }

  @Test("subtitle uses descriptive tend-to language")
  func subtitle_usesDescriptiveLanguage() {
    let text = TemporalPatternsView.subtitle.lowercased()
    #expect(text.contains("naturally"))
    #expect(text.contains("tend"))
    #expect(!text.contains("should"))
    #expect(!text.contains("need to"))
  }

  @Test("affirmation honors unique rhythms")
  func affirmation_honorsUniqueRhythms() {
    let text = TemporalPatternsView.affirmation.lowercased()
    #expect(text.contains("unique"))
    #expect(!text.contains("should"))
    #expect(!text.contains("need to"))
    #expect(!text.contains("better"))
    #expect(!text.contains("worse"))
  }

  // MARK: - Hour Label

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

  // MARK: - Hourly Summary

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

  // MARK: - Neutral Dosage Color (Issue #285)

  @Test("dosageColor returns neutral purple for Medicinal")
  func dosageColor_returnsNeutralPurpleForMedicinal() {
    #expect(TemporalPatternsView.dosageColor(for: "Medicinal") == .purple)
  }

  @Test("dosageColor returns neutral purple for Toxic")
  func dosageColor_returnsNeutralPurpleForToxic() {
    #expect(TemporalPatternsView.dosageColor(for: "Toxic") == .purple)
  }

  @Test("dosageColor returns neutral purple for nil")
  func dosageColor_returnsNeutralPurpleForNil() {
    #expect(TemporalPatternsView.dosageColor(for: nil) == .purple)
  }

  @Test("dosageColor never returns evaluative colors")
  func dosageColor_neverReturnsEvaluativeColors() {
    for dosage in ["Medicinal", "Toxic", nil] {
      let color = TemporalPatternsView.dosageColor(for: dosage)
      #expect(color != .red)
      #expect(color != .green)
      #expect(color != .orange)
      #expect(color != .yellow)
    }
  }

  // MARK: - Integration

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
