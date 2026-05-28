import SwiftUI

/// Shared display card for a single emotion expression with its
/// medicinal / toxic dosage indicator. ViewModel-free; takes a label,
/// the expression text, and the dosage as init parameters.
///
/// Designed to be reusable across browsing (curriculum detail rails),
/// journal selection (flow review), and any future surfaces that need
/// to render a single dosage-tinted expression — see Phase 3b (#298).
///
/// First call site: `JournalReviewView`. Promoted to `Views/Components/`
/// from its earlier home in `Views/Journal/` so non-journal callers can
/// discover and reuse it without leaking journal-specific naming.
struct EmotionExpressionCard: View {
  let label: String
  let expression: String
  let dosage: CatalogDosage

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      HStack {
        Circle()
          .fill(dosage == .medicinal ? Color.green : Color.red)
          .frame(width: 10, height: 10)

        Text(expression)
          .font(.body)
          .fontWeight(.medium)
          .foregroundStyle(.primary)

        Spacer()

        Text(dosage == .medicinal ? "Medicinal" : "Toxic")
          .font(.caption)
          .foregroundStyle(.secondary)
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
  EmotionExpressionCard(
    label: "Primary Emotion",
    expression: "Gratitude",
    dosage: .medicinal
  )
  .padding()
  .background(Color.black)
}

#Preview("Emotion Card — Toxic") {
  EmotionExpressionCard(
    label: "Secondary Emotion",
    expression: "Resentment",
    dosage: .toxic
  )
  .padding()
  .background(Color.black)
}
#endif
