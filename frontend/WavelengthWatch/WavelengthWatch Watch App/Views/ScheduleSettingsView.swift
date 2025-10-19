import SwiftUI

struct ScheduleSettingsView: View {
  @StateObject private var viewModel = ScheduleViewModel()
  @State private var showingAddSchedule = false

  var body: some View {
    List {
      Section {
        ForEach(viewModel.schedules) { schedule in
          NavigationLink {
            ScheduleEditView(
              schedule: schedule,
              onSave: { updated in
                viewModel.updateSchedule(updated)
              }
            )
          } label: {
            ScheduleRow(schedule: schedule) {
              viewModel.toggleSchedule(schedule)
            }
          }
        }
        .onDelete { offsets in
          viewModel.deleteSchedule(at: offsets)
        }
      } header: {
        Text("Journal Prompts")
          .font(.caption)
          .foregroundColor(.white.opacity(0.7))
      }

      Button {
        showingAddSchedule = true
      } label: {
        Label("Add Schedule", systemImage: "plus.circle.fill")
          .foregroundColor(.blue)
      }
    }
    .navigationTitle("Schedules")
    .sheet(isPresented: $showingAddSchedule) {
      NavigationStack {
        ScheduleEditView(
          schedule: nil,
          onSave: { newSchedule in
            viewModel.addSchedule(newSchedule)
            showingAddSchedule = false
          }
        )
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              showingAddSchedule = false
            }
          }
        }
      }
    }
  }
}

struct ScheduleRow: View {
  let schedule: JournalSchedule
  let onToggle: () -> Void

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(timeString)
          .font(.headline)
        Text(daysString)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      Toggle("", isOn: .init(
        get: { schedule.enabled },
        set: { _ in onToggle() }
      ))
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

struct ScheduleEditView: View {
  let schedule: JournalSchedule?
  let onSave: (JournalSchedule) -> Void

  @State private var selectedHour: Int
  @State private var selectedMinute: Int
  @State private var selectedDays: Set<Int>
  @Environment(\.dismiss) private var dismiss

  init(schedule: JournalSchedule?, onSave: @escaping (JournalSchedule) -> Void) {
    self.schedule = schedule
    self.onSave = onSave

    _selectedHour = State(initialValue: schedule?.time.hour ?? 8)
    _selectedMinute = State(initialValue: schedule?.time.minute ?? 0)
    _selectedDays = State(initialValue: schedule?.repeatDays ?? [0, 1, 2, 3, 4, 5, 6])
  }

  var body: some View {
    Form {
      Section {
        HStack {
          Picker("Hour", selection: $selectedHour) {
            ForEach(0 ..< 24) { hour in
              Text("\(hour)").tag(hour)
            }
          }
          .pickerStyle(.wheel)
          .frame(width: 60)

          Text(":")
            .font(.title2)

          Picker("Minute", selection: $selectedMinute) {
            ForEach(0 ..< 60) { minute in
              Text(String(format: "%02d", minute)).tag(minute)
            }
          }
          .pickerStyle(.wheel)
          .frame(width: 60)
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
    var time = DateComponents()
    time.hour = selectedHour
    time.minute = selectedMinute

    let updatedSchedule = JournalSchedule(
      id: schedule?.id ?? UUID(),
      time: time,
      enabled: schedule?.enabled ?? true,
      repeatDays: selectedDays
    )

    onSave(updatedSchedule)
    dismiss()
  }
}

#Preview {
  NavigationStack {
    ScheduleSettingsView()
  }
}
