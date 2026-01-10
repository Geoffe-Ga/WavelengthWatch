import SwiftUI

/// A reusable horizontal bar chart component for displaying distribution data.
///
/// This component displays a list of items as horizontal bars with labels and percentages.
/// Each bar's width is proportional to its percentage value and colored according to the item.
/// Items are displayed in the order provided (not sorted by value).
///
/// ## Usage
/// ```swift
/// let items = [
///   HorizontalBarChart.BarChartItem(
///     id: "green",
///     label: "Green",
///     percentage: 24.0,
///     color: .green
///   ),
///   HorizontalBarChart.BarChartItem(
///     id: "blue",
///     label: "Blue",
///     percentage: 18.0,
///     color: .blue
///   )
/// ]
/// HorizontalBarChart(items: items)
/// ```
///
/// ## Design
/// - Label aligned to leading edge
/// - Bar grows from left to right
/// - Percentage displayed at trailing edge
/// - Bars animated on appearance
struct HorizontalBarChart: View {
  /// The items to display in the chart
  let items: [BarChartItem]

  /// The maximum width available for bars (calculated from geometry)
  private let barSpacing: CGFloat = 4
  private let rowHeight: CGFloat = 20

  var body: some View {
    VStack(alignment: .leading, spacing: barSpacing) {
      ForEach(items) { item in
        BarRow(item: item, rowHeight: rowHeight)
      }
    }
  }
}

// MARK: - Supporting Views

/// A single row in the horizontal bar chart
private struct BarRow: View {
  let item: HorizontalBarChart.BarChartItem
  let rowHeight: CGFloat

  @State private var animatedPercentage: Double = 0

  var body: some View {
    HStack(spacing: 8) {
      // Label
      Text(item.label)
        .font(.caption2)
        .lineLimit(1)
        .frame(width: 50, alignment: .leading)

      // Bar with background and foreground
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          // Background track
          RoundedRectangle(cornerRadius: 3)
            .fill(Color.secondary.opacity(0.2))
            .frame(height: rowHeight)

          // Foreground bar
          RoundedRectangle(cornerRadius: 3)
            .fill(item.color)
            .frame(
              width: barWidth(
                for: animatedPercentage,
                availableWidth: geometry.size.width
              ),
              height: rowHeight
            )
        }
      }
      .frame(height: rowHeight)

      // Percentage
      Text(formattedPercentage(item.percentage))
        .font(.caption2)
        .foregroundColor(.secondary)
        .frame(width: 35, alignment: .trailing)
    }
    .onAppear {
      withAnimation(.easeOut(duration: 0.6)) {
        animatedPercentage = item.percentage
      }
    }
  }

  /// Calculates the bar width based on percentage
  private func barWidth(for percentage: Double, availableWidth: CGFloat) -> CGFloat {
    let clampedPercentage = min(max(percentage, 0.0), 100.0)
    return availableWidth * (clampedPercentage / 100.0)
  }

  /// Formats the percentage for display
  private func formattedPercentage(_ percentage: Double) -> String {
    if percentage.truncatingRemainder(dividingBy: 1) == 0 {
      "\(Int(percentage))%"
    } else {
      String(format: "%.1f%%", percentage)
    }
  }
}

// MARK: - Data Model

extension HorizontalBarChart {
  /// A single item in the horizontal bar chart
  struct BarChartItem: Identifiable {
    /// Unique identifier for the item
    let id: String

    /// Label displayed on the leading edge
    let label: String

    /// Percentage value (0-100)
    let percentage: Double

    /// Color of the bar
    let color: Color

    /// Creates a new bar chart item
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - label: Display label
    ///   - percentage: Value between 0 and 100
    ///   - color: Bar color
    init(id: String, label: String, percentage: Double, color: Color) {
      self.id = id
      self.label = label
      self.percentage = percentage
      self.color = color
    }
  }
}

// MARK: - Previews

#Preview("Mode Distribution Example") {
  VStack(alignment: .leading, spacing: 12) {
    Text("Mode Distribution")
      .font(.headline)

    HorizontalBarChart(items: [
      .init(id: "green", label: "Green", percentage: 24.0, color: .green),
      .init(id: "orange", label: "Orange", percentage: 18.0, color: .orange),
      .init(id: "blue", label: "Blue", percentage: 12.0, color: .blue),
      .init(id: "red", label: "Red", percentage: 10.0, color: .red),
      .init(id: "yellow", label: "Yellow", percentage: 8.0, color: .yellow),
    ])
  }
  .padding()
  .previewDisplayName("Mode Distribution")
}

#Preview("Edge Cases") {
  VStack(alignment: .leading, spacing: 12) {
    Text("Edge Cases")
      .font(.headline)

    HorizontalBarChart(items: [
      .init(id: "zero", label: "Zero", percentage: 0.0, color: .gray),
      .init(id: "full", label: "Full", percentage: 100.0, color: .green),
      .init(id: "decimal", label: "Decimal", percentage: 45.7, color: .blue),
    ])
  }
  .padding()
  .previewDisplayName("Edge Cases")
}

#Preview("Empty State") {
  HorizontalBarChart(items: [])
    .padding()
    .previewDisplayName("Empty")
}

#Preview("Many Items") {
  ScrollView {
    VStack(alignment: .leading, spacing: 12) {
      Text("All Modes")
        .font(.headline)

      HorizontalBarChart(items: [
        .init(id: "beige", label: "Beige", percentage: 15.0, color: Color(red: 0.96, green: 0.96, blue: 0.86)),
        .init(id: "purple", label: "Purple", percentage: 8.0, color: .purple),
        .init(id: "red", label: "Red", percentage: 10.0, color: .red),
        .init(id: "blue", label: "Blue", percentage: 12.0, color: .blue),
        .init(id: "orange", label: "Orange", percentage: 18.0, color: .orange),
        .init(id: "green", label: "Green", percentage: 24.0, color: .green),
        .init(id: "yellow", label: "Yellow", percentage: 8.0, color: .yellow),
        .init(id: "teal", label: "Teal", percentage: 3.0, color: .teal),
        .init(id: "uv", label: "UV", percentage: 1.5, color: Color(red: 0.58, green: 0.4, blue: 0.74)),
        .init(id: "clear", label: "Clear", percentage: 0.5, color: Color(white: 0.9)),
      ])
    }
    .padding()
  }
  .previewDisplayName("Many Items")
}
