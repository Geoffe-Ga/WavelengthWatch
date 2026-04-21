import SwiftUI

/// Displays when a user naturally tends to check in — framed as their
/// natural rhythm rather than a performance metric (Issue #285).
///
/// Uses a single neutral color, descriptive (not prescriptive) language,
/// and an affirmation that every rhythm is valid.
struct TemporalPatternsView: View {
  let patterns: TemporalPatterns
  let phases: [CatalogPhaseModel]

  /// Single neutral color shared across rows — no evaluative palette.
  static let neutralColor: Color = .purple

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(Self.title)
        .font(.headline)
        .foregroundColor(.secondary)

      Text(Self.subtitle)
        .font(.caption2)
        .foregroundColor(.secondary)

      if patterns.hourlyDistribution.isEmpty {
        EmptyStateView()
      } else {
        VStack(alignment: .leading, spacing: 6) {
          ForEach(hourlySummaries, id: \.hourLabel) { summary in
            HourlyRow(summary: summary)
          }
        }

        Text(Self.affirmation)
          .font(.caption2)
          .foregroundColor(.secondary)
          .italic()
          .multilineTextAlignment(.leading)
          .padding(.top, 8)
      }
    }
  }

  // MARK: - Copy

  static let title = "Your Natural Rhythm"
  static let subtitle = "When you naturally tend to check in"
  static let affirmation = "Everyone's rhythm is unique. This is your pattern, and it's valid."

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

  /// Single neutral color for all rows — no medicinal/toxic evaluative coding (Issue #285).
  static func dosageColor(for _: String?) -> Color {
    neutralColor
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

      // Phase + dosage indicator (neutral color)
      VStack(alignment: .leading, spacing: 1) {
        if let phaseName = summary.phaseName {
          Text(phaseName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(TemporalPatternsView.neutralColor)
        }

        if let dosage = summary.dosage {
          Text(dosage)
            .font(.system(size: 9))
            .foregroundColor(.secondary)
        }
      }
      .frame(width: 55, alignment: .leading)

      // Bar (neutral color)
      GeometryReader { geometry in
        RoundedRectangle(cornerRadius: 3)
          .fill(TemporalPatternsView.neutralColor)
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
      Text("No rhythm data yet")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
  }
}
