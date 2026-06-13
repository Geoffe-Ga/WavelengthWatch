import SwiftUI

/// A single phase page: the crystal card on its layer-tinted background.
///
/// The navigation chevron used to live here, one per page. It was bottom-
/// anchored inside a card that `.ignoresSafeArea` could inflate taller than the
/// viewport, which pushed the chevron below the visible area — and, on lazily
/// realized pages, left it intermittently uncomposited (#457). It now lives as
/// a single viewport-pinned overlay in `LayerScrollView`, so this view is
/// purely the (non-interactive) card.
struct PhasePageView: View {
  let layer: CatalogLayerModel
  let phase: CatalogPhaseModel
  let color: Color
  let screenWidth: CGFloat // Stable width from parent GeometryReader

  var body: some View {
    // Use screenWidth from parent to avoid nested GeometryReader race conditions
    // during LayerFilterMode transitions (fixes #119, #158, #165)
    let scale = UIConstants.scaleFactor(for: screenWidth)

    VStack(spacing: 0) {
      // Top gutter for vertical scroll
      Spacer()

      PhaseCrystalCard(layer: layer, phase: phase, color: color, scale: scale)

      Spacer()
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      // Bottom gutter for page indicators
      Spacer()
        .frame(height: 16)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      LinearGradient(
        gradient: Gradient(colors: [
          Color.black.opacity(0.98),
          Color.black.opacity(0.9),
          Color.black,
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .overlay(
        RadialGradient(
          gradient: Gradient(colors: [
            color.opacity(0.18),
            Color.clear,
          ]),
          center: .center,
          startRadius: 20,
          endRadius: screenWidth * 0.9
        )
      )
    )
    .ignoresSafeArea(.all)
  }
}
