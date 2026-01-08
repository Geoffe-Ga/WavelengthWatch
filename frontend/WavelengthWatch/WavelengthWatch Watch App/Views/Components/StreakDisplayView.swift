import SwiftUI

/// A reusable component for displaying journal entry streak statistics.
///
/// Shows current streak with fire icon, longest streak, optional consistency score,
/// and trend indicators to show progress toward goals.
///
/// ## Usage
/// ```swift
/// // Basic streak display
/// StreakDisplayView(
///   currentStreak: 5,
///   longestStreak: 12
/// )
///
/// // With consistency score
/// StreakDisplayView(
///   currentStreak: 25,
///   longestStreak: 30,
///   consistencyScore: 83.33
/// )
/// ```
///
/// ## Analytics Context
/// Part of the analytics feature (Issue #195) for displaying temporal patterns
/// and consistency metrics to users. Supports growth indicators by showing
/// trend arrows based on current vs longest streak comparison.
struct StreakDisplayView: View {
  let currentStreak: Int
  let longestStreak: Int
  let consistencyScore: Double?

  /// Creates a streak display view with optional consistency score.
  ///
  /// - Parameters:
  ///   - currentStreak: Current consecutive days with at least 1 entry
  ///   - longestStreak: Historical best streak
  ///   - consistencyScore: Optional consistency percentage (0-100)
  init(
    currentStreak: Int,
    longestStreak: Int,
    consistencyScore: Double? = nil
  ) {
    self.currentStreak = currentStreak
    self.longestStreak = longestStreak
    self.consistencyScore = consistencyScore
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Current streak with fire icon
      HStack(spacing: 6) {
        Text("🔥")
          .font(.title2)

        VStack(alignment: .leading, spacing: 2) {
          Text(currentStreakText)
            .font(.headline)
            .fontWeight(.semibold)

          Text(longestStreakText)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        // Trend indicator
        Text(trendArrow)
          .font(.title3)
          .foregroundColor(trendColor)
      }

      // Consistency score (if provided)
      if let score = consistencyScore {
        HStack(spacing: 4) {
          Text("Consistency:")
            .font(.caption2)
            .foregroundColor(.secondary)

          Text(String(format: "%.0f%%", score))
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
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

  // MARK: - Computed Properties

  /// Formatted text for current streak with proper pluralization
  var currentStreakText: String {
    let dayWord = currentStreak == 1 ? "Day" : "Days"
    return "\(currentStreak) \(dayWord) Streak"
  }

  /// Formatted text for longest streak subtitle
  var longestStreakText: String {
    let dayWord = longestStreak == 1 ? "day" : "days"
    return "Longest: \(longestStreak) \(dayWord)"
  }

  /// Trend indicator based on current vs longest streak comparison
  var trendIndicator: TrendIndicator {
    if currentStreak > longestStreak {
      .improving
    } else if currentStreak == longestStreak {
      .stable
    } else {
      .declining
    }
  }

  /// Arrow symbol for trend direction
  var trendArrow: String {
    switch trendIndicator {
    case .improving:
      "↑"
    case .stable:
      "→"
    case .declining:
      "↓"
    }
  }

  /// Color for trend indicator
  private var trendColor: Color {
    switch trendIndicator {
    case .improving:
      .green
    case .stable:
      .blue
    case .declining:
      .orange
    }
  }
}

// MARK: - Supporting Types

/// Represents the trend of current streak relative to longest streak
enum TrendIndicator: Equatable {
  case improving // Current > Longest (new record)
  case stable // Current == Longest (maintaining record)
  case declining // Current < Longest (working back toward record)
}

// MARK: - Previews

#Preview("Active Streak") {
  StreakDisplayView(
    currentStreak: 5,
    longestStreak: 12
  )
  .padding()
  .previewDisplayName("Active Streak")
}

#Preview("New Record") {
  StreakDisplayView(
    currentStreak: 15,
    longestStreak: 12,
    consistencyScore: 93.3
  )
  .padding()
  .previewDisplayName("New Record")
}

#Preview("Perfect Consistency") {
  StreakDisplayView(
    currentStreak: 30,
    longestStreak: 30,
    consistencyScore: 100.0
  )
  .padding()
  .previewDisplayName("Perfect Consistency")
}

#Preview("No Streak") {
  StreakDisplayView(
    currentStreak: 0,
    longestStreak: 12
  )
  .padding()
  .previewDisplayName("No Current Streak")
}

#Preview("Single Day") {
  StreakDisplayView(
    currentStreak: 1,
    longestStreak: 1
  )
  .padding()
  .previewDisplayName("Single Day")
}

#Preview("Large Numbers") {
  StreakDisplayView(
    currentStreak: 365,
    longestStreak: 400,
    consistencyScore: 91.25
  )
  .padding()
  .previewDisplayName("Large Numbers")
}
