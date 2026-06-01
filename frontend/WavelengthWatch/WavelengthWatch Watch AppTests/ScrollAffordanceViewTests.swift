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

  @Test("interacting opacity is a valid opacity value (never above 1.0)")
  func interacting_isValidOpacity() {
    let interacting = ScrollAffordanceView.chevronOpacity(isInteracting: true)
    #expect(interacting > 0)
    #expect(interacting <= 1.0)
  }
}
