import SwiftUI

/// Card background that uses a translucent fill normally but a solid opaque
/// surface when "Reduce Transparency" is enabled. Reads the environment itself
/// so call sites don't each need `@Environment(\.accessibilityReduceTransparency)`.
///
/// The fill is any `ShapeStyle` — a flat `Color` or a `LinearGradient` — and is
/// swapped for `WLColorTokens.opaqueSurface` under Reduce Transparency so the
/// surface stays legible. An optional `stroke` border is preserved in both
/// modes, since the border provides edge definition independent of translucency.
struct WLCardSurface: ViewModifier {
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  let translucentFill: AnyShapeStyle
  let cornerRadius: CGFloat
  let stroke: Color?
  let strokeWidth: CGFloat

  func body(content: Content) -> some View {
    content.background(background)
  }

  private var background: some View {
    RoundedRectangle(cornerRadius: cornerRadius)
      .fill(reduceTransparency ? AnyShapeStyle(WLColorTokens.opaqueSurface) : translucentFill)
      .overlay(strokeOverlay)
  }

  @ViewBuilder
  private var strokeOverlay: some View {
    if let stroke {
      RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(stroke, lineWidth: strokeWidth)
    }
  }
}

extension View {
  /// Applies a rounded card background that degrades from `translucentFill` to
  /// a solid opaque surface under Reduce Transparency. Pass a `Color` or a
  /// `LinearGradient` as the fill, and an optional `stroke` border.
  func wlCardSurface(
    _ translucentFill: some ShapeStyle,
    cornerRadius: CGFloat,
    stroke: Color? = nil,
    strokeWidth: CGFloat = 0.5
  ) -> some View {
    modifier(WLCardSurface(
      translucentFill: AnyShapeStyle(translucentFill),
      cornerRadius: cornerRadius,
      stroke: stroke,
      strokeWidth: strokeWidth
    ))
  }
}
