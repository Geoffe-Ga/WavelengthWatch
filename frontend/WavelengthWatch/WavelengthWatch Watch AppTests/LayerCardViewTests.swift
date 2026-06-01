import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

/// Shallow construction coverage for the rebuilt `LayerCardView` (#408).
///
/// The card is now an identity-layout page (no `scaleEffect` /
/// `rotation3DEffect` / `offset`), sized via `containerRelativeFrame`. Per
/// the project's view-test philosophy these are construction smoke tests —
/// they pin the simplified init and guard against a regressed dependency
/// surface; the visual "no horizontal bump" property is device-verified.
@MainActor
struct LayerCardViewTests {
  @Test("constructs for a curriculum layer without the removed transform inputs")
  func constructsForCurriculumLayer() {
    let catalog = CatalogTestHelper.createTestCatalog()

    _ = LayerCardView(
      layer: catalog.layers[1],
      phaseCount: catalog.phaseOrder.count,
      selection: .constant(1),
      screenWidth: 180
    )
  }

  @Test("constructs for the strategies layer")
  func constructsForStrategiesLayer() {
    let catalog = CatalogTestHelper.createTestCatalog()

    _ = LayerCardView(
      layer: catalog.layers[0],
      phaseCount: catalog.phaseOrder.count,
      selection: .constant(0),
      screenWidth: 198
    )
  }
}
