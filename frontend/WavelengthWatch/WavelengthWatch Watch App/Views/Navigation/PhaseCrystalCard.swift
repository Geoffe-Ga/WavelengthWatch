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

  /// Scales every color-bearing layer (orb, accent, stroke, glass tint).
  /// `1.0` = current production look; lower = calmer / more translucent glass.
  /// Defaulted so production call sites are unchanged; the audit `#Preview`
  /// (issue #430 visual Phase 0) varies it to find a readable value for #433.
  var colorIntensity: Double = 1.0

  /// Layer color at `base` opacity, further scaled by `colorIntensity`.
  private func tint(_ base: Double) -> Color {
    color.opacity(base * colorIntensity)
  }

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
            tint(0.3),
            tint(0.1),
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
    // Fixed: content is a fixed visual height; scaling this pad only pushes the orb out.
    .padding(.vertical, 16)
    .frame(minWidth: UIConstants.phaseCardMinWidth * scale)
    .wlGlass(.regular, tint: tint(1.0), cornerRadius: WLSpacingTokens.cardCornerRadiusLarge)
    .overlay(crystalStroke)
    .modifier(CardDepthShadow(color: color))
  }

  private var layerContext: some View {
    VStack(spacing: 4 * scale) {
      Text(layer.title)
        .font(WLTypographyTokens.sectionHeader)
        .fontWeight(WLTypographyTokens.sectionHeaderWeight)
        .foregroundColor(WLColorTokens.secondaryText)
        .tracking(WLTypographyTokens.sectionHeaderTracking)
        .textCase(.uppercase)
        .lineLimit(1)
        .minimumScaleFactor(0.8)

      Text(layer.subtitle)
        .font(.caption2)
        .foregroundColor(WLColorTokens.tertiaryText)
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
        .fill(tint(0.3))
        .frame(
          width: UIConstants.phaseAccentOuterWidth * scale,
          height: UIConstants.phaseAccentOuterHeight * scale
        )
        .blur(radius: 3 * scale)

      Capsule()
        .fill(
          LinearGradient(
            gradient: Gradient(colors: [
              tint(0.6),
              tint(1.0),
              tint(0.6),
            ]),
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .frame(
          width: UIConstants.phaseAccentInnerWidth * scale,
          height: UIConstants.phaseAccentInnerHeight * scale
        )
        .shadow(color: tint(0.8), radius: 4 * scale)
    }
  }

  /// The crystalline gradient edge that gives the card its identity, layered
  /// over the glass surface.
  private var crystalStroke: some View {
    RoundedRectangle(cornerRadius: WLSpacingTokens.cardCornerRadiusLarge)
      .stroke(
        LinearGradient(
          gradient: Gradient(colors: [
            tint(0.3),
            Color.white.opacity(0.1),
            tint(0.2),
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        ),
        lineWidth: 1
      )
  }
}

/// Depth shadow for the crystal card, scoped by OS so the glass surface
/// isn't double-shadowed. On watchOS 26 the `glassEffect` material renders
/// its own depth, so only a single light separation shadow is added; the
/// pre-26 fallback is a flat tinted surface and needs the fuller two-shadow
/// stack to read as a floating card.
private struct CardDepthShadow: ViewModifier {
  let color: Color

  func body(content: Content) -> some View {
    if #available(watchOS 26, *) {
      content.shadow(color: .black.opacity(0.25), radius: 4)
    } else {
      content
        .shadow(color: color.opacity(0.2), radius: 8)
        .shadow(color: .black.opacity(0.3), radius: 4)
    }
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
    id: 3,
    color: "Red",
    title: "RED",
    subtitle: "(Power)",
    phases: [phase]
  )
  PhaseCrystalCard(layer: layer, phase: phase, color: .red, scale: 1.0)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

// MARK: - Phase 0 visual-audit harness (#430)

/// Renders the card at descending `colorIntensity` levels so the readable
/// target can be chosen for #433. Preview-only; not used in production.
private struct CardIntensityLadder: View {
  let colorName: String
  let color: Color
  let title: String
  let subtitle: String

  private let levels: [Double] = [1.0, 0.6, 0.45, 0.3]
  private var phase: CatalogPhaseModel {
    CatalogPhaseModel(id: 2, name: "Peaking", medicinal: [], toxic: [], strategies: [])
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 18) {
        ForEach(levels, id: \.self) { level in
          VStack(spacing: 4) {
            Text("intensity \(level, specifier: "%.2f")\(level == 1.0 ? "  (current)" : "")")
              .font(.caption2)
              .foregroundColor(.white.opacity(0.65))
            PhaseCrystalCard(
              layer: CatalogLayerModel(
                id: 3, color: colorName, title: title, subtitle: subtitle, phases: [phase]
              ),
              phase: phase,
              color: color,
              scale: 1.0,
              colorIntensity: level
            )
          }
        }
      }
      .padding(.vertical, 24)
    }
    .background(Color.black)
  }
}

#Preview("§430 brightness ladder — Red") {
  CardIntensityLadder(colorName: "Red", color: .red, title: "RED", subtitle: "(Power)")
}

#Preview("§430 brightness ladder — Yellow") {
  CardIntensityLadder(colorName: "Yellow", color: .yellow, title: "YELLOW", subtitle: "(Achiever)")
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
    title: "PURPLE",
    subtitle: "(Tribal)",
    phases: [phase]
  )
  PhaseCrystalCard(layer: layer, phase: phase, color: .purple, scale: 1.0)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
