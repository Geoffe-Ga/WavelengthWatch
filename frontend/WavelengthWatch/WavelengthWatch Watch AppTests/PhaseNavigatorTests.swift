import Testing

@testable import WavelengthWatch_Watch_App

struct PhaseNavigatorTests {
  @Test func wrapsFromFirstToLast() {
    let adjusted = PhaseNavigator.adjustedSelection(0, phaseCount: 6)
    #expect(adjusted == 6)
  }

  @Test func wrapsFromLastToFirst() {
    let adjusted = PhaseNavigator.adjustedSelection(7, phaseCount: 6)
    #expect(adjusted == 1)
  }

  @Test func normalizesSelection() {
    let index = PhaseNavigator.normalizedIndex(1, phaseCount: 6)
    #expect(index == 0)
    let last = PhaseNavigator.normalizedIndex(6, phaseCount: 6)
    #expect(last == 5)
  }
}
