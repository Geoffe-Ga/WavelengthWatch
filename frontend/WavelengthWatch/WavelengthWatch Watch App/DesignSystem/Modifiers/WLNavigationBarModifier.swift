import SwiftUI

/// Modifier for navigation bar / toolbar area styling.
///
/// On watchOS 26+ the system renders Liquid Glass on the navigation chrome
/// automatically when the toolbar background is visible — so we stop
/// hiding it. On older runtimes we keep the previous behavior of hiding
/// the default opaque toolbar background to let content show through.
struct WLNavigationBarModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(watchOS 26, *) {
      // System-rendered Liquid Glass on the toolbar — no override needed.
      content
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
  func wlNavigationBar() -> some View {
    modifier(WLNavigationBarModifier())
  }
}
