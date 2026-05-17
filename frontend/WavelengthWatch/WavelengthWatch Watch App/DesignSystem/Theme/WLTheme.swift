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
  /// The build now targets the watchOS 26 SDK (via Xcode 26), so the
  /// `if #available(watchOS 26, *)` gate resolves to real API calls
  /// at runtime on supported hardware and to fallbacks elsewhere.
  static var isGlassAvailable: Bool {
    if #available(watchOS 26, *) {
      return true
    }
    return false
  }
}
