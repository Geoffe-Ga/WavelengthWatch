import SwiftUI

/// Central namespace for the WavelengthWatch design system.
///
/// Provides access to color, typography, and spacing tokens,
/// plus the `isGlassAvailable` flag used by modifiers to
/// branch between Liquid Glass and fallback styling.
enum WLTheme {
  typealias Colors = WLColorTokens
  typealias Typography = WLTypographyTokens
  typealias Spacing = WLSpacingTokens

  /// Whether Liquid Glass APIs are available at runtime.
  ///
  /// Checks watchOS 26 availability. On older versions, all Glass
  /// modifiers degrade to fallback styling automatically.
  ///
  /// - Note: Until Xcode 18 ships with the watchOS 26 SDK, this
  ///   always returns `false`. Remove the early return when the
  ///   SDK is available.
  static var isGlassAvailable: Bool {
    // TODO: watchOS 26 — Remove early return when Xcode 18 SDK ships
    false
  }
}
