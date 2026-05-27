import SwiftUI

/// Form for creating or editing a `JournalSchedule`. Presents a time
/// chooser (handled by `TimePickerView`) and a day-of-week checklist;
/// on save, builds an updated `JournalSchedule` and hands it back to
/// the caller via `onSave`.
///
/// Extracted from `ScheduleSettingsView.swift` so each struct in that
/// surface lives in its own file.
struct ScheduleEditView: View {
  let schedule: JournalSchedule?
  let onSave: (JournalSchedule) -> Void

  @State private var selectedTime: Date
  @State private var selectedDays: Set<Int>
  @State private var showingTimePicker = false
  @Environment(\.dismiss) private var dismiss

  private static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
  }()

  init(schedule: JournalSchedule?, onSave: @escaping (JournalSchedule) -> Void) {
    self.schedule = schedule
    self.onSave = onSave

    // Convert DateComponents to Date for picker
    let calendar = Calendar.current
    let hour = schedule?.time.hour ?? 8
    let minute = schedule?.time.minute ?? 0
    let date = calendar.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()

    _selectedTime = State(initialValue: date)
    _selectedDays = State(initialValue: schedule?.repeatDays ?? [0, 1, 2, 3, 4, 5, 6])
  }

  var body: some View {
    Form {
      Section {
        Button {
          showingTimePicker = true
        } label: {
          HStack {
            Text("Set Time")
              .foregroundColor(.primary)
            Spacer()
            Text(timeString)
              .foregroundColor(.blue)
          }
        }
      } header: {
        Text("Time")
          .font(.caption)
      }

      Section {
        ForEach(0 ..< 7) { day in
          Button {
            toggleDay(day)
          } label: {
            HStack {
              Text(dayName(day))
                .foregroundColor(.primary)
              Spacer()
              if selectedDays.contains(day) {
                Image(systemName: "checkmark")
                  .foregroundColor(.blue)
              }
            }
          }
        }
      } header: {
        Text("Repeat")
          .font(.caption)
      }

      Button("Save") {
        saveSchedule()
      }
      .foregroundColor(.blue)
    }
    .navigationTitle(schedule == nil ? "New Schedule" : "Edit Schedule")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showingTimePicker) {
      TimePickerView(selectedTime: $selectedTime)
    }
  }

  private var timeString: String {
    Self.timeFormatter.string(from: selectedTime)
  }

  private func toggleDay(_ day: Int) {
    if selectedDays.contains(day) {
      selectedDays.remove(day)
    } else {
      selectedDays.insert(day)
    }
  }

  private func dayName(_ day: Int) -> String {
    ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][day]
  }

  private func saveSchedule() {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: selectedTime)

    let updatedSchedule = JournalSchedule(
      id: schedule?.id ?? UUID(),
      time: components,
      enabled: schedule?.enabled ?? true,
      repeatDays: selectedDays
    )

    onSave(updatedSchedule)
    dismiss()
  }
}
