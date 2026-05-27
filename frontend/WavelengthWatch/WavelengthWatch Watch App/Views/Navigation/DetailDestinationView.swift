import SwiftUI

/// Routes a `DetailDestination` enum case to the appropriate detail
/// view. Lifted out of `ContentView.body` so the navigation destination
/// configuration stays a one-line `.navigationDestination(for:)` call.
struct DetailDestinationView: View {
  let destination: DetailDestination

  var body: some View {
    switch destination {
    case let .curriculum(layer, phase, colorName):
      CurriculumDetailView(layer: layer, phase: phase, color: Color(stage: colorName))
    case let .strategy(phase, colorName):
      StrategyListView(phase: phase, color: Color(stage: colorName))
    }
  }
}
