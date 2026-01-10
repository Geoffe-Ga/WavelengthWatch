import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("EmotionalLandscape Models Tests")
struct EmotionalLandscapeModelsTests {
  // MARK: - LayerDistributionItem Tests

  @Test("LayerDistributionItem decodes from JSON with snake_case keys")
  func layerDistributionItem_decodesFromJSON() throws {
    let json = """
    {
      "layer_id": 1,
      "count": 10,
      "percentage": 25.5
    }
    """

    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    let item = try decoder.decode(LayerDistributionItem.self, from: data)

    #expect(item.layerId == 1)
    #expect(item.count == 10)
    #expect(item.percentage == 25.5)
  }

  @Test("LayerDistributionItem conforms to Equatable")
  func layerDistributionItem_conformsToEquatable() {
    let item1 = LayerDistributionItem(layerId: 1, count: 10, percentage: 25.0)
    let item2 = LayerDistributionItem(layerId: 1, count: 10, percentage: 25.0)
    let item3 = LayerDistributionItem(layerId: 2, count: 5, percentage: 12.5)

    #expect(item1 == item2)
    #expect(item1 != item3)
  }

  // MARK: - PhaseDistributionItem Tests

  @Test("PhaseDistributionItem decodes from JSON with snake_case keys")
  func phaseDistributionItem_decodesFromJSON() throws {
    let json = """
    {
      "phase_id": 2,
      "count": 15,
      "percentage": 37.5
    }
    """

    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    let item = try decoder.decode(PhaseDistributionItem.self, from: data)

    #expect(item.phaseId == 2)
    #expect(item.count == 15)
    #expect(item.percentage == 37.5)
  }

  @Test("PhaseDistributionItem conforms to Equatable")
  func phaseDistributionItem_conformsToEquatable() {
    let item1 = PhaseDistributionItem(phaseId: 1, count: 5, percentage: 12.5)
    let item2 = PhaseDistributionItem(phaseId: 1, count: 5, percentage: 12.5)
    let item3 = PhaseDistributionItem(phaseId: 2, count: 10, percentage: 25.0)

    #expect(item1 == item2)
    #expect(item1 != item3)
  }

  // MARK: - TopEmotionItem Tests

  @Test("TopEmotionItem decodes from JSON with snake_case keys")
  func topEmotionItem_decodesFromJSON() throws {
    let json = """
    {
      "curriculum_id": 5,
      "expression": "Hopeful",
      "layer_id": 2,
      "phase_id": 1,
      "dosage": "Medicinal",
      "count": 8
    }
    """

    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    let item = try decoder.decode(TopEmotionItem.self, from: data)

    #expect(item.curriculumId == 5)
    #expect(item.expression == "Hopeful")
    #expect(item.layerId == 2)
    #expect(item.phaseId == 1)
    #expect(item.dosage == "Medicinal")
    #expect(item.count == 8)
  }

  @Test("TopEmotionItem conforms to Equatable")
  func topEmotionItem_conformsToEquatable() {
    let item1 = TopEmotionItem(
      curriculumId: 1,
      expression: "Joy",
      layerId: 1,
      phaseId: 1,
      dosage: "Medicinal",
      count: 5
    )
    let item2 = TopEmotionItem(
      curriculumId: 1,
      expression: "Joy",
      layerId: 1,
      phaseId: 1,
      dosage: "Medicinal",
      count: 5
    )
    let item3 = TopEmotionItem(
      curriculumId: 2,
      expression: "Anger",
      layerId: 3,
      phaseId: 2,
      dosage: "Toxic",
      count: 3
    )

    #expect(item1 == item2)
    #expect(item1 != item3)
  }

  // MARK: - EmotionalLandscape Tests

  @Test("EmotionalLandscape decodes from JSON with all components")
  func emotionalLandscape_decodesFromJSON() throws {
    let json = """
    {
      "layer_distribution": [
        {"layer_id": 1, "count": 10, "percentage": 50.0},
        {"layer_id": 2, "count": 10, "percentage": 50.0}
      ],
      "phase_distribution": [
        {"phase_id": 1, "count": 15, "percentage": 75.0},
        {"phase_id": 2, "count": 5, "percentage": 25.0}
      ],
      "top_emotions": [
        {
          "curriculum_id": 1,
          "expression": "Joy",
          "layer_id": 1,
          "phase_id": 1,
          "dosage": "Medicinal",
          "count": 8
        }
      ]
    }
    """

    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    let landscape = try decoder.decode(EmotionalLandscape.self, from: data)

    #expect(landscape.layerDistribution.count == 2)
    #expect(landscape.phaseDistribution.count == 2)
    #expect(landscape.topEmotions.count == 1)

    #expect(landscape.layerDistribution[0].layerId == 1)
    #expect(landscape.phaseDistribution[0].phaseId == 1)
    #expect(landscape.topEmotions[0].expression == "Joy")
  }

  @Test("EmotionalLandscape conforms to Equatable")
  func emotionalLandscape_conformsToEquatable() {
    let layer1 = LayerDistributionItem(layerId: 1, count: 10, percentage: 50.0)
    let phase1 = PhaseDistributionItem(phaseId: 1, count: 10, percentage: 50.0)
    let emotion1 = TopEmotionItem(
      curriculumId: 1,
      expression: "Joy",
      layerId: 1,
      phaseId: 1,
      dosage: "Medicinal",
      count: 5
    )

    let landscape1 = EmotionalLandscape(
      layerDistribution: [layer1],
      phaseDistribution: [phase1],
      topEmotions: [emotion1]
    )

    let landscape2 = EmotionalLandscape(
      layerDistribution: [layer1],
      phaseDistribution: [phase1],
      topEmotions: [emotion1]
    )

    let landscape3 = EmotionalLandscape(
      layerDistribution: [],
      phaseDistribution: [],
      topEmotions: []
    )

    #expect(landscape1 == landscape2)
    #expect(landscape1 != landscape3)
  }

  @Test("EmotionalLandscape handles empty arrays")
  func emotionalLandscape_handlesEmptyArrays() throws {
    let json = """
    {
      "layer_distribution": [],
      "phase_distribution": [],
      "top_emotions": []
    }
    """

    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    let landscape = try decoder.decode(EmotionalLandscape.self, from: data)

    #expect(landscape.layerDistribution.isEmpty)
    #expect(landscape.phaseDistribution.isEmpty)
    #expect(landscape.topEmotions.isEmpty)
  }
}
