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
    // The vertical-scroll depth effect now lives on `PhaseCrystalCard` (in
    // `PhasePageView`) rather than the whole page, so the bottom-right logging
    // chevron and the page background are never dimmed by it — the chevron
    // stays visible on first load even before the centered card's scroll phase
    // resolves to identity (#440).
  }
}
