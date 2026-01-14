import Foundation

final class ContentViewModel: ObservableObject {
  @Published var layers: [CatalogLayerModel] = []
  @Published var phaseOrder: [String] = []
  @Published var isLoading = false
  @Published var loadErrorMessage: String?
  @Published var journalFeedback: JournalFeedback?

  /// Index in the full (unfiltered) layers array. Derived from selectedLayerId.
  @Published var selectedLayerIndex: Int {
    didSet {
      // Auto-initialize selectedLayerId from selectedLayerIndex when set directly
      // Guard to prevent infinite loops
      if layers.count > 0, selectedLayerIndex >= 0, selectedLayerIndex < layers.count {
        let layerId = layers[selectedLayerIndex].id
        if selectedLayerId != layerId {
          selectedLayerId = layerId
        }
      }
    }
  }

  @Published var selectedPhaseIndex: Int
  @Published var currentInitiatedBy: InitiatedBy = .self_initiated
  @Published var layerFilterMode: LayerFilterMode = .all {
    didSet {
      handleFilterModeChange(from: oldValue, to: layerFilterMode)
    }
  }

  /// SOURCE OF TRUTH: Which layer is currently selected, tracked by layer ID.
  /// This remains stable across filter mode changes. selectedLayerIndex is derived from this.
  @Published var selectedLayerId: Int? {
    didSet {
      // Keep selectedLayerIndex in sync when selectedLayerId changes
      // Guard to prevent infinite loops
      if let layerId = selectedLayerId,
         let fullIndex = layerIdToIndex(layerId),
         selectedLayerIndex != fullIndex
      {
        selectedLayerIndex = fullIndex
      }
    }
  }

  let catalogRepository: CatalogRepositoryProtocol
  let journalRepository: JournalRepositoryProtocol
  private let journalClient: JournalClientProtocol

  /// Returns layers filtered according to the current filter mode.
  ///
  /// The filtered layers change based on `layerFilterMode`:
  /// - `.all`: All layers (0-10) for normal browsing
  /// - `.emotionsOnly`: Only emotion layers (1-10), excluding strategies
  /// - `.strategiesOnly`: Only strategies layer (0)
  var filteredLayers: [CatalogLayerModel] {
    layerFilterMode.filter(layers)
  }

  struct JournalFeedback: Identifiable, Equatable {
    enum Kind: Equatable {
      case success
      case failure(String)
    }

    let id = UUID()
    let kind: Kind
  }

  nonisolated init(
    catalogRepository: CatalogRepositoryProtocol,
    journalRepository: JournalRepositoryProtocol,
    journalClient: JournalClientProtocol,
    initialLayerIndex: Int = 0,
    initialPhaseIndex: Int = 0
  ) {
    self.catalogRepository = catalogRepository
    self.journalRepository = journalRepository
    self.journalClient = journalClient
    self.selectedLayerIndex = initialLayerIndex
    self.selectedPhaseIndex = initialPhaseIndex
  }

  @MainActor
  func loadCatalog(forceRefresh: Bool = false) async {
    if isLoading { return }
    isLoading = true
    loadErrorMessage = nil

    if layers.isEmpty, let cached = catalogRepository.cachedCatalog() {
      applyCatalog(cached)
    }

    do {
      let catalog = try await catalogRepository.loadCatalog(forceRefresh: forceRefresh)
      applyCatalog(catalog)
    } catch {
      if layers.isEmpty {
        loadErrorMessage = "Unable to load the catalog right now."
      }
    }

    isLoading = false
  }

  @MainActor
  func retry() async {
    await loadCatalog(forceRefresh: true)
  }

  @MainActor
  func journal(
    curriculumID: Int,
    secondaryCurriculumID: Int? = nil,
    strategyID: Int? = nil,
    initiatedBy: InitiatedBy? = nil
  ) async {
    do {
      try await journalThrowing(
        curriculumID: curriculumID,
        secondaryCurriculumID: secondaryCurriculumID,
        strategyID: strategyID,
        initiatedBy: initiatedBy
      )
      journalFeedback = JournalFeedback(kind: .success)
    } catch {
      journalFeedback = JournalFeedback(kind: .failure("We couldn't log your entry. Please try again."))
    }
  }

