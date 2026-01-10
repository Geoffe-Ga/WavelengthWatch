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

  @Test("phaseColor returns green for Rising phase")
  func phaseColor_returnsGreenForRising() {
    let color = PhaseJourneyView.phaseColor(for: "Rising")

    #expect(color == .green)
  }

  @Test("phaseColor returns yellow for Peaking phase")
  func phaseColor_returnsYellowForPeaking() {
    let color = PhaseJourneyView.phaseColor(for: "Peaking")

    #expect(color == .yellow)
  }

  @Test("phaseColor returns orange for Falling phase")
  func phaseColor_returnsOrangeForFalling() {
    let color = PhaseJourneyView.phaseColor(for: "Falling")

    #expect(color == .orange)
  }

  @Test("phaseColor returns blue for Resting phase")
  func phaseColor_returnsBlueForResting() {
    let color = PhaseJourneyView.phaseColor(for: "Resting")

    #expect(color == .blue)
  }

  @Test("phaseColor returns gray for unknown phase")
  func phaseColor_returnsGrayForUnknown() {
    let color = PhaseJourneyView.phaseColor(for: "UnknownPhase")

    #expect(color == .gray)
  }

  @Test("phaseColor is case-insensitive")
  func phaseColor_isCaseInsensitive() {
    #expect(PhaseJourneyView.phaseColor(for: "rising") == .green)
    #expect(PhaseJourneyView.phaseColor(for: "PEAKING") == .yellow)
    #expect(PhaseJourneyView.phaseColor(for: "FaLLiNg") == .orange)
    #expect(PhaseJourneyView.phaseColor(for: "RESTING") == .blue)
  }

  @Test("barChartItems filters out invalid phase IDs")
  func barChartItems_filtersOutInvalidPhaseIds() {
    let distribution = [
      PhaseDistributionItem(phaseId: 1, count: 10, percentage: 50.0),
      PhaseDistributionItem(phaseId: 999, count: 10, percentage: 50.0),
    ]
    let phases = [
      CatalogPhaseModel(id: 1, name: "Rising", medicinal: [], toxic: [], strategies: []),
    ]

    let view = PhaseJourneyView(phaseDistribution: distribution, phases: phases)
    let items = view.barChartItems

    #expect(items.count == 1)
    #expect(items[0].id == "1")
  }

  @Test("barChartItems preserves order from phaseDistribution")
  func barChartItems_preservesOrder() {
    let distribution = [
      PhaseDistributionItem(phaseId: 2, count: 5, percentage: 25.0),
      PhaseDistributionItem(phaseId: 1, count: 15, percentage: 75.0),
    ]
    let phases = [
      CatalogPhaseModel(id: 1, name: "Rising", medicinal: [], toxic: [], strategies: []),
      CatalogPhaseModel(id: 2, name: "Peaking", medicinal: [], toxic: [], strategies: []),
    ]

    let view = PhaseJourneyView(phaseDistribution: distribution, phases: phases)
    let items = view.barChartItems

    #expect(items.count == 2)
    #expect(items[0].id == "2")
    #expect(items[0].label == "Peaking")
    #expect(items[1].id == "1")
    #expect(items[1].label == "Rising")
  }

  @Test("barChartItems applies correct colors based on phase names")
  func barChartItems_appliesCorrectColors() {
    let distribution = [
      PhaseDistributionItem(phaseId: 1, count: 10, percentage: 50.0),
      PhaseDistributionItem(phaseId: 2, count: 10, percentage: 50.0),
    ]
    let phases = [
      CatalogPhaseModel(id: 1, name: "Rising", medicinal: [], toxic: [], strategies: []),
      CatalogPhaseModel(id: 2, name: "Resting", medicinal: [], toxic: [], strategies: []),
    ]

    let view = PhaseJourneyView(phaseDistribution: distribution, phases: phases)
    let items = view.barChartItems

    #expect(items.count == 2)
    #expect(items[0].color == .green)
    #expect(items[1].color == .blue)
  }
}
