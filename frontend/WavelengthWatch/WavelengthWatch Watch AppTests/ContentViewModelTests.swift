import Foundation
import Testing

@testable import WavelengthWatch_Watch_App

@Suite("ContentViewModel Tests")
struct ContentViewModelTests {
  @Test func loadsCatalogSuccessfully() async throws {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.loadCatalog()

    #expect(!viewModel.layers.isEmpty)
    #expect(viewModel.loadErrorMessage == nil)
    #expect(viewModel.isLoading == false)
  }

  @Test func surfacesErrorWhenLoadingFails() async {
    enum TestError: Error { case failure }
    let repository = CatalogRepositoryMock(result: .failure(TestError.failure))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.loadCatalog()

    #expect(viewModel.layers.isEmpty)
    #expect(viewModel.loadErrorMessage != nil)
  }

  @Test func retriesAfterFailure() async {
    enum TestError: Error { case failure }
    let repository = CatalogRepositoryMock(result: .failure(TestError.failure))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.loadCatalog()
    #expect(viewModel.layers.isEmpty)

    repository.result = .success(SampleData.catalog)
    await viewModel.retry()

    #expect(!viewModel.layers.isEmpty)
    #expect(viewModel.loadErrorMessage == nil)
  }

  @Test func reportsJournalOutcome() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.journal(curriculumID: 1)
    switch viewModel.journalFeedback?.kind {
    case .success?: #expect(true)
    default: #expect(Bool(false))
    }

    journal.shouldFail = true
    await viewModel.journal(curriculumID: 1)
    switch viewModel.journalFeedback?.kind {
    case let .failure(message)?:
      #expect(message.contains("try again"))
    default: #expect(Bool(false))
    }
  }

  @Test func logsJournalEntriesWithStrategy() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.journal(curriculumID: 1, strategyID: 3)

    #expect(journal.submissions.count == 1)
    let submission = journal.submissions[0]
    #expect(submission.0 == 1) // curriculumID
    #expect(submission.1 == nil) // secondaryCurriculumID
    #expect(submission.2 == 3) // strategyID
  }

  @Test func logsJournalEntriesWithSecondaryCurriculum() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.journal(curriculumID: 1, secondaryCurriculumID: 2)

    #expect(journal.submissions.count == 1)
    let submission = journal.submissions[0]
    #expect(submission.0 == 1) // curriculumID
    #expect(submission.1 == 2) // secondaryCurriculumID
    #expect(submission.2 == nil) // strategyID
  }

  // MARK: - Layer Filtering Tests

  @Test func filteredLayersDefaultsToAll() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.loadCatalog()

    // Default filter mode should be .all
    #expect(viewModel.layerFilterMode == .all)
    #expect(viewModel.filteredLayers.count == viewModel.layers.count)
  }

  @Test func filteredLayersWithEmotionsOnlyExcludesLayerZero() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.loadCatalog()

    // Set filter to emotions only
    viewModel.layerFilterMode = .emotionsOnly

    // Should exclude layer 0 (11 total layers, 10 emotion layers)
    #expect(!viewModel.filteredLayers.contains { $0.id == 0 })
    #expect(viewModel.filteredLayers.count == 10)
    #expect(viewModel.filteredLayers.count == viewModel.layers.count - 1)
  }

  @Test func filteredLayersWithStrategiesOnlyIncludesOnlyLayerZero() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.loadCatalog()

    // Set filter to strategies only
    viewModel.layerFilterMode = .strategiesOnly

    // Should include only layer 0
    #expect(viewModel.filteredLayers.count == 1)
    #expect(viewModel.filteredLayers.first?.id == 0)
  }

  @Test func filteredLayersReactsToModeChange() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.loadCatalog()

    let originalCount = viewModel.filteredLayers.count

    // Change to emotions only
    viewModel.layerFilterMode = .emotionsOnly
    let emotionsCount = viewModel.filteredLayers.count

    // Change to strategies only
    viewModel.layerFilterMode = .strategiesOnly
    let strategiesCount = viewModel.filteredLayers.count

    // Verify filtering works (prod has 11 layers: 0-10)
    #expect(originalCount == 11) // All layers (0-10)
    #expect(emotionsCount == 10) // Only emotion layers (1-10)
    #expect(strategiesCount == 1) // Only strategy layer (0)
    #expect(originalCount > emotionsCount)
    #expect(emotionsCount > strategiesCount)
  }

  @Test func filteredLayersWhenLayersEmptyReturnsEmpty() {
    let repository = CatalogRepositoryMock(result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    // Don't load catalog, layers should be empty
    #expect(viewModel.layers.isEmpty)
    #expect(viewModel.filteredLayers.isEmpty)

    // Try different filter modes
    viewModel.layerFilterMode = .emotionsOnly
    #expect(viewModel.filteredLayers.isEmpty)

    viewModel.layerFilterMode = .strategiesOnly
    #expect(viewModel.filteredLayers.isEmpty)
  }
}
