import os
import SwiftUI

/// TEMPORARY (#457 Phase 0.1): where did the chevron's resolved frame land,
/// relative to its own card? Distinguishes a *layout* failure (off-card or
/// zero-size) from a *compositing* failure (a correct, on-card frame that
/// still never paints) on lazily-realized cards. Both rects are read in the
/// same `.global` space. Remove with the rest of the Phase 0 diagnostics once
/// the RCA lands.
enum ChevronFrameDiagnosis: String {
  case onscreen
  case zeroSize
  case offscreenAbove
  case offscreenBelow
  case offscreenSide
  case indeterminate

  static func classify(chevron: CGRect, container: CGRect) -> ChevronFrameDiagnosis {
    guard container.width > 0, container.height > 0 else { return .indeterminate }
    guard chevron.width > 0, chevron.height > 0 else { return .zeroSize }
    if chevron.maxY <= container.minY { return .offscreenAbove }
    if chevron.minY >= container.maxY { return .offscreenBelow }
    if chevron.maxX <= container.minX || chevron.minX >= container.maxX {
      return .offscreenSide
    }
    return .onscreen
  }
}

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

  /// TEMPORARY (#457 Phase 0.1): the card's resolved global frame, captured so
  /// the chevron's frame can be judged against its own container.
  @State private var cardFrame: CGRect = .zero

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
          // TEMPORARY (#457 Phase 0.1): where did the chevron actually land?
          // Off-screen / zero-size => layout failure; an on-screen frame that
          // still doesn't paint => compositing failure. Fires on settle.
          .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
          } action: { frame in
            let verdict = ChevronFrameDiagnosis.classify(chevron: frame, container: cardFrame)
            Self.chevronLog.log("chevron frame layer=\(layer.id, privacy: .public) phase=\(phase.id, privacy: .public) x=\(Int(frame.minX), privacy: .public) y=\(Int(frame.minY), privacy: .public) w=\(Int(frame.width), privacy: .public) h=\(Int(frame.height), privacy: .public) cardY=\(Int(cardFrame.minY), privacy: .public) cardH=\(Int(cardFrame.height), privacy: .public) verdict=\(verdict.rawValue, privacy: .public)")
          }
        }
        .padding(.bottom, 20)
      }
    }
    // TEMPORARY (#457 Phase 0): page lazily created on first scroll to this card.
    .onAppear {
      Self.chevronLog.log("page onAppear layer=\(layer.id, privacy: .public) phase=\(phase.id, privacy: .public)")
    }
    // TEMPORARY (#457 Phase 0.1): the card's own frame, used as the chevron's
    // container reference in the same `.global` coordinate space.
    .onGeometryChange(for: CGRect.self) { proxy in
      proxy.frame(in: .global)
    } action: { frame in
      cardFrame = frame
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
