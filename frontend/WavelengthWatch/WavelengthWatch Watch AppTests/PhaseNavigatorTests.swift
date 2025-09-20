import XCTest
@testable import WavelengthWatch_Watch_App

final class PhaseNavigatorTests: XCTestCase {
  func testAdjustedSelectionWrapsBeforeFirstPage() {
    XCTAssertEqual(PhaseNavigator.adjustedSelection(0, phaseCount: 6), 6)
  }

  func testAdjustedSelectionWrapsAfterLastPage() {
    XCTAssertEqual(PhaseNavigator.adjustedSelection(7, phaseCount: 6), 1)
  }

  func testAdjustedSelectionReturnsMiddlePageUnchanged() {
    XCTAssertEqual(PhaseNavigator.adjustedSelection(3, phaseCount: 6), 3)
  }
}
