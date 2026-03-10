import SwiftUI

/// Displays temporal patterns showing dominant phase and dosage per hour
struct TemporalPatternsView: View {
  let patterns: TemporalPatterns
  let phases: [CatalogPhaseModel]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Temporal Patterns")
        .font(.headline)
        .foregroundColor(.secondary)

      if patterns.hourlyDistribution.isEmpty {
        EmptyStateView()
      } else {
        VStack(alignment: .leading, spacing: 6) {
          ForEach(hourlySummaries, id: \.hourLabel) { summary in
            HourlyRow(summary: summary)
          }
        }
      }
    }
  }

  // MARK: - Data Transformation

  /// Summary of a single hour's dominant phase and dosage
  struct HourlySummary: Equatable {
    let hourLabel: String
    let count: Int
    let percentage: Double
    let phaseName: String?
    let dosage: String?
  }

  var hourlySummaries: [HourlySummary] {
    guard !patterns.hourlyDistribution.isEmpty else { return [] }

    let totalCount = patterns.hourlyDistribution.reduce(0) { $0 + $1.count }

    return patterns.hourlyDistribution.map { item in
      let percentage = (Double(item.count) / Double(totalCount)) * 100
      let phaseName = item.dominantPhaseId.flatMap { phaseId in
        phases.first(where: { $0.id == phaseId })?.name
      }

      return HourlySummary(
        hourLabel: Self.hourLabel(item.hour),
        count: item.count,
        percentage: percentage,
        phaseName: phaseName,
        dosage: item.dominantDosage
      )
    }
  }

  static func hourLabel(_ hour: Int) -> String {
    let adjustedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
    let period = hour < 12 ? "AM" : "PM"
    return "\(adjustedHour) \(period)"
  }

  /// Maps dosage to a color — Medicinal gets green, Toxic gets neutral
  static func dosageColor(for dosage: String?) -> Color {
    switch dosage {
    case "Medicinal":
      .green
    case "Toxic":
      .secondary
    default:
      .purple
    }
  }
}

// MARK: - Subviews

private struct HourlyRow: View {
  let summary: TemporalPatternsView.HourlySummary

  var body: some View {
    HStack(spacing: 6) {
      // Time label
      Text(summary.hourLabel)
        .font(.caption2)
        .frame(width: 40, alignment: .leading)

      // Phase + dosage indicator
      VStack(alignment: .leading, spacing: 1) {
        if let phaseName = summary.phaseName {
          Text(phaseName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(TemporalPatternsView.dosageColor(for: summary.dosage))
        }

        if let dosage = summary.dosage {
          Text(dosage)
            .font(.system(size: 9))
            .foregroundColor(.secondary)
        }
      }
      .frame(width: 55, alignment: .leading)

      // Bar
      GeometryReader { geometry in
        RoundedRectangle(cornerRadius: 3)
          .fill(TemporalPatternsView.dosageColor(for: summary.dosage))
          .frame(
            width: geometry.size.width * min(max(summary.percentage, 0) / 100.0, 1.0),
            height: 12
          )
      }
      .frame(height: 12)

      // Count
      Text("\(summary.count)")
        .font(.caption2)
        .foregroundColor(.secondary)
        .frame(width: 20, alignment: .trailing)
    }
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
