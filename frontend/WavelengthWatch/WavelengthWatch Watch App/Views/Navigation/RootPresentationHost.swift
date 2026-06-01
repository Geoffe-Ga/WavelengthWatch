import SwiftUI

/// The single root-level presentation host, attached above the
/// NavigationStack push so the presentations it renders are never deferred
/// behind an in-flight navigation transaction.
///
/// In this skeleton (issue #405) the host owns the `storageError` alert —
/// the simplest fully self-contained surface — proving the
/// coordinator-driven host renders end-to-end. The `menu` and `onboarding`
/// sheets are coordinator-driven from this same `PresentationCoordinator`
/// but still presented from `MainContentDialogsModifier` for now; #406 /
/// #407 relocate their content here and fold the publisher-driven journal
/// feedback and flow review onto the host too.
struct RootPresentationHost: ViewModifier {
  @ObservedObject var coordinator: PresentationCoordinator

  func body(content: Content) -> some View {
    content
      .alert(
        "Storage Error",
        isPresented: coordinator.isPresented(for: .storageError)
      ) {
        Button("OK", role: .cancel) {}
      } message: {
        Text("Your journal couldn't be opened, so entries logged this session won't be saved. Please reopen the app; if the problem continues, contact support.")
      }
  }
}

extension View {
  /// Attaches the root presentation host. See `RootPresentationHost`.
  func rootPresentationHost(coordinator: PresentationCoordinator) -> some View {
    modifier(RootPresentationHost(coordinator: coordinator))
  }
}
