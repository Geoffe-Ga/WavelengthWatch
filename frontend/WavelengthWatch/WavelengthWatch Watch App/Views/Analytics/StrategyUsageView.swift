import SwiftUI

/// Displays strategy usage analytics grouped by phase with diversity scores
struct StrategyUsageView: View {
  let analytics: SelfCareAnalytics
  let phases: [CatalogPhaseModel]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Strategy Usage")
        .font(.headline)
        .foregroundColor(.secondary)

      if analytics.topStrategies.isEmpty, phaseGroups.isEmpty {
        EmptyStateView()
      } else {
        VStack(alignment: .leading, spacing: 12) {
          // Overall diversity
          OverallDiversityView(
            score: analytics.diversityScore,
            totalEntries: analytics.totalStrategyEntries,
            tagline: diversityTagline
          )

          // Strategies grouped by phase
          ForEach(phaseGroups, id: \.phaseName) { group in
            PhaseStrategyCardView(group: group)
          }
        }
      }
    }
  }

  // MARK: - Data Transformation

  /// Resolved phase group with human-readable phase name
  struct ResolvedPhaseGroup: Equatable {
    let phaseName: String
    let strategies: [TopStrategyItem]
    let diversityScore: Double
    let totalEntries: Int
  }

  var phaseGroups: [ResolvedPhaseGroup] {
    analytics.strategyGroups.map { group in
      let phaseName = phases.first(where: { $0.id == group.phaseId })?.name
        ?? "Phase \(group.phaseId)"

      return ResolvedPhaseGroup(
        phaseName: phaseName,
        strategies: group.strategies,
        diversityScore: group.diversityScore,
        totalEntries: group.totalEntries
      )
    }
  }

  var diversityTagline: String {
    "Ratio of unique strategies to total uses"
  }
}

// MARK: - Subviews

private struct OverallDiversityView: View {
  let score: Double
  let totalEntries: Int
  let tagline: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 8) {
        Text("Diversity")
          .font(.caption2)
          .foregroundColor(.secondary)

        Text(String(format: "%.1f%%", score))
          .font(.subheadline)
          .fontWeight(.semibold)

        Text("(\(totalEntries) uses)")
          .font(.caption2)
          .foregroundColor(.secondary)
      }

      Text(tagline)
        .font(.system(size: 9))
        .foregroundColor(.secondary)
    }
  }
}

private struct PhaseStrategyCardView: View {
  let group: StrategyUsageView.ResolvedPhaseGroup

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      // Phase header with per-phase diversity
      HStack {
        Text(group.phaseName)
          .font(.caption)
          .fontWeight(.semibold)

        Spacer()

        Text(String(format: "%.0f%%", group.diversityScore))
          .font(.caption2)
          .foregroundColor(.secondary)
      }

      // Strategy cards
      ForEach(group.strategies, id: \.strategyId) { strategy in
        StrategyCardView(strategy: strategy)
      }
    }
    .padding(8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.secondary.opacity(0.1))
    )
  }
}

private struct StrategyCardView: View {
  let strategy: TopStrategyItem

  var body: some View {
    HStack {
      Text(strategy.strategy)
        .font(.caption2)
        .lineLimit(1)

      Spacer()

      Text(String(format: "%.0f%%", strategy.percentage))
        .font(.caption2)
        .fontWeight(.medium)
        .foregroundColor(.secondary)
    }
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
