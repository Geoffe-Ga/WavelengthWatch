import SwiftUI

/// Displays phase distribution showing the user's journey through phases
struct PhaseJourneyView: View {
  let phaseDistribution: [PhaseDistributionItem]
  let phases: [CatalogPhaseModel]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Phase Journey")
        .font(.headline)
        .foregroundColor(.secondary)

      if phaseDistribution.isEmpty {
        EmptyStateView()
      } else {
        HorizontalBarChart(items: barChartItems)
      }
    }
  }

  var barChartItems: [HorizontalBarChart.BarChartItem] {
    phaseDistribution.compactMap { item in
      guard let phase = phases.first(where: { $0.id == item.phaseId }) else {
        return nil
      }

      return HorizontalBarChart.BarChartItem(
        id: "\(item.phaseId)",
        label: phase.name,
        percentage: item.percentage,
        color: Self.phaseColor(for: phase.name)
      )
    }
  }

  /// Maps phase names to colors for visualization
  static func phaseColor(for phaseName: String) -> Color {
    switch phaseName.lowercased() {
    case "rising":
      .green // Dawn/growth
    case "peaking":
      .yellow // Noon/peak energy
    case "falling":
      .orange // Sunset/transition
    case "resting":
      .blue // Night/restoration
    default:
      .gray // Unknown phases
    }
  }
}

private struct EmptyStateView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "chart.line.uptrend.xyaxis")
        .font(.title)
        .foregroundColor(.secondary)
      Text("No data")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
  }
}
