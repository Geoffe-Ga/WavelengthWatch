import SwiftUI

/// Displays growth indicators showing medicinal trend, layer diversity, and phase coverage
struct GrowthIndicatorsView: View {
  let indicators: GrowthIndicators

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Growth Indicators")
        .font(.headline)
        .foregroundColor(.secondary)

      if isEmpty {
        EmptyStateView()
      } else {
        VStack(alignment: .leading, spacing: 8) {
          MedicinalTrendView(
            trend: indicators.medicinalTrend,
            direction: trendDirection,
            arrow: trendArrow,
            color: trendColor,
            formattedText: formattedTrend
          )

          DiversityCoverageView(
            layerText: layerDiversityText,
            phaseText: phaseCoverageText
          )
        }
      }
    }
  }

  // MARK: - Trend Direction

  enum TrendDirection {
    case positive
    case negative
    case neutral
  }

  var trendDirection: TrendDirection {
    // Threshold for meaningful trend: ±5%
    // Matches backend analytics logic for growth significance
    let threshold = 5.0

    if indicators.medicinalTrend > threshold {
      return .positive
    } else if indicators.medicinalTrend < -threshold {
      return .negative
    } else {
      return .neutral
    }
  }

  // MARK: - UI Properties

  var trendArrow: String {
    switch trendDirection {
    case .positive:
      "arrow.up"
    case .negative:
      "arrow.down"
    case .neutral:
      "arrow.forward"
    }
  }

  var trendColor: Color {
    switch trendDirection {
    case .positive:
      .green
    case .negative:
      .red
    case .neutral:
      .orange
    }
  }

  var formattedTrend: String {
    let sign = indicators.medicinalTrend > 0 ? "+" : ""
    return String(format: "%@%.1f%%", sign, indicators.medicinalTrend)
  }

  var layerDiversityText: String {
    let count = indicators.layerDiversity
    return "\(count) \(count == 1 ? "mode" : "modes")"
  }

  var phaseCoverageText: String {
    "\(indicators.phaseCoverage) of 6 phases"
  }

  var isEmpty: Bool {
    indicators.layerDiversity == 0
      && indicators.phaseCoverage == 0
      && indicators.medicinalTrend == 0.0
  }
}

// MARK: - Subviews

private struct MedicinalTrendView: View {
  let trend: Double
  let direction: GrowthIndicatorsView.TrendDirection
  let arrow: String
  let color: Color
  let formattedText: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Medicinal Trend")
        .font(.caption2)
        .foregroundColor(.secondary)

      HStack(spacing: 8) {
        Text(formattedText)
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundColor(color)

        Image(systemName: arrow)
          .foregroundColor(color)
          .font(.caption)
      }
    }
  }
}

private struct DiversityCoverageView: View {
  let layerText: String
  let phaseText: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      VStack(alignment: .leading, spacing: 2) {
        Text("Layer Diversity")
          .font(.caption2)
          .foregroundColor(.secondary)

        Text(layerText)
          .font(.subheadline)
      }

      VStack(alignment: .leading, spacing: 2) {
        Text("Phase Coverage")
          .font(.caption2)
          .foregroundColor(.secondary)

        Text(phaseText)
          .font(.subheadline)
      }
    }
    .padding(.top, 4)
  }
}

private struct EmptyStateView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "chart.line.uptrend.xyaxis")
        .font(.title)
        .foregroundColor(.secondary)
      Text("No growth data")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
  }
}
