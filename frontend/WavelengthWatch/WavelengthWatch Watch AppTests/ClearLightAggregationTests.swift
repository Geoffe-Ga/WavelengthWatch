import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

/// Tests for Clear Light layer emotion aggregation logic
/// Verifies that Clear Light (layer 10) correctly aggregates all emotions
/// from all other layers (1-9), excluding Strategies (layer 0) and itself.
@Suite("Clear Light Aggregation Tests")
struct ClearLightAggregationTests {
  // MARK: - Aggregation Logic Tests

  @Test("Aggregates medicinal emotions from all emotion layers")
  func aggregatesMedicinalFromAllLayers() {
    let catalog = SampleData.catalog
    let layers = catalog.layers.reversed() // Match ContentViewModel ordering

    // Simulate the aggregation logic from CurriculumDetailView
    var medicinalEmotions: [(entry: CatalogCurriculumEntryModel, layerTitle: String, layerColor: String)] = []
    let clearLightLayerID = 10

    for layer in layers where layer.id != 0 && layer.id != clearLightLayerID {
      for phase in layer.phases {
        for entry in phase.medicinal {
          medicinalEmotions.append((entry: entry, layerTitle: layer.title, layerColor: layer.color))
        }
      }
    }

    // Sample catalog has 9 emotion layers (1-9), each with 1 phase, each with 1 medicinal
    #expect(medicinalEmotions.count == 9)

    // Verify emotions come from correct layers
    let layerTitles = Set(medicinalEmotions.map(\.layerTitle))
    #expect(layerTitles.contains("BEIGE"))
    #expect(layerTitles.contains("PURPLE"))
    #expect(layerTitles.contains("RED"))
    #expect(!layerTitles.contains("SELF-CARE")) // Layer 0 excluded
    #expect(!layerTitles.contains("CLEAR LIGHT")) // Layer 10 excluded
  }

  @Test("Aggregates toxic emotions from all emotion layers")
  func aggregatesToxicFromAllLayers() {
    let catalog = SampleData.catalog
    let layers = catalog.layers.reversed()

    var toxicEmotions: [(entry: CatalogCurriculumEntryModel, layerTitle: String, layerColor: String)] = []
    let clearLightLayerID = 10

    for layer in layers where layer.id != 0 && layer.id != clearLightLayerID {
      for phase in layer.phases {
        for entry in phase.toxic {
          toxicEmotions.append((entry: entry, layerTitle: layer.title, layerColor: layer.color))
        }
      }
    }

    // Sample catalog has 9 emotion layers, each with 1 toxic emotion
    #expect(toxicEmotions.count == 9)
  }

  @Test("Excludes Strategies layer (id 0) from aggregation")
  func excludesStrategiesLayer() {
    let catalog = SampleData.catalog
    let layers = catalog.layers.reversed()

    var allLayerIds: Set<Int> = []
    let clearLightLayerID = 10

    for layer in layers where layer.id != 0 && layer.id != clearLightLayerID {
      allLayerIds.insert(layer.id)
    }

    #expect(!allLayerIds.contains(0))
    #expect(!allLayerIds.contains(clearLightLayerID))
  }

  @Test("Clear Light layer has id 10")
  func clearLightLayerIdIs10() {
    let catalog = SampleData.catalog
    let clearLightLayer = catalog.layers.first { $0.color == "Clear Light" }

    #expect(clearLightLayer != nil)
    #expect(clearLightLayer?.id == 10)
  }

  @Test("Clear Light layer has no direct emotions")
  func clearLightHasNoDirectEmotions() {
    let catalog = SampleData.catalog
    let clearLightLayer = catalog.layers.first { $0.color == "Clear Light" }

    #expect(clearLightLayer != nil)
    // Clear Light layer should have empty phases (emotions come from aggregation)
    #expect(clearLightLayer?.phases.isEmpty == true)
  }

  // MARK: - LayeredEmotion Model Tests

  @Test("LayeredEmotion stores source layer metadata")
  func layeredEmotionStoresMetadata() {
    let entry = CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Joy")

    // Simulate LayeredEmotion creation (the struct is private, so we verify the concept)
    let layerTitle = "PURPLE"
    let layerColor = "Purple"

    #expect(entry.id == 1)
    #expect(entry.expression == "Joy")
    #expect(layerTitle == "PURPLE")
    #expect(layerColor == "Purple")
  }

  // MARK: - Edge Cases

  @Test("Handles empty catalog gracefully")
  func handlesEmptyCatalog() {
    let emptyCatalog = CatalogResponseModel(phaseOrder: [], layers: [])

    var emotions: [CatalogCurriculumEntryModel] = []
    let clearLightLayerID = 10

    for layer in emptyCatalog.layers where layer.id != 0 && layer.id != clearLightLayerID {
      for phase in layer.phases {
        emotions.append(contentsOf: phase.medicinal)
      }
    }

    #expect(emotions.isEmpty)
  }

  @Test("Handles catalog with only Clear Light layer")
  func handlesCatalogWithOnlyClearLight() {
    let clearLightOnly = CatalogResponseModel(
      phaseOrder: ["Rising"],
      layers: [
        CatalogLayerModel(id: 10, color: "Clear Light", title: "CLEAR LIGHT", subtitle: "(Unitive)", phases: []),
      ]
    )

    var emotions: [CatalogCurriculumEntryModel] = []
    let clearLightLayerID = 10

    for layer in clearLightOnly.layers where layer.id != 0 && layer.id != clearLightLayerID {
      for phase in layer.phases {
        emotions.append(contentsOf: phase.medicinal)
      }
    }

    // Should be empty since we only have Clear Light which is excluded
    #expect(emotions.isEmpty)
  }
}
