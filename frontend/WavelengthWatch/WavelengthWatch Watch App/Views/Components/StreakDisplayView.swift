import SwiftUI

/// A neutral activity summary that replaces streak-style gamification.
struct StreakDisplayView: View {
  let monthlyCheckIns: Int

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

  var activityText: String {
    let word = monthlyCheckIns == 1 ? "check-in" : "check-ins"
    return "\(monthlyCheckIns) \(word) in the last 30 days"
  }

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

#Preview("Very Active") {
  StreakDisplayView(monthlyCheckIns: 42)
    .padding()
    .previewDisplayName("Very Active")
}
