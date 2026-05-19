import SwiftUI

/// Top-bar toolbar for the main shell: back chevron while a journal flow
/// is in progress, ellipsis-circle menu button otherwise. Suppressed
/// entirely while the user is in a detail view so the system back
/// chevron has the leading slot to itself.
struct MainNavigationToolbar: ToolbarContent {
  let isShowingDetailView: Bool
  let isInFlow: Bool
  let onBack: () -> Void
  let onMenu: () -> Void

  var body: some ToolbarContent {
    if !isShowingDetailView {
      ToolbarItem(placement: .topBarLeading) {
        if isInFlow {
          Button(action: onBack) {
            Image(systemName: "chevron.left")
              .font(.system(size: UIConstants.menuButtonSize))
              .foregroundColor(.white.opacity(0.7))
          }
          .buttonStyle(.plain)
        } else {
          Button(action: onMenu) {
            Image(systemName: "ellipsis.circle")
              .font(.system(size: UIConstants.menuButtonSize))
              .foregroundColor(.white.opacity(0.7))
          }
          .buttonStyle(.plain)
        }
      }
    }
  }
}
