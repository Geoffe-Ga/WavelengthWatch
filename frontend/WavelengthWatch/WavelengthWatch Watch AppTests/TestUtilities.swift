import Foundation
import SwiftUI
import Testing
import UserNotifications
@testable import WavelengthWatch_Watch_App

// Shared test mocks and utilities used across multiple test files

// MARK: - Bundle Mock

final class MockBundle: BundleProtocol, @unchecked Sendable {
  var infoPlistValues: [String: Any] = [:]
  var plistPaths: [String: String] = [:]

  func object(forInfoDictionaryKey key: String) -> Any? {
    infoPlistValues[key]
  }

  func path(forResource name: String?, ofType ext: String?) -> String? {
    guard let name else { return nil }
    return plistPaths[name]
  }
}

// MARK: - Notification Center Mock

final class MockNotificationCenter: NotificationCenterProtocol {
  var requestedPermissions: UNAuthorizationOptions?
  var permissionResult: Bool = true
  var addedRequests: [UNNotificationRequest] = []
  var removedAllPending = false
  var categoriesSet: Set<UNNotificationCategory> = []

  func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
    requestedPermissions = options
    return permissionResult
  }

  func add(_ request: UNNotificationRequest) async throws {
    addedRequests.append(request)
  }

  func removeAllPendingNotificationRequests() {
    removedAllPending = true
    addedRequests.removeAll()
  }

  func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
    categoriesSet = categories
  }
}
