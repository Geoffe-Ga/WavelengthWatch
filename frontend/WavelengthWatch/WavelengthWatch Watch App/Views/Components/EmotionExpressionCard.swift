import SwiftUI

/// Shared display card for a single emotion expression with its
/// medicinal / toxic dosage indicator. ViewModel-free; takes a label,
/// the expression text, and the dosage as init parameters.
///
/// Designed to be reusable across browsing (curriculum detail rails),
/// journal selection (flow review), and any future surfaces that need
/// to render a single dosage-tinted expression — see Phase 3b (#298).
///
/// Canonical review card used by the live journal flow (`FlowReviewSheet`).
/// Layout puts the dosage tag *below* the expression for legibility on the
/// narrow watch screen (per #159) rather than crowding it onto the same row.
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
        .tracking(1.2)

      Text(expression)
        .font(.body)
        .fontWeight(.bold)
        .lineLimit(nil)

      HStack(spacing: 6) {
        Circle()
          .fill(dosage == .medicinal ? Color.green : Color.red)
          .frame(width: WLSpacingTokens.indicatorDotMedium, height: WLSpacingTokens.indicatorDotMedium)

        Text(dosage == .medicinal ? "Medicinal" : "Toxic")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .textCase(.uppercase)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(WLSpacingTokens.cardPaddingStandard)
    .wlCardSurface(WLColorTokens.cardFill, cornerRadius: WLSpacingTokens.cardCornerRadiusSmall)
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
