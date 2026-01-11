import SwiftUI

/// Displays strategy usage analytics with top strategies and diversity score
struct StrategyUsageView: View {
  let analytics: SelfCareAnalytics

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Strategy Usage")
        .font(.headline)
        .foregroundColor(.secondary)

      if analytics.topStrategies.isEmpty {
        EmptyStateView()
      } else {
        VStack(alignment: .leading, spacing: 8) {
          HorizontalBarChart(items: barChartItems)

          DiversityScoreView(
            score: analytics.diversityScore,
            totalEntries: analytics.totalStrategyEntries
          )
        }
      }
    }
  }

  var barChartItems: [HorizontalBarChart.BarChartItem] {
    analytics.topStrategies.map { strategy in
      HorizontalBarChart.BarChartItem(
        id: "\(strategy.strategyId)",
        label: strategy.strategy,
        percentage: strategy.percentage,
        color: .blue
      )
    }
  }
}

private struct DiversityScoreView: View {
  let score: Double
  let totalEntries: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Diversity Score")
        .font(.caption2)
        .foregroundColor(.secondary)

      HStack(spacing: 8) {
        // Diversity score: (unique strategies / total uses) * 100
        // Matches backend calculation at analytics.py:648
        Text(String(format: "%.1f%%", score))
          .font(.title3)
          .fontWeight(.semibold)

        Text("(\(totalEntries) uses)")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding(.top, 4)
  }
}

private struct EmptyStateView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "chart.bar.xaxis")
        .font(.title)
        .foregroundColor(.secondary)
      Text("No strategies used yet")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
  }
}
