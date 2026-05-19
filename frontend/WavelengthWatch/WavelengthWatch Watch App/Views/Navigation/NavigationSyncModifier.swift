import SwiftUI

/// Keeps the dual-axis navigation state (`layerSelection` / `phaseSelection`
/// in the view, plus the AppStorage-backed persistence values) synchronized
/// with the ground-truth IDs and indices that `ContentViewModel` exposes.
///
/// SwiftUI's `@State` and `ContentViewModel`'s `@Published` properties form
/// two parallel state machines for the same conceptual values — selected
/// layer, selected phase. This modifier handles the six observer paths that
/// reconcile them whenever either side moves:
///
/// 1. `phaseOrder` changes → re-normalize the offset-by-one phase selection.
/// 2. `layerSelection` (filtered index) changes → write the layer ID and
///    full-array index back to the view model + AppStorage.
/// 3. `selectedLayerId` changes → mirror it back into the filtered index.
/// 4. `layerFilterMode` changes → re-derive the filtered index for the
///    currently-selected layer (or clamp to valid range).
/// 5. `phaseSelection` changes → normalize the infinite-scroll offset and
///    write the canonical index to the view model + AppStorage.
/// 6. `selectedPhaseIndex` changes → mirror it back as the offset value.
///
/// Phase 2b (#296) will refactor `PhaseNavigator` and the layer filtering
/// system, at which point this modifier collapses into a proper
/// `NavigationViewModel`. For now it isolates the synchronization noise
/// from `ContentView`'s body.
struct NavigationSyncModifier: ViewModifier {
  @ObservedObject var viewModel: ContentViewModel
  @Binding var layerSelection: Int
  @Binding var phaseSelection: Int
  @Binding var storedLayerIndex: Int
  @Binding var storedPhaseIndex: Int

  func body(content: Content) -> some View {
    content
      .onChange(of: viewModel.phaseOrder) {
        adjustPhaseSelection()
      }
      .onChange(of: layerSelection) { _, newValue in
        // Filtered index → layer ID → full array index → AppStorage.
        if let layerId = viewModel.filteredIndexToLayerId(newValue) {
          viewModel.selectedLayerId = layerId
          if let fullIndex = viewModel.layerIdToIndex(layerId) {
            viewModel.selectedLayerIndex = fullIndex
            storedLayerIndex = fullIndex
          }
        }
      }
      .onChange(of: viewModel.selectedLayerId) { _, newLayerId in
        // Mirror an externally-set layer ID into the filtered index.
        guard let layerId = newLayerId,
              let filteredIndex = viewModel.layerIdToFilteredIndex(layerId)
        else { return }
        if layerSelection != filteredIndex {
          layerSelection = filteredIndex
        }
      }
      .onChange(of: viewModel.layerFilterMode) { _, _ in
        // Filter changes invalidate the filtered index for the current
        // layer ID — fixes #180 (strategy cards rendered tiny after flow
        // completion because layerSelection wasn't re-derived).
        guard let layerId = viewModel.selectedLayerId,
              let filteredIndex = viewModel.layerIdToFilteredIndex(layerId)
        else {
          let maxIndex = max(0, viewModel.filteredLayers.count - 1)
          if layerSelection > maxIndex {
            layerSelection = maxIndex
          }
          return
        }
        if layerSelection != filteredIndex {
          layerSelection = filteredIndex
        }
      }
      .onChange(of: phaseSelection) { _, newValue in
        guard !viewModel.phaseOrder.isEmpty else { return }
        let adjusted = PhaseNavigator.adjustedSelection(newValue, phaseCount: viewModel.phaseOrder.count)
        if adjusted != newValue {
          phaseSelection = adjusted
        }
        let normalized = PhaseNavigator.normalizedIndex(adjusted, phaseCount: viewModel.phaseOrder.count)
        viewModel.selectedPhaseIndex = normalized
        storedPhaseIndex = normalized
      }
      .onChange(of: viewModel.selectedPhaseIndex) { _, newValue in
        let expected = newValue + 1
        if phaseSelection != expected {
          phaseSelection = expected
        }
      }
  }

  private func adjustPhaseSelection() {
    guard !viewModel.phaseOrder.isEmpty else { return }
    let adjusted = PhaseNavigator.adjustedSelection(phaseSelection, phaseCount: viewModel.phaseOrder.count)
    if adjusted != phaseSelection {
      phaseSelection = adjusted
    }
  }
}

extension View {
  /// Attaches the dual-axis navigation state-sync modifier. See
  /// `NavigationSyncModifier` for the per-observer contract.
  func navigationSync(
    viewModel: ContentViewModel,
    layerSelection: Binding<Int>,
    phaseSelection: Binding<Int>,
    storedLayerIndex: Binding<Int>,
    storedPhaseIndex: Binding<Int>
  ) -> some View {
    modifier(NavigationSyncModifier(
      viewModel: viewModel,
      layerSelection: layerSelection,
      phaseSelection: phaseSelection,
      storedLayerIndex: storedLayerIndex,
      storedPhaseIndex: storedPhaseIndex
    ))
  }
}
