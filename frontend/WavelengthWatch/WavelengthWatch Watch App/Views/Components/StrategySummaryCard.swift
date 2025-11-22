import SwiftUI

/// A reusable card component for displaying selected strategies in the journal flow.
///
/// This card shows a strategy with its color indicator.
/// It supports both standard and compact display modes for different UI contexts.
///
/// ## Usage
/// ```swift
/// // Standard display
/// StrategySummaryCard(strategy: selectedStrategy)
///
/// // Compact mode for flow step headers
/// StrategySummaryCard(strategy: selectedStrategy, compact: true)
/// ```
struct StrategySummaryCard: View {
  let strategy: CatalogStrategyModel
  var compact: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: compact ? 2 : 4) {
      // Strategy text (main content)
      Text(strategy.strategy)
        .font(compact ? .body : .title3)
        .fontWeight(.bold)
        .lineLimit(compact ? 2 : nil)

      // Color indicator
      HStack(spacing: 4) {
        Circle()
          .fill(strategyColor)
          .frame(width: 6, height: 6)

        Text(strategy.color)
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

  /// Returns the appropriate color for the strategy indicator
  private var strategyColor: Color {
    Color(stage: strategy.color)
  }
}

// MARK: - Previews

#Preview("Blue Strategy - Standard") {
  StrategySummaryCard(
    strategy: CatalogStrategyModel(
      id: 1,
      strategy: "Cold Shower",
      color: "Blue"
    )
  )
  .padding()
  .previewDisplayName("Standard")
}

#Preview("Orange Strategy - Compact") {
  StrategySummaryCard(
    strategy: CatalogStrategyModel(
      id: 2,
      strategy: "Exercise or Physical Movement",
      color: "Orange"
    ),
    compact: true
  )
  .padding()
  .previewDisplayName("Compact")
}

#Preview("Green Strategy") {
  StrategySummaryCard(
    strategy: CatalogStrategyModel(
      id: 3,
      strategy: "Meditation",
      color: "Green"
    )
  )
  .padding()
  .previewDisplayName("Green")
}
