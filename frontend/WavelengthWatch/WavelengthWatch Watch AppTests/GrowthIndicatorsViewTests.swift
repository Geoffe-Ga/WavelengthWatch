import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("GrowthIndicatorsView Tests")
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
      medicinalTrend: 12.5,
      layerDiversity: 4,
      phaseCoverage: 5
    ))

    #expect(view.indicators.medicinalTrend == 12.5)
    #expect(view.indicators.layerDiversity == 4)
    #expect(view.indicators.phaseCoverage == 5)
  }

  @Test("trendDirection returns positive for trend above threshold")
  func trendDirection_returnsPositiveForTrendAboveThreshold() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 5.5,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.trendDirection == .positive)
  }

  @Test("trendDirection returns negative for trend below negative threshold")
  func trendDirection_returnsNegativeForTrendBelowThreshold() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: -6.0,
      layerDiversity: 2,
      phaseCoverage: 3
    ))

    #expect(view.trendDirection == .negative)
  }

  @Test("trendDirection returns neutral for trend within thresholds")
  func trendDirection_returnsNeutralForTrendWithinThresholds() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 2.0,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.trendDirection == .neutral)
  }

  @Test("trendDirection handles zero trend as neutral")
  func trendDirection_handlesZeroTrendAsNeutral() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 0.0,
      layerDiversity: 1,
      phaseCoverage: 2
    ))

    #expect(view.trendDirection == .neutral)
  }

  @Test("trendArrow returns up arrow for positive trend")
  func trendArrow_returnsUpArrowForPositiveTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 10.0,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.trendArrow == "arrow.up")
  }

  @Test("trendArrow returns down arrow for negative trend")
  func trendArrow_returnsDownArrowForNegativeTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: -8.0,
      layerDiversity: 2,
      phaseCoverage: 3
    ))

    #expect(view.trendArrow == "arrow.down")
  }

  @Test("trendArrow returns forward arrow for neutral trend")
  func trendArrow_returnsForwardArrowForNeutralTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 1.5,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.trendArrow == "arrow.forward")
  }

  @Test("trendColor returns green for positive trend")
  func trendColor_returnsGreenForPositiveTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 15.0,
      layerDiversity: 4,
      phaseCoverage: 5
    ))

    #expect(view.trendColor == .green)
  }

  @Test("trendColor returns red for negative trend")
  func trendColor_returnsRedForNegativeTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: -12.0,
      layerDiversity: 2,
      phaseCoverage: 3
    ))

    #expect(view.trendColor == .red)
  }

  @Test("trendColor returns orange for neutral trend")
  func trendColor_returnsOrangeForNeutralTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 3.0,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.trendColor == .orange)
  }

  @Test("formattedTrend includes percentage and sign for positive trend")
  func formattedTrend_includesPercentageAndSignForPositiveTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 12.34,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.formattedTrend == "+12.3%")
  }

  @Test("formattedTrend includes percentage and sign for negative trend")
  func formattedTrend_includesPercentageAndSignForNegativeTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: -8.76,
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

  @Test("layerDiversityText formats singular layer correctly")
  func layerDiversityText_formatsSingularLayerCorrectly() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 5.0,
      layerDiversity: 1,
      phaseCoverage: 3
    ))

    #expect(view.layerDiversityText == "1 mode")
  }

  @Test("layerDiversityText formats plural layers correctly")
  func layerDiversityText_formatsPluralLayersCorrectly() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 5.0,
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
      medicinalTrend: 5.0,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.phaseCoverageText == "4 of 6 phases")
  }

  @Test("phaseCoverageText handles all phases covered")
  func phaseCoverageText_handlesAllPhasesCovered() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 10.0,
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

  @Test("isEmpty returns false when has positive trend")
  func isEmpty_returnsFalseWhenHasPositiveTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 5.0,
      layerDiversity: 0,
      phaseCoverage: 0
    ))

    #expect(view.isEmpty == false)
  }

  @Test("isEmpty returns false when has negative trend")
  func isEmpty_returnsFalseWhenHasNegativeTrend() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: -5.0,
      layerDiversity: 0,
      phaseCoverage: 0
    ))

    #expect(view.isEmpty == false)
  }

  @Test("integration test with realistic positive growth data")
  func integrationTest_withRealisticPositiveGrowthData() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 18.5,
      layerDiversity: 5,
      phaseCoverage: 6
    ))

    #expect(view.trendDirection == .positive)
    #expect(view.trendArrow == "arrow.up")
    #expect(view.trendColor == .green)
    #expect(view.formattedTrend == "+18.5%")
    #expect(view.layerDiversityText == "5 modes")
    #expect(view.phaseCoverageText == "6 of 6 phases")
    #expect(view.isEmpty == false)
  }

  @Test("integration test with realistic negative growth data")
  func integrationTest_withRealisticNegativeGrowthData() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: -15.2,
      layerDiversity: 2,
      phaseCoverage: 3
    ))

    #expect(view.trendDirection == .negative)
    #expect(view.trendArrow == "arrow.down")
    #expect(view.trendColor == .red)
    #expect(view.formattedTrend == "-15.2%")
    #expect(view.layerDiversityText == "2 modes")
    #expect(view.phaseCoverageText == "3 of 6 phases")
    #expect(view.isEmpty == false)
  }

  @Test("integration test with realistic neutral growth data")
  func integrationTest_withRealisticNeutralGrowthData() {
    let view = GrowthIndicatorsView(indicators: GrowthIndicators(
      medicinalTrend: 2.5,
      layerDiversity: 3,
      phaseCoverage: 4
    ))

    #expect(view.trendDirection == .neutral)
    #expect(view.trendArrow == "arrow.forward")
    #expect(view.trendColor == .orange)
    #expect(view.formattedTrend == "+2.5%")
    #expect(view.layerDiversityText == "3 modes")
    #expect(view.phaseCoverageText == "4 of 6 phases")
    #expect(view.isEmpty == false)
  }
}
