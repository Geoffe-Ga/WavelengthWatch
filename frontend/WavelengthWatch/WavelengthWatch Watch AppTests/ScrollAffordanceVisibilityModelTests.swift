import Testing
@testable import WavelengthWatch_Watch_App

/// Transition coverage for the directional-chevron timed-reveal state machine
/// (#438). Timing is injected via `advance(by:)`, so these are pure-logic tests
/// with no wall-clock dependency.
@MainActor
struct ScrollAffordanceVisibilityModelTests {
  private let allAvailable = ScrollAffordances(
    canGoUp: true, canGoDown: true, canGoLeft: true, canGoRight: true
  )

  private func model() -> ScrollAffordanceVisibilityModel {
    ScrollAffordanceVisibilityModel(availability: ScrollAffordances(
      canGoUp: true, canGoDown: true, canGoLeft: true, canGoRight: true
    ))
  }

  // MARK: - Resting / load

  @Test("at rest (no events) every chevron is hidden")
  func rest_allHidden() {
    let m = model()
    #expect(m.state == ChevronVisibilityState(
      up: .hidden, down: .hidden, left: .hidden, right: .hidden
    ))
  }

  @Test("first load: lit for 300ms, then visible-unlit for 800ms, then hidden")
  func load_litThenVisibleThenHidden() {
    let m = model()
    m.appeared()
    #expect(m.state == ChevronVisibilityState(
      up: .lit, down: .lit, left: .lit, right: .lit
    ))

    m.advance(by: .milliseconds(300))
    #expect(m.state == ChevronVisibilityState(
      up: .visibleUnlit, down: .visibleUnlit, left: .visibleUnlit, right: .visibleUnlit
    ))

    m.advance(by: .milliseconds(800))
    #expect(m.state == ChevronVisibilityState(
      up: .hidden, down: .hidden, left: .hidden, right: .hidden
    ))
  }

  @Test("load-lit overflow carries through the settle window to hidden")
  func load_overflowResolvesToHidden() {
    let m = model()
    m.appeared()
    // 300ms lit + 800ms settle = 1100ms total -> hidden.
    m.advance(by: .milliseconds(1100))
    #expect(m.state.up == .hidden)
  }

  @Test("load-lit partially elapsed stays lit")
  func load_partialStaysLit() {
    let m = model()
    m.appeared()
    m.advance(by: .milliseconds(150))
    #expect(m.state.up == .lit)
  }

  // MARK: - Scroll

  @Test("on scroll the scrolled direction is lit, other available are visible-unlit")
  func scroll_directionLit_othersVisible() {
    let m = model()
    m.scrollStarted(.up)
    #expect(m.state.up == .lit)
    #expect(m.state.down == .visibleUnlit)
    #expect(m.state.left == .visibleUnlit)
    #expect(m.state.right == .visibleUnlit)
  }

  @Test("scrolling has no timeout — advancing keeps it lit")
  func scroll_hasNoTimeout() {
    let m = model()
    m.scrollStarted(.right)
    m.advance(by: .seconds(10))
    #expect(m.state.right == .lit)
  }

  @Test("scroll end: visible-unlit for 800ms, then hidden")
  func scrollEnd_visibleThenHidden() {
    let m = model()
    m.scrollEnded()
    #expect(m.state == ChevronVisibilityState(
      up: .visibleUnlit, down: .visibleUnlit, left: .visibleUnlit, right: .visibleUnlit
    ))

    m.advance(by: .milliseconds(800))
    #expect(m.state == ChevronVisibilityState(
      up: .hidden, down: .hidden, left: .hidden, right: .hidden
    ))
  }

  @Test("each scroll-end restarts the 800ms window")
  func scrollEnd_restartsWindow() {
    let m = model()
    m.scrollEnded()
    m.advance(by: .milliseconds(500))
    #expect(m.state.up == .visibleUnlit)

    m.scrollEnded() // restart
    m.advance(by: .milliseconds(500)) // 500 < 800, so still visible
    #expect(m.state.up == .visibleUnlit)

    m.advance(by: .milliseconds(300)) // now 800 total since restart
    #expect(m.state.up == .hidden)
  }

  @Test("a new scroll pre-empts an in-progress settle window")
  func newScroll_preemptsWindow() {
    let m = model()
    m.scrollEnded()
    m.advance(by: .milliseconds(400))
    m.scrollStarted(.left)
    #expect(m.state.left == .lit)
    #expect(m.state.up == .visibleUnlit)
  }

  @Test("a new scroll pre-empts the load sequence")
  func newScroll_preemptsLoad() {
    let m = model()
    m.appeared()
    m.advance(by: .milliseconds(100)) // still in load-lit
    m.scrollStarted(.down)
    #expect(m.state.down == .lit)
  }

  // MARK: - Edge availability

  @Test("unavailable directions never render in any phase")
  func unavailable_neverRendered() {
    let m = ScrollAffordanceVisibilityModel(availability: ScrollAffordances(
      canGoUp: false, canGoDown: true, canGoLeft: false, canGoRight: true
    ))
    m.appeared() // lit phase
    #expect(m.state.up == .hidden)
    #expect(m.state.left == .hidden)
    #expect(m.state.down == .lit)
    #expect(m.state.right == .lit)
  }

  @Test("availability changes restyle without disturbing the timing phase")
  func availabilityChange_restylesInPlace() {
    let m = ScrollAffordanceVisibilityModel(availability: allAvailable)
    m.scrollStarted(.up)
    m.updateAvailability(ScrollAffordances(
      canGoUp: true, canGoDown: false, canGoLeft: true, canGoRight: true
    ))
    #expect(m.state.up == .lit) // scroll phase preserved
    #expect(m.state.down == .hidden) // newly unavailable
  }

  // MARK: - nextDeadline (live-driver contract)

  @Test("nextDeadline is nil at rest and while scrolling, set while timed")
  func nextDeadline_reflectsPhase() {
    let m = model()
    #expect(m.nextDeadline == nil) // hidden/rest

    m.appeared()
    #expect(m.nextDeadline == .milliseconds(300))

    m.scrollStarted(.up)
    #expect(m.nextDeadline == nil) // scrolling waits on an event

    m.scrollEnded()
    #expect(m.nextDeadline == .milliseconds(800))
  }
}
