import SwiftUI

/// Shared display card for a single strategy with its color
/// indicator. ViewModel-free; takes a `CatalogStrategyModel` as the
/// only init parameter.
///
/// Designed to be reusable across journal selection (flow review),
/// strategy listing, and any future surfaces that need to render a
/// single tinted strategy — see Phase 3b (#298).
///
/// First call site: `JournalReviewView`. Promoted to `Views/Components/`
/// from its earlier home in `Views/Journal/` so non-journal callers can
/// discover and reuse it. Named `StrategyExpressionCard` to avoid
/// colliding with `Curriculum/StrategyCard` (a tap-action wrapper) and
/// `Components/StrategySummaryCard` (an analytics aggregate).
struct StrategyExpressionCard: View {
  let strategy: CatalogStrategyModel

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Strategy")
        .font(.caption)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      HStack {
        Circle()
          .fill(Color(stage: strategy.color))
          .frame(width: 10, height: 10)

        Text(strategy.strategy)
          .font(.body)
          .fontWeight(.medium)
          .foregroundStyle(.primary)

        Spacer()
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(WLColorTokens.elevatedCardFill)
    .cornerRadius(10)
  }
}

#if DEBUG
#Preview("Strategy Card") {
  StrategyExpressionCard(
    strategy: CatalogStrategyModel(id: 1, strategy: "Take a deep breath", color: "Blue")
  )
  .padding()
  .background(Color.black)
}
#endif
