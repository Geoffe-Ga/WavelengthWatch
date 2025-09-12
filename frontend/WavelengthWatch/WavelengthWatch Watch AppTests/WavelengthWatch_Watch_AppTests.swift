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

  @Test func handlesMissingWithdrawal() {
    let data = StrategyData.load()
    #expect(data[.Withdrawal]?.isEmpty == true)
  }
}

struct HeaderParsingTests {
  @Test func parsesStrategiesHeader() {
    let headers = HeaderData.load()
    #expect(headers["Strategies"]?.title == "Self-Care Strategies")
    #expect(headers["Blue"]?.subtitle == "(Feel)")
  }
}
