import SwiftUI

/// List-row view for a single `JournalSchedule` in `ScheduleSettingsView`.
/// Shows the schedule's formatted time, repeat-days summary, and an
/// enable toggle bound back to the parent.
///
/// Extracted from `ScheduleSettingsView.swift` so each struct in that
/// surface lives in its own file.
struct ScheduleRow: View {
  let schedule: JournalSchedule
  @Binding var isEnabled: Bool

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
  }()

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(timeString)
          .font(.headline)
        Text(daysString)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Toggle("", isOn: $isEnabled)
        .labelsHidden()
    }
  }

  private var timeString: String {
    guard let hour = schedule.time.hour,
          let minute = schedule.time.minute
    else {
      return "Invalid Time"
    }

    let period = hour >= 12 ? "PM" : "AM"
    let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
    return String(format: "%d:%02d %@", displayHour, minute, period)
  }

  private var daysString: String {
    let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    if schedule.repeatDays.count == 7 {
      return "Every day"
    } else if schedule.repeatDays.isEmpty {
      return "Never"
    } else {
      let sortedDays = schedule.repeatDays.sorted()
      return sortedDays.map { dayNames[$0] }.joined(separator: ", ")
    }
  }
}
