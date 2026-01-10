import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("ModeDistributionView Tests")
struct ModeDistributionViewTests {
  @Test("view initializes with empty distribution")
  func view_initializesWithEmptyDistribution() {
    let view = ModeDistributionView(layerDistribution: [], layers: [])

    #expect(view.layerDistribution.isEmpty)
    #expect(view.layers.isEmpty)
  }

  @Test("view initializes with distribution data")
  func view_initializesWithData() {
    let distribution = [
      LayerDistributionItem(layerId: 1, count: 10, percentage: 50.0),
      LayerDistributionItem(layerId: 2, count: 10, percentage: 50.0),
    ]
    let layers = [
      CatalogLayerModel(id: 1, color: "#FF0000", title: "Red", subtitle: "Test", phases: []),
      CatalogLayerModel(id: 2, color: "#00FF00", title: "Green", subtitle: "Test", phases: []),
    ]

    let view = ModeDistributionView(layerDistribution: distribution, layers: layers)

    #expect(view.layerDistribution.count == 2)
    #expect(view.layers.count == 2)
  }

  @Test("Color hex initializer parses valid hex string")
  func color_parsesValidHex() {
    let color1 = Color(hex: "#FF0000")
    let color2 = Color(hex: "00FF00")
    let color3 = Color(hex: "0000FF")

    #expect(color1 != nil)
    #expect(color2 != nil)
    #expect(color3 != nil)
  }

  @Test("Color hex initializer returns nil for invalid hex")
  func color_returnsNilForInvalidHex() {
    let invalidColor = Color(hex: "invalid")

    #expect(invalidColor == nil)
  }
}
