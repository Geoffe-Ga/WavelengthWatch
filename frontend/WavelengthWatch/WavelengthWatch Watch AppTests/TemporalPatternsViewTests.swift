import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("TemporalPatternsView Tests")
struct TemporalPatternsViewTests {
  @Test("view initializes with empty data")
  func view_initializesWithEmptyData() {
    let view = TemporalPatternsView(patterns: TemporalPatterns(
      hourlyDistribution: [],
      consistencyScore: 0.0
    ))

    #expect(view.patterns.hourlyDistribution.isEmpty)
    #expect(view.patterns.consistencyScore == 0.0)
  }

  @Test("view initializes with pattern data")
  func view_initializesWithData() {
    let distribution = [
      HourlyDistributionItem(hour: 9, count: 5),
      HourlyDistributionItem(hour: 14, count: 3),
      HourlyDistributionItem(hour: 20, count: 7),
    ]

    let view = TemporalPatternsView(patterns: TemporalPatterns(
      hourlyDistribution: distribution,
      consistencyScore: 85.5
    ))

    #expect(view.patterns.hourlyDistribution.count == 3)
    #expect(view.patterns.consistencyScore == 85.5)
  }

  @Test("barChartItems converts hourly data correctly")
  func barChartItems_convertsHourlyDataCorrectly() {
    let distribution = [
      HourlyDistributionItem(hour: 9, count: 5),
      HourlyDistributionItem(hour: 14, count: 10),
    ]

    let view = TemporalPatternsView(patterns: TemporalPatterns(
      hourlyDistribution: distribution,
      consistencyScore: 50.0
    ))

    let items = view.barChartItems

    #expect(items.count == 2)
    #expect(items[0].id == "9")
    #expect(items[0].label == "9 AM")
    #expect(abs(items[0].percentage - 33.33) < 0.01)
    #expect(items[1].id == "14")
    #expect(items[1].label == "2 PM")
    #expect(abs(items[1].percentage - 66.67) < 0.01)
  }

  @Test("barChartItems handles empty distribution")
  func barChartItems_handlesEmptyDistribution() {
    let view = TemporalPatternsView(patterns: TemporalPatterns(
      hourlyDistribution: [],
      consistencyScore: 0.0
    ))

    let items = view.barChartItems

    #expect(items.isEmpty)
  }

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

  @Test("barChartItems calculates percentages correctly")
  func barChartItems_calculatesPercentagesCorrectly() {
    let distribution = [
      HourlyDistributionItem(hour: 9, count: 3),
      HourlyDistributionItem(hour: 14, count: 6),
      HourlyDistributionItem(hour: 20, count: 1),
    ]

    let view = TemporalPatternsView(patterns: TemporalPatterns(
      hourlyDistribution: distribution,
      consistencyScore: 50.0
    ))

    let items = view.barChartItems

    #expect(items.count == 3)
    #expect(items[0].percentage == 30.0)
    #expect(items[1].percentage == 60.0)
    #expect(items[2].percentage == 10.0)
  }
}
