import Foundation

/// How a single directional chevron is currently drawn.
///
/// `hidden` means the view is removed entirely (the SwiftUI equivalent of
/// `display: none`), not merely transparent — at rest the chevrons take up no
/// space and render nothing.
enum ChevronStyle: Equatable {
  case lit
  case visibleUnlit
  case hidden
}

/// One of the four dual-axis navigation directions.
enum ScrollDirection: Equatable {
  case up
  case down
  case left
  case right
}

/// The drawn style of all four directional chevrons at a moment in time.
struct ChevronVisibilityState: Equatable {
  var up: ChevronStyle = .hidden
  var down: ChevronStyle = .hidden
  var left: ChevronStyle = .hidden
  var right: ChevronStyle = .hidden
}

/// Drives the directional chevrons' timed reveal: mostly hidden, lit on the
/// scrolled direction, then a visible-unlit settle window, then hidden again.
///
/// Pure, view-independent state with **injectable timing** — transitions are
/// driven by `advance(by:)` over an elapsed `Duration`, so the whole machine is
/// unit-testable without wall-clock sleeps. A thin live driver ticks
/// `advance(by:)` using `nextDeadline`; edge-availability stays the concern of
/// `ScrollAffordanceModel` and is supplied here, never recomputed.
@MainActor
final class ScrollAffordanceVisibilityModel: ObservableObject {
  /// Lit emphasis on first load.
  static let loadLitDuration: Duration = .milliseconds(300)
  /// Visible-unlit settle window after load-lit and after every scroll.
  static let settleDuration: Duration = .milliseconds(800)

  @Published private(set) var state = ChevronVisibilityState()

  /// Bumped on every external event so a live `.task(id:)` driver restarts its
  /// sleep loop against the new phase.
  @Published private(set) var version = 0

  private var availability: ScrollAffordances
  private var phase: Phase = .hidden

  private enum Phase: Equatable {
    case hidden
    case loadLit(remaining: Duration)
    /// Visible-unlit window (entered after load-lit and after every scroll-end).
    case settle(remaining: Duration)
    case scrolling(ScrollDirection)
  }

  init(availability: ScrollAffordances = ScrollAffordances()) {
    self.availability = availability
    recompute()
  }

  /// Edge availability changed (layer/phase move); restyle without disturbing
  /// the current timing phase.
  func updateAvailability(_ availability: ScrollAffordances) {
    self.availability = availability
    recompute()
  }

  /// The navigation screen appeared: lit for `loadLitDuration`, then settle.
  func appeared() {
    enter(.loadLit(remaining: Self.loadLitDuration))
  }

  /// A scroll is in progress toward `direction`: that chevron lights, the rest
  /// stay visible-unlit, with no timeout until `scrollEnded()`.
  func scrollStarted(_ direction: ScrollDirection) {
    enter(.scrolling(direction))
  }

  /// The scroll settled: all available chevrons are visible-unlit for
  /// `settleDuration`, then hidden. Restarts the window if already settling.
  func scrollEnded() {
    enter(.settle(remaining: Self.settleDuration))
  }

  /// Advance internal timers by `delta`. Overflow past a timed phase carries
  /// into the next, so a single large step resolves to the final state.
  func advance(by delta: Duration) {
    switch phase {
    case .hidden, .scrolling:
      return // no timeout; only an event leaves these phases
    case let .loadLit(remaining):
      if delta >= remaining {
        phase = .settle(remaining: Self.settleDuration)
        advance(by: delta - remaining) // recursive call recomputes; no double publish
      } else {
        phase = .loadLit(remaining: remaining - delta)
        recompute()
      }
    case let .settle(remaining):
      if delta >= remaining {
        phase = .hidden
      } else {
        phase = .settle(remaining: remaining - delta)
      }
      recompute()
    }
  }

  /// Time until the next automatic transition, or `nil` when the current phase
  /// waits on an external event (`hidden`, `scrolling`).
  var nextDeadline: Duration? {
    switch phase {
    case .hidden, .scrolling: nil
    case let .loadLit(remaining): remaining
    case let .settle(remaining): remaining
    }
  }

  private func enter(_ newPhase: Phase) {
    phase = newPhase
    version &+= 1
    recompute()
  }

  private func recompute() {
    state = ChevronVisibilityState(
      up: style(available: availability.canGoUp, direction: .up),
      down: style(available: availability.canGoDown, direction: .down),
      left: style(available: availability.canGoLeft, direction: .left),
      right: style(available: availability.canGoRight, direction: .right)
    )
  }

  private func style(available: Bool, direction: ScrollDirection) -> ChevronStyle {
    guard available else { return .hidden }
    switch phase {
    case .hidden: return .hidden
    case .loadLit: return .lit
    case .settle: return .visibleUnlit
    case let .scrolling(scrolled): return scrolled == direction ? .lit : .visibleUnlit
    }
  }
}
