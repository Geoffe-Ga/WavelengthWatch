import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("HorizontalBarChart Tests")
struct HorizontalBarChartTests {
  // MARK: - Data Model Tests

  @Test("BarChartItem has required properties")
  func barChartItem_hasRequiredProperties() {
    let item = HorizontalBarChart.BarChartItem(
      id: "test-id",
      label: "Test Label",
      percentage: 50.0,
      color: .blue
    )

    #expect(item.id == "test-id")
    #expect(item.label == "Test Label")
    #expect(item.percentage == 50.0)
    // Color comparison is not straightforward, so we just verify it compiles
  }

  @Test("BarChartItem conforms to Identifiable")
  func barChartItem_conformsToIdentifiable() {
    let item = HorizontalBarChart.BarChartItem(
      id: "test",
      label: "Test",
      percentage: 0,
      color: .red
    )

    // If this compiles, Identifiable conformance is satisfied
    let _: String = item.id
  }

  // MARK: - View Initialization Tests

  @Test("HorizontalBarChart initializes with empty items")
  func horizontalBarChart_initializesWithEmptyItems() {
    let chart = HorizontalBarChart(items: [])

    #expect(chart.items.isEmpty)
  }

  @Test("HorizontalBarChart initializes with items")
  func horizontalBarChart_initializesWithItems() {
    let items = [
      HorizontalBarChart.BarChartItem(
        id: "1",
        label: "First",
        percentage: 30.0,
        color: .green
      ),
      HorizontalBarChart.BarChartItem(
        id: "2",
        label: "Second",
        percentage: 70.0,
        color: .blue
      ),
    ]

    let chart = HorizontalBarChart(items: items)

    #expect(chart.items.count == 2)
    #expect(chart.items[0].label == "First")
    #expect(chart.items[1].label == "Second")
  }

  @Test("HorizontalBarChart preserves item order")
  func horizontalBarChart_preservesItemOrder() {
    let items = [
      HorizontalBarChart.BarChartItem(
        id: "low",
        label: "Low %",
        percentage: 10.0,
        color: .red
      ),
      HorizontalBarChart.BarChartItem(
        id: "high",
        label: "High %",
        percentage: 90.0,
        color: .green
      ),
      HorizontalBarChart.BarChartItem(
        id: "mid",
        label: "Mid %",
        percentage: 50.0,
        color: .blue
      ),
    ]

    let chart = HorizontalBarChart(items: items)

    // Items should remain in provided order (not sorted by percentage)
    #expect(chart.items[0].percentage == 10.0)
    #expect(chart.items[1].percentage == 90.0)
    #expect(chart.items[2].percentage == 50.0)
  }

  // MARK: - Edge Case Tests

  @Test("HorizontalBarChart handles zero percentage")
  func horizontalBarChart_handlesZeroPercentage() {
    let items = [
      HorizontalBarChart.BarChartItem(
        id: "zero",
        label: "Zero",
        percentage: 0.0,
        color: .gray
      ),
    ]

    let chart = HorizontalBarChart(items: items)

    #expect(chart.items[0].percentage == 0.0)
  }

  @Test("HorizontalBarChart handles 100 percentage")
  func horizontalBarChart_handles100Percentage() {
    let items = [
      HorizontalBarChart.BarChartItem(
        id: "full",
        label: "Full",
        percentage: 100.0,
        color: .green
      ),
    ]

    let chart = HorizontalBarChart(items: items)

    #expect(chart.items[0].percentage == 100.0)
  }

  @Test("HorizontalBarChart handles decimal percentages")
  func horizontalBarChart_handlesDecimalPercentages() {
    let items = [
      HorizontalBarChart.BarChartItem(
        id: "decimal",
        label: "Decimal",
        percentage: 45.7,
        color: .orange
      ),
    ]

    let chart = HorizontalBarChart(items: items)

    #expect(chart.items[0].percentage == 45.7)
  }

  // MARK: - Multiple Items Tests

  @Test("HorizontalBarChart handles many items")
  func horizontalBarChart_handlesManyItems() {
    let items = (0 ..< 10).map { i in
      HorizontalBarChart.BarChartItem(
        id: "item-\(i)",
        label: "Item \(i)",
        percentage: Double(i * 10),
        color: .blue
      )
    }

    let chart = HorizontalBarChart(items: items)

    #expect(chart.items.count == 10)
    #expect(chart.items.first?.percentage == 0.0)
    #expect(chart.items.last?.percentage == 90.0)
  }
}
