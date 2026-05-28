import SwiftUI

struct ScheduleSettingsView: View {
  @StateObject private var viewModel = ScheduleViewModel()
  @State private var showingAddSchedule = false
  @State private var showingPermissionAlert = false
  @State private var permissionAlertMessage = ""

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
                get: {
                  guard index < viewModel.schedules.count else { return false }
                  return viewModel.schedules[index].enabled
                },
                set: {
                  guard index < viewModel.schedules.count else { return }
                  viewModel.schedules[index].enabled = $0
                  viewModel.saveSchedules()
                }
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
          .foregroundStyle(WLColorTokens.secondaryText)
      }

      Button {
        showingAddSchedule = true
      } label: {
        Label("Add Schedule", systemImage: "plus.circle.fill")
          .foregroundStyle(WLColorTokens.interactiveAccent)
      }
    }
    .navigationTitle("Schedules")
    .onAppear {
      Task {
        do {
          let granted = try await viewModel.requestNotificationPermission()
          if !granted {
            permissionAlertMessage = "Notifications are disabled. Enable them in Settings to receive scheduled journal prompts."
            showingPermissionAlert = true
          }
        } catch {
          permissionAlertMessage = "Failed to request notification permissions: \(error.localizedDescription)"
          showingPermissionAlert = true
        }
      }
    }
    .alert("Notification Permissions", isPresented: $showingPermissionAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(permissionAlertMessage)
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

#Preview {
  NavigationStack {
    ScheduleSettingsView()
  }
}
