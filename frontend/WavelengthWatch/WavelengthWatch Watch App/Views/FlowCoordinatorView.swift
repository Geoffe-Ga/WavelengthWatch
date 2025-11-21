import SwiftUI

/// Coordinates the multi-step emotion logging flow presented as a sheet.
///
/// This coordinator owns the NavigationStack and JournalFlowViewModel,
/// managing the flow's lifecycle from initialization to cancellation.
/// The flow is presented as a sheet that can be dismissed via a cancel button.
struct FlowCoordinatorView: View {
  let catalog: CatalogResponseModel
  @Binding var isPresented: Bool
  @StateObject var flowViewModel: JournalFlowViewModel

  init(catalog: CatalogResponseModel, initiatedBy: InitiatedBy, isPresented: Binding<Bool> = .constant(true)) {
    self.catalog = catalog
    self._isPresented = isPresented
    self._flowViewModel = StateObject(wrappedValue: JournalFlowViewModel(catalog: catalog, initiatedBy: initiatedBy))
  }

  var body: some View {
    NavigationStack {
      currentStepView
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
              cancel()
            }
          }
        }
    }
  }

  @ViewBuilder
  private var currentStepView: some View {
    switch flowViewModel.currentStep {
    case .primaryEmotion:
      primaryEmotionView
    case .secondaryEmotion:
      secondaryEmotionView
    case .strategySelection:
      strategySelectionView
    case .review:
      reviewView
    }
  }

  private var primaryEmotionView: some View {
    FilteredLayerNavigationView(
      layers: flowViewModel.filteredLayers,
      phaseOrder: catalog.phaseOrder,
      selectedLayerIndex: .constant(0),
      selectedPhaseIndex: .constant(0),
      onPhaseCardTap: {}
    )
  }

  private var secondaryEmotionView: some View {
    FilteredLayerNavigationView(
      layers: flowViewModel.filteredLayers,
      phaseOrder: catalog.phaseOrder,
      selectedLayerIndex: .constant(0),
      selectedPhaseIndex: .constant(0),
      onPhaseCardTap: {}
    )
  }

  private var strategySelectionView: some View {
    FilteredLayerNavigationView(
      layers: flowViewModel.filteredLayers,
      phaseOrder: catalog.phaseOrder,
      selectedLayerIndex: .constant(0),
      selectedPhaseIndex: .constant(0),
      onPhaseCardTap: {}
    )
  }

  private var reviewView: some View {
    Text("Review")
  }

  func cancel() {
    flowViewModel.reset()
    isPresented = false
  }
}
