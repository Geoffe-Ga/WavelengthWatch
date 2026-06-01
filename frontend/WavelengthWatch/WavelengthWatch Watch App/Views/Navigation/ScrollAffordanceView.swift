import SwiftUI

/// Edge-aware directional chevrons for the dual-axis navigation. A chevron
/// is rendered for a direction only when movement that way is possible, so
/// the absence of a chevron is itself the "you're at the edge" signal.
///
/// The chevrons are always present; their overall emphasis is full while a
/// scroll is in progress and de-emphasized at rest, so the edge cue never
/// disappears mid-gesture. Purely an affordance hint — it never intercepts
/// touches, so it can't interfere with the scroll/crown gestures underneath.
struct ScrollAffordanceView: View {
  let affordances: ScrollAffordances
  let isInteracting: Bool

  var body: some View {
    ZStack {
      if affordances.canGoUp { chevron("chevron.up", alignment: .top) }
      if affordances.canGoDown { chevron("chevron.down", alignment: .bottom) }
      if affordances.canGoLeft { chevron("chevron.left", alignment: .leading) }
      if affordances.canGoRight { chevron("chevron.right", alignment: .trailing) }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .opacity(Self.chevronOpacity(isInteracting: isInteracting))
    .animation(.easeInOut(duration: 0.2), value: isInteracting)
    .allowsHitTesting(false)
  }

  /// Emphasis while a scroll is in progress.
  private static let interactingOpacity: Double = 0.9
  /// Ambient emphasis at rest — quiet but never zero, so an
  /// available-direction chevron is always at least faintly visible.
  private static let restingOpacity: Double = 0.35

  /// Full while a scroll is in progress, de-emphasized at rest. Never zero,
  /// which is what keeps a chevron from ever disappearing on a timer.
  static func chevronOpacity(isInteracting: Bool) -> Double {
    isInteracting ? interactingOpacity : restingOpacity
  }

  private func chevron(_ systemName: String, alignment: Alignment) -> some View {
    Image(systemName: systemName)
      .font(.system(size: 12, weight: .semibold))
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
      .padding(4)
  }
}
