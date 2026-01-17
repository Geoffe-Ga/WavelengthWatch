import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

/// Integration tests for AnalyticsView initialization and dependency wiring.
///
/// These tests verify that AnalyticsView properly initializes AnalyticsViewModel
/// with all required dependencies for offline-first functionality.
@MainActor
@Suite("AnalyticsView Integration Tests")
struct AnalyticsViewIntegrationTests {
  // MARK: - Mock Services

  final class MockAnalyticsService: AnalyticsServiceProtocol {
    var shouldFail = false
    var overviewToReturn: AnalyticsOverview?

    func getOverview(userId: Int) async throws -> AnalyticsOverview {
      if shouldFail {
        throw NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network unavailable"])
      }
      guard let overview = overviewToReturn else {
        throw NSError(domain: "test", code: -1)
      }
      return overview
    }

    func getEmotionalLandscape(userId: Int) async throws -> EmotionalLandscape {
      throw NSError(domain: "test", code: -1)
    }

    func getSelfCare(userId: Int, limit: Int) async throws -> SelfCareAnalytics {
      throw NSError(domain: "test", code: -1)
    }

    func getTemporalPatterns(
      userId: Int,
      startDate: Date,
      endDate: Date
    ) async throws -> TemporalPatterns {
      throw NSError(domain: "test", code: -1)
    }

    func getGrowthIndicators(
      userId: Int,
      startDate: Date,
      endDate: Date
    ) async throws -> GrowthIndicators {
      throw NSError(domain: "test", code: -1)
    }
  }

  final class MockJournalRepository: JournalRepositoryProtocol {
    var entries: [LocalJournalEntry] = []

    func save(_ entry: LocalJournalEntry) throws {}
    func update(_ entry: LocalJournalEntry) throws {}
    func delete(id: UUID) throws {}
    func fetch(id: UUID) throws -> LocalJournalEntry? { nil }

    func fetchAll() throws -> [LocalJournalEntry] {
      entries
    }

    func fetchPendingSync() throws -> [LocalJournalEntry] {
      entries.filter { $0.syncStatus == .pending }
    }

    func count() throws -> Int {
      entries.count
    }
  }

  final class MockCatalogRepository: CatalogRepositoryProtocol {
    var catalog: CatalogResponseModel?

    func cachedCatalog() -> CatalogResponseModel? {
      catalog
    }

    func loadCatalog(forceRefresh: Bool) async throws -> CatalogResponseModel {
      throw NSError(domain: "test", code: -1)
    }

    func refreshCatalog() async throws -> CatalogResponseModel {
      throw NSError(domain: "test", code: -1)
    }
  }

  // MARK: - Test Helpers

  private func createTestCatalog() -> CatalogResponseModel {
    CatalogResponseModel(
      phaseOrder: ["Rising", "Peaking"],
      layers: [
        CatalogLayerModel(
          id: 1,
          color: "#F5DEB3",
          title: "Beige",
          subtitle: "The Observer",
          phases: [
            CatalogPhaseModel(
              id: 1,
              name: "Rising",
              medicinal: [
                CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Curious"),
              ],
              toxic: [
                CatalogCurriculumEntryModel(id: 2, dosage: .toxic, expression: "Anxious"),
              ],
              strategies: []
            ),
          ]
        ),
      ]
    )
  }

  private func createTestEntries() -> [LocalJournalEntry] {
    [
      LocalJournalEntry(
        createdAt: Date(),
        userID: 1,
        curriculumID: 1,
        secondaryCurriculumID: nil,
        strategyID: nil,
        initiatedBy: .self_initiated
      ),
      LocalJournalEntry(
        createdAt: Date().addingTimeInterval(-86400),
        userID: 1,
        curriculumID: 2,
        secondaryCurriculumID: nil,
        strategyID: nil,
        initiatedBy: .self_initiated
      ),
    ]
  }

  // MARK: - Tests

  /// Test that analytics works offline with local data when backend fails.
  ///
  /// This is the core test for issue #242: verifies that AnalyticsViewModel
  /// falls back to local calculation when the backend is unavailable.
  @Test("Analytics works offline with local data")
  func analytics_worksOfflineWithLocalData() async {
    // Setup: Backend fails, but local data exists
    let mockService = MockAnalyticsService()
    mockService.shouldFail = true

    let mockRepository = MockJournalRepository()
    mockRepository.entries = createTestEntries()

    let mockCatalog = MockCatalogRepository()
    let catalog = createTestCatalog()
    mockCatalog.catalog = catalog

    let calculator = LocalAnalyticsCalculator(catalog: catalog)

    // Create ViewModel with all dependencies (this is what AnalyticsView should do)
    let viewModel = AnalyticsViewModel(
      analyticsService: mockService,
      localCalculator: calculator,
      journalRepository: mockRepository,
      catalogRepository: mockCatalog
    )

    // Act: Load analytics
    await viewModel.loadAnalytics()

    // Assert: Should load successfully using local data
    if case let .loaded(overview) = viewModel.state {
      #expect(overview.totalEntries == 2)
      #expect(overview.uniqueEmotions == 2)
    } else {
      Issue.record("Expected loaded state with local data, got \(viewModel.state)")
    }
  }

  /// Test that analytics fails gracefully when no local dependencies are provided.
  ///
  /// This test documents the CURRENT BROKEN behavior: when AnalyticsView
  /// doesn't pass local dependencies, analytics fails offline.
  @Test("Analytics fails without local dependencies (documents bug)")
  func analytics_failsWithoutLocalDependencies() async {
    // Setup: Backend fails, NO local dependencies provided
    let mockService = MockAnalyticsService()
    mockService.shouldFail = true

    // Create ViewModel WITHOUT local dependencies (current broken state)
    let viewModel = AnalyticsViewModel(
      analyticsService: mockService,
      localCalculator: nil, // Missing!
      journalRepository: nil, // Missing!
      catalogRepository: nil // Missing!
    )

    // Act: Load analytics
    await viewModel.loadAnalytics()

    // Assert: Should be in error state (this is the bug)
    if case .error = viewModel.state {
      // This is the CURRENT behavior - analytics fails offline
      // After fixing #242, this test should be updated or removed
    } else {
      Issue.record("Expected error state without local dependencies, got \(viewModel.state)")
    }
  }
}
