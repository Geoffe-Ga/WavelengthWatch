import SwiftUI

/// Card background that uses a translucent fill normally but a solid opaque
/// surface when "Reduce Transparency" is enabled. Reads the environment itself
/// so call sites don't each need `@Environment(\.accessibilityReduceTransparency)`.
private struct WLCardSurface: ViewModifier {
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  let translucentFill: Color
  let cornerRadius: CGFloat

  func body(content: Content) -> some View {
    content.background(
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(reduceTransparency ? WLColorTokens.opaqueSurface : translucentFill)
    )
  }
}

extension View {
  /// Applies a rounded card background that degrades from `translucentFill` to
  /// a solid opaque surface under Reduce Transparency.
  func wlCardSurface(_ translucentFill: Color, cornerRadius: CGFloat) -> some View {
    modifier(WLCardSurface(translucentFill: translucentFill, cornerRadius: cornerRadius))
  }
}
