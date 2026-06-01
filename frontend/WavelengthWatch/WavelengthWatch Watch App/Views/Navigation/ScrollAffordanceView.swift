import SwiftUI

/// Edge-aware directional chevrons for the dual-axis navigation. A chevron
/// is rendered for a direction only when movement that way is possible, so
/// the absence of a chevron is itself the "you're at the edge" signal.
///
/// Purely an affordance hint — it never intercepts touches, so it can't
/// interfere with the scroll/crown gestures underneath. Overall visibility
/// is controlled by the caller (gated at parity with the existing indicator
/// in #410; driven by live scroll state + edge availability in #411).
struct ScrollAffordanceView: View {
  let affordances: ScrollAffordances

  var body: some View {
    ZStack {
      if affordances.canGoUp { chevron("chevron.up", alignment: .top) }
      if affordances.canGoDown { chevron("chevron.down", alignment: .bottom) }
      if affordances.canGoLeft { chevron("chevron.left", alignment: .leading) }
      if affordances.canGoRight { chevron("chevron.right", alignment: .trailing) }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .allowsHitTesting(false)
  }

  private func chevron(_ systemName: String, alignment: Alignment) -> some View {
    Image(systemName: systemName)
      .font(.system(size: 12, weight: .semibold))
      .foregroundStyle(.white.opacity(0.5))
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
      .padding(4)
  }
}
