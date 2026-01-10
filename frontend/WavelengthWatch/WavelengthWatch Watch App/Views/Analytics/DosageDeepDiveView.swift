import SwiftUI

/// Displays top emotions grouped by dosage type (Medicinal vs Toxic)
struct DosageDeepDiveView: View {
  let topEmotions: [TopEmotionItem]

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Dosage Deep Dive")
        .font(.headline)
        .foregroundColor(.secondary)

      if topEmotions.isEmpty {
        EmptyStateView()
      } else {
        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            // Medicinal section
            if !medicinalEmotions.isEmpty {
              EmotionSection(
                title: "Medicinal",
                emotions: medicinalEmotions,
                dosageColor: Self.dosageColor(for: "Medicinal")
              )
            }

            // Toxic section
            if !toxicEmotions.isEmpty {
              EmotionSection(
                title: "Toxic",
                emotions: toxicEmotions,
                dosageColor: Self.dosageColor(for: "Toxic")
              )
            }
          }
        }
      }
    }
  }

  var medicinalEmotions: [TopEmotionItem] {
    topEmotions.filter { $0.dosage == "Medicinal" }
  }

  var toxicEmotions: [TopEmotionItem] {
    topEmotions.filter { $0.dosage == "Toxic" }
  }

  /// Maps dosage types to colors
  static func dosageColor(for dosage: String) -> Color {
    switch dosage {
    case "Medicinal":
      .green
    case "Toxic":
      .red
    default:
      .gray
    }
  }
}

private struct EmotionSection: View {
  let title: String
  let emotions: [TopEmotionItem]
  let dosageColor: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Circle()
          .fill(dosageColor)
          .frame(width: 8, height: 8)
        Text(title)
          .font(.subheadline)
          .fontWeight(.semibold)
      }

      ForEach(emotions, id: \.curriculumId) { emotion in
        EmotionRow(emotion: emotion)
      }
    }
  }
}

private struct EmotionRow: View {
  let emotion: TopEmotionItem

  var body: some View {
    HStack {
      Text(emotion.expression)
        .font(.caption)
      Spacer()
      Text("\(emotion.count)")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding(.vertical, 4)
    .padding(.horizontal, 8)
    .background(Color.secondary.opacity(0.1))
    .cornerRadius(6)
  }
}

private struct EmptyStateView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "heart.text.square")
        .font(.title)
        .foregroundColor(.secondary)
      Text("No emotions tracked")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
  }
}
