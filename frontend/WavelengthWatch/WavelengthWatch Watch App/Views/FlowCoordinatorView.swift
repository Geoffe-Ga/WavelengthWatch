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

  // State tracking for layer/phase selections per step
  @State private var primaryLayerIndex: Int = 0
  @State private var primaryPhaseIndex: Int = 0
  @State private var secondaryLayerIndex: Int = 0
  @State private var secondaryPhaseIndex: Int = 0
  @State private var strategyLayerIndex: Int = 0
  @State private var strategyPhaseIndex: Int = 0

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
          ToolbarItem(placement: .confirmationAction) {
            if flowViewModel.currentStep != .review, flowViewModel.currentStep != .primaryEmotion {
              Button("Skip") {
                flowViewModel.advanceStep()
              }
            }
          }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
  }

  private var navigationTitle: String {
    switch flowViewModel.currentStep {
    case .primaryEmotion:
      "Primary Emotion"
    case .secondaryEmotion:
      "Secondary Emotion"
    case .strategySelection:
      "Strategy"
    case .review:
      "Review"
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
    PrimaryEmotionSelectionView(
      catalog: catalog,
      flowViewModel: flowViewModel
    )
  }

  private var secondaryEmotionView: some View {
    FilteredLayerNavigationView(
      layers: flowViewModel.filteredLayers,
      phaseOrder: catalog.phaseOrder,
      selectedLayerIndex: $secondaryLayerIndex,
      selectedPhaseIndex: $secondaryPhaseIndex,
      onPhaseCardTap: {
        // TODO: Phase 1.3 - Navigate to curriculum detail view
        // Calls flowViewModel.selectSecondaryCurriculum(id:)
      }
    )
  }

  private var strategySelectionView: some View {
    FilteredLayerNavigationView(
      layers: flowViewModel.filteredLayers,
      phaseOrder: catalog.phaseOrder,
      selectedLayerIndex: $strategyLayerIndex,
      selectedPhaseIndex: $strategyPhaseIndex,
      onPhaseCardTap: {
        // TODO: Phase 1.3 - Navigate to strategy detail view
        // Calls flowViewModel.selectStrategy(id:)
      }
    )
  }

  private var reviewView: some View {
    VStack(spacing: 20) {
      Text("Review Step")
        .font(.title2)
        .fontWeight(.thin)
        .foregroundColor(.white)
        .padding()

      Text("TODO: Phase 2.x - Display selected emotions and strategies")
        .font(.callout)
        .foregroundColor(.white.opacity(0.6))
        .multilineTextAlignment(.center)
        .padding()

      // Placeholder: Future implementation will show:
      // - Selected primary emotion (from flowViewModel.getPrimaryCurriculum())
      // - Selected secondary emotion (from flowViewModel.getSecondaryCurriculum())
      // - Selected strategy (from flowViewModel.getStrategy())
      // - Submit button to create journal entry
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
  }

  func cancel() {
    flowViewModel.reset()
    isPresented = false
  }
}
