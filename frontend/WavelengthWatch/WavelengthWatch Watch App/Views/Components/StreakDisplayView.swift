import SwiftUI

/// A neutral activity summary that replaces streak-style gamification.
///
/// Displays the number of check-ins over the past ~30 days as a plain
/// descriptive observation, with no streak counting, fire emoji, or
/// "longest/previous high" framing that implies daily goals.
///
/// ## Usage
/// ```swift
/// StreakDisplayView(monthlyCheckIns: 7)
/// ```
///
/// ## Analytics Context
/// Part of the analytics reframes batch 1 (Issues #280, #281, #282, #285)
/// to align with APTITUDE values — presence over engagement metrics.
/// Replaces the previous streak counter (Issue #280).
struct StreakDisplayView: View {
  let monthlyCheckIns: Int

  /// Creates a recent activity display.
  ///
  /// - Parameter monthlyCheckIns: Total check-ins in the trailing ~30 days.
  init(monthlyCheckIns: Int) {
    precondition(monthlyCheckIns >= 0, "Monthly check-ins cannot be negative")
    self.monthlyCheckIns = monthlyCheckIns
  }

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "calendar")
        .font(.title2)
        .foregroundColor(.purple)

      VStack(alignment: .leading, spacing: 2) {
        Text(activityText)
          .font(.headline)
          .fontWeight(.semibold)

        Text(contextText)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.secondary.opacity(0.15))
    )
  }

  // MARK: - Computed Properties

  /// Neutral, descriptive activity line — no streak / goal framing.
  var activityText: String {
    let word = monthlyCheckIns == 1 ? "check-in" : "check-ins"
    return "\(monthlyCheckIns) \(word) this month"
  }

  /// Supportive context that affirms natural rhythms.
  var contextText: String {
    "Your check-in rhythm naturally varies"
  }
}

// MARK: - Previews

#Preview("Recent Activity") {
  StreakDisplayView(monthlyCheckIns: 7)
    .padding()
    .previewDisplayName("Recent Activity")
}

#Preview("Single Check-In") {
  StreakDisplayView(monthlyCheckIns: 1)
    .padding()
    .previewDisplayName("Single Check-In")
}

#Preview("Quieter Period") {
  StreakDisplayView(monthlyCheckIns: 0)
    .padding()
    .previewDisplayName("Quieter Period")
}

#Preview("Very Active") {
  StreakDisplayView(monthlyCheckIns: 42)
    .padding()
    .previewDisplayName("Very Active")
}
