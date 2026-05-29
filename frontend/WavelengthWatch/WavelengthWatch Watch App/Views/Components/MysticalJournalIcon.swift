import SwiftUI

struct MysticalJournalIcon: View {
  let color: Color
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isGlowing = false

  var body: some View {
    ZStack {
      Circle()
        .strokeBorder(
          color.opacity(isGlowing ? 0.6 : 0.3),
          lineWidth: 1.0
        )
        .frame(width: 14, height: 14)
        .shadow(
          color: color.opacity(isGlowing ? 0.4 : 0.2),
          radius: isGlowing ? 2 : 1
        )

      Image(systemName: "plus")
        .font(.system(size: 8, weight: .medium))
        .foregroundColor(color.opacity(isGlowing ? 0.9 : 0.6))
    }
    .scaleEffect(isGlowing ? 1.1 : 1.0)
    .wlAnimation(
      .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
      value: isGlowing
    )
    .onAppear {
      // Don't start the perpetual glow loop under Reduce Motion — leave the
      // icon static at its base appearance.
      if !reduceMotion {
        isGlowing = true
      }
    }
  }
}
