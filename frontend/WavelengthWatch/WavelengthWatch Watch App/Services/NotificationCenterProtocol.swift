import Foundation
import UserNotifications

protocol NotificationCenterProtocol {
  func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
  func add(_ request: UNNotificationRequest) async throws
  func removeAllPendingNotificationRequests()
  func setNotificationCategories(_ categories: Set<UNNotificationCategory>)
}

extension UNUserNotificationCenter: NotificationCenterProtocol {}
