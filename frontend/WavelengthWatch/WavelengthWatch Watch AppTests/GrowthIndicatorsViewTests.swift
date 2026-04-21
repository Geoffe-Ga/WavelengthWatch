import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

struct GrowthIndicatorsViewTests {
  @Test("view initializes with empty data")
  func view_initializesWithEmptyData() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.0,
      layerDiversity: 0,
      phaseCoverage: 0
    ))

    #expect(view.indicators.medicinalTrend == 0.0)
    #expect(view.indicators.layerDiversity == 0)
    #expect(view.indicators.phaseCoverage == 0)
  }

  @Test("view initializes with growth data")
  func view_initializesWithData() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.125,
      layerDiversity: 4,
      phaseCoverage: 5
    ))

    #expect(view.indicators.medicinalTrend == 0.125)
    #expect(view.indicators.layerDiversity == 4)
    #expect(view.indicators.phaseCoverage == 5)
  }

  // MARK: - Trend Direction (neutral descriptors)

  @Test("trendDirection returns more for trend above threshold")
  func trendDirection_returnsMoreForTrendAboveThreshold() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.055, // 5.5%, above 5% threshold
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.trendDirection == .more)
  }

  @Test("trendDirection returns quieter for trend below negative threshold")
  func trendDirection_returnsQuieterForTrendBelowThreshold() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: -0.06,
      layerDiversity: 2,
      phaseCoverage: 3
    ))

    #expect(view.trendDirection == .quieter)
  }

  @Test("trendDirection returns steady within threshold")
  func trendDirection_returnsSteadyWithinThreshold() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.02,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.trendDirection == .steady)
  }

  @Test("trendDirection returns steady for zero trend")
  func trendDirection_returnsSteadyForZeroTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.0,
      layerDiversity: 1,
      phaseCoverage: 2
    ))

    #expect(view.trendDirection == .steady)
  }

  // MARK: - Trend Arrow (neutral direction indicator only)

  @Test("trendArrow returns up arrow for more trend")
  func trendArrow_returnsUpArrowForMoreTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.10,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.trendArrow == "arrow.up")
  }

  @Test("trendArrow returns down arrow for quieter trend")
  func trendArrow_returnsDownArrowForQuieterTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: -0.08,
      layerDiversity: 2,
      phaseCoverage: 3
    ))

    #expect(view.trendArrow == "arrow.down")
  }

  @Test("trendArrow returns forward arrow for steady trend")
  func trendArrow_returnsForwardArrowForSteadyTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.015,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.trendArrow == "arrow.forward")
  }

  // MARK: - Trend Color (neutral in all cases)

  @Test("trendColor is neutral for more trend (no evaluative green)")
  func trendColor_isNeutralForMoreTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.15,
      layerDiversity: 4,
      phaseCoverage: 5
    ))

    #expect(view.trendColor != .green)
    #expect(view.trendColor != .red)
    #expect(view.trendColor != .orange)
    #expect(view.trendColor != .yellow)
  }

  @Test("trendColor is neutral for quieter trend")
  func trendColor_isNeutralForQuieterTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: -0.12,
      layerDiversity: 2,
      phaseCoverage: 3
    ))

    #expect(view.trendColor != .red)
    #expect(view.trendColor != .orange)
    #expect(view.trendColor != .green)
    #expect(view.trendColor != .yellow)
  }

  @Test("trendColor is neutral for steady trend")
  func trendColor_isNeutralForSteadyTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.03,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.trendColor != .red)
    #expect(view.trendColor != .orange)
    #expect(view.trendColor != .green)
    #expect(view.trendColor != .yellow)
  }

  @Test("trendColor is identical across directions")
  func trendColor_identicalAcrossDirections() {
    let more = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.20,
      layerDiversity: 3,
      phaseCoverage: 4
    ))
    let quieter = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: -0.20,
      layerDiversity: 3,
      phaseCoverage: 4
    ))
    let steady = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.01,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(more.trendColor == quieter.trendColor)
    #expect(quieter.trendColor == steady.trendColor)
  }

  // MARK: - Trend Description (no prescriptive language)

  @Test("trendDescription avoids prescriptive language")
  func trendDescription_avoidsPrescriptiveLanguage() {
    let cases: [Double] = [0.15, -0.15, 0.0]
    for trend in cases {
      let view = GrowthIndicatorsView(indicators: GrowthIndicators(
        medicinalTrend: trend,
        layerDiversity: 3,
        phaseCoverage: 4
      ))
      let text = view.trendDescription.lowercased()
      #expect(!text.contains("declining"))
      #expect(!text.contains("failure"))
      #expect(!text.contains("should"))
      #expect(!text.contains("need to"))
      #expect(!text.contains("better"))
      #expect(!text.contains("worse"))
    }
  }

  // MARK: - Rhythm Context (supportive affirmation)

  @Test("rhythmContext affirms natural ebbs and flows")
  func rhythmContext_affirmsNaturalEbbAndFlow() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: -0.05,
      layerDiversity: 2,
      phaseCoverage: 3
    ))
    let text = view.rhythmContext.lowercased()
    #expect(text.contains("natural"))
    #expect(!text.contains("should"))
    #expect(!text.contains("goal"))
  }

  // MARK: - Formatted Trend (factual, unchanged)

  @Test("formattedTrend includes percentage and sign for increase")
  func formattedTrend_includesPercentageAndSignForIncrease() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.1234,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.formattedTrend == "+12.3%")
  }

  @Test("formattedTrend includes percentage and sign for decrease")
  func formattedTrend_includesPercentageAndSignForDecrease() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: -0.0876,
      layerDiversity: 2,
      phaseCoverage: 3
    ))

    #expect(view.formattedTrend == "-8.8%")
  }

  @Test("formattedTrend handles zero trend")
  func formattedTrend_handlesZeroTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.0,
      layerDiversity: 1,
      phaseCoverage: 2
    ))

    #expect(view.formattedTrend == "0.0%")
  }

  // MARK: - Diversity / Coverage Text

  @Test("layerDiversityText formats singular layer correctly")
  func layerDiversityText_formatsSingularLayerCorrectly() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.05,
      layerDiversity: 1,
      phaseCoverage: 3
    ))

    #expect(view.layerDiversityText == "1 mode")
  }

  @Test("layerDiversityText formats plural layers correctly")
  func layerDiversityText_formatsPluralLayersCorrectly() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.05,
      layerDiversity: 4,
      phaseCoverage: 5
    ))

    #expect(view.layerDiversityText == "4 modes")
  }

  @Test("layerDiversityText handles zero layers")
  func layerDiversityText_handlesZeroLayers() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.0,
      layerDiversity: 0,
      phaseCoverage: 0
    ))

    #expect(view.layerDiversityText == "0 modes")
  }

  @Test("phaseCoverageText formats correctly")
  func phaseCoverageText_formatsCorrectly() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.05,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.phaseCoverageText == "4 of 6 phases")
  }

  @Test("phaseCoverageText handles all phases covered")
  func phaseCoverageText_handlesAllPhasesCovered() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.10,
      layerDiversity: 5,
      phaseCoverage: 6
    ))

    #expect(view.phaseCoverageText == "6 of 6 phases")
  }

  @Test("phaseCoverageText handles no phases covered")
  func phaseCoverageText_handlesNoPhasesCovered() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.0,
      layerDiversity: 0,
      phaseCoverage: 0
    ))

    #expect(view.phaseCoverageText == "0 of 6 phases")
  }

  // MARK: - isEmpty

  @Test("isEmpty returns true when no data")
  func isEmpty_returnsTrueWhenNoData() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.0,
      layerDiversity: 0,
      phaseCoverage: 0
    ))

    #expect(view.isEmpty == true)
  }

  @Test("isEmpty returns false when has diversity data")
  func isEmpty_returnsFalseWhenHasDiversityData() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.0,
      layerDiversity: 2,
      phaseCoverage: 0
    ))

    #expect(view.isEmpty == false)
  }

  @Test("isEmpty returns false when has phase coverage data")
  func isEmpty_returnsFalseWhenHasPhaseCoverageData() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.0,
      layerDiversity: 0,
      phaseCoverage: 3
    ))

    #expect(view.isEmpty == false)
  }

  @Test("isEmpty returns false when has more trend")
  func isEmpty_returnsFalseWhenHasMoreTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.05,
      layerDiversity: 0,
      phaseCoverage: 0
    ))

    #expect(view.isEmpty == false)
  }

  @Test("isEmpty returns false when has quieter trend")
  func isEmpty_returnsFalseWhenHasQuieterTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: -0.05,
      layerDiversity: 0,
      phaseCoverage: 0
    ))

    #expect(view.isEmpty == false)
  }

  // MARK: - Integration

  @Test("integration test with realistic more-medicinal data")
  func integrationTest_withRealisticMoreMedicinalData() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.185,
      layerDiversity: 5,
      phaseCoverage: 6
    ))

    #expect(view.trendDirection == .more)
    #expect(view.trendArrow == "arrow.up")
    #expect(view.trendColor != .green)
    #expect(view.trendColor != .red)
    #expect(view.formattedTrend == "+18.5%")
    #expect(view.layerDiversityText == "5 modes")
    #expect(view.phaseCoverageText == "6 of 6 phases")
    #expect(view.isEmpty == false)
  }

  @Test("integration test with realistic quieter-phase data")
  func integrationTest_withRealisticQuieterPhaseData() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: -0.152,
      layerDiversity: 2,
      phaseCoverage: 3
    ))

    #expect(view.trendDirection == .quieter)
    #expect(view.trendArrow == "arrow.down")
    #expect(view.trendColor != .red)
    #expect(view.trendColor != .orange)
    #expect(view.formattedTrend == "-15.2%")
    #expect(view.layerDiversityText == "2 modes")
    #expect(view.phaseCoverageText == "3 of 6 phases")
    #expect(view.isEmpty == false)
  }

  @Test("integration test with realistic steady data")
  func integrationTest_withRealisticSteadyData() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.025,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.trendDirection == .steady)
    #expect(view.trendArrow == "arrow.forward")
    #expect(view.trendColor != .red)
    #expect(view.trendColor != .orange)
    #expect(view.formattedTrend == "+2.5%")
    #expect(view.layerDiversityText == "3 modes")
    #expect(view.phaseCoverageText == "4 of 6 phases")
    #expect(view.isEmpty == false)
  }
}
