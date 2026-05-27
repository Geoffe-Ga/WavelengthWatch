import SwiftUI

/// Sheet-presented wheel-style time picker used by `ScheduleEditView`.
/// Writes to a `Binding<Date>` the caller owns; presents Done +
/// Cancel toolbar buttons that dismiss the sheet.
///
/// Extracted from `ScheduleSettingsView.swift` so each struct in that
/// surface lives in its own file.
struct TimePickerView: View {
  @Binding var selectedTime: Date
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        Text("Set Time")
          .font(.headline)
          .padding(.top)

        DatePicker(
          "Time",
          selection: $selectedTime,
          displayedComponents: .hourAndMinute
        )
        .datePickerStyle(.wheel)
        .labelsHidden()

        Button("Done") {
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
}
