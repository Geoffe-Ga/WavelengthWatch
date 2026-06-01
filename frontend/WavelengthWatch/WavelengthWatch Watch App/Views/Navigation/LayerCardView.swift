import SwiftUI

/// A single full-screen layer page in the vertical scroller.
///
/// Sized to exactly one scroll-container page via `containerRelativeFrame`
/// and laid out with an identity transform — no `scaleEffect`,
/// `rotation3DEffect`, or `offset`. The hand-stacked depth transforms that
/// used to live here (a perspective x-axis rotation over a negative-spacing
/// `LazyVStack`) re-projected the card's optical center as it animated and
/// were the source of the "leftward bump" on vertical scroll (B3 in
/// `prompts/claude-comm/spec-primary-selector-rebuild.md`). Depth is now a
/// single offset-derived `scrollTransition` (#409) that resolves to an exact
/// identity at the resting/centered page, so it can never shift the card.
struct LayerCardView: View {
  let layer: CatalogLayerModel
  let phaseCount: Int
  @Binding var selection: Int
  let screenWidth: CGFloat // Stable width from parent GeometryReader

  var body: some View {
    LayerView(
      layer: layer,
      phaseCount: phaseCount,
      selection: $selection,
      screenWidth: screenWidth
    )
    .containerRelativeFrame([.horizontal, .vertical])
    // Offset-derived depth (#409, SPEC §4.1): a single center-anchored
    // scale + opacity + blur the scroll system drives from page geometry.
    // At `phase.isIdentity` (the resting/centered page) every modifier is
    // an exact identity (scale 1, opacity 1, blur 0), so the resting card's
    // center cannot shift — the structural guarantee against B3. Started
    // flat (no tilt) per SPEC §11 Q2; `scaleEffect`'s default `.center`
    // anchor keeps the effect symmetric, never translating horizontally.
    .scrollTransition(.interactive, axis: .vertical) { content, phase in
      content
        .opacity(phase.isIdentity ? 1 : 0.35)
        .scaleEffect(phase.isIdentity ? 1 : 0.95)
        .blur(radius: phase.isIdentity ? 0 : 1)
    }
  }
}
