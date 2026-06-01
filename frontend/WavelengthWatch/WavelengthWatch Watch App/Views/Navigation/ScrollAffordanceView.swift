import SwiftUI

/// Edge-aware directional chevrons for the dual-axis navigation. A chevron
/// is rendered for a direction only when movement that way is possible, so
/// the absence of a chevron is itself the "you're at the edge" signal.
///
/// The chevrons are always present; their overall emphasis is full while a
/// scroll is in progress and de-emphasized at rest, so the edge cue never
/// disappears mid-gesture. Each sits on a Liquid Glass chip (grouped in a
/// `GlassEffectContainer` so they blend correctly on watchOS 26). Purely an
/// affordance hint — it never intercepts touches, so it can't interfere with
/// the scroll/crown gestures underneath.
struct ScrollAffordanceView: View {
  let affordances: ScrollAffordances
  let isInteracting: Bool

  /// Emphasis while a scroll is in progress.
  private static let interactingOpacity: Double = 0.9
  /// Ambient emphasis at rest — quiet but never zero, so an
  /// available-direction chevron is always at least faintly visible.
  private static let restingOpacity: Double = 0.35

  /// Corner radius of the small glass chip behind each chevron; large enough
  /// to read as a pill/circle at chip size.
  private let chipCornerRadius: CGFloat = 99

  var body: some View {
    chevronLayer
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .opacity(Self.chevronOpacity(isInteracting: isInteracting))
      .animation(.easeInOut(duration: 0.2), value: isInteracting)
      .allowsHitTesting(false)
  }

  /// Groups the chevrons' glass effects so they blend correctly on
  /// watchOS 26; older versions render the same chevrons with the `wlGlass`
  /// fallback (no container needed).
  @ViewBuilder
  private var chevronLayer: some View {
    if #available(watchOS 26, *) {
      GlassEffectContainer { chevrons }
    } else {
      chevrons
    }
  }

  private var chevrons: some View {
    ZStack {
      if affordances.canGoUp { chevron("chevron.up", alignment: .top) }
      if affordances.canGoDown { chevron("chevron.down", alignment: .bottom) }
      if affordances.canGoLeft { chevron("chevron.left", alignment: .leading) }
      if affordances.canGoRight { chevron("chevron.right", alignment: .trailing) }
    }
  }

  /// Full while a scroll is in progress, de-emphasized at rest. Never zero,
  /// which is what keeps a chevron from ever disappearing on a timer.
  static func chevronOpacity(isInteracting: Bool) -> Double {
    isInteracting ? interactingOpacity : restingOpacity
  }

  private func chevron(_ systemName: String, alignment: Alignment) -> some View {
    Image(systemName: systemName)
      .font(.system(size: 12, weight: .semibold))
      .foregroundStyle(.white)
      .padding(5)
      .wlGlass(.regular, cornerRadius: chipCornerRadius)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
      .padding(4)
  }
}
