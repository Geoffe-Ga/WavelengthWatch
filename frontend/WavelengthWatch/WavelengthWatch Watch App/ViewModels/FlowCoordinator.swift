import Foundation

/// Coordinates the multi-step emotion logging flow without any UI logic
///
/// FlowCoordinator is responsible for:
/// - Tracking current flow step (state machine)
/// - Capturing user selections (primary, secondary, strategy)
/// - Controlling ContentViewModel.layerFilterMode to filter visible layers
/// - NOT responsible for UI rendering (ContentView handles that)
///
/// Design principle: PURE STATE MANAGEMENT
/// This class knows nothing about SwiftUI views, sheets, alerts, or navigation.
/// It only manages the flow state machine and controls which layers are visible.
@MainActor
final class FlowCoordinator: ObservableObject {
  // MARK: - Dependencies

  /// ContentViewModel instance to control layer filtering
  let contentViewModel: ContentViewModel

  // MARK: - Published State

  /// Current step in the flow state machine
  @Published var currentStep: FlowStep = .idle

  /// User selections throughout the flow
  @Published var selections: Selections = .init()

  // MARK: - Initialization

  init(contentViewModel: ContentViewModel) {
    self.contentViewModel = contentViewModel
  }

  // MARK: - Flow Control

  /// Starts the primary emotion selection flow
  ///
  /// Sets layerFilterMode to .emotionsOnly and transitions to selectingPrimary state.
  func startPrimarySelection() {
    contentViewModel.layerFilterMode = .emotionsOnly
    currentStep = .selectingPrimary
  }

  /// Captures the primary emotion selection
  ///
  /// Stores the emotion and transitions to confirmingPrimary state.
  /// - Parameter emotion: The selected primary emotion
  func capturePrimary(_ emotion: CatalogCurriculumEntryModel) {
    selections.primary = emotion
    currentStep = .confirmingPrimary
  }

  /// Captures the secondary emotion selection (optional)
  ///
  /// Stores the emotion (or nil if skipped) and transitions to confirmingSecondary state.
  /// - Parameter emotion: The selected secondary emotion, or nil if skipped
  func captureSecondary(_ emotion: CatalogCurriculumEntryModel?) {
    selections.secondary = emotion
    currentStep = .confirmingSecondary
  }

  /// Captures the strategy selection (optional)
  ///
  /// Stores the strategy (or nil if skipped) and transitions to confirmingStrategy state.
  /// - Parameter strategy: The selected strategy, or nil if skipped
  func captureStrategy(_ strategy: CatalogStrategyModel?) {
    selections.strategy = strategy
    currentStep = .confirmingStrategy
  }

  // MARK: - Navigation

  /// Prompts for secondary emotion selection
  ///
  /// Sets layerFilterMode to .emotionsOnly and transitions to selectingSecondary state.
  func promptForSecondary() {
    contentViewModel.layerFilterMode = .emotionsOnly
    currentStep = .selectingSecondary
  }

  /// Prompts for strategy selection
  ///
  /// Sets layerFilterMode to .strategiesOnly and transitions to selectingStrategy state.
  func promptForStrategy() {
    contentViewModel.layerFilterMode = .strategiesOnly
    currentStep = .selectingStrategy
  }

  /// Shows the review screen
  ///
  /// Transitions to review state where user can submit or go back.
  func showReview() {
    currentStep = .review
  }

  // MARK: - Completion

  /// Submits the journal entry to the backend
  ///
  /// Validates that primary emotion is selected, then calls ContentViewModel's journal method.
  /// On success, resets the flow state.
  /// - Throws: FlowError.missingPrimaryEmotion if no primary emotion is selected
  func submit() async throws {
    guard let primary = selections.primary else {
      throw FlowError.missingPrimaryEmotion
    }

    // Use existing journal submission from ContentViewModel
    try await contentViewModel.journal(
      curriculumID: primary.id,
      secondaryCurriculumID: selections.secondary?.id,
      strategyID: selections.strategy?.id,
      initiatedBy: .self_initiated
    )

    // Reset flow on success
    reset()
  }

  // MARK: - Cancellation

  /// Cancels the flow and resets all state
  ///
  /// Clears selections, returns to idle state, and restores .all filter mode.
  func cancel() {
    reset()
    contentViewModel.layerFilterMode = .all
  }

  /// Resets the flow state without changing filter mode
  ///
  /// Clears all selections and returns to idle state.
  func reset() {
    currentStep = .idle
    selections = .init()
  }

  // MARK: - Nested Types

  /// Flow state machine steps
  enum FlowStep: Equatable {
    case idle // Not in flow
    case selectingPrimary // User navigating ContentView for primary
    case confirmingPrimary // Show confirmation sheet
    case selectingSecondary // User navigating ContentView for secondary
    case confirmingSecondary // Show confirmation sheet
    case selectingStrategy // User navigating ContentView for strategy
    case confirmingStrategy // Show confirmation sheet
    case review // Show review sheet
  }

  /// User selections throughout the flow
  struct Selections: Equatable {
    var primary: CatalogCurriculumEntryModel?
    var secondary: CatalogCurriculumEntryModel?
    var strategy: CatalogStrategyModel?
  }

  /// Errors that can occur during flow execution
  enum FlowError: Error {
    case missingPrimaryEmotion
  }
}
