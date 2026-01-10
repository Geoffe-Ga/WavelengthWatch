import SwiftUI

/// Displays mode (layer) distribution using a horizontal bar chart
struct ModeDistributionView: View {
  let layerDistribution: [LayerDistributionItem]
  let layers: [CatalogLayerModel]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Mode Distribution")
        .font(.headline)
        .foregroundColor(.secondary)

      if layerDistribution.isEmpty {
        EmptyStateView()
      } else {
        HorizontalBarChart(items: barChartItems)
      }
    }
  }

  private var barChartItems: [HorizontalBarChart.BarChartItem] {
    layerDistribution.compactMap { item in
      guard let layer = layers.first(where: { $0.id == item.layerId }) else {
        return nil
      }

      return HorizontalBarChart.BarChartItem(
        id: "\(item.layerId)",
        label: layer.title,
        percentage: item.percentage,
        color: Color(hex: layer.color) ?? .gray
      )
    }
  }
}

private struct EmptyStateView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "chart.bar.xaxis")
        .font(.title)
        .foregroundColor(.secondary)
      Text("No data")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
  }
}

// MARK: - Color Hex Extension

extension Color {
  init?(hex: String) {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

    var rgb: UInt64 = 0

    guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
      return nil
    }

    let r = Double((rgb & 0xFF0000) >> 16) / 255.0
    let g = Double((rgb & 0x00FF00) >> 8) / 255.0
    let b = Double(rgb & 0x0000FF) / 255.0

    self.init(red: r, green: g, blue: b)
  }
}
