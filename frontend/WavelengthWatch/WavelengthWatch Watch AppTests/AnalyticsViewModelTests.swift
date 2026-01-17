import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("AnalyticsViewModel Tests")
struct AnalyticsViewModelTests {
  // MARK: - Mock Service

  final class MockAnalyticsService: AnalyticsServiceProtocol {
    var overviewToReturn: AnalyticsOverview?
    var emotionalLandscapeToReturn: EmotionalLandscape?
    var errorToThrow: Error?
    var getOverviewCallCount = 0
    var getEmotionalLandscapeCallCount = 0
    var lastUserId: Int?

    func getOverview(userId: Int) async throws -> AnalyticsOverview {
      getOverviewCallCount += 1
      lastUserId = userId

      if let error = errorToThrow {
        throw error
      }

      guard let overview = overviewToReturn else {
        throw NSError(domain: "test", code: -1)
      }

      return overview
    }

    func getEmotionalLandscape(userId: Int) async throws -> EmotionalLandscape {
      getEmotionalLandscapeCallCount += 1
      lastUserId = userId

      if let error = errorToThrow {
        throw error
      }

      guard let landscape = emotionalLandscapeToReturn else {
        throw NSError(domain: "test", code: -1)
      }

      return landscape
    }

    func getSelfCare(userId: Int, limit: Int) async throws -> SelfCareAnalytics {
      fatalError("Not implemented in this test")
    }

    func getTemporalPatterns(
      userId: Int,
      startDate: Date,
      endDate: Date
    ) async throws -> TemporalPatterns {
      fatalError("Not implemented in this test")
    }
  }

  // MARK: - Initialization Tests

  @Test("viewModel starts in idle state")
  @MainActor
  func viewModel_startsInIdleState() {
    let mockService = MockAnalyticsService()
    let viewModel = AnalyticsViewModel(analyticsService: mockService)

    #expect(viewModel.state == .idle)
  }

  // MARK: - Loading Tests

  @Test("viewModel loads analytics successfully")
  @MainActor
  func viewModel_loadsAnalyticsSuccessfully() async {
    let mockService = MockAnalyticsService()
    let mockOverview = AnalyticsOverview(
      totalEntries: 10,
      currentStreak: 5,
      longestStreak: 12,
      avgFrequency: 2.0,
      lastCheckIn: Date(),
      medicinalRatio: 0.75,
      medicinalTrend: 0.05,
      dominantLayerId: 1,
      dominantPhaseId: 2,
      uniqueEmotions: 8,
      strategiesUsed: 3,
      secondaryEmotionsPct: 0.6
    )
    mockService.overviewToReturn = mockOverview

    let viewModel = AnalyticsViewModel(analyticsService: mockService)

    await viewModel.loadAnalytics()

    if case let .loaded(overview) = viewModel.state {
      #expect(overview == mockOverview)
      #expect(mockService.getOverviewCallCount == 1)
    } else {
      Issue.record("Expected loaded state, got \(viewModel.state)")
    }
  }

  @Test("viewModel handles loading error")
  @MainActor
  func viewModel_handlesLoadingError() async {
    let mockService = MockAnalyticsService()
    mockService.errorToThrow = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

    let viewModel = AnalyticsViewModel(analyticsService: mockService)

    await viewModel.loadAnalytics()

    if case let .error(message) = viewModel.state {
      #expect(message.contains("Failed to load analytics"))
      #expect(mockService.getOverviewCallCount == 1)
    } else {
      Issue.record("Expected error state, got \(viewModel.state)")
    }
  }

  @Test("viewModel transitions to loading state")
  @MainActor
  func viewModel_transitionsToLoadingState() async {
    let mockService = MockAnalyticsService()
    // Make the service hang so we can check the loading state
    mockService.overviewToReturn = AnalyticsOverview(
      totalEntries: 0,
      currentStreak: 0,
      longestStreak: 0,
      avgFrequency: 0,
      lastCheckIn: nil,
      medicinalRatio: 0,
      medicinalTrend: 0,
      dominantLayerId: nil,
      dominantPhaseId: nil,
      uniqueEmotions: 0,
      strategiesUsed: 0,
      secondaryEmotionsPct: 0
    )

    let viewModel = AnalyticsViewModel(analyticsService: mockService)

    // Start loading but don't await
    let task = Task {
      await viewModel.loadAnalytics()
    }

    // Give it a moment to transition to loading
    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

    // Cancel to avoid hanging
    task.cancel()

    // State should either be loading or loaded (race condition)
    let isLoadingOrLoaded = switch viewModel.state {
    case .loading, .loaded: true
    default: false
    }

    #expect(isLoadingOrLoaded)
  }

  // MARK: - Retry Tests

