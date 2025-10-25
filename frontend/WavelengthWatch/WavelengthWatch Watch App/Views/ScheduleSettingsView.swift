import SwiftUI

struct ScheduleSettingsView: View {
  @StateObject private var viewModel = ScheduleViewModel()
  @State private var showingAddSchedule = false

  var body: some View {
    List {
      Section {
        ForEach(Array(viewModel.schedules.enumerated()), id: \.element.id) { index, schedule in
          NavigationLink {
            ScheduleEditView(
              schedule: schedule,
              onSave: { updated in
                viewModel.updateSchedule(updated)
              }
            )
          } label: {
            ScheduleRow(
              schedule: schedule,
              isEnabled: Binding(
                get: { viewModel.schedules[index].enabled },
                set: { viewModel.schedules[index].enabled = $0; viewModel.saveSchedules() }
              )
            )
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
    .onAppear {
      Task {
        try? await viewModel.requestNotificationPermission()
      }
    }
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
  @Binding var isEnabled: Bool

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

struct ScheduleEditView: View {
  let schedule: JournalSchedule?
  let onSave: (JournalSchedule) -> Void

  @State private var selectedTime: Date
  @State private var selectedDays: Set<Int>
  @State private var showingTimePicker = false
  @Environment(\.dismiss) private var dismiss

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
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: selectedTime)
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

struct TimePickerView: View {
  @Binding var selectedTime: Date
  @Environment(\.dismiss) private var dismiss
  @State private var selectedHour: Int
  @State private var selectedMinute: Int
  @State private var isPM: Bool

  init(selectedTime: Binding<Date>) {
    _selectedTime = selectedTime
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: selectedTime.wrappedValue)
    let hour24 = components.hour ?? 8
    let minute = components.minute ?? 0

    // Convert 24-hour to 12-hour format
    let hour12: Int
    let isPM: Bool
    if hour24 == 0 {
      hour12 = 12
      isPM = false
    } else if hour24 < 12 {
      hour12 = hour24
      isPM = false
    } else if hour24 == 12 {
      hour12 = 12
      isPM = true
    } else {
      hour12 = hour24 - 12
      isPM = true
    }

    _selectedHour = State(initialValue: hour12)
    _selectedMinute = State(initialValue: minute)
    _isPM = State(initialValue: isPM)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 12) {
        Text("Set Time")
          .font(.headline)
          .padding(.top)

        HStack(spacing: 2) {
          // Hour picker (1-12 with wraparound)
          Picker("Hour", selection: $selectedHour) {
            ForEach(1 ... 12, id: \.self) { hour in
              Text("\(hour)")
                .tag(hour)
            }
          }
          .pickerStyle(.wheel)
          .frame(width: 45)

          Text(":")
            .font(.title3)

          // Minute picker (0-59 with wraparound)
          Picker("Minute", selection: $selectedMinute) {
            ForEach(0 ..< 60, id: \.self) { minute in
              Text(String(format: "%02d", minute))
                .tag(minute)
            }
          }
          .pickerStyle(.wheel)
          .frame(width: 55)

          // AM/PM picker
          Picker("Period", selection: $isPM) {
            Text("AM").tag(false)
            Text("PM").tag(true)
          }
          .pickerStyle(.wheel)
          .frame(width: 45)
        }
        .padding(.horizontal, 4)

        Button("Done") {
          updateTime()
          dismiss()
        }
        .foregroundColor(.blue)
        .padding(.bottom)
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }

  private func updateTime() {
    let calendar = Calendar.current

    // Convert 12-hour format to 24-hour
    var hour24: Int = if selectedHour == 12 {
      isPM ? 12 : 0
    } else {
      isPM ? selectedHour + 12 : selectedHour
    }

    let components = DateComponents(hour: hour24, minute: selectedMinute)
    if let newDate = calendar.date(from: components) {
      selectedTime = newDate
    }
  }
}

#Preview {
  NavigationStack {
    ScheduleSettingsView()
  }
}
