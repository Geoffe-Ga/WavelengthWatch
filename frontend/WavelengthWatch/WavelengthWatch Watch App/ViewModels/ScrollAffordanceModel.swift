import Foundation

/// Which directions the dual-axis navigation can currently move in.
///
/// The vertical layer axis is clamped (`0 ..< layerCount`), so up/down are
/// genuinely edge-aware. The horizontal phase axis wraps infinitely (the
/// inner TabView's sentinel pages), so left/right are available whenever
/// there is more than one phase to wrap between.
struct ScrollAffordances: Equatable {
  var canGoUp = false
  var canGoDown = false
  var canGoLeft = false
  var canGoRight = false
}

/// Derives edge availability and tracks whether a scroll is in progress, so
/// the affordance chevrons can be shown for exactly the directions that are
/// possible — and kept visible for the whole duration of a gesture rather
/// than hidden by a timer.
///
/// Pure state with no view dependency, so the edge math and interaction
/// transitions are unit-testable without rendering anything.
@MainActor
final class ScrollAffordanceModel: ObservableObject {
  @Published private(set) var affordances = ScrollAffordances()

  /// True while a scroll/crown/drag gesture is in progress. Currently unset;
  /// callers will drive it from the live scroll phase to gate chevron
  /// visibility.
  @Published private(set) var isInteracting = false

  /// Recomputes edge availability from the current selection and counts.
  /// Infinite-wrap aware: left/right depend only on whether more than one
  /// phase exists, never on the phase index.
  func update(layerSelection: Int, layerCount: Int, phaseCount: Int) {
    affordances = ScrollAffordances(
      canGoUp: layerSelection > 0,
      canGoDown: layerSelection < layerCount - 1,
      canGoLeft: phaseCount > 1,
      canGoRight: phaseCount > 1
    )
  }

  /// Records whether a scroll interaction is in progress.
  func setInteracting(_ interacting: Bool) {
    guard isInteracting != interacting else { return }
    isInteracting = interacting
  }
}
