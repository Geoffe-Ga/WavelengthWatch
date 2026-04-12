import SwiftUI

/// Color tokens for the WavelengthWatch design system.
///
/// All layer colors, semantic colors, and surface opacities are
/// defined here. Views should reference these tokens instead of
/// constructing colors inline.
enum WLColorTokens {
  // MARK: - Layer Colors (Spiral Dynamics)

  /// Returns the SwiftUI Color for a named layer, delegating to Color(stage:).
  static func layer(_ name: String) -> Color {
    Color(stage: name)
  }

  static let beige: Color = .brown
  static let purple: Color = .purple
  static let red: Color = .red
  static let blue: Color = .blue
  static let orange: Color = .orange
  static let green: Color = .green
  static let yellow: Color = .yellow
  static let teal: Color = .teal
  static let ultraviolet: Color = .indigo
  static let clearLight: Color = .white
  static let strategies: Color = .gray

  // MARK: - Semantic Surface Colors

  /// Card background fill (fallback for pre-Glass)
  static let cardFill = Color.secondary.opacity(0.15)

  /// Card background fill with layer tint
  static func cardFill(tinted color: Color) -> Color {
    color.opacity(surfaceOpacitySubtle)
  }

  /// Elevated card fill (for review sheets, etc.)
  static let elevatedCardFill = Color.secondary.opacity(0.1)

  // MARK: - Text Colors

  static let primaryText: Color = .white
  static let secondaryText = Color.white.opacity(0.7)
  static let tertiaryText = Color.white.opacity(0.5)
  static let labelText: Color = .secondary

  // MARK: - Surface Opacities

  static let surfaceOpacityHigh: Double = 0.6
  static let surfaceOpacityMedium: Double = 0.3
  static let surfaceOpacityLow: Double = 0.1
  static let surfaceOpacitySubtle: Double = 0.08

  // MARK: - Background Gradients

  /// Standard dark page background gradient
  static func pageBackground() -> LinearGradient {
    LinearGradient(
      gradient: Gradient(colors: [Color.black, Color.black.opacity(0.8)]),
      startPoint: .top,
      endPoint: .bottom
    )
  }

  /// Layer-tinted card gradient
  static func cardGradient(_ color: Color) -> LinearGradient {
    LinearGradient(
      gradient: Gradient(colors: [
        color.opacity(surfaceOpacityMedium),
        color.opacity(surfaceOpacityLow),
      ]),
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}
