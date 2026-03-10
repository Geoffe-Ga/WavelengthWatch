import SwiftUI

enum UIConstants {
  static let menuButtonSize: CGFloat = 20

  /// Reference screen width for scaling (Apple Watch Series 9 45mm = 198pt)
  static let referenceScreenWidth: CGFloat = 198

  /// Calculate scale factor based on actual screen width
  static func scaleFactor(for width: CGFloat) -> CGFloat {
    width / referenceScreenWidth
  }

  // Phase card dimensions (at reference size)
  static let phaseOrbSize: CGFloat = 160
  static let phaseAccentOuterWidth: CGFloat = 60
  static let phaseAccentOuterHeight: CGFloat = 3
  static let phaseAccentInnerWidth: CGFloat = 50
  static let phaseAccentInnerHeight: CGFloat = 2

  /// Phase card minimum width - ensures cards don't get too narrow
  static let phaseCardMinWidth: CGFloat = 145

  /// Analytics view dimensions
  static let analyticsIconSize: CGFloat = 48
}
