import Testing
@testable import WavelengthWatch_Watch_App

/// Coverage for `DetailDestination.forPhase(in:phase:)` — the routing the single
/// hoisted navigation chevron relies on (#457). The strategies layer (id 0)
/// must reach the strategy list; every other layer reaches its curriculum.
struct DetailDestinationTests {
  private let phase = CatalogPhaseModel(
    id: 1, name: "Rising", medicinal: [], toxic: [], strategies: []
  )

  private func layer(id: Int) -> CatalogLayerModel {
    CatalogLayerModel(id: id, color: "Red", title: "T", subtitle: "S", phases: [phase])
  }

  @Test("the strategies layer (id 0) routes to a strategy destination")
  func strategiesLayerRoutesToStrategy() {
    let destination = DetailDestination.forPhase(in: layer(id: 0), phase: phase)
    #expect(destination == .strategy(phase: phase, colorName: "Red"))
  }

  @Test("any non-strategies layer routes to a curriculum destination")
  func emotionLayerRoutesToCurriculum() {
    let emotionLayer = layer(id: 5)
    let destination = DetailDestination.forPhase(in: emotionLayer, phase: phase)
    #expect(destination == .curriculum(layer: emotionLayer, phase: phase, colorName: "Red"))
  }

  @Test("strategiesLayerID is 0 — the data contract the routing relies on")
  func strategiesLayerID_isZero() {
    // Guards the routing: if this drifts from the catalog's strategies-layer id,
    // `forPhase` would silently send layer 0 to a curriculum and vice versa.
    #expect(CatalogLayerModel.strategiesLayerID == 0)
  }
}
