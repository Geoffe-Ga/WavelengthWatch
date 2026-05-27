import SwiftUI

/// Card displayed in `JournalReviewView` for each selected emotion
/// (primary or secondary). Shows the label, expression, and a
/// medicinal/toxic indicator with matching tint.
///
/// Extracted from `JournalReviewView` so the review screen's body
/// reads as composition rather than inline form-building.
struct JournalReviewEmotionCard: View {
  let label: String
  let expression: String
  let dosage: CatalogDosage

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label)
        .font(.caption)
        .foregroundColor(.secondary)
        .textCase(.uppercase)

      HStack {
        Circle()
          .fill(dosage == .medicinal ? Color.green : Color.red)
          .frame(width: 10, height: 10)

        Text(expression)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(.primary)

        Spacer()

        Text(dosage == .medicinal ? "Medicinal" : "Toxic")
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(WLColorTokens.elevatedCardFill)
    .cornerRadius(10)
  }
}

#if DEBUG
#Preview("Emotion Card — Medicinal") {
  JournalReviewEmotionCard(
    label: "Primary Emotion",
    expression: "Gratitude",
    dosage: .medicinal
  )
  .padding()
  .background(Color.black)
}

#Preview("Emotion Card — Toxic") {
  JournalReviewEmotionCard(
    label: "Secondary Emotion",
    expression: "Resentment",
    dosage: .toxic
  )
  .padding()
  .background(Color.black)
}
#endif
