import os
import SwiftUI

struct PhasePageView: View {
  let layer: CatalogLayerModel
  let phase: CatalogPhaseModel
  let color: Color
  let screenWidth: CGFloat // Stable width from parent GeometryReader

  /// TEMPORARY (#457 Phase 0): cold-start chevron diagnostics. Remove after RCA.
  private static let chevronLog = Logger(
    subsystem: "com.wavelengthwatch.watch",
    category: "chevron"
  )

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
          // TEMPORARY (#457 Phase 0): did the chevron view get created at all?
          .onAppear {
            Self.chevronLog.log("chevron onAppear layer=\(layer.id, privacy: .public) phase=\(phase.id, privacy: .public)")
          }
        }
        .padding(.bottom, 20)
      }
    }
    // TEMPORARY (#457 Phase 0): page lazily created on first scroll to this card.
    .onAppear {
      Self.chevronLog.log("page onAppear layer=\(layer.id, privacy: .public) phase=\(phase.id, privacy: .public)")
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
