import SwiftUI

/// Shared display card for a single strategy with its color
/// indicator. ViewModel-free; takes a `CatalogStrategyModel` as the
/// only init parameter.
///
/// Designed to be reusable across journal selection (flow review),
/// strategy listing, and any future surfaces that need to render a
/// single tinted strategy — see Phase 3b (#298).
///
/// Rendered by the live journal flow's `FlowReviewSheet`. Named
/// `StrategyExpressionCard` to avoid colliding with
/// `Curriculum/StrategyCard` (a tap-action wrapper) and
/// `Components/StrategySummaryCard` (an analytics aggregate).
struct StrategyExpressionCard: View {
  let label: String
  let strategy: CatalogStrategyModel

  /// - Parameters:
  ///   - label: Section label above the strategy (default "Strategy"), for
  ///     parity with `EmotionExpressionCard`'s `label`.
  ///   - strategy: The strategy to render.
  init(label: String = "Strategy", strategy: CatalogStrategyModel) {
    self.label = label
    self.strategy = strategy
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label)
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
    .wlCardSurface(WLColorTokens.elevatedCardFill, cornerRadius: 10)
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
