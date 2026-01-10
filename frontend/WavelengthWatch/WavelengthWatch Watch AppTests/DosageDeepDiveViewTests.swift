import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("DosageDeepDiveView Tests")
struct DosageDeepDiveViewTests {
  @Test("view initializes with empty emotions list")
  func view_initializesWithEmptyList() {
    let view = DosageDeepDiveView(topEmotions: [])

    #expect(view.topEmotions.isEmpty)
  }

  @Test("view initializes with emotions data")
  func view_initializesWithData() {
    let emotions = [
      TopEmotionItem(
        curriculumId: 1,
        expression: "Joy",
        layerId: 1,
        phaseId: 1,
        dosage: "Medicinal",
        count: 8
      ),
      TopEmotionItem(
        curriculumId: 2,
        expression: "Anger",
        layerId: 3,
        phaseId: 2,
        dosage: "Toxic",
        count: 3
      ),
    ]

    let view = DosageDeepDiveView(topEmotions: emotions)

    #expect(view.topEmotions.count == 2)
  }

  @Test("medicinalEmotions filters correctly")
  func medicinalEmotions_filtersCorrectly() {
    let emotions = [
      TopEmotionItem(
        curriculumId: 1,
        expression: "Joy",
        layerId: 1,
        phaseId: 1,
        dosage: "Medicinal",
        count: 8
      ),
      TopEmotionItem(
        curriculumId: 2,
        expression: "Anger",
        layerId: 3,
        phaseId: 2,
        dosage: "Toxic",
        count: 3
      ),
      TopEmotionItem(
        curriculumId: 3,
        expression: "Hope",
        layerId: 2,
        phaseId: 1,
        dosage: "Medicinal",
        count: 5
      ),
    ]

    let view = DosageDeepDiveView(topEmotions: emotions)
    let medicinal = view.medicinalEmotions

    #expect(medicinal.count == 2)
    #expect(medicinal.allSatisfy { $0.dosage == "Medicinal" })
  }

  @Test("toxicEmotions filters correctly")
  func toxicEmotions_filtersCorrectly() {
    let emotions = [
      TopEmotionItem(
        curriculumId: 1,
        expression: "Joy",
        layerId: 1,
        phaseId: 1,
        dosage: "Medicinal",
        count: 8
      ),
      TopEmotionItem(
        curriculumId: 2,
        expression: "Anger",
        layerId: 3,
        phaseId: 2,
        dosage: "Toxic",
        count: 3
      ),
      TopEmotionItem(
        curriculumId: 4,
        expression: "Fear",
        layerId: 4,
        phaseId: 2,
        dosage: "Toxic",
        count: 2
      ),
    ]

    let view = DosageDeepDiveView(topEmotions: emotions)
    let toxic = view.toxicEmotions

    #expect(toxic.count == 2)
    #expect(toxic.allSatisfy { $0.dosage == "Toxic" })
  }

  @Test("dosageColor returns green for Medicinal")
  func dosageColor_returnsGreenForMedicinal() {
    let color = DosageDeepDiveView.dosageColor(for: "Medicinal")

    #expect(color == .green)
  }

  @Test("dosageColor returns red for Toxic")
  func dosageColor_returnsRedForToxic() {
    let color = DosageDeepDiveView.dosageColor(for: "Toxic")

    #expect(color == .red)
  }

  @Test("dosageColor returns gray for unknown dosage")
  func dosageColor_returnsGrayForUnknown() {
    let color = DosageDeepDiveView.dosageColor(for: "Unknown")

    #expect(color == .gray)
  }
}
