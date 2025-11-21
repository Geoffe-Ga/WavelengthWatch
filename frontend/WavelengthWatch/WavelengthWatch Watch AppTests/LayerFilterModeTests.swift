import Testing
@testable import WavelengthWatch_Watch_App

@Suite("LayerFilterMode Tests")
struct LayerFilterModeTests {
  // MARK: - Test Data

  private func makeMockLayers() -> [CatalogLayerModel] {
    [
      CatalogLayerModel(
        id: 0,
        color: "Strategies",
        title: "Self-Care",
        subtitle: "Strategies",
        phases: []
      ),
      CatalogLayerModel(
        id: 1,
        color: "Beige",
        title: "Beige",
        subtitle: "Survival",
        phases: []
      ),
      CatalogLayerModel(
        id: 2,
        color: "Purple",
        title: "Purple",
        subtitle: "Tribal",
        phases: []
      ),
      CatalogLayerModel(
        id: 3,
        color: "Red",
        title: "Red",
        subtitle: "Power",
        phases: []
      ),
    ]
  }

  // MARK: - Filter All Tests

  @Test("filter all returns all layers")
  func filterAll_returnsAllLayers() {
    let layers = makeMockLayers()
    let filtered = LayerFilterMode.all.filter(layers)

    #expect(filtered.count == 4)
    #expect(filtered[0].id == 0)
    #expect(filtered[1].id == 1)
    #expect(filtered[2].id == 2)
    #expect(filtered[3].id == 3)
  }

  // MARK: - Emotions Only Tests

  @Test("filter emotionsOnly excludes layer zero")
  func filterEmotionsOnly_excludesLayerZero() {
    let layers = makeMockLayers()
    let filtered = LayerFilterMode.emotionsOnly.filter(layers)

    #expect(!filtered.contains { $0.id == 0 })
  }

  @Test("filter emotionsOnly includes layers one to ten")
  func filterEmotionsOnly_includesLayersOneToTen() {
    let layers = makeMockLayers()
    let filtered = LayerFilterMode.emotionsOnly.filter(layers)

    #expect(filtered.count == 3)
    #expect(filtered[0].id == 1)
    #expect(filtered[1].id == 2)
    #expect(filtered[2].id == 3)
  }

  @Test("filter emotionsOnly with empty array returns empty")
  func filterEmotionsOnly_withEmptyArray_returnsEmpty() {
    let layers: [CatalogLayerModel] = []
    let filtered = LayerFilterMode.emotionsOnly.filter(layers)

    #expect(filtered.isEmpty)
  }

  // MARK: - Strategies Only Tests

  @Test("filter strategiesOnly includes only layer zero")
  func filterStrategiesOnly_includesOnlyLayerZero() {
    let layers = makeMockLayers()
    let filtered = LayerFilterMode.strategiesOnly.filter(layers)

    #expect(filtered.count == 1)
    #expect(filtered[0].id == 0)
  }

  @Test("filter strategiesOnly excludes other layers")
  func filterStrategiesOnly_excludesOtherLayers() {
    let layers = makeMockLayers()
    let filtered = LayerFilterMode.strategiesOnly.filter(layers)

    #expect(!filtered.contains { $0.id > 0 })
  }

  // MARK: - Equatable Tests

  @Test("equatable same modes are equal")
  func equatable_sameModesAreEqual() {
    #expect(LayerFilterMode.all == LayerFilterMode.all)
    #expect(LayerFilterMode.emotionsOnly == LayerFilterMode.emotionsOnly)
    #expect(LayerFilterMode.strategiesOnly == LayerFilterMode.strategiesOnly)
  }

  @Test("equatable different modes are not equal")
  func equatable_differentModesAreNotEqual() {
    #expect(LayerFilterMode.all != LayerFilterMode.emotionsOnly)
    #expect(LayerFilterMode.emotionsOnly != LayerFilterMode.strategiesOnly)
    #expect(LayerFilterMode.strategiesOnly != LayerFilterMode.all)
  }
}
