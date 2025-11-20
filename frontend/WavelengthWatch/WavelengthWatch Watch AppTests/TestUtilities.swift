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

// MARK: - Catalog Cache Mock

/// In-memory cache implementation for tests - avoids file I/O overhead
final class InMemoryCatalogCacheMock: CatalogCachePersisting {
  var storedData: Data?
  var removeCount = 0

  func loadCatalogData() throws -> Data? {
    storedData
  }

  func writeCatalogData(_ data: Data) throws {
    storedData = data
  }

  func removeCatalogData() throws {
    storedData = nil
    removeCount += 1
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
