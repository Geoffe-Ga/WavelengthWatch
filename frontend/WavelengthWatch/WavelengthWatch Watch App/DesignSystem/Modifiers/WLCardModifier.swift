import SwiftUI

/// Card style modifier for content containers.
///
/// Applies consistent padding, corner radius, glass background,
/// and optional layer-color tinting. Replaces the inline
/// `.background(RoundedRectangle(...).fill(...))` pattern.
struct WLCardModifier: ViewModifier {
  let tint: Color?
  let isCompact: Bool

  init(tint: Color? = nil, isCompact: Bool = false) {
    self.tint = tint
    self.isCompact = isCompact
  }

  private var cornerRadius: CGFloat {
    isCompact
      ? WLSpacingTokens.cardCornerRadiusCompact
      : WLSpacingTokens.cardCornerRadius
  }

  private var padding: CGFloat {
    isCompact
      ? WLSpacingTokens.cardPaddingCompact
      : WLSpacingTokens.cardPaddingStandard
  }

  func body(content: Content) -> some View {
    content
      .padding(padding)
      .wlGlass(
        .regular,
        tint: tint,
        cornerRadius: cornerRadius
      )
  }
}

// MARK: - View Extension

extension View {
  /// Applies card styling with optional tint color.
  func wlCard(tint: Color? = nil, compact: Bool = false) -> some View {
    modifier(WLCardModifier(tint: tint, isCompact: compact))
  }
}
