import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

// MARK: - Mock Persistence

final class MockSyncSettingsPersistence: SyncSettingsPersisting {
  private var boolStorage: [String: Bool] = [:]
  private var doubleStorage: [String: Double] = [:]

  func bool(forKey key: String) -> Bool {
    boolStorage[key] ?? false
  }

  func set(_ value: Bool, forKey key: String) {
    boolStorage[key] = value
  }

  func double(forKey key: String) -> Double {
    doubleStorage[key] ?? 0.0
  }

  func set(_ value: Double, forKey key: String) {
    doubleStorage[key] = value
  }

  func removeObject(forKey key: String) {
    boolStorage.removeValue(forKey: key)
    doubleStorage.removeValue(forKey: key)
  }
}

// MARK: - SyncSettings Tests

struct SyncSettingsTests {
  @Test func cloudSyncEnabledDefaultsToFalse() {
    let persistence = MockSyncSettingsPersistence()
    let settings = SyncSettings(persistence: persistence)

    #expect(settings.cloudSyncEnabled == false)
  }

  @Test func cloudSyncEnabledCanBeSet() {
    let persistence = MockSyncSettingsPersistence()
    let settings = SyncSettings(persistence: persistence)

    settings.cloudSyncEnabled = true

    #expect(settings.cloudSyncEnabled == true)
  }

  @Test func cloudSyncEnabledPersists() {
    let persistence = MockSyncSettingsPersistence()
    let settings1 = SyncSettings(persistence: persistence)

    settings1.cloudSyncEnabled = true

    let settings2 = SyncSettings(persistence: persistence)
    #expect(settings2.cloudSyncEnabled == true)
  }

  @Test func hasCompletedInitialMigrationDefaultsToFalse() {
    let persistence = MockSyncSettingsPersistence()
    let settings = SyncSettings(persistence: persistence)

    #expect(settings.hasCompletedInitialMigration == false)
  }

  @Test func hasCompletedInitialMigrationCanBeSet() {
    let persistence = MockSyncSettingsPersistence()
    let settings = SyncSettings(persistence: persistence)

    settings.hasCompletedInitialMigration = true

    #expect(settings.hasCompletedInitialMigration == true)
  }

  @Test func resetClearsAllSettings() {
    let persistence = MockSyncSettingsPersistence()
    let settings = SyncSettings(persistence: persistence)

    settings.cloudSyncEnabled = true
    settings.hasCompletedInitialMigration = true

    settings.reset()

    #expect(settings.cloudSyncEnabled == false)
    #expect(settings.hasCompletedInitialMigration == false)
  }

  @Test func lastSyncTimestampDefaultsToNil() {
    let defaults = UserDefaults(suiteName: "SyncSettingsTests.lastSyncTimestampDefaultsToNil")!
    defaults.removePersistentDomain(forName: "SyncSettingsTests.lastSyncTimestampDefaultsToNil")
    let settings = SyncSettings(persistence: defaults)

    #expect(settings.lastSyncTimestamp == nil)
  }

  @Test func lastSyncTimestampCanBeSet() {
    let defaults = UserDefaults(suiteName: "SyncSettingsTests.lastSyncTimestampCanBeSet")!
    defaults.removePersistentDomain(forName: "SyncSettingsTests.lastSyncTimestampCanBeSet")
    let settings = SyncSettings(persistence: defaults)
    let now = Date()

    settings.lastSyncTimestamp = now

    // Allow 1 second tolerance for floating point conversion
    if let timestamp = settings.lastSyncTimestamp {
      #expect(abs(timestamp.timeIntervalSince1970 - now.timeIntervalSince1970) < 1)
    } else {
      Issue.record("Expected lastSyncTimestamp to be set")
    }
  }

  @Test func lastSyncTimestampCanBeCleared() {
    let defaults = UserDefaults(suiteName: "SyncSettingsTests.lastSyncTimestampCanBeCleared")!
    defaults.removePersistentDomain(forName: "SyncSettingsTests.lastSyncTimestampCanBeCleared")
    let settings = SyncSettings(persistence: defaults)

    settings.lastSyncTimestamp = Date()
    settings.lastSyncTimestamp = nil

    #expect(settings.lastSyncTimestamp == nil)
  }

  @Test func hasCompletedOnboardingDefaultsToFalse() {
    let persistence = MockSyncSettingsPersistence()
    let settings = SyncSettings(persistence: persistence)

    #expect(settings.hasCompletedOnboarding == false)
  }

  @Test func hasCompletedOnboardingCanBeSet() {
    let persistence = MockSyncSettingsPersistence()
    let settings = SyncSettings(persistence: persistence)

    settings.hasCompletedOnboarding = true

    #expect(settings.hasCompletedOnboarding == true)
  }

  @Test func hasCompletedOnboardingPersists() {
    let persistence = MockSyncSettingsPersistence()
    let settings1 = SyncSettings(persistence: persistence)

    settings1.hasCompletedOnboarding = true

    let settings2 = SyncSettings(persistence: persistence)
    #expect(settings2.hasCompletedOnboarding == true)
  }

  @Test func resetClearsOnboardingFlag() {
    let persistence = MockSyncSettingsPersistence()
    let settings = SyncSettings(persistence: persistence)

    settings.hasCompletedOnboarding = true
    settings.reset()

    #expect(settings.hasCompletedOnboarding == false)
  }
}

// MARK: - SyncSettingsViewModel Tests

@MainActor
struct SyncSettingsViewModelTests {
  @Test func initializesWithSyncSettingsValue() {
    let persistence = MockSyncSettingsPersistence()
    let settings = SyncSettings(persistence: persistence)
    settings.cloudSyncEnabled = true

    let viewModel = SyncSettingsViewModel(syncSettings: settings)

    #expect(viewModel.cloudSyncEnabled == true)
  }

  @Test func updatingSyncSettingsUpdatesViewModel() {
    let persistence = MockSyncSettingsPersistence()
    let settings = SyncSettings(persistence: persistence)
    let viewModel = SyncSettingsViewModel(syncSettings: settings)

    #expect(viewModel.cloudSyncEnabled == false)

    viewModel.cloudSyncEnabled = true

    #expect(viewModel.cloudSyncEnabled == true)
    #expect(settings.cloudSyncEnabled == true)
  }

  @Test func resetClearsSyncSettings() {
    let persistence = MockSyncSettingsPersistence()
    let settings = SyncSettings(persistence: persistence)
    let viewModel = SyncSettingsViewModel(syncSettings: settings)

    viewModel.cloudSyncEnabled = true
    viewModel.reset()

    #expect(viewModel.cloudSyncEnabled == false)
    #expect(settings.cloudSyncEnabled == false)
  }
}
