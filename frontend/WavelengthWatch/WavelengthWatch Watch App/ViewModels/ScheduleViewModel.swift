import Foundation
import SwiftUI

final class ScheduleViewModel: ObservableObject {
  @Published var schedules: [JournalSchedule] = []

  private let userDefaults: UserDefaults
  private let notificationScheduler: NotificationSchedulerProtocol
  private let schedulesKey = "com.wavelengthwatch.journalSchedules"

  nonisolated init(
    userDefaults: UserDefaults = .standard,
    notificationScheduler: NotificationSchedulerProtocol = NotificationScheduler()
  ) {
    self.userDefaults = userDefaults
    self.notificationScheduler = notificationScheduler
    Task { @MainActor in
      loadSchedules()
    }
  }

  // MARK: - Persistence

  @MainActor
  private func loadSchedules() {
    guard let data = userDefaults.data(forKey: schedulesKey) else {
      return
    }

    do {
      let decoder = JSONDecoder()
      schedules = try decoder.decode([JournalSchedule].self, from: data)
    } catch {
      // If decoding fails, reset to empty array
      schedules = []
    }
  }

  @MainActor
  func saveSchedules() {
    do {
      let encoder = JSONEncoder()
      let data = try encoder.encode(schedules)
      userDefaults.set(data, forKey: schedulesKey)

      // Update notifications whenever schedules change
      Task {
        try? await notificationScheduler.scheduleNotifications(for: schedules)
      }
    } catch {
      // Silently fail - could add error reporting here
    }
  }

  // MARK: - Permissions

  func requestNotificationPermission() async throws -> Bool {
    try await notificationScheduler.requestPermission()
  }

  // MARK: - CRUD Operations

  @MainActor
  func addSchedule(_ schedule: JournalSchedule) {
    schedules.append(schedule)
    saveSchedules()
  }

  @MainActor
  func updateSchedule(_ schedule: JournalSchedule) {
    guard let index = schedules.firstIndex(where: { $0.id == schedule.id }) else {
      return
    }
    schedules[index] = schedule
    saveSchedules()
  }

  @MainActor
  func deleteSchedule(at offsets: IndexSet) {
    schedules.remove(atOffsets: offsets)
    saveSchedules()
  }
}
