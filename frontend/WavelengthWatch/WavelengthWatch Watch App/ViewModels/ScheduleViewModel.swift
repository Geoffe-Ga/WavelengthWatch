import Foundation
import SwiftUI

@MainActor
final class ScheduleViewModel: ObservableObject {
  @Published var schedules: [JournalSchedule] = []

  private let userDefaults: UserDefaults
  private let notificationScheduler: NotificationSchedulerProtocol
  private let schedulesKey = "com.wavelengthwatch.journalSchedules"

  init(
    userDefaults: UserDefaults = .standard,
    notificationScheduler: NotificationSchedulerProtocol = NotificationScheduler()
  ) {
    self.userDefaults = userDefaults
    self.notificationScheduler = notificationScheduler
    loadSchedules()
  }

  // MARK: - Persistence

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

  private func saveSchedules() {
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

  func addSchedule(_ schedule: JournalSchedule) {
    schedules.append(schedule)
    saveSchedules()
  }

  func updateSchedule(_ schedule: JournalSchedule) {
    guard let index = schedules.firstIndex(where: { $0.id == schedule.id }) else {
      return
    }
    schedules[index] = schedule
    saveSchedules()
  }

  func deleteSchedule(at offsets: IndexSet) {
    schedules.remove(atOffsets: offsets)
    saveSchedules()
  }

  func toggleSchedule(_ schedule: JournalSchedule) {
    guard let index = schedules.firstIndex(where: { $0.id == schedule.id }) else {
      return
    }
    schedules[index].enabled.toggle()
    saveSchedules()
  }
}
