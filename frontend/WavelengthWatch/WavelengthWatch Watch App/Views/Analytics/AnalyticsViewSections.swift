import SwiftUI

extension AnalyticsView {
  // MARK: - Check-In Activity Section

  func checkInActivitySection(overview: AnalyticsOverview) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("CHECK-IN ACTIVITY")
        .font(.caption)
        .foregroundColor(.secondary)
        .tracking(1.5)

      HStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 4) {
          Text("\(overview.totalEntries)")
            .font(.title2)
            .fontWeight(.semibold)

          Text("Total Entries")
            .font(.caption2)
            .foregroundColor(.secondary)
        }

        Divider()
          .frame(height: 30)

        VStack(alignment: .leading, spacing: 4) {
          Text(String(format: "%.1f", overview.avgFrequency))
            .font(.title2)
            .fontWeight(.semibold)

          Text("Per Day")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.secondary.opacity(0.15))
      )

      // Recent Activity Display
      if overview.currentStreak > 0 || overview.totalEntries >= 2 {
        StreakDisplayView(
          currentStreak: overview.currentStreak,
          longestStreak: overview.longestStreak
        )
      }

      // Last Check-In
      if let lastCheckIn = overview.lastCheckIn {
        HStack(spacing: 6) {
          Image(systemName: "clock")
            .font(.caption)
            .foregroundColor(.secondary)

          Text("Last check-in: \(lastCheckIn, style: .relative) ago")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
  }

  // MARK: - Emotional Health Section

  func emotionalHealthSection(overview: AnalyticsOverview) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("EMOTIONAL HEALTH")
        .font(.caption)
        .foregroundColor(.secondary)
        .tracking(1.5)

      VStack(spacing: 12) {
        CircularProgressView(
          percentage: overview.medicinalRatio * 100,
          size: 100
        )

        Text("Medicinal Ratio")
          .font(.caption)
          .foregroundColor(.secondary)

        // Trend Indicator
        if overview.medicinalTrend != 0 {
          HStack(spacing: 4) {
            Image(systemName: overview.medicinalTrend > 0 ? "arrow.up" : "arrow.down")
              .font(.caption2)
              .foregroundColor(overview.medicinalTrend > 0 ? .green : .orange)

            Text(String(format: "%.1f%% this period", abs(overview.medicinalTrend * 100)))
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
      }
      .frame(maxWidth: .infinity)
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.secondary.opacity(0.15))
      )
    }
  }

  // MARK: - Current State Section

  func currentStateSection(layerId: Int, phaseId: Int) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("CURRENT STATE (LAST 7 DAYS)")
        .font(.caption)
        .foregroundColor(.secondary)
        .tracking(1.5)

      VStack(alignment: .leading, spacing: 8) {
        if let layer = contentViewModel.layers.first(where: { $0.id == layerId }),
           let phase = layer.phases.first(where: { $0.id == phaseId })
        {
          HStack(spacing: 8) {
            Circle()
              .fill(Color(stage: layer.color))
              .frame(width: 12, height: 12)
              .shadow(color: Color(stage: layer.color), radius: 2)

            VStack(alignment: .leading, spacing: 2) {
              Text("Dominant Mode")
                .font(.caption2)
                .foregroundColor(.secondary)

              Text(layer.title)
                .font(.body)
                .fontWeight(.medium)
            }
          }

          HStack(spacing: 8) {
            Image(systemName: "waveform")
              .font(.caption)
              .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 2) {
              Text("Dominant Phase")
                .font(.caption2)
                .foregroundColor(.secondary)

              Text(phase.name)
                .font(.body)
                .fontWeight(.medium)
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.secondary.opacity(0.15))
      )
    }
  }

  // MARK: - Quick Stats Section

  func quickStatsSection(overview: AnalyticsOverview) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("QUICK STATS")
        .font(.caption)
        .foregroundColor(.secondary)
        .tracking(1.5)

      VStack(spacing: 8) {
        quickStatRow(
          icon: "heart.text.square",
          label: "Unique Emotions",
          value: "\(overview.uniqueEmotions)"
        )

        quickStatRow(
          icon: "leaf",
          label: "Strategies Used",
          value: "\(overview.strategiesUsed)"
        )

        quickStatRow(
          icon: "arrow.triangle.branch",
          label: "With Secondary Emotion",
          value: String(format: "%.0f%%", overview.secondaryEmotionsPct * 100)
        )
      }
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.secondary.opacity(0.15))
      )
    }
  }

  func quickStatRow(icon: String, label: String, value: String) -> some View {
    HStack {
      Image(systemName: icon)
        .font(.body)
        .foregroundColor(.secondary)
        .frame(width: 24)

      Text(label)
        .font(.caption)
        .foregroundColor(.secondary)

      Spacer()

      Text(value)
        .font(.body)
        .fontWeight(.semibold)
    }
  }

  // MARK: - Detailed Insights Button

  var detailedInsightsButton: some View {
    NavigationLink(
      destination: AnalyticsDetailHubView(
        journalRepository: journalRepository,
        catalogRepository: catalogRepository
      )
    ) {
      HStack {
        Image(systemName: "chart.bar.doc.horizontal")
          .font(.title3)
          .foregroundColor(.blue)

        VStack(alignment: .leading, spacing: 2) {
          Text("View Detailed Insights")
            .font(.body)
            .fontWeight(.semibold)

          Text("Explore patterns, trends & growth")
            .font(.caption2)
            .foregroundColor(.secondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.blue.opacity(0.15))
      )
    }
    .buttonStyle(.plain)
  }
}
