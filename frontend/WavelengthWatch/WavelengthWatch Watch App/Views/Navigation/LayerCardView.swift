import SwiftUI

/// A single full-screen layer page in the vertical scroller.
///
/// Sized to exactly one scroll-container page via `containerRelativeFrame`
/// and laid out with an identity transform — no `scaleEffect`,
/// `rotation3DEffect`, or `offset`. The hand-stacked depth transforms that
/// used to live here (a perspective x-axis rotation over a negative-spacing
/// `LazyVStack`) re-projected the card's optical center as it animated and
/// were the source of the "leftward bump" on vertical scroll (B3 in
/// `prompts/claude-comm/spec-primary-selector-rebuild.md`). They are gone, and
/// so is the later `scrollTransition` depth effect (#409/#440) — its sharp-at-
/// rest state never resolved reliably and left cards permanently blurred (#449).
/// Cards are now always crisp; the no-bump guarantee holds simply by having no
/// vertical transform at all.
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
  }
}
