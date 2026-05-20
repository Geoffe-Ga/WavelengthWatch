import SwiftUI

/// The mystical floating card at the center of a phase page — the orb,
/// layer context (title + subtitle), the hero phase name, and the
/// horizontal accent capsule. Pure data-driven view; no state of its
/// own. All sizing is driven by the `scale` value derived from the
/// parent's stable `screenWidth` (avoids nested `GeometryReader` races,
/// per #119 / #158 / #165).
struct PhaseCrystalCard: View {
  let layer: CatalogLayerModel
  let phase: CatalogPhaseModel
  let color: Color
  let scale: CGFloat

  var body: some View {
    ZStack {
      backgroundOrb
      cardContent
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - Subviews

  private var backgroundOrb: some View {
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
  }

  private var cardContent: some View {
    VStack(spacing: 12 * scale) {
      layerContext
      phaseHero
      crystalAccent
    }
    .padding(.horizontal, 20 * scale)
    // Vertical rhythm stays fixed: the card's content (caption + title3 + accent) is
    // already a fixed visual height, so scaling the pad only pushes the orb out without
    // improving readability on larger watches.
    .padding(.vertical, 16)
    .frame(minWidth: UIConstants.phaseCardMinWidth * scale)
    .background(cardBackground)
  }

  private var layerContext: some View {
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
  }

  /// Hero phase name — fixed `.title3` fits "Bottoming Out" on all
  /// watch sizes without truncation.
  private var phaseHero: some View {
    Text(phase.name)
      .font(.title3)
      .fontWeight(.medium)
      .foregroundColor(.white)
      .multilineTextAlignment(.center)
      .shadow(color: .black.opacity(0.3), radius: 2 * scale, x: 0, y: 1)
      .padding(.horizontal, 8 * scale)
  }

  /// Geometric crystal accent — outer glow capsule + inner gradient line.
  private var crystalAccent: some View {
    ZStack {
      Capsule()
        .fill(color.opacity(0.3))
        .frame(
          width: UIConstants.phaseAccentOuterWidth * scale,
          height: UIConstants.phaseAccentOuterHeight * scale
        )
        .blur(radius: 3 * scale)

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

  private var cardBackground: some View {
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
  }
}

#Preview("Red layer, Peaking phase") {
  let phase = CatalogPhaseModel(
    id: 2,
    name: "Peaking",
    medicinal: [],
    toxic: [],
    strategies: []
  )
  let layer = CatalogLayerModel(
    id: 4,
    color: "Red",
    title: "Red",
    subtitle: "Power",
    phases: [phase]
  )
  return PhaseCrystalCard(layer: layer, phase: phase, color: .red, scale: 1.0)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

#Preview("Edge case — Bottoming Out") {
  let phase = CatalogPhaseModel(
    id: 5,
    name: "Bottoming Out",
    medicinal: [],
    toxic: [],
    strategies: []
  )
  let layer = CatalogLayerModel(
    id: 2,
    color: "Purple",
    title: "Purple",
    subtitle: "Magic",
    phases: [phase]
  )
  return PhaseCrystalCard(layer: layer, phase: phase, color: .purple, scale: 1.0)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
