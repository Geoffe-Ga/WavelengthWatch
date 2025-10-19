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
    UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(notificationDelegate)
    }
  }
}

// MARK: - Notification Handling

@MainActor
final class NotificationDelegate: ObservableObject {
  @Published var scheduledNotificationReceived: (scheduleId: String, initiatedBy: InitiatedBy)?

  func handleNotificationResponse(_ response: UNNotificationResponse) {
    let userInfo = response.notification.request.content.userInfo

    if let scheduleId = userInfo["scheduleId"] as? String,
       let initiatedByString = userInfo["initiatedBy"] as? String,
       initiatedByString == "scheduled"
    {
      scheduledNotificationReceived = (scheduleId, .scheduled)
    }
  }

  func clearNotificationState() {
    scheduledNotificationReceived = nil
  }
}

// Shim to bridge UNUserNotificationCenterDelegate to our NotificationDelegate
final class NotificationDelegateShim: NSObject, UNUserNotificationCenterDelegate {
  static let shared = NotificationDelegateShim()

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    Task { @MainActor in
      // In a real implementation, we'd forward this to NotificationDelegate
      // For now, this satisfies the delegate requirement
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
