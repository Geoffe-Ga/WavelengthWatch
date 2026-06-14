import Foundation

/// A request to show the "Would you like to log …?" confirmation for a
/// journal entry, carried as the payload of
/// `PresentationCoordinator.ActivePresentation.logConfirmation`.
///
/// Leaf cards (`CurriculumCard`, `StrategyCard`, `StrategyListView`) used
/// to own this as local `@State` + a `.alert` rendered from inside a
/// pushed `navigationDestination`, which is exactly why the confirmation
/// was deferred until the user backed out (B2 in
/// `prompts/claude-comm/spec-primary-selector-rebuild.md` §2). Hoisting it
/// here lets `RootPresentationHost`, anchored above the navigation push,
/// present it immediately. The request carries the verbatim alert copy so
/// the host renders it without re-deriving strings, and an `Action`
/// describing what "Yes" should do.
struct LogConfirmationRequest: Equatable {
  /// Alert title, verbatim (e.g. "Log Medicinal", "Log Strategy").
  let alertTitle: String
  /// Alert message, verbatim (e.g. `Would you like to log "Grounded"?`).
  let message: String
  /// What tapping "Yes" performs.
  let action: Action

  /// The two journal-logging shapes a confirmation can resolve to. The
  /// branching mirrors the leaf cards' former `handleLogAction` exactly;
  /// see `LogConfirmationHandler`.
  enum Action: Equatable {
    /// Log a curriculum entry (`CurriculumCard`).
    case curriculum(entry: CatalogCurriculumEntryModel)
    /// Log a strategy against a curriculum id (`StrategyCard`,
    /// `StrategyListView`). `curriculumID` is nil when no curriculum entry
    /// is available to log against — valid only inside the
    /// strategy-selection flow.
    case strategy(strategy: CatalogStrategyModel, curriculumID: Int?)
  }
}

/// Performs the journal-logging action behind a `LogConfirmationRequest`.
///
/// This is the single home for the branching the three leaf cards used to
/// each duplicate in their private `handleLogAction`. A tap from `idle`
/// (normal browsing) starts the guided flow (`startPrimarySelection` +
/// `capturePrimary`) so the secondary-emotion / strategy / review steps are
/// offered (#445). While a selection step is active
/// (`selectingPrimary`/`selectingSecondary`/`selectingStrategy`) the
/// confirmation captures into `FlowCoordinator`; the remaining non-selecting
/// steps (already inside the flow) log directly via `ContentViewModel.journal`.
/// `perform` is `async` so the direct-log path can `await` the journal call
/// (the cards previously wrapped it in a fire-and-forget `Task`); the
/// flow-capture paths are synchronous and complete before the first await.
@MainActor
struct LogConfirmationHandler {
  let flowCoordinator: FlowCoordinator
  let viewModel: ContentViewModel

  func perform(_ action: LogConfirmationRequest.Action) async {
    switch action {
    case let .curriculum(entry):
      switch flowCoordinator.currentStep {
      case .selectingPrimary:
        flowCoordinator.capturePrimary(entry)
      case .selectingSecondary:
        flowCoordinator.captureSecondary(entry)
      case .idle:
        // A tap from normal browsing starts the guided flow so the
        // "Add Secondary Emotion" / strategy / review steps are offered (#445).
        flowCoordinator.startPrimarySelection()
        flowCoordinator.capturePrimary(entry)
      case .confirmingPrimary, .confirmingSecondary,
           .selectingStrategy, .confirmingStrategy, .review:
        // Already inside the flow on a non-selecting step: persist immediately
        // and render feedback from the result.
        await viewModel.journal(curriculumID: entry.id)
      }
    case let .strategy(strategy, curriculumID):
      if flowCoordinator.currentStep == .selectingStrategy {
        flowCoordinator.captureStrategy(strategy)
      } else if let curriculumID {
        await viewModel.journal(curriculumID: curriculumID, strategyID: strategy.id)
      }
    }
  }
}
