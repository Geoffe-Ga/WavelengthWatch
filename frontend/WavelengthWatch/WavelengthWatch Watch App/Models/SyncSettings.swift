import Foundation

/// Protocol for sync settings persistence.
///
/// Abstracts UserDefaults access for testing purposes.
protocol SyncSettingsPersisting {
  func bool(forKey key: String) -> Bool
  func set(_ value: Bool, forKey key: String)
  func double(forKey key: String) -> Double
  func set(_ value: Double, forKey key: String)
  func removeObject(forKey key: String)
}

extension UserDefaults: SyncSettingsPersisting {}

/// Manages user preferences for cloud sync feature.
///
/// This class provides a clean API for accessing the "Sync to Cloud" toggle
/// and related settings. All storage operations go through the persistence
/// protocol for testability.
///
/// ## Default Behavior
/// - `cloudSyncEnabled`: `false` (local-only by default, per spec)
/// - `hasCompletedInitialMigration`: `false` (triggers migration check on first launch)
///
/// ## Privacy Design
/// Cloud sync is opt-in, respecting user privacy. Journal entries are stored
/// locally by default and only synced to the backend when explicitly enabled.
final class SyncSettings {
  /// UserDefaults key for cloud sync toggle.
  static let cloudSyncEnabledKey = "com.wavelengthwatch.cloudSyncEnabled"

  /// UserDefaults key for tracking initial migration completion.
  static let initialMigrationCompletedKey = "com.wavelengthwatch.initialMigrationCompleted"

  /// UserDefaults key for tracking last sync timestamp.
  static let lastSyncTimestampKey = "com.wavelengthwatch.lastSyncTimestamp"

  private let persistence: SyncSettingsPersisting

  /// Creates a SyncSettings instance with the specified persistence layer.
  ///
  /// - Parameter persistence: Storage backend (defaults to UserDefaults.standard)
  init(persistence: SyncSettingsPersisting = UserDefaults.standard) {
    self.persistence = persistence
  }

  /// Whether cloud sync is enabled.
  ///
  /// When `true`, journal entries are synced to the backend server.
  /// When `false`, entries remain local-only.
  ///
  /// Default: `false` (privacy-first design)
  var cloudSyncEnabled: Bool {
    get { persistence.bool(forKey: Self.cloudSyncEnabledKey) }
    set { persistence.set(newValue, forKey: Self.cloudSyncEnabledKey) }
  }

  /// Whether the initial data migration has been completed.
  ///
  /// On first launch after enabling sync, existing backend entries
  /// are imported to the local database. This flag prevents duplicate imports.
  var hasCompletedInitialMigration: Bool {
    get { persistence.bool(forKey: Self.initialMigrationCompletedKey) }
    set { persistence.set(newValue, forKey: Self.initialMigrationCompletedKey) }
  }

  /// Last successful sync timestamp (stored as TimeInterval since 1970).
  ///
  /// Used for incremental sync operations to fetch only new entries.
  var lastSyncTimestamp: Date? {
    get {
      let interval = persistence.double(forKey: Self.lastSyncTimestampKey)
      return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
    }
    set {
      if let date = newValue {
        persistence.set(date.timeIntervalSince1970, forKey: Self.lastSyncTimestampKey)
      } else {
        persistence.removeObject(forKey: Self.lastSyncTimestampKey)
      }
    }
  }

  /// Resets all sync settings to defaults.
  ///
  /// Used for testing and when user wants to start fresh.
  func reset() {
    persistence.removeObject(forKey: Self.cloudSyncEnabledKey)
    persistence.removeObject(forKey: Self.initialMigrationCompletedKey)
    persistence.removeObject(forKey: Self.lastSyncTimestampKey)
  }
}
