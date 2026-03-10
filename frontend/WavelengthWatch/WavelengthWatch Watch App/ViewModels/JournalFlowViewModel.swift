import Foundation

/// Manages state for the multi-step emotion logging flow.
///
/// The flow progresses through these steps:
/// 1. Entry type selection (emotion or rest)
/// 2. Primary emotion selection (emotions-only filter) - skipped for REST
/// 3. Secondary emotion selection (emotions-only filter, optional)
/// 4. Strategy selection (strategies-only filter, optional)
/// 5. Review and submit
///
/// The ViewModel tracks selections, manages filter modes based on current step,
/// and provides validation for whether the user can proceed.
final class JournalFlowViewModel: ObservableObject {
  /// Flow steps in order
  enum FlowStep: Equatable {
    case entryTypeSelection
    case primaryEmotion
    case secondaryEmotion
    case strategySelection
    case review
  }

  // MARK: - Published State

  @Published var currentStep: FlowStep = .entryTypeSelection
  @Published var entryType: EntryType = .emotion
  @Published var primaryCurriculumID: Int?
  @Published var secondaryCurriculumID: Int?
  @Published var strategyID: Int?
  @Published var initiatedBy: InitiatedBy

  // MARK: - Private State

  private let catalog: CatalogResponseModel

  /// Layers array in display order [10,9,...,1,0] - reversed to match main app navigation
  private var layers: [CatalogLayerModel]

  // MARK: - Initialization

  @MainActor
  init(catalog: CatalogResponseModel, initiatedBy: InitiatedBy = .self_initiated) {
    self.catalog = catalog
    // Reverse once at initialization to get display order (Clear Light first)
    self.layers = catalog.layers.reversed()
    self.initiatedBy = initiatedBy
  }

  // MARK: - Computed Properties

  /// Returns layers filtered based on the current step.
  ///
  /// Layers are already in display order (Clear Light first, Beige last) from initialization,
  /// so filtering maintains the correct order.
  var filteredLayers: [CatalogLayerModel] {
    filterMode.filter(layers)
  }

  /// Returns the filter mode for the current step.
  var filterMode: LayerFilterMode {
    switch currentStep {
    case .entryTypeSelection:
      .all
    case .primaryEmotion, .secondaryEmotion:
      .emotionsOnly
    case .strategySelection:
      .strategiesOnly
    case .review:
      .all
    }
  }

  /// Whether the user can proceed from the current step.
  ///
  /// - Entry type selection: requires entry type to be set
  /// - Primary emotion: requires a selection (only for EMOTION entries)
  /// - Secondary emotion: always can proceed (optional)
  /// - Strategy selection: always can proceed (optional)
  /// - Review: cannot proceed (final step)
  var canProceed: Bool {
    switch currentStep {
    case .entryTypeSelection:
      true // Entry type is always set
    case .primaryEmotion:
      primaryCurriculumID != nil
    case .secondaryEmotion, .strategySelection:
      true
    case .review:
      false
    }
  }

  // MARK: - Selection Methods

  /// Selects the primary emotion curriculum entry.
  @MainActor
  func selectPrimaryCurriculum(id: Int) {
    primaryCurriculumID = id
  }

  /// Selects the secondary emotion curriculum entry.
  @MainActor
  func selectSecondaryCurriculum(id: Int?) {
    secondaryCurriculumID = id
  }

  /// Selects a strategy.
  @MainActor
  func selectStrategy(id: Int?) {
    strategyID = id
  }

  // MARK: - Navigation Methods

  /// Selects entry type and advances flow accordingly.
  @MainActor
  func selectEntryType(_ type: EntryType) {
    entryType = type
    if type == .rest {
      // Skip to review for REST entries
      currentStep = .review
    } else {
      // Continue to emotion selection for EMOTION entries
      currentStep = .primaryEmotion
    }
  }

  /// Selects REST entry type and skips to review.
  @MainActor
  func selectRestPeriod() {
    selectEntryType(.rest)
  }

  /// Advances to the next step in the flow.
  @MainActor
  func advanceStep() {
    switch currentStep {
    case .entryTypeSelection:
      // Navigate based on entry type
      if entryType == .rest {
        currentStep = .review
      } else {
        currentStep = .primaryEmotion
      }
    case .primaryEmotion:
      currentStep = .secondaryEmotion
    case .secondaryEmotion:
      currentStep = .strategySelection
    case .strategySelection:
      currentStep = .review
    case .review:
      break // Already at final step
    }
  }

  /// Resets the flow to the beginning, clearing all selections.
  @MainActor
  func reset() {
    currentStep = .entryTypeSelection
    entryType = .emotion
    primaryCurriculumID = nil
    secondaryCurriculumID = nil
    strategyID = nil
  }

  // MARK: - Data Retrieval Methods

  /// Returns the primary curriculum entry if one is selected.
  func getPrimaryCurriculum() -> CatalogCurriculumEntryModel? {
    guard let primaryID = primaryCurriculumID else { return nil }
    return findCurriculum(by: primaryID)
  }

  /// Returns the secondary curriculum entry if one is selected.
  func getSecondaryCurriculum() -> CatalogCurriculumEntryModel? {
    guard let secondaryID = secondaryCurriculumID else { return nil }
    return findCurriculum(by: secondaryID)
  }

  /// Returns the selected strategy if one is selected.
  func getStrategy() -> CatalogStrategyModel? {
    guard let stratID = strategyID else { return nil }
    return findStrategy(by: stratID)
  }

  // MARK: - Private Helper Methods

  /// Finds a curriculum entry by ID across all layers and phases.
  private func findCurriculum(by id: Int) -> CatalogCurriculumEntryModel? {
    for layer in layers {
      for phase in layer.phases {
        if let found = phase.medicinal.first(where: { $0.id == id }) {
          return found
        }
        if let found = phase.toxic.first(where: { $0.id == id }) {
          return found
        }
      }
    }
    return nil
  }

  /// Finds a strategy by ID across all layers and phases.
  private func findStrategy(by id: Int) -> CatalogStrategyModel? {
    for layer in layers {
      for phase in layer.phases {
        if let found = phase.strategies.first(where: { $0.id == id }) {
          return found
        }
      }
    }
    return nil
  }
}
