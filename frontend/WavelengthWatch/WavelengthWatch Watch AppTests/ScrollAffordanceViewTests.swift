import Testing
@testable import WavelengthWatch_Watch_App

/// `ScrollAffordanceView` is now a thin renderer of a `ChevronVisibilityState`;
/// the lit / visible-unlit / hidden timing logic lives in
/// `ScrollAffordanceVisibilityModel` (see `ScrollAffordanceVisibilityModelTests`).
/// Per the project's view-test philosophy this is a shallow construction check.
@MainActor
struct ScrollAffordanceViewTests {
  @Test("view constructs from a visibility state and exposes it")
  func constructsFromState() {
    let view = ScrollAffordanceView(state: ChevronVisibilityState(
      up: .lit, down: .visibleUnlit, left: .hidden, right: .visibleUnlit
    ))

    #expect(view.state.up == .lit)
    #expect(view.state.down == .visibleUnlit)
    #expect(view.state.left == .hidden)
  }
}
