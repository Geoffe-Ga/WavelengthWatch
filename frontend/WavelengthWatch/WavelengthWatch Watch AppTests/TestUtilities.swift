import Foundation
import SwiftUI
import Testing
import UserNotifications
@testable import WavelengthWatch_Watch_App

// Shared test mocks and utilities used across multiple test files

// MARK: - Bundle Mock

/// Mock Bundle for testing AppConfiguration
/// Note: This mock is only used synchronously within single-threaded tests,
/// so mutable state is safe. Not marked Sendable to avoid false safety claims.
final class MockBundle: BundleProtocol {
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

/// Mock implementation of UNUserNotificationCenter for testing
/// Eliminates system IPC overhead (~100-500ms per test) and prevents state pollution
/// between test runs. All notification tests MUST use this mock instead of the real
/// notification center to ensure fast, isolated, deterministic tests.
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

  /// Verifies that this mock was actually used (no system calls were made)
  /// Call this in tests to ensure the mock is properly injected
  func assertWasUsed() {
    // If this mock has any recorded interactions, it was successfully used
    let wasUsed = requestedPermissions != nil ||
      !addedRequests.isEmpty ||
      removedAllPending ||
      !categoriesSet.isEmpty
    assert(wasUsed, "MockNotificationCenter was not used - check that it's properly injected")
  }
}
