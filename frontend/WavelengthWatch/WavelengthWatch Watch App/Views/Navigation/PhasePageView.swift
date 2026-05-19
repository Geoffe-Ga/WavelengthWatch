import SwiftUI

struct PhasePageView: View {
  let layer: CatalogLayerModel
  let phase: CatalogPhaseModel
  let color: Color
  let screenWidth: CGFloat // Stable width from parent GeometryReader

  var body: some View {
    // Use screenWidth from parent to avoid nested GeometryReader race conditions
    // during LayerFilterMode transitions (fixes #119, #158, #165)
    let scale = UIConstants.scaleFactor(for: screenWidth)

    ZStack {
      // Background - non-tappable
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

      // Small tappable navigation button - bottom right
      VStack {
        Spacer()
        HStack {
          Spacer()
          NavigationLink(value: navigationDestination) {
            Image(systemName: "chevron.right.circle.fill")
              .foregroundColor(.white.opacity(0.8))
              .font(.title2)
              .background(
                Circle()
                  .fill(color.opacity(0.3))
                  .frame(width: 32, height: 32)
              )
          }
          .buttonStyle(.plain)
          .padding(.trailing, 12)
        }
        .padding(.bottom, 20)
      }
    }
  }

  /// Value-based navigation destination for NavigationPath tracking
  private var navigationDestination: DetailDestination {
    if layer.id == 0 {
      .strategy(phase: phase, colorName: layer.color)
    } else {
      .curriculum(layer: layer, phase: phase, colorName: layer.color)
    }
  }
}
