import SwiftUI

/// A reusable component for displaying journal entry streak statistics.
///
/// Shows current streak with fire icon, longest streak,
/// and trend indicators to show progress toward goals.
///
/// ## Usage
/// ```swift
/// StreakDisplayView(
///   currentStreak: 5,
///   longestStreak: 12
/// )
/// ```
///
/// ## Analytics Context
/// Part of the analytics feature (Issue #195) for displaying temporal patterns
/// to users. Supports growth indicators by showing trend arrows based on
/// current vs longest streak comparison.
struct StreakDisplayView: View {
  let currentStreak: Int
  let longestStreak: Int

  /// Creates a streak display view.
  ///
  /// - Parameters:
  ///   - currentStreak: Current consecutive days with at least 1 entry
  ///   - longestStreak: Historical best streak
  init(
    currentStreak: Int,
    longestStreak: Int
  ) {
    precondition(currentStreak >= 0, "Current streak cannot be negative")
    precondition(longestStreak >= 0, "Longest streak cannot be negative")
    precondition(
      currentStreak <= longestStreak,
      "Current streak (\(currentStreak)) cannot exceed longest streak (\(longestStreak)). Caller must update longestStreak when record is broken."
    )

    self.currentStreak = currentStreak
    self.longestStreak = longestStreak
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
  ///
  /// Note: `.improving` case removed after adding validation that currentStreak <= longestStreak.
  /// When a new record is achieved, the caller must update longestStreak to match currentStreak.
  var trendIndicator: TrendIndicator {
    if currentStreak == longestStreak {
      .stable // At personal record
    } else {
      .resting // Honoring natural rhythm
    }
  }

  /// Arrow symbol for trend direction
  var trendArrow: String {
    switch trendIndicator {
    case .stable:
      "→"
    case .resting:
      "↓"
    }
  }

  /// Color for trend indicator
  ///
  /// Uses neutral, supportive colors to honor natural rhythms.
  /// Avoids red/orange evaluative colors that imply judgment.
  var trendColor: Color {
    switch trendIndicator {
    case .stable:
      .green // At personal best - positive!
    case .resting:
      .secondary // Neutral - honoring natural rhythm
    }
  }
}

// MARK: - Supporting Types

/// Represents the trend of current streak relative to longest streak
///
/// Note: `.improving` case removed because currentStreak cannot exceed longestStreak
/// (enforced by precondition in init). When a new record is achieved, the caller
/// must update longestStreak to match currentStreak, resulting in `.stable` status.
///
/// Uses neutral, supportive language to honor natural rhythms rather than judge engagement.
enum TrendIndicator: Equatable {
  case stable // Current == Longest (at personal record)
  case resting // Current < Longest (honoring natural rhythm)
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

#Preview("At Record") {
  StreakDisplayView(
    currentStreak: 15,
    longestStreak: 15
  )
  .padding()
  .previewDisplayName("At Personal Record")
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
    longestStreak: 400
  )
  .padding()
  .previewDisplayName("Large Numbers")
}
