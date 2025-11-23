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

  // Track whether user has chosen to add secondary emotion
  @State private var showingSecondaryEmotionPicker: Bool = false

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
            if shouldShowToolbarSkip {
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

  /// Whether to show the toolbar skip button for the current step.
  ///
  /// Skip button is hidden when:
  /// - On primary emotion step (required selection)
  /// - On secondary emotion prompt (prompt has its own skip button)
  /// - On review step (final step)
  private var shouldShowToolbarSkip: Bool {
    switch flowViewModel.currentStep {
    case .primaryEmotion, .review:
      false
    case .secondaryEmotion:
      showingSecondaryEmotionPicker // Only show if in picker mode, not prompt
    case .strategySelection:
      true
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
    Group {
      if showingSecondaryEmotionPicker {
        // Show emotion selection UI after user chooses to add secondary
        SecondaryEmotionSelectionView(
          catalog: catalog,
          flowViewModel: flowViewModel
        )
      } else {
        // Show prompt first
        SecondaryEmotionPromptView(
          flowViewModel: flowViewModel,
          onAddSecondary: {
            showingSecondaryEmotionPicker = true
          }
        )
      }
    }
    .onChange(of: flowViewModel.currentStep) { _, newStep in
      // Reset picker state when leaving secondary emotion step
      if newStep != .secondaryEmotion {
        showingSecondaryEmotionPicker = false
      }
    }
  }

  private var strategySelectionView: some View {
    StrategySelectionView(
      catalog: catalog,
      flowViewModel: flowViewModel
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