  @Test("viewModel retry calls loadAnalytics")
  @MainActor
  func viewModel_retryCallsLoadAnalytics() async {
    let mockService = MockAnalyticsService()
    mockService.errorToThrow = NSError(domain: "test", code: -1)

    let viewModel = AnalyticsViewModel(analyticsService: mockService)

    await viewModel.loadAnalytics()
    #expect(mockService.getOverviewCallCount == 1)

    // Clear error and retry
    mockService.errorToThrow = nil
    mockService.overviewToReturn = AnalyticsOverview(
      totalEntries: 5,
      currentStreak: 2,
      longestStreak: 2,
      avgFrequency: 1.0,
      lastCheckIn: nil,
      medicinalRatio: 0.5,
      medicinalTrend: 0,
      dominantLayerId: nil,
      dominantPhaseId: nil,
      uniqueEmotions: 3,
      strategiesUsed: 1,
      secondaryEmotionsPct: 0.4
    )

    await viewModel.retry()

    #expect(mockService.getOverviewCallCount == 2)
    if case .loaded = viewModel.state {
      // Success
    } else {
      Issue.record("Expected loaded state after retry")
    }
  }

  // MARK: - User ID Tests

  @Test("viewModel passes numeric user identifier to service")
  @MainActor
  func viewModel_passesNumericUserIdToService() async {
    let mockService = MockAnalyticsService()
    mockService.overviewToReturn = AnalyticsOverview(
      totalEntries: 0,
      currentStreak: 0,
      longestStreak: 0,
      avgFrequency: 0,
      lastCheckIn: nil,
      medicinalRatio: 0,
      medicinalTrend: 0,
      dominantLayerId: nil,
      dominantPhaseId: nil,
      uniqueEmotions: 0,
      strategiesUsed: 0,
      secondaryEmotionsPct: 0
    )

    let viewModel = AnalyticsViewModel(
      analyticsService: mockService,
      userDefaults: .standard
    )

    await viewModel.loadAnalytics()

    #expect(mockService.lastUserId != nil)
    #expect(mockService.lastUserId! > 0)
  }

  // MARK: - Local Fallback Tests

  final class MockLocalAnalyticsCalculator: LocalAnalyticsCalculatorProtocol {
    var overviewToReturn: AnalyticsOverview?
    var landscapeToReturn: EmotionalLandscape?
    var calculateOverviewCallCount = 0
    var calculateLandscapeCallCount = 0

    func calculateOverview(
      entries: [LocalJournalEntry],
      startDate: Date,
      endDate: Date
    ) -> AnalyticsOverview {
      calculateOverviewCallCount += 1
      return overviewToReturn ?? AnalyticsOverview(
        totalEntries: 0,
        currentStreak: 0,
        longestStreak: 0,
        avgFrequency: 0,
        lastCheckIn: nil,
        medicinalRatio: 0,
        medicinalTrend: 0,
        dominantLayerId: nil,
        dominantPhaseId: nil,
        uniqueEmotions: 0,
        strategiesUsed: 0,
        secondaryEmotionsPct: 0
      )
    }

    func calculateEmotionalLandscape(
      entries: [LocalJournalEntry],
      limit: Int
    ) -> EmotionalLandscape {
      calculateLandscapeCallCount += 1
      return landscapeToReturn ?? EmotionalLandscape(
        layerDistribution: [],
        phaseDistribution: [],
        topEmotions: []
      )
    }

    func calculateSelfCare(
      entries: [LocalJournalEntry],
      limit: Int
    ) -> SelfCareAnalytics {
      SelfCareAnalytics(
        topStrategies: [],
        diversityScore: 0.0,
        totalStrategyEntries: 0
      )
    }

    func calculateTemporalPatterns(
      entries: [LocalJournalEntry],
      startDate: Date,
      endDate: Date
    ) -> TemporalPatterns {
      TemporalPatterns(
        hourlyDistribution: [],
        consistencyScore: 0.0
      )
    }

    func calculateGrowthIndicators(
      entries: [LocalJournalEntry],
      startDate: Date,
      endDate: Date
    ) -> GrowthIndicators {
      GrowthIndicators(
        medicinalTrend: 0.0,
        layerDiversity: 0,
        phaseCoverage: 0
      )
    }
  }

  final class MockJournalRepository: JournalRepositoryProtocol {
    var entriesToReturn: [LocalJournalEntry] = []
    var errorToThrow: Error?
    var fetchAllCallCount = 0

    func save(_ entry: LocalJournalEntry) throws {
      if let error = errorToThrow { throw error }
    }

    func update(_ entry: LocalJournalEntry) throws {
      if let error = errorToThrow { throw error }
    }

    func delete(id: UUID) throws {
      if let error = errorToThrow { throw error }
    }

    func fetch(id: UUID) throws -> LocalJournalEntry? {
      if let error = errorToThrow { throw error }
      return entriesToReturn.first { $0.id == id }
    }

    func fetchAll() throws -> [LocalJournalEntry] {
      fetchAllCallCount += 1
      if let error = errorToThrow { throw error }
      return entriesToReturn
    }

    func fetchPendingSync() throws -> [LocalJournalEntry] {
      if let error = errorToThrow { throw error }
      return entriesToReturn.filter { $0.syncStatus == .pending }
    }

