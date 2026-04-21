import SwiftUI

/// Displays activity pattern indicators — medicinal trend, layer diversity, and phase coverage.
///
/// Reframed in Issue #282 to honor the wavelength's natural ebbs and flows:
/// no red/green evaluative colors, no "declining/increasing" performance language,
/// and supportive context explaining that quieter phases are part of the rhythm.
struct GrowthIndicatorsView: View {
  let indicators: GrowthIndicators

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Your Activity Pattern")
        .font(.headline)
        .foregroundColor(.secondary)

      if isEmpty {
        EmptyStateView()
      } else {
        VStack(alignment: .leading, spacing: 8) {
          MedicinalTrendView(
            description: trendDescription,
            arrow: trendArrow,
            color: trendColor,
            formattedText: formattedTrend
          )

          DiversityCoverageView(
            layerText: layerDiversityText,
            phaseText: phaseCoverageText
          )

          Text(rhythmContext)
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
            .padding(.top, 4)
        }
      }
    }
  }

  // MARK: - Trend Direction

  /// Neutral descriptors for medicinal ratio movement over time.
  /// No "positive/negative" framing — every phase of the wavelength is valid.
  enum TrendDirection {
    case more // More medicinal expressions this period
    case quieter // Fewer medicinal expressions — a natural contraction
    case steady // Within a small threshold of the previous period
  }

  var trendDirection: TrendDirection {
    // Threshold for meaningful change: ±5% (0.05 in decimal)
    let threshold = 0.05

    if indicators.medicinalTrend > threshold {
      return .more
    } else if indicators.medicinalTrend < -threshold {
      return .quieter
    } else {
      return .steady
    }
  }

  // MARK: - UI Properties

  var trendArrow: String {
    switch trendDirection {
    case .more:
      "arrow.up"
    case .quieter:
      "arrow.down"
    case .steady:
      "arrow.forward"
    }
  }

  /// Single neutral color for all trend directions — no evaluative palette (Issue #282).
  var trendColor: Color {
    .secondary
  }

  /// Descriptive, judgment-free label for the trend direction.
  var trendDescription: String {
    switch trendDirection {
    case .more:
      "More medicinal this period"
    case .quieter:
      "A quieter phase right now"
    case .steady:
      "A steady rhythm"
    }
  }

  var formattedTrend: String {
    // medicinalTrend is a decimal fraction (0.0-1.0), multiply by 100 for display
    let displayValue = indicators.medicinalTrend * 100
    let sign = displayValue > 0 ? "+" : ""
    return String(format: "%@%.1f%%", sign, displayValue)
  }

  var layerDiversityText: String {
    let count = indicators.layerDiversity
    return "\(count) \(count == 1 ? "mode" : "modes")"
  }

  var phaseCoverageText: String {
    "\(indicators.phaseCoverage) of 6 phases"
  }

  /// Supportive affirmation anchored in APTITUDE's wavelength teachings.
  var rhythmContext: String {
    "Your engagement naturally ebbs and flows. Quieter phases can be times of integration and rest."
  }

  var isEmpty: Bool {
    indicators.layerDiversity == 0
      && indicators.phaseCoverage == 0
      && indicators.medicinalTrend == 0.0
  }
}

// MARK: - Subviews

private struct MedicinalTrendView: View {
  let description: String
  let arrow: String
  let color: Color
  let formattedText: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Medicinal Rhythm")
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

      Text(description)
        .font(.caption2)
        .foregroundColor(.secondary)
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
      Image(systemName: "waveform.path")
        .font(.title)
        .foregroundColor(.secondary)
      Text("No activity data yet")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
  }
}
