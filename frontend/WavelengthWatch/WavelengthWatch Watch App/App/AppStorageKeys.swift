import Foundation

/// Single source of truth for `UserDefaults` / `@AppStorage` keys used
/// to persist root navigation state across launches. Centralizing them
/// here keeps the two sites that read the same value (the
/// `@AppStorage(...)` declaration in `ContentView` and the raw
/// `UserDefaults.standard.integer(forKey:)` calls in
/// `ContentViewDependencies`) from drifting if a key is ever renamed.
enum AppStorageKeys {
  /// Persisted layer index (full-array, not filtered) for the dual-axis
  /// navigation.
  static let selectedLayerIndex = "selectedLayerIndex"

  /// Persisted phase index (zero-indexed canonical value; the SwiftUI
  /// tab model adds a +1 offset internally for its infinite-scroll
  /// behavior).
  static let selectedPhaseIndex = "selectedPhaseIndex"
}
