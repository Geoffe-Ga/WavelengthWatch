import SwiftUI

/// A single full-screen layer page in the vertical scroller.
///
/// Sized to exactly one scroll-container page via `containerRelativeFrame`
/// and laid out with an identity transform — no `scaleEffect`,
/// `rotation3DEffect`, or `offset`. The hand-stacked depth transforms that
/// used to live here (a perspective x-axis rotation over a negative-spacing
/// `LazyVStack`) re-projected the card's optical center as it animated and
/// were the source of the "leftward bump" on vertical scroll (B3 in
/// `prompts/claude-comm/spec-primary-selector-rebuild.md`). Depth returns in
/// #409 as a single offset-derived `scrollTransition` that resolves to an
/// exact identity at rest.
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
