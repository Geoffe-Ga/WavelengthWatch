import SwiftUI

/// Modifier for navigation bar / toolbar area styling.
///
/// On watchOS 26+, this will use `safeAreaBar` with glass effect.
/// On older versions, it hides the default toolbar background.
struct WLNavigationBarModifier: ViewModifier {
  let tint: Color?

  init(tint: Color? = nil) {
    self.tint = tint
  }

  func body(content: Content) -> some View {
    if WLTheme.isGlassAvailable {
      // TODO: watchOS 26 — Apply safeAreaBar with glass:
      // content.safeAreaBar(edge: .top) {
      //   Color.clear.glassEffect(.regular, in: .rect)
      // }
      applyFallback(to: content)
    } else {
      applyFallback(to: content)
    }
  }

  private func applyFallback(to content: Content) -> some View {
    content
      .toolbarBackground(.hidden, for: .navigationBar)
  }
}

// MARK: - View Extension

extension View {
  /// Applies design-system navigation bar styling.
  func wlNavigationBar(tint: Color? = nil) -> some View {
    modifier(WLNavigationBarModifier(tint: tint))
  }
}
