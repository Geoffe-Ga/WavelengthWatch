import SwiftUI

/// Card displayed in `JournalReviewView` for the selected strategy.
/// Shows the strategy name with its color indicator tinted via the
/// catalog model's `color` field.
///
/// Extracted from `JournalReviewView` along with the `colorForStrategy`
/// helper so the review screen's body stays composition-focused.
/// `colorForStrategy` switches on lowercase color names, which matches
/// the catalog's strategy-color casing (distinct from layer-stage names
/// consumed by `Color(stage:)`).
struct JournalReviewStrategyCard: View {
  let strategy: CatalogStrategyModel

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Strategy")
        .font(.caption)
        .foregroundColor(.secondary)
        .textCase(.uppercase)

      HStack {
        Circle()
          .fill(Self.colorForStrategy(strategy.color))
          .frame(width: 10, height: 10)

        Text(strategy.strategy)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(.primary)

        Spacer()
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(WLColorTokens.elevatedCardFill)
    .cornerRadius(10)
  }

  static func colorForStrategy(_ colorName: String) -> Color {
    switch colorName.lowercased() {
    case "blue": .blue
    case "cyan": .cyan
    case "green": .green
    case "yellow": .yellow
    case "orange": .orange
    case "red": .red
    case "purple": .purple
    case "pink": .pink
    default: .gray
    }
  }
}
