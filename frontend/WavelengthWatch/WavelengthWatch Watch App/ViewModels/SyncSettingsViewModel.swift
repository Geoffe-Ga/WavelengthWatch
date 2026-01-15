import Foundation

/// View model for sync settings screen.
///
/// Provides SwiftUI-friendly interface to SyncSettings and handles
/// toggle state changes. Uses @Published for reactive UI updates.
///
/// ## Usage
/// ```swift
/// @StateObject private var viewModel = SyncSettingsViewModel()
///
/// Toggle("Sync to Cloud", isOn: $viewModel.cloudSyncEnabled)
/// ```
@MainActor
final class SyncSettingsViewModel: ObservableObject {
  @Published var cloudSyncEnabled: Bool {
    didSet {
      syncSettings.cloudSyncEnabled = cloudSyncEnabled
    }
  }

  /// Whether the user has completed onboarding.
  ///
  /// Published to trigger UI updates when onboarding completes.
  /// Private setter ensures only the view model can mark onboarding complete.
  @Published private(set) var hasCompletedOnboarding: Bool

  private let syncSettings: SyncSettings

  /// Creates a view model with the specified sync settings.
  ///
  /// - Parameter syncSettings: Settings storage (defaults to shared instance)
  init(syncSettings: SyncSettings = SyncSettings()) {
    self.syncSettings = syncSettings
    self.cloudSyncEnabled = syncSettings.cloudSyncEnabled
    self.hasCompletedOnboarding = syncSettings.hasCompletedOnboarding
  }

  /// Marks onboarding as complete.
  ///
  /// Called when user finishes the first-run onboarding flow.
  func completeOnboarding() {
    syncSettings.hasCompletedOnboarding = true
    hasCompletedOnboarding = true
  }

  /// Resets all sync settings to defaults.
  ///
  /// Used for testing or when user wants to start fresh.
  /// Sets cloudSyncEnabled to false and clears migration flags.
  func reset() {
    syncSettings.reset()
    cloudSyncEnabled = false
    hasCompletedOnboarding = false
  }
}
