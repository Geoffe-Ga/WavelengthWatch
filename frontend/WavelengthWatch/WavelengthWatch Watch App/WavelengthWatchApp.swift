//
//  WavelengthWatchApp.swift
//  WavelengthWatch Watch App
//
//  Created by Geoff Gallinger on 9/10/25.
//

import SwiftUI
import UserNotifications

@main
struct WavelengthWatch_Watch_AppApp: App {
  @StateObject private var notificationDelegate = NotificationDelegate()

  init() {
    configureNotificationCategories()
  }

  private func configureNotificationCategories() {
    let logEmotionsAction = UNNotificationAction(
      identifier: "LOG_EMOTIONS",
      title: "Log Emotions",
      options: [.foreground]
    )

    let category = UNNotificationCategory(
      identifier: "JOURNAL_CHECKIN",
      actions: [logEmotionsAction],
      intentIdentifiers: [],
      options: []
    )

    UNUserNotificationCenter.current().setNotificationCategories([category])
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(notificationDelegate)
    }
  }
}

// MARK: - Notification Handling

struct ScheduledNotification: Equatable {
  let scheduleId: String
  let initiatedBy: InitiatedBy
}

@MainActor
final class NotificationDelegate: ObservableObject {
  @Published var scheduledNotificationReceived: ScheduledNotification?

  func handleNotificationResponse(_ response: UNNotificationResponse) {
    let userInfo = response.notification.request.content.userInfo

    if let scheduleId = userInfo["scheduleId"] as? String,
       let initiatedByString = userInfo["initiatedBy"] as? String,
       initiatedByString == "scheduled"
    {
      scheduledNotificationReceived = ScheduledNotification(
        scheduleId: scheduleId,
        initiatedBy: .scheduled
      )
    }
  }

  func clearNotificationState() {
    scheduledNotificationReceived = nil
  }
}

// Shim to bridge UNUserNotificationCenterDelegate to our NotificationDelegate
final class NotificationDelegateShim: NSObject, UNUserNotificationCenterDelegate {
  static let shared = NotificationDelegateShim()
  weak var delegate: NotificationDelegate?

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    Task { @MainActor in
      delegate?.handleNotificationResponse(response)
      completionHandler()
    }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }
}
