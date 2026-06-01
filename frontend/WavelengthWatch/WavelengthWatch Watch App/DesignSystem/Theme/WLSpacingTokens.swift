import SwiftUI

/// Spacing and layout tokens for consistent sizing.
///
/// These supplement `UIConstants` (which holds component-specific
/// dimensions) with general-purpose spacing values.
enum WLSpacingTokens {
  // MARK: - Padding

  static let paddingXS: CGFloat = 4
  static let paddingS: CGFloat = 8
  static let paddingM: CGFloat = 12
  static let paddingL: CGFloat = 16
  static let paddingXL: CGFloat = 20

  // MARK: - Card Properties

  static let cardCornerRadius: CGFloat = 12
  static let cardCornerRadiusSmall: CGFloat = 8
  static let cardCornerRadiusCompact: CGFloat = 6
  /// Larger radius for the hero phase "crystal" card, which is visually
  /// bigger than the standard cards.
  static let cardCornerRadiusLarge: CGFloat = 16
  static let cardBorderWidth: CGFloat = 0.5
  static let cardPaddingStandard: CGFloat = 12
  static let cardPaddingCompact: CGFloat = 8
  /// Effectively-circular radius for small "pill" chips (e.g. the glass
  /// chips behind the affordance chevrons): any value past half the chip's
  /// size yields a capsule/circle.
  static let pillCornerRadius: CGFloat = 99

  // MARK: - Indicator Sizes

  static let indicatorDotSmall: CGFloat = 6
  static let indicatorDotMedium: CGFloat = 10

  // MARK: - Component Spacing

  static let listItemSpacing: CGFloat = 8
  static let sectionSpacing: CGFloat = 16
  static let cardContentSpacing: CGFloat = 4
}
