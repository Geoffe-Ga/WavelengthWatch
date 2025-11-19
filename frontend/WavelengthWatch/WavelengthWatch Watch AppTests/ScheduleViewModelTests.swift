import Foundation
import Testing
import UserNotifications
@testable import WavelengthWatch_Watch_App

struct ScheduleViewModelTests {
  @MainActor
  @Test func requestsNotificationPermission() async throws {
    let mockCenter = MockNotificationCenter()
    let scheduler = NotificationScheduler(notificationCenter: mockCenter)
    let defaults = UserDefaults(suiteName: "ScheduleViewModelTests.permission")!
    defaults.removePersistentDomain(forName: "ScheduleViewModelTests.permission")
    let viewModel = ScheduleViewModel(userDefaults: defaults, notificationScheduler: scheduler)

    let granted = try await viewModel.requestNotificationPermission()

    #expect(granted == true)
    #expect(mockCenter.requestedPermissions?.contains(.alert) == true)
    #expect(mockCenter.requestedPermissions?.contains(.sound) == true)
    #expect(mockCenter.requestedPermissions?.contains(.badge) == true)
  }

  @MainActor
  @Test func addsScheduleAndPersists() throws {
    let defaults = UserDefaults(suiteName: "ScheduleViewModelTests.add")!
    defaults.removePersistentDomain(forName: "ScheduleViewModelTests.add")

    let viewModel = ScheduleViewModel(userDefaults: defaults)
    #expect(viewModel.schedules.isEmpty)

    var time = DateComponents()
    time.hour = 8
    time.minute = 0
    let schedule = JournalSchedule(time: time, repeatDays: [1, 2, 3, 4, 5])

    viewModel.addSchedule(schedule)
    #expect(viewModel.schedules.count == 1)
    #expect(viewModel.schedules[0].id == schedule.id)

    // Verify persistence
    let newViewModel = ScheduleViewModel(userDefaults: defaults)
    #expect(newViewModel.schedules.count == 1)
    #expect(newViewModel.schedules[0].id == schedule.id)
  }

  @MainActor
  @Test func updatesSchedule() {
    let defaults = UserDefaults(suiteName: "ScheduleViewModelTests.update")!
    defaults.removePersistentDomain(forName: "ScheduleViewModelTests.update")

    let viewModel = ScheduleViewModel(userDefaults: defaults)

    var time = DateComponents()
    time.hour = 8
    time.minute = 0
    let schedule = JournalSchedule(time: time, repeatDays: [1, 2, 3])
    viewModel.addSchedule(schedule)

    var updatedTime = DateComponents()
    updatedTime.hour = 10
    updatedTime.minute = 30
    let updated = JournalSchedule(
      id: schedule.id,
      time: updatedTime,
      enabled: false,
      repeatDays: [0, 6]
    )
    viewModel.updateSchedule(updated)

    #expect(viewModel.schedules.count == 1)
    #expect(viewModel.schedules[0].time.hour == 10)
    #expect(viewModel.schedules[0].enabled == false)
  }

  @MainActor
  @Test func deletesSchedule() {
    let defaults = UserDefaults(suiteName: "ScheduleViewModelTests.delete")!
    defaults.removePersistentDomain(forName: "ScheduleViewModelTests.delete")

    let viewModel = ScheduleViewModel(userDefaults: defaults)

    var time = DateComponents()
    time.hour = 8
    time.minute = 0
    viewModel.addSchedule(JournalSchedule(time: time))
    viewModel.addSchedule(JournalSchedule(time: time))

    #expect(viewModel.schedules.count == 2)

    viewModel.deleteSchedule(at: IndexSet(integer: 0))
    #expect(viewModel.schedules.count == 1)
  }

  @MainActor
  @Test func togglesScheduleEnabledViaDirectBinding() {
    let defaults = UserDefaults(suiteName: "ScheduleViewModelTests.toggle")!
    defaults.removePersistentDomain(forName: "ScheduleViewModelTests.toggle")

    let viewModel = ScheduleViewModel(userDefaults: defaults)

    var time = DateComponents()
    time.hour = 8
    time.minute = 0
    let schedule = JournalSchedule(time: time, enabled: true)
    viewModel.addSchedule(schedule)

    #expect(viewModel.schedules[0].enabled == true)

    // Toggle via direct binding access (as ScheduleRow now does)
    viewModel.schedules[0].enabled.toggle()
    viewModel.saveSchedules()
    #expect(viewModel.schedules[0].enabled == false)

    viewModel.schedules[0].enabled.toggle()
    viewModel.saveSchedules()
    #expect(viewModel.schedules[0].enabled == true)
  }
}
