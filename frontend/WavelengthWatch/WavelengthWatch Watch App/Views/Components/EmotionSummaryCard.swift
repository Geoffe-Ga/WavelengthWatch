import SwiftUI

/// A reusable card component for displaying selected emotion entries in the journal flow.
///
/// This card shows a curriculum entry (emotion) with optional layer and phase context.
/// It supports both standard and compact display modes for different UI contexts.
///
/// ## Usage
/// ```swift
/// // Full context display
/// EmotionSummaryCard(
///   curriculum: selectedEmotion,
///   layer: emotionLayer,
///   phase: emotionPhase
/// )
///
/// // Compact mode for flow step headers
/// EmotionSummaryCard(
///   curriculum: selectedEmotion,
///   layer: emotionLayer,
///   phase: emotionPhase,
///   compact: true
/// )
/// ```
struct EmotionSummaryCard: View {
  let curriculum: CatalogCurriculumEntryModel
  let layer: CatalogLayerModel?
  let phase: CatalogPhaseModel?
  var compact: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: compact ? 2 : 4) {
      // Layer context (if provided)
      if let layer {
        Text(layer.title)
          .font(compact ? .caption2 : .caption)
          .foregroundColor(.secondary)
          .textCase(.uppercase)
          .tracking(1.2)
      }

      // Phase context (if provided)
      if let phase {
        Text(phase.name)
          .font(compact ? .caption : .body)
          .fontWeight(.medium)
      }

      // Expression (main content)
      Text(curriculum.expression)
        .font(compact ? .body : .title3)
        .fontWeight(.bold)
        .lineLimit(compact ? 2 : nil)

      // Dosage indicator
      HStack(spacing: 4) {
        Circle()
          .fill(dosageColor)
          .frame(width: 6, height: 6)

        Text(curriculum.dosage.rawValue)
          .font(.caption2)
          .foregroundColor(.secondary)
          .textCase(.uppercase)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(compact ? 8 : 12)
    .background(
      RoundedRectangle(cornerRadius: compact ? 6 : 8)
        .fill(Color.secondary.opacity(0.15))
    )
  }

  /// Returns the appropriate color for the dosage indicator
  private var dosageColor: Color {
    switch curriculum.dosage {
    case .medicinal:
      .green
    case .toxic:
      .red
    }
  }
}

// MARK: - Previews

#Preview("Medicinal - Full Context") {
  EmotionSummaryCard(
    curriculum: CatalogCurriculumEntryModel(
      id: 1,
      dosage: .medicinal,
      expression: "Confident"
    ),
    layer: CatalogLayerModel(
      id: 3,
      color: "Red",
      title: "Red",
      subtitle: "Power",
      phases: []
    ),
    phase: CatalogPhaseModel(
      id: 2,
      name: "Rising",
      medicinal: [],
      toxic: [],
      strategies: []
    )
  )
  .padding()
  .previewDisplayName("Medicinal - Full")
}

#Preview("Toxic - Compact") {
  EmotionSummaryCard(
    curriculum: CatalogCurriculumEntryModel(
      id: 2,
      dosage: .toxic,
      expression: "Aggressive and Domineering"
    ),
    layer: CatalogLayerModel(
      id: 3,
      color: "Red",
      title: "Red",
      subtitle: "Power",
      phases: []
    ),
    phase: CatalogPhaseModel(
      id: 2,
      name: "Peaking",
      medicinal: [],
      toxic: [],
      strategies: []
    ),
    compact: true
  )
  .padding()
  .previewDisplayName("Toxic - Compact")
}

#Preview("Minimal - No Context") {
  EmotionSummaryCard(
    curriculum: CatalogCurriculumEntryModel(
      id: 3,
      dosage: .medicinal,
      expression: "Peaceful"
    ),
    layer: nil,
    phase: nil
  )
  .padding()
  .previewDisplayName("No Context")
}
