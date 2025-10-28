import Foundation

@MainActor
final class ContentViewModel: ObservableObject {
  @Published var layers: [CatalogLayerModel] = []
  @Published var phaseOrder: [String] = []
  @Published var isLoading = false
  @Published var loadErrorMessage: String?
  @Published var journalFeedback: JournalFeedback?
  @Published var selectedLayerIndex: Int
  @Published var selectedPhaseIndex: Int
  @Published var currentInitiatedBy: InitiatedBy = .self_initiated

  private let repository: CatalogRepositoryProtocol
  private let journalClient: JournalClientProtocol

  struct JournalFeedback: Identifiable, Equatable {
    enum Kind: Equatable {
      case success
      case failure(String)
    }

    let id = UUID()
    let kind: Kind
  }

  init(
    repository: CatalogRepositoryProtocol,
    journalClient: JournalClientProtocol,
    initialLayerIndex: Int = 0,
    initialPhaseIndex: Int = 0
  ) {
    self.repository = repository
    self.journalClient = journalClient
    self.selectedLayerIndex = initialLayerIndex
    self.selectedPhaseIndex = initialPhaseIndex
  }

  func loadCatalog(forceRefresh: Bool = false) async {
    if isLoading { return }
    isLoading = true
    loadErrorMessage = nil

    if layers.isEmpty, let cached = repository.cachedCatalog() {
      applyCatalog(cached)
    }

    do {
      let catalog = try await repository.loadCatalog(forceRefresh: forceRefresh)
      applyCatalog(catalog)
    } catch {
      if layers.isEmpty {
        loadErrorMessage = "Unable to load the catalog right now."
      }
    }

    isLoading = false
  }

  func retry() async {
    await loadCatalog(forceRefresh: true)
  }

  func journal(
    curriculumID: Int,
    secondaryCurriculumID: Int? = nil,
    strategyID: Int? = nil,
    initiatedBy: InitiatedBy? = nil
  ) async {
    do {
      let effectiveInitiatedBy = initiatedBy ?? currentInitiatedBy
      _ = try await journalClient.submit(
        curriculumID: curriculumID,
        secondaryCurriculumID: secondaryCurriculumID,
        strategyID: strategyID,
        initiatedBy: effectiveInitiatedBy
      )
      journalFeedback = JournalFeedback(kind: .success)
      // Reset to self-initiated after successful submission
      currentInitiatedBy = .self_initiated
    } catch {
      journalFeedback = JournalFeedback(kind: .failure("We couldn't log your entry. Please try again."))
      // Reset to self-initiated after failure
      currentInitiatedBy = .self_initiated
    }
  }

  func setInitiatedBy(_ value: InitiatedBy) {
    currentInitiatedBy = value
  }

  private func applyCatalog(_ catalog: CatalogResponseModel) {
    layers = catalog.layers.reversed()
    phaseOrder = catalog.phaseOrder

    if selectedLayerIndex >= layers.count {
      selectedLayerIndex = max(0, layers.count - 1)
    }
    if selectedPhaseIndex >= phaseOrder.count {
      selectedPhaseIndex = max(0, phaseOrder.count - 1)
    }
  }
}
