import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

/// Structural smoke tests for the design-system nav-bar modifier.
/// The runtime branching (`#available(watchOS 26, *)`) selects between a
/// no-op on 26+ and `.toolbarBackground(.hidden, for: .navigationBar)`
/// on older runtimes — neither is unit-testable without snapshot or
/// ViewInspector infrastructure. These tests pin the construction and
/// extension surface so future refactors don't accidentally remove or
/// break the entry point.
struct WLNavigationBarModifierTests {
  @Test func modifier_canBeInstantiated() {
    _ = WLNavigationBarModifier()
  }

  @Test func viewExtension_isCallable() {
    // Compile-time smoke: applying the modifier through the View extension
    // succeeds. If `wlNavigationBar()` is renamed or removed, this fails
    // to compile. We deliberately don't evaluate `.body` here — outside a
    // real SwiftUI render pipeline that would crash on DynamicProperty
    // initialization rather than testing anything meaningful.
    _ = Text("nav").wlNavigationBar()
  }
}