  /// Throwing variant of journal() for use by FlowCoordinator
  ///
  /// This variant throws errors instead of converting them to journalFeedback,
  /// allowing callers to handle errors explicitly (e.g., preserve state for retry).
  @MainActor
  func journalThrowing(
    curriculumID: Int,
    secondaryCurriculumID: Int? = nil,
    strategyID: Int? = nil,
    initiatedBy: InitiatedBy? = nil
  ) async throws {
    let effectiveInitiatedBy = initiatedBy ?? currentInitiatedBy
    _ = try await journalClient.submit(
      curriculumID: curriculumID,
      secondaryCurriculumID: secondaryCurriculumID,
      strategyID: strategyID,
      initiatedBy: effectiveInitiatedBy
    )
    // Reset to self-initiated after successful submission
    currentInitiatedBy = .self_initiated
  }

  @MainActor
  func setInitiatedBy(_ value: InitiatedBy) {
    currentInitiatedBy = value
  }

  /// Converts a layer ID to its index in the full layers array.
  func layerIdToIndex(_ layerId: Int) -> Int? {
    layers.firstIndex { $0.id == layerId }
  }

  /// Converts a layer ID to its index in the filtered layers array.
  func layerIdToFilteredIndex(_ layerId: Int) -> Int? {
    filteredLayers.firstIndex { $0.id == layerId }
  }

  /// Converts a filtered index to the corresponding layer ID.
  func filteredIndexToLayerId(_ filteredIndex: Int) -> Int? {
    guard filteredIndex >= 0, filteredIndex < filteredLayers.count else { return nil }
    return filteredLayers[filteredIndex].id
  }

  /// Converts a full array index to the corresponding layer ID.
  func indexToLayerId(_ index: Int) -> Int? {
    guard index >= 0, index < layers.count else { return nil }
    return layers[index].id
  }

  @MainActor
  private func applyCatalog(_ catalog: CatalogResponseModel) {
    layers = catalog.layers.reversed()
    phaseOrder = catalog.phaseOrder

    if selectedLayerIndex >= layers.count {
      selectedLayerIndex = max(0, layers.count - 1)
    }
    if selectedPhaseIndex >= phaseOrder.count {
      selectedPhaseIndex = max(0, phaseOrder.count - 1)
    }

    // Initialize selectedLayerId from selectedLayerIndex
    if selectedLayerId == nil, selectedLayerIndex < layers.count {
      selectedLayerId = layers[selectedLayerIndex].id
    }
  }

  /// Handles filter mode changes by preserving or clamping the selected layer ID.
  ///
  /// This method ONLY manages selectedLayerId (the source of truth).
  /// When the filter mode changes:
  /// - If the currently selected layer (by ID) exists in the new filtered set, preserve it (do nothing)
  /// - If not, clamp selectedLayerId to the first layer in the new filtered set
  ///
  /// Note: selectedLayerIndex will be synced separately by ContentView's onChange handlers.
  private func handleFilterModeChange(from oldMode: LayerFilterMode, to newMode: LayerFilterMode) {
    guard oldMode != newMode else { return }
    guard layers.count > 0 else { return } // Only process if layers are loaded
    guard let currentLayerId = selectedLayerId else { return }

    // Check if current layer exists in new filtered set
    if layerIdToFilteredIndex(currentLayerId) != nil {
      // Layer exists in new filtered set, preserve selectedLayerId
      // Do nothing - selectedLayerId stays the same
    } else {
      // Selected layer not in new filtered set, clamp to first available layer
      guard filteredLayers.count > 0 else {
        selectedLayerId = nil
        return
      }

      // Update selectedLayerId to first layer in filtered set
      selectedLayerId = filteredLayers[0].id
    }
  }
}
