import Testing
@testable import WavelengthWatch_Watch_App

/// Tests for `ScrollAffordanceView`'s emphasis policy. Visibility itself is
/// edge-driven (covered by `ScrollAffordanceModelTests`); this pins the
/// opacity contract that replaced the old timer — an available-direction
/// chevron is emphasized while scrolling and merely de-emphasized at rest,
/// never hidden (the structural guarantee against B1).
struct ScrollAffordanceViewTests {
  @Test("chevrons are more emphasized while interacting than at rest")
  func interacting_isMoreEmphasizedThanRest() {
    let interacting = ScrollAffordanceView.chevronOpacity(isInteracting: true)
    let atRest = ScrollAffordanceView.chevronOpacity(isInteracting: false)

    #expect(interacting > atRest)
  }

  @Test("chevrons stay visible at rest — opacity is never zero")
  func atRest_isNonZero() {
    #expect(ScrollAffordanceView.chevronOpacity(isInteracting: false) > 0)
  }

  /// B1 follow-up: vertical navigation is programmatic (crown / drag →
  /// `scrollTo`), so the scroll-phase `isInteracting` signal often never fires
  /// for vertical moves. Baseline visibility therefore can't depend on it — an
  /// available-direction chevron must be *clearly* visible at rest, not merely
  /// non-zero. Pins resting opacity high enough to read on-device.
  @Test("chevrons are clearly visible at rest, independent of the scroll-phase signal")
  func atRest_isClearlyVisible() {
    #expect(ScrollAffordanceView.chevronOpacity(isInteracting: false) >= 0.8)
  }

  @Test("interacting opacity is a valid opacity value (never above 1.0)")
  func interacting_isValidOpacity() {
    let interacting = ScrollAffordanceView.chevronOpacity(isInteracting: true)
    #expect(interacting > 0)
    #expect(interacting <= 1.0)
  }
}
