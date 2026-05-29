import SwiftUI

/// Applies an animation that is suppressed when the system "Reduce Motion"
/// accessibility setting is on. Reads the environment itself, so call sites
/// don't each need to declare `@Environment(\.accessibilityReduceMotion)`.
private struct WLConditionalAnimation<V: Equatable>: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  let animation: Animation?
  let value: V

  func body(content: Content) -> some View {
    content.animation(reduceMotion ? nil : animation, value: value)
  }
}

extension View {
  /// Like `.animation(_:value:)`, but yields no animation when Reduce Motion
  /// is enabled. Use for decorative / morphing motion that should respect the
  /// accessibility setting.
  func wlAnimation(_ animation: Animation?, value: some Equatable) -> some View {
    modifier(WLConditionalAnimation(animation: animation, value: value))
  }
}
