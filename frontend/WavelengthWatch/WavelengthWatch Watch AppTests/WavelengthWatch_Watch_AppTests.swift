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

  @Test func parsesLayerHeader() throws {
    let headers = HeaderData.load()
    let strategiesHeader = headers["Strategies"]
    #expect(strategiesHeader?.subtitle == "(For Surfing)")
  }
}
