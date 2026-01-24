import SwiftUI

/// Displays temporal patterns showing time-of-day distribution and consistency
struct TemporalPatternsView: View {
  let patterns: TemporalPatterns

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Temporal Patterns")
        .font(.headline)
        .foregroundColor(.secondary)

      if patterns.hourlyDistribution.isEmpty {
        EmptyStateView()
      } else {
        VStack(alignment: .leading, spacing: 8) {
          HorizontalBarChart(items: barChartItems)

          ConsistencyScoreView(score: patterns.consistencyScore)
        }
      }
    }
  }

  var barChartItems: [HorizontalBarChart.BarChartItem] {
    // Guard ensures totalCount is always > 0, preventing division by zero
    guard !patterns.hourlyDistribution.isEmpty else { return [] }

    let totalCount = patterns.hourlyDistribution.reduce(0) { $0 + $1.count }

    return patterns.hourlyDistribution.map { item in
      let percentage = (Double(item.count) / Double(totalCount)) * 100

      return HorizontalBarChart.BarChartItem(
        id: "\(item.hour)",
        label: Self.hourLabel(item.hour),
        percentage: percentage,
        color: .purple
      )
    }
  }

  static func hourLabel(_ hour: Int) -> String {
    let adjustedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
    let period = hour < 12 ? "AM" : "PM"
    return "\(adjustedHour) \(period)"
  }
}

private struct ConsistencyScoreView: View {
  let score: Double

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Your Natural Rhythm")
        .font(.caption2)
        .foregroundColor(.secondary)

      HStack(spacing: 8) {
        Text(String(format: "%.1f%%", score))
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundColor(.secondary)

        Image(systemName: "chart.line.uptrend.xyaxis")
          .foregroundColor(.secondary)
          .font(.caption)
      }

      Text("Your check-in frequency naturally varies with your wavelength.")
        .font(.caption2)
        .foregroundColor(.secondary)
        .padding(.top, 2)
    }
    .padding(.top, 4)
  }
}

private struct EmptyStateView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "clock")
        .font(.title)
        .foregroundColor(.secondary)
      Text("No temporal data")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
  }
}
