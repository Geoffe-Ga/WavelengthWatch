import Foundation
import UserNotifications

protocol NotificationSchedulerProtocol {
  func requestPermission() async throws -> Bool
  func scheduleNotifications(for schedules: [JournalSchedule]) async throws
  func cancelAllNotifications()
}

final class NotificationScheduler: NotificationSchedulerProtocol {
  private let notificationCenter: NotificationCenterProtocol
  private static let journalCategoryIdentifier = "JOURNAL_CHECKIN"
  private static let logEmotionsActionIdentifier = "LOG_EMOTIONS"

  init(notificationCenter: NotificationCenterProtocol = UNUserNotificationCenter.current()) {
    self.notificationCenter = notificationCenter
  }

  private func configureNotificationCategories() {
    // Create "Log Emotions" action
    let logEmotionsAction = UNNotificationAction(
      identifier: Self.logEmotionsActionIdentifier,
      title: "Log Emotions",
      options: [.foreground]
    )

    // Create category with actions
    let category = UNNotificationCategory(
      identifier: Self.journalCategoryIdentifier,
      actions: [logEmotionsAction],
      intentIdentifiers: [],
      options: []
    )

    notificationCenter.setNotificationCategories([category])
  }

  func requestPermission() async throws -> Bool {
    // Configure categories before requesting permission
    configureNotificationCategories()
    return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
  }

  func scheduleNotifications(for schedules: [JournalSchedule]) async throws {
    // Ensure categories are configured
    configureNotificationCategories()

    // Remove all existing notifications
    notificationCenter.removeAllPendingNotificationRequests()

    // Schedule new notifications for each enabled schedule
    for schedule in schedules where schedule.enabled && schedule.isValid {
      try await scheduleNotification(for: schedule)
    }
  }

  func cancelAllNotifications() {
    notificationCenter.removeAllPendingNotificationRequests()
  }

  // MARK: - Private

  private func scheduleNotification(for schedule: JournalSchedule) async throws {
    guard let hour = schedule.time.hour,
          let minute = schedule.time.minute
    else {
      return
    }

    let content = UNMutableNotificationContent()
    content.title = "Journal Check-In"
    content.body = "How are you feeling right now?"
    content.sound = .default
    content.categoryIdentifier = Self.journalCategoryIdentifier
    content.userInfo = [
      "scheduleId": schedule.id.uuidString,
      "initiatedBy": "scheduled",
    ]

    // Create a notification for each selected day
    for day in schedule.repeatDays.sorted() {
      var dateComponents = DateComponents()
      dateComponents.hour = hour
      dateComponents.minute = minute
      dateComponents.weekday = day + 1 // UNCalendar uses 1-7 for Sun-Sat

      let trigger = UNCalendarNotificationTrigger(
        dateMatching: dateComponents,
        repeats: true
      )

      let identifier = "\(schedule.id.uuidString)-day\(day)"
      let request = UNNotificationRequest(
        identifier: identifier,
        content: content,
        trigger: trigger
      )

      try await notificationCenter.add(request)
    }
  }
}
