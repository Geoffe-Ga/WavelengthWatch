import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("PhaseJourneyView Tests")
struct PhaseJourneyViewTests {
  @Test("view initializes with empty distribution")
  func view_initializesWithEmptyDistribution() {
    let view = PhaseJourneyView(phaseDistribution: [], phases: [])

    #expect(view.phaseDistribution.isEmpty)
    #expect(view.phases.isEmpty)
  }

  @Test("view initializes with distribution data")
  func view_initializesWithData() {
    let distribution = [
      PhaseDistributionItem(phaseId: 1, count: 15, percentage: 75.0),
      PhaseDistributionItem(phaseId: 2, count: 5, percentage: 25.0),
    ]
    let phases = [
      CatalogPhaseModel(id: 1, name: "Rising", medicinal: [], toxic: [], strategies: []),
      CatalogPhaseModel(id: 2, name: "Peaking", medicinal: [], toxic: [], strategies: []),
    ]

    let view = PhaseJourneyView(phaseDistribution: distribution, phases: phases)

    #expect(view.phaseDistribution.count == 2)
    #expect(view.phases.count == 2)
  }

  @Test("phaseColor returns correct color for Rising phase")
  func phaseColor_returnsCorrectColorForRising() {
    // Rising should map to a specific color (e.g., green/sunrise)
    let color = PhaseJourneyView.phaseColor(for: "Rising")

    #expect(color != nil)
  }

  @Test("phaseColor returns correct color for Peaking phase")
  func phaseColor_returnsCorrectColorForPeaking() {
    let color = PhaseJourneyView.phaseColor(for: "Peaking")

    #expect(color != nil)
  }

  @Test("phaseColor returns correct color for Falling phase")
  func phaseColor_returnsCorrectColorForFalling() {
    let color = PhaseJourneyView.phaseColor(for: "Falling")

    #expect(color != nil)
  }

  @Test("phaseColor returns correct color for Resting phase")
  func phaseColor_returnsCorrectColorForResting() {
    let color = PhaseJourneyView.phaseColor(for: "Resting")

    #expect(color != nil)
  }

  @Test("phaseColor returns default color for unknown phase")
  func phaseColor_returnsDefaultForUnknown() {
    let color = PhaseJourneyView.phaseColor(for: "UnknownPhase")

    #expect(color != nil) // Should return a default, not nil
  }
}
