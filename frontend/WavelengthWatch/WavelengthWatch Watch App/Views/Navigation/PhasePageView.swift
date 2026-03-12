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

        // Mystical floating crystal interface
        ZStack {
          // Mystical background orb with layer color
          Circle()
            .fill(
              RadialGradient(
                gradient: Gradient(colors: [
                  color.opacity(0.3),
                  color.opacity(0.1),
                  Color.clear,
                ]),
                center: .center,
                startRadius: 20 * scale,
                endRadius: 80 * scale
              )
            )
            .frame(
              width: UIConstants.phaseOrbSize * scale,
              height: UIConstants.phaseOrbSize * scale
            )
            .blur(radius: 1 * scale)

          // Main content container - floating card
          VStack(spacing: 12 * scale) {
            // Layer context - minimal and elegant
            VStack(spacing: 4 * scale) {
              Text(layer.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
                .tracking(1.5)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

              Text(layer.subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }

            // Hero phase name - fixed font size for uniform appearance
            // Uses .title3 which fits "Bottoming Out" on all watch sizes without truncation
            Text(phase.name)
              .font(.title3)
              .fontWeight(.medium)
              .foregroundColor(.white)
              .multilineTextAlignment(.center)
              .shadow(color: .black.opacity(0.3), radius: 2 * scale, x: 0, y: 1)
              .padding(.horizontal, 8 * scale)

            // Mystical accent - geometric crystal element
            ZStack {
              // Outer glow
              Capsule()
                .fill(color.opacity(0.3))
                .frame(
                  width: UIConstants.phaseAccentOuterWidth * scale,
                  height: UIConstants.phaseAccentOuterHeight * scale
                )
                .blur(radius: 3 * scale)

              // Inner crystal line
              Capsule()
                .fill(
                  LinearGradient(
                    gradient: Gradient(colors: [
                      color.opacity(0.6),
                      color,
                      color.opacity(0.6),
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
                .frame(
                  width: UIConstants.phaseAccentInnerWidth * scale,
                  height: UIConstants.phaseAccentInnerHeight * scale
                )
                .shadow(color: color.opacity(0.8), radius: 4 * scale)
            }
          }
          .padding(.horizontal, 20 * scale)
          .padding(.vertical, 16)
          .frame(minWidth: UIConstants.phaseCardMinWidth * scale)
          .background(
            // Floating card background
            RoundedRectangle(cornerRadius: 16)
              .fill(
                LinearGradient(
                  gradient: Gradient(colors: [
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.6),
                  ]),
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .overlay(
                RoundedRectangle(cornerRadius: 16)
                  .stroke(
                    LinearGradient(
                      gradient: Gradient(colors: [
                        color.opacity(0.3),
                        Color.white.opacity(0.1),
                        color.opacity(0.2),
                      ]),
                      startPoint: .topLeading,
                      endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                  )
              )
              .shadow(color: color.opacity(0.2), radius: 8)
              .shadow(color: .black.opacity(0.3), radius: 4)
          )
        }
        .frame(maxWidth: .infinity)

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
