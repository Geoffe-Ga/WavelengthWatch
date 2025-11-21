import SwiftUI
import Testing

@testable import WavelengthWatch_Watch_App

@MainActor
struct FilteredLayerNavigationViewTests {
  private func createTestLayers(count: Int) -> [CatalogLayerModel] {
    let phase = CatalogPhaseModel(
      id: 0,
      name: "Test Phase",
      medicinal: [],
      toxic: [],
      strategies: []
    )

    return (0 ..< count).map { index in
      CatalogLayerModel(
        id: index,
        color: "Test\(index)",
        title: "Layer \(index)",
        subtitle: "Subtitle \(index)",
        phases: [phase]
      )
    }
  }

  @Test func initializesWithProvidedLayers() {
    let layers = createTestLayers(count: 3)
    let phaseOrder = ["Phase1", "Phase2"]
    let selectedLayer = Binding.constant(0)
    let selectedPhase = Binding.constant(0)

    let view = FilteredLayerNavigationView(
      layers: layers,
      phaseOrder: phaseOrder,
      selectedLayerIndex: selectedLayer,
      selectedPhaseIndex: selectedPhase,
      onPhaseCardTap: {}
    )

    #expect(view.layers.count == 3)
    #expect(view.phaseOrder.count == 2)
  }

  @Test func displaysAllProvidedLayers() {
    let layers = createTestLayers(count: 5)
    let selectedLayer = Binding.constant(0)
    let selectedPhase = Binding.constant(0)

    let view = FilteredLayerNavigationView(
      layers: layers,
      phaseOrder: ["Phase1"],
      selectedLayerIndex: selectedLayer,
      selectedPhaseIndex: selectedPhase,
      onPhaseCardTap: {}
    )

    #expect(view.layers.count == 5)
    #expect(view.layers[0].id == 0)
    #expect(view.layers[4].id == 4)
  }

  @Test func worksWithEmotionsOnlyFilter() {
    let allLayers = createTestLayers(count: 11)
    let emotionLayers = allLayers.filter { $0.id >= 1 }
    let selectedLayer = Binding.constant(0)
    let selectedPhase = Binding.constant(0)

    let view = FilteredLayerNavigationView(
      layers: emotionLayers,
      phaseOrder: ["Phase1"],
      selectedLayerIndex: selectedLayer,
      selectedPhaseIndex: selectedPhase,
      onPhaseCardTap: {}
    )

    #expect(view.layers.count == 10)
    #expect(view.layers.allSatisfy { $0.id >= 1 })
  }

  @Test func worksWithStrategiesOnlyFilter() {
    let allLayers = createTestLayers(count: 11)
    let strategyLayers = allLayers.filter { $0.id == 0 }
    let selectedLayer = Binding.constant(0)
    let selectedPhase = Binding.constant(0)

    let view = FilteredLayerNavigationView(
      layers: strategyLayers,
      phaseOrder: ["Phase1"],
      selectedLayerIndex: selectedLayer,
      selectedPhaseIndex: selectedPhase,
      onPhaseCardTap: {}
    )

    #expect(view.layers.count == 1)
    #expect(view.layers[0].id == 0)
  }

  @Test func layerSelectionBindingWorks() {
    let layers = createTestLayers(count: 3)
    var selectedLayerValue = 0
    let selectedLayer = Binding(
      get: { selectedLayerValue },
      set: { selectedLayerValue = $0 }
    )
    let selectedPhase = Binding.constant(0)

    let view = FilteredLayerNavigationView(
      layers: layers,
      phaseOrder: ["Phase1"],
      selectedLayerIndex: selectedLayer,
      selectedPhaseIndex: selectedPhase,
      onPhaseCardTap: {}
    )

    #expect(selectedLayerValue == 0)

    selectedLayer.wrappedValue = 2
    #expect(selectedLayerValue == 2)
  }

  @Test func phaseSelectionBindingWorks() {
    let layers = createTestLayers(count: 3)
    let selectedLayer = Binding.constant(0)
    var selectedPhaseValue = 0
    let selectedPhase = Binding(
      get: { selectedPhaseValue },
      set: { selectedPhaseValue = $0 }
    )

    let view = FilteredLayerNavigationView(
      layers: layers,
      phaseOrder: ["Phase1", "Phase2", "Phase3"],
      selectedLayerIndex: selectedLayer,
      selectedPhaseIndex: selectedPhase,
      onPhaseCardTap: {}
    )

    #expect(selectedPhaseValue == 0)

    selectedPhase.wrappedValue = 1
    #expect(selectedPhaseValue == 1)
  }

  @Test func tapCallbackIsProvided() {
    let layers = createTestLayers(count: 1)
    var tapCallbackInvoked = false

    let view = FilteredLayerNavigationView(
      layers: layers,
      phaseOrder: ["Phase1"],
      selectedLayerIndex: Binding.constant(0),
      selectedPhaseIndex: Binding.constant(0),
      onPhaseCardTap: {
        tapCallbackInvoked = true
      }
    )

    view.onPhaseCardTap()
    #expect(tapCallbackInvoked == true)
  }

  @Test func handlesEmptyLayerArray() {
    let layers: [CatalogLayerModel] = []
    let selectedLayer = Binding.constant(0)
    let selectedPhase = Binding.constant(0)

    let view = FilteredLayerNavigationView(
      layers: layers,
      phaseOrder: ["Phase1"],
      selectedLayerIndex: selectedLayer,
      selectedPhaseIndex: selectedPhase,
      onPhaseCardTap: {}
    )

    #expect(view.layers.isEmpty)
  }

  @Test func handlesEmptyPhaseOrder() {
    let layers = createTestLayers(count: 2)
    let selectedLayer = Binding.constant(0)
    let selectedPhase = Binding.constant(0)

    let view = FilteredLayerNavigationView(
      layers: layers,
      phaseOrder: [],
      selectedLayerIndex: selectedLayer,
      selectedPhaseIndex: selectedPhase,
      onPhaseCardTap: {}
    )

    #expect(view.phaseOrder.isEmpty)
  }
}
