import SwiftUI

/// Edge-aware directional chevrons for the dual-axis navigation, drawn as a
/// timed reveal: mostly hidden, **lit** on the scrolled direction, then a brief
/// **visible-unlit** settle window after a scroll and on first load. Per-
/// direction styling comes from `ScrollAffordanceVisibilityModel`; a `.hidden`
/// chevron is removed from the hierarchy entirely (not merely transparent), so
/// at rest the affordance renders nothing.
///
/// The four chevrons are anchored to the **card's center** as a symmetric
/// cross — each the same fixed `centerOffset` from the center — so they never
/// shift as the card's content width changes from phase to phase. Purely an
/// affordance hint: it never intercepts touches.
struct ScrollAffordanceView: View {
  let state: ChevronVisibilityState

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// Distance of each chevron from the card center; the four form a symmetric
  /// cross/diamond independent of the card's per-phase width. Tunable on-device.
  private static let centerOffset: CGFloat = 86
  /// Vertical nudge so the cross centers on the card, which sits slightly above
  /// the overlay's center because of the bottom page-indicator gutter.
  private static let cardCenterYAdjust: CGFloat = -10
  private static let symbolSize: CGFloat = 16

  var body: some View {
    chevronLayer
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .allowsHitTesting(false)
  }

  /// `GlassEffectContainer` is required (not just nice-to-have) for multiple
  /// glass elements to blend correctly on watchOS 26.
  @ViewBuilder
  private var chevronLayer: some View {
    if #available(watchOS 26, *) {
      GlassEffectContainer { chevrons }
    } else {
      chevrons
    }
  }

  private var chevrons: some View {
    ZStack {
      chevron("chevron.up", style: state.up, offset: CGSize(width: 0, height: -Self.centerOffset))
      chevron("chevron.down", style: state.down, offset: CGSize(width: 0, height: Self.centerOffset))
      chevron("chevron.left", style: state.left, offset: CGSize(width: -Self.centerOffset, height: 0))
      chevron("chevron.right", style: state.right, offset: CGSize(width: Self.centerOffset, height: 0))
    }
    .offset(y: Self.cardCenterYAdjust)
    // Opacity-only cross-fade (no positional motion) so reveal/hide reads
    // gently under Reduce Motion; shortened there to avoid a lingering flash.
    .animation(.easeInOut(duration: reduceMotion ? 0.1 : 0.2), value: state)
  }

  /// `lit` uses prominent glass at full strength; `visibleUnlit` uses the
  /// subtler glass at reduced opacity; `hidden` removes the view entirely.
  @ViewBuilder
  private func chevron(_ systemName: String, style: ChevronStyle, offset: CGSize) -> some View {
    if style != .hidden {
      Image(systemName: systemName)
        .font(.system(size: Self.symbolSize, weight: .bold))
        .foregroundStyle(.white)
        .padding(7)
        .wlGlass(style == .lit ? .prominent : .regular, cornerRadius: WLSpacingTokens.pillCornerRadius)
        .opacity(style == .lit ? 1.0 : 0.6)
        .offset(offset)
        .transition(.opacity)
    }
  }
}
