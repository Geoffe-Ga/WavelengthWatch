import SwiftUI

/// Glass effect intensity levels.
///
/// Maps to watchOS 26 `GlassEffectStyle` values when available,
/// falls back to opacity-based translucency on older OS versions.
enum WLGlassIntensity: Equatable {
  /// Subtle glass for backgrounds
  case regular
  /// Prominent glass for interactive elements
  case prominent
}

/// View modifier that applies Liquid Glass styling or a fallback.
///
/// On watchOS 26+, this will call `glassEffect(_:in:)`.
/// On older versions, it applies a translucent material-like
/// background with border and shadow.
struct WLGlassModifier: ViewModifier {
  let intensity: WLGlassIntensity
  let tint: Color?
  let cornerRadius: CGFloat

  init(
    intensity: WLGlassIntensity = .regular,
    tint: Color? = nil,
    cornerRadius: CGFloat = WLSpacingTokens.cardCornerRadius
  ) {
    self.intensity = intensity
    self.tint = tint
    self.cornerRadius = cornerRadius
  }

  func body(content: Content) -> some View {
    if #available(watchOS 26, *) {
      applyGlass(to: content)
    } else {
      applyFallback(to: content)
    }
  }

  @available(watchOS 26, *)
  @ViewBuilder
  private func applyGlass(to content: Content) -> some View {
    // The watchOS 26 `Glass` type has `.regular` but no `.prominent`; the
    // closest equivalent for our "prominent / interactive" intent is
    // `.regular.interactive()`, which provides press-state feedback.
    let style: Glass = intensity == .prominent ? .regular.interactive() : .regular
    let shape = RoundedRectangle(cornerRadius: cornerRadius)
    if let tint {
      content.glassEffect(style.tint(tint), in: shape)
    } else {
      content.glassEffect(style, in: shape)
    }
  }

  @ViewBuilder
  private func applyFallback(to content: Content) -> some View {
    let fillOpacity = intensity == .prominent
      ? WLColorTokens.surfaceOpacityMedium
      : WLColorTokens.surfaceOpacityLow

    content
      .background(
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill((tint ?? Color.white).opacity(fillOpacity))
          .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
              .stroke(
                Color.white.opacity(0.15),
                lineWidth: WLSpacingTokens.cardBorderWidth
              )
          )
      )
  }
}

// MARK: - View Extension

extension View {
  /// Applies Liquid Glass styling (or fallback on older OS).
  func wlGlass(
    _ intensity: WLGlassIntensity = .regular,
    tint: Color? = nil,
    cornerRadius: CGFloat = WLSpacingTokens.cardCornerRadius
  ) -> some View {
    modifier(WLGlassModifier(
      intensity: intensity,
      tint: tint,
      cornerRadius: cornerRadius
    ))
  }
}
