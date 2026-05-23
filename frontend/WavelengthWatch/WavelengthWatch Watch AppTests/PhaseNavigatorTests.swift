import Testing
@testable import WavelengthWatch_Watch_App

/// Coverage for the circular-navigation utilities `PhaseNavigator`
/// exposes. The sentinel pages at `0` and `phaseCount + 1` are the
/// trickiest part; tests below pin each boundary plus the degenerate
/// `phaseCount` values that the caller (`NavigationViewModel`) guards
/// against but the utility itself must also tolerate.
struct PhaseNavigatorTests {
  // MARK: - adjustedSelection: sentinel wrapping

  @Test("leading sentinel (0) wraps to the last real page")
  func adjustedSelection_leadingSentinel_wrapsToLast() {
    #expect(PhaseNavigator.adjustedSelection(0, phaseCount: 6) == 6)
  }

  @Test("trailing sentinel (phaseCount + 1) wraps to the first real page")
  func adjustedSelection_trailingSentinel_wrapsToFirst() {
    #expect(PhaseNavigator.adjustedSelection(7, phaseCount: 6) == 1)
  }

  @Test("a real-page selection passes through unchanged")
  func adjustedSelection_realPages_passThrough() {
    for page in 1 ... 6 {
      #expect(PhaseNavigator.adjustedSelection(page, phaseCount: 6) == page)
    }
  }

  @Test("a single-phase order wraps both sentinels back to the only page")
  func adjustedSelection_phaseCount1_collapsesToSinglePage() {
    // Real-page pass-through at phaseCount: 1 is covered by the contract
    // pinned in adjustedSelection_realPages_passThrough; this test focuses
    // strictly on the sentinel wrap.
    #expect(PhaseNavigator.adjustedSelection(0, phaseCount: 1) == 1)
    #expect(PhaseNavigator.adjustedSelection(2, phaseCount: 1) == 1)
  }

  // MARK: - normalizedIndex: sentinel and real-page mapping

  @Test("real pages 1...phaseCount map to indices 0...phaseCount - 1")
  func normalizedIndex_realPages_mapZeroBased() {
    for page in 1 ... 6 {
      #expect(PhaseNavigator.normalizedIndex(page, phaseCount: 6) == page - 1)
    }
  }

  @Test("leading sentinel (0) normalizes directly to the last index")
  func normalizedIndex_leadingSentinel_mapsToLastIndex() {
    // Equivalent to `normalizedIndex(adjustedSelection(0, 6), 6)` — the
    // modulo math wraps in a single step, so adjustedSelection is not a
    // prerequisite for normalizedIndex to handle a sentinel.
    #expect(PhaseNavigator.normalizedIndex(0, phaseCount: 6) == 5)
  }

  @Test("trailing sentinel (phaseCount + 1) normalizes directly to the first index")
  func normalizedIndex_trailingSentinel_mapsToFirstIndex() {
    #expect(PhaseNavigator.normalizedIndex(7, phaseCount: 6) == 0)
  }

  @Test("a single-phase order normalizes every real page to index 0")
  func normalizedIndex_phaseCount1_alwaysReturnsZero() {
    #expect(PhaseNavigator.normalizedIndex(1, phaseCount: 1) == 0)
    // And the sentinels too — both wrap to the only index.
    #expect(PhaseNavigator.normalizedIndex(0, phaseCount: 1) == 0)
    #expect(PhaseNavigator.normalizedIndex(2, phaseCount: 1) == 0)
  }
}