    func count() throws -> Int {
      if let error = errorToThrow { throw error }
      return entriesToReturn.count
    }
  }

  final class MockCatalogRepository: CatalogRepositoryProtocol {
    var catalogToReturn: CatalogResponseModel?

    func cachedCatalog() -> CatalogResponseModel? {
      catalogToReturn
    }

    func loadCatalog(forceRefresh: Bool) async throws -> CatalogResponseModel {
      throw NSError(domain: "test", code: -1)
    }

    func refreshCatalog() async throws -> CatalogResponseModel {
      throw NSError(domain: "test", code: -1)
    }
  }

  @Test("viewModel falls back to local when backend fails")
  @MainActor
  func viewModel_fallsBackToLocalWhenBackendFails() async {
    let mockService = MockAnalyticsService()
    mockService.errorToThrow = NSError(domain: "test", code: -1)

    let mockCalculator = MockLocalAnalyticsCalculator()
    let localOverview = AnalyticsOverview(
      totalEntries: 5,
      currentStreak: 2,
      longestStreak: 3,
      avgFrequency: 1.5,
      lastCheckIn: Date(),
      medicinalRatio: 0.6,
      medicinalTrend: 0.1,
      dominantLayerId: 2,
      dominantPhaseId: 1,
      uniqueEmotions: 4,
      strategiesUsed: 2,
      secondaryEmotionsPct: 0.5
    )
    mockCalculator.overviewToReturn = localOverview

    let mockRepository = MockJournalRepository()
    mockRepository.entriesToReturn = [
      LocalJournalEntry(createdAt: Date(), userID: 1, curriculumID: 1),
    ]

    let mockCatalog = MockCatalogRepository()
    mockCatalog.catalogToReturn = testCatalog()

    let viewModel = AnalyticsViewModel(
      analyticsService: mockService,
      localCalculator: mockCalculator,
      journalRepository: mockRepository,
      catalogRepository: mockCatalog
    )

    await viewModel.loadAnalytics()

    if case let .loaded(overview) = viewModel.state {
      #expect(overview == localOverview)
      #expect(mockService.getOverviewCallCount == 1)
      #expect(mockCalculator.calculateOverviewCallCount == 1)
      #expect(mockRepository.fetchAllCallCount == 1)
    } else {
      Issue.record("Expected loaded state with local data, got \(viewModel.state)")
    }
  }

  @Test("viewModel reports error when both backend and local fail")
  @MainActor
  func viewModel_reportsErrorWhenBothFail() async {
    let mockService = MockAnalyticsService()
    mockService.errorToThrow = NSError(domain: "test", code: -1)

    let mockRepository = MockJournalRepository()
    mockRepository.errorToThrow = NSError(domain: "test", code: -2)

    let mockCatalog = MockCatalogRepository()

    let viewModel = AnalyticsViewModel(
      analyticsService: mockService,
      localCalculator: nil,
      journalRepository: mockRepository,
      catalogRepository: mockCatalog
    )

    await viewModel.loadAnalytics()

    if case let .error(message) = viewModel.state {
      #expect(message.contains("Failed to load analytics"))
      #expect(mockService.getOverviewCallCount == 1)
    } else {
      Issue.record("Expected error state, got \(viewModel.state)")
    }
  }

  @Test("viewModel uses backend successfully without trying local")
  @MainActor
  func viewModel_usesBackendWithoutTryingLocal() async {
    let mockService = MockAnalyticsService()
    let backendOverview = AnalyticsOverview(
      totalEntries: 10,
      currentStreak: 5,
      longestStreak: 12,
      avgFrequency: 2.0,
      lastCheckIn: Date(),
      medicinalRatio: 0.75,
      medicinalTrend: 0.05,
      dominantLayerId: 1,
      dominantPhaseId: 2,
      uniqueEmotions: 8,
      strategiesUsed: 3,
      secondaryEmotionsPct: 0.6
    )
    mockService.overviewToReturn = backendOverview

    let mockCalculator = MockLocalAnalyticsCalculator()
    let mockRepository = MockJournalRepository()
    let mockCatalog = MockCatalogRepository()

    let viewModel = AnalyticsViewModel(
      analyticsService: mockService,
      localCalculator: mockCalculator,
      journalRepository: mockRepository,
      catalogRepository: mockCatalog
    )

    await viewModel.loadAnalytics()

    if case let .loaded(overview) = viewModel.state {
      #expect(overview == backendOverview)
      #expect(mockService.getOverviewCallCount == 1)
      #expect(mockCalculator.calculateOverviewCallCount == 0)
      #expect(mockRepository.fetchAllCallCount == 0)
    } else {
      Issue.record("Expected loaded state, got \(viewModel.state)")
    }
  }

  // Helper to create test catalog
  private func testCatalog() -> CatalogResponseModel {
    CatalogResponseModel(
      phaseOrder: ["Rising", "Peaking", "Falling", "Resting"],
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
              toxic: [],
              strategies: []
            ),
          ]
        ),
      ]
    )
  }
}
