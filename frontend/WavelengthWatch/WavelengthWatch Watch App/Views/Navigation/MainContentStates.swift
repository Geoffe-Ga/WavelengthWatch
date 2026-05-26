import SwiftUI

/// State machine for the main shell's body: catalog loading, load
/// error with retry, empty phase order, or the live layered content.
///
/// Lifts the ~30 lines of `if-else` branching out of `ContentView` so
/// `ContentView` can stay focused on lifecycle, dialogs, and toolbar
/// wiring. Owns no state of its own; reads `viewModel` for the branch
/// selector and forwards `navigationViewModel`'s selection bindings into
/// `LayerScrollView`.
struct MainContentStates: View {
  @ObservedObject var viewModel: ContentViewModel
  @ObservedObject var navigationViewModel: NavigationViewModel

  var body: some View {
    ZStack {
      if viewModel.layers.isEmpty {
        emptyLayersBranch
      } else if viewModel.phaseOrder.isEmpty {
        Text("No phase information available.")
      } else {
        LayerScrollView(
          viewModel: viewModel,
          layerSelection: $navigationViewModel.layerSelection,
          phaseSelection: $navigationViewModel.phaseSelection
        )
      }
    }
  }

  /// Loading / load-error / fallback branch — only reached while the
  /// catalog hasn't populated `viewModel.layers`.
  @ViewBuilder
  private var emptyLayersBranch: some View {
    if viewModel.isLoading {
      ProgressView("Loading curriculum…")
        .foregroundStyle(.white)
    } else if let error = viewModel.loadErrorMessage {
      VStack(spacing: 12) {
        Text(error)
          .multilineTextAlignment(.center)
        Button("Retry") {
          Task { await viewModel.retry() }
        }
      }
      .padding()
    } else {
      ProgressView("Loading curriculum…")
    }
  }
}
