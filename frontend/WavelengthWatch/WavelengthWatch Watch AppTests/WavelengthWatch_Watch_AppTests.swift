//
//  WavelengthWatch_Watch_AppTests.swift
//  WavelengthWatch Watch AppTests
//
//  Created by Geoff Gallinger on 9/10/25.
//

import Testing
@testable import WavelengthWatch_Watch_App

struct StrategyParsingTests {
  @Test func parsesRisingFirstStrategy() throws {
    let data = StrategyData.load()
    #expect(data[.Rising]?.first?.strategy == "Cold Shower")
  }

  @Test func parsesWithdrawalFirstStrategy() throws {
    let data = StrategyData.load()
    #expect(data[.Withdrawal]?.first?.strategy == "Eating Something Grounding")
  }

  @Test func parsesLayerHeader() throws {
    let headers = HeaderData.load()
    let strategiesHeader = headers["Strategies"]
    #expect(strategiesHeader?.subtitle == "(For Surfing)")
  }

  @Test func parsesCurriculumEntry() throws {
    let curriculum = CurriculumData.load()
    let entry = curriculum["Beige"]?[.Rising]
    #expect(entry?.medicine == "Commitment")
  }
}

struct PhaseNavigatorTests {
  @Test func wrapsFromFirstToLast() throws {
    let adjusted = PhaseNavigator.adjustedSelection(0, phaseCount: Phase.allCases.count)
    #expect(adjusted == Phase.allCases.count)
  }

  @Test func wrapsFromLastToFirst() throws {
    let count = Phase.allCases.count
    let adjusted = PhaseNavigator.adjustedSelection(count + 1, phaseCount: count)
    #expect(adjusted == 1)
  }

  @Test func normalizesSelection() throws {
    let count = Phase.allCases.count
    let index = PhaseNavigator.normalizedIndex(1, phaseCount: count)
    #expect(index == 0)
    let last = PhaseNavigator.normalizedIndex(count, phaseCount: count)
    #expect(last == count - 1)
  }
}
