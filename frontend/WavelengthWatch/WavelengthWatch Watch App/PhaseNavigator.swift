import Foundation

/// Utility helpers for navigating phases within a circular TabView.
///
/// The watch interface allows swiping horizontally through the six
/// phases. To provide a seamless experience, the TabView renders an
/// extra page on either end so the user can move from the first phase
/// to the last (and vice‑versa) without interruption. These helpers
/// manage the bookkeeping for that behaviour.
enum PhaseNavigator {
  /// Returns a selection value confined to the valid range of pages.
  ///
  /// - Parameters:
  ///   - selection: The current page selection which may include the
  ///     sentinel values `0` (before the first) and `phaseCount + 1`
  ///     (after the last).
  ///   - phaseCount: Total number of phases.
  /// - Returns: A selection in the range `1...phaseCount`.
  static func adjustedSelection(_ selection: Int, phaseCount: Int) -> Int {
    if selection == 0 {
      return phaseCount
    } else if selection == phaseCount + 1 {
      return 1
    } else {
      return selection
    }
  }

  /// Maps the current page selection to a zero‑based phase index.
  ///
  /// This strips the leading/trailing sentinel pages and normalises the
  /// result so it can index directly into `Phase.allCases`.
  static func normalizedIndex(_ selection: Int, phaseCount: Int) -> Int {
    (selection - 1 + phaseCount) % phaseCount
  }
}
