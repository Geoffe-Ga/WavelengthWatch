import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("TemporalPatternsViewModel Tests")
struct TemporalPatternsViewModelTests {
  // MARK: - Mock Service

  final class MockAnalyticsService: AnalyticsServiceProtocol {
    var temporalPatternsToReturn: TemporalPatterns?
    var errorToThrow: Error?
    var getTemporalPatternsCallCount = 0
    var lastUserId: Int?
    var lastStartDate: Date?
    var lastEndDate: Date?

    func getOverview(userId: Int) async throws -> AnalyticsOverview {
      fatalError("Not implemented in this test")
    }

    func getEmotionalLandscape(userId: Int) async throws -> EmotionalLandscape {
      fatalError("Not implemented in this test")
    }

    func getSelfCare(userId: Int, limit: Int) async throws -> SelfCareAnalytics {
      fatalError("Not implemented in this test")
    }

    func getTemporalPatterns(
      userId: Int,
      startDate: Date,
      endDate: Date
    ) async throws -> TemporalPatterns {
      getTemporalPatternsCallCount += 1
      lastUserId = userId
      lastStartDate = startDate
      lastEndDate = endDate

      if let error = errorToThrow {
        throw error
      }

      guard let patterns = temporalPatternsToReturn else {
        throw NSError(domain: "test", code: -1)
      }

      return patterns
    }
  }

  // MARK: - Mock Local Calculator

  final class MockLocalAnalyticsCalculator: LocalAnalyticsCalculatorProtocol {
    var temporalPatternsToReturn: TemporalPatterns?
    var calculateTemporalPatternsCallCount = 0
    var lastEntries: [LocalJournalEntry]?
    var lastStartDate: Date?
    var lastEndDate: Date?

    func calculateOverview(
      entries: [LocalJournalEntry],
      startDate: Date,
      endDate: Date
    ) -> AnalyticsOverview {
      fatalError("Not implemented in this test")
    }

    func calculateEmotionalLandscape(
      entries: [LocalJournalEntry],
      limit: Int
    ) -> EmotionalLandscape {
      fatalError("Not implemented in this test")
    }

    func calculateSelfCare(
      entries: [LocalJournalEntry],
      limit: Int
    ) -> SelfCareAnalytics {
      fatalError("Not implemented in this test")
    }

    func calculateTemporalPatterns(
      entries: [LocalJournalEntry],
      startDate: Date,
      endDate: Date
    ) -> TemporalPatterns {
      calculateTemporalPatternsCallCount += 1
      lastEntries = entries
      lastStartDate = startDate
      lastEndDate = endDate
      return temporalPatternsToReturn ?? TemporalPatterns(
        hourlyDistribution: [],
        consistencyScore: 0.0
      )
    }

    func calculateGrowthIndicators(
      entries: [LocalJournalEntry],
      startDate: Date,
      endDate: Date
    ) -> GrowthIndicators {
      fatalError("Not implemented in this test")
    }
  }

  // MARK: - Mock Journal Repository

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

  // MARK: - Mock Sync Settings Persistence

  final class MockSyncSettingsPersistence: SyncSettingsPersisting {
    var boolValues: [String: Bool] = [:]
    var doubleValues: [String: Double] = [:]

    func bool(forKey key: String) -> Bool {
      boolValues[key] ?? false
    }

    func set(_ value: Bool, forKey key: String) {
      boolValues[key] = value
    }

    func double(forKey key: String) -> Double {
      doubleValues[key] ?? 0.0
    }

    func set(_ value: Double, forKey key: String) {
      doubleValues[key] = value
    }

    func removeObject(forKey key: String) {
      boolValues.removeValue(forKey: key)
      doubleValues.removeValue(forKey: key)
    }
  }

  // MARK: - Test Fixtures

  static let testStartDate = Date(timeIntervalSince1970: 1_704_067_200) // 2024-01-01
  static let testEndDate = Date(timeIntervalSince1970: 1_706_745_600) // 2024-02-01

  // MARK: - Initialization Tests

  @Test("viewModel starts in idle state")
  @MainActor
  func viewModel_startsInIdleState() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)
    let viewModel = TemporalPatternsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    #expect(viewModel.state == .idle)
  }

  // MARK: - Loading Tests (Cloud Sync Enabled)

  @Test("viewModel loads temporal patterns from backend when cloud sync enabled")
  @MainActor
  func viewModel_loadsFromBackendWhenCloudSyncEnabled() async {
    let mockService = MockAnalyticsService()
    let mockPatterns = TemporalPatterns(
      hourlyDistribution: [
        HourlyDistributionItem(hour: 9, count: 5),
        HourlyDistributionItem(hour: 14, count: 3),
      ],
      consistencyScore: 75.0
    )
    mockService.temporalPatternsToReturn = mockPatterns

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = true
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = TemporalPatternsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings,
      userId: 123
    )

    await viewModel.loadTemporalPatterns(
      startDate: Self.testStartDate,
      endDate: Self.testEndDate
    )

    if case let .loaded(patterns) = viewModel.state {
      #expect(patterns == mockPatterns)
      #expect(mockService.getTemporalPatternsCallCount == 1)
      #expect(mockService.lastUserId == 123)
      #expect(mockService.lastStartDate == Self.testStartDate)
      #expect(mockService.lastEndDate == Self.testEndDate)
    } else {
      Issue.record("Expected loaded state, got \(viewModel.state)")
    }
  }

  @Test("viewModel falls back to local when backend fails and cloud sync enabled")
  @MainActor
  func viewModel_fallsBackToLocalWhenBackendFails() async {
    let mockService = MockAnalyticsService()
    mockService.errorToThrow = NSError(domain: "test", code: -1)

    let mockCalculator = MockLocalAnalyticsCalculator()
    let localPatterns = TemporalPatterns(
      hourlyDistribution: [
        HourlyDistributionItem(hour: 10, count: 2),
      ],
      consistencyScore: 50.0
    )
    mockCalculator.temporalPatternsToReturn = localPatterns

    let mockRepository = MockJournalRepository()
    mockRepository.entriesToReturn = [
      LocalJournalEntry(createdAt: Date(), userID: 1, curriculumID: 1, strategyID: nil),
    ]

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = true
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = TemporalPatternsViewModel(
      analyticsService: mockService,
      localCalculator: mockCalculator,
      journalRepository: mockRepository,
      syncSettings: syncSettings
    )

    await viewModel.loadTemporalPatterns(
      startDate: Self.testStartDate,
      endDate: Self.testEndDate
    )

    if case let .loaded(patterns) = viewModel.state {
      #expect(patterns == localPatterns)
      #expect(mockService.getTemporalPatternsCallCount == 1)
      #expect(mockCalculator.calculateTemporalPatternsCallCount == 1)
      #expect(mockRepository.fetchAllCallCount == 1)
    } else {
      Issue.record("Expected loaded state with local data, got \(viewModel.state)")
    }
  }

  // MARK: - Loading Tests (Cloud Sync Disabled)

  @Test("viewModel uses local calculator exclusively when cloud sync disabled")
  @MainActor
  func viewModel_usesLocalOnlyWhenCloudSyncDisabled() async {
    let mockService = MockAnalyticsService()
    mockService.temporalPatternsToReturn = TemporalPatterns(
      hourlyDistribution: [],
      consistencyScore: 0.0
    )

    let mockCalculator = MockLocalAnalyticsCalculator()
    let localPatterns = TemporalPatterns(
      hourlyDistribution: [
        HourlyDistributionItem(hour: 8, count: 7),
        HourlyDistributionItem(hour: 20, count: 4),
      ],
      consistencyScore: 85.0
    )
    mockCalculator.temporalPatternsToReturn = localPatterns

    let mockRepository = MockJournalRepository()
    mockRepository.entriesToReturn = [
      LocalJournalEntry(createdAt: Date(), userID: 1, curriculumID: 1, strategyID: nil),
    ]

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = false
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = TemporalPatternsViewModel(
      analyticsService: mockService,
      localCalculator: mockCalculator,
      journalRepository: mockRepository,
      syncSettings: syncSettings
    )

    await viewModel.loadTemporalPatterns(
      startDate: Self.testStartDate,
      endDate: Self.testEndDate
    )

    if case let .loaded(patterns) = viewModel.state {
      #expect(patterns == localPatterns)
      #expect(mockService.getTemporalPatternsCallCount == 0) // Backend NOT called
      #expect(mockCalculator.calculateTemporalPatternsCallCount == 1)
      #expect(mockRepository.fetchAllCallCount == 1)
    } else {
      Issue.record("Expected loaded state, got \(viewModel.state)")
    }
  }

  // MARK: - Error Tests

  @Test("viewModel reports error when both backend and local fail")
  @MainActor
  func viewModel_reportsErrorWhenBothFail() async {
    let mockService = MockAnalyticsService()
    mockService.errorToThrow = NSError(domain: "test", code: -1)

    let mockRepository = MockJournalRepository()
    mockRepository.errorToThrow = NSError(domain: "test", code: -2)

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = true
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = TemporalPatternsViewModel(
      analyticsService: mockService,
      localCalculator: nil,
      journalRepository: mockRepository,
      syncSettings: syncSettings
    )

    await viewModel.loadTemporalPatterns(
      startDate: Self.testStartDate,
      endDate: Self.testEndDate
    )

    if case let .error(message) = viewModel.state {
      #expect(message.contains("Failed to load"))
      #expect(mockService.getTemporalPatternsCallCount == 1)
    } else {
      Issue.record("Expected error state, got \(viewModel.state)")
    }
  }

  @Test("viewModel reports error when local calculator missing and cloud sync disabled")
  @MainActor
  func viewModel_reportsErrorWhenLocalMissingAndCloudSyncDisabled() async {
    let mockService = MockAnalyticsService()

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = false
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = TemporalPatternsViewModel(
      analyticsService: mockService,
      localCalculator: nil,
      journalRepository: nil,
      syncSettings: syncSettings
    )

    await viewModel.loadTemporalPatterns(
      startDate: Self.testStartDate,
      endDate: Self.testEndDate
    )

    if case let .error(message) = viewModel.state {
      #expect(message.contains("Local analytics"))
    } else {
      Issue.record("Expected error state, got \(viewModel.state)")
    }
  }

  // MARK: - Computed Properties Tests

  @Test("hourlyDistribution returns correct items when loaded")
  @MainActor
  func hourlyDistribution_returnsItemsWhenLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = TemporalPatternsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    let distribution = [
      HourlyDistributionItem(hour: 9, count: 5),
      HourlyDistributionItem(hour: 14, count: 3),
    ]
    let patterns = TemporalPatterns(
      hourlyDistribution: distribution,
      consistencyScore: 75.0
    )
    viewModel.state = .loaded(patterns)

    #expect(viewModel.hourlyDistribution == distribution)
  }

  @Test("hourlyDistribution returns empty array when not loaded")
  @MainActor
  func hourlyDistribution_returnsEmptyWhenNotLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = TemporalPatternsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    #expect(viewModel.hourlyDistribution.isEmpty)
  }

  @Test("consistencyScore returns correct value when loaded")
  @MainActor
  func consistencyScore_returnsValueWhenLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = TemporalPatternsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    let patterns = TemporalPatterns(
      hourlyDistribution: [],
      consistencyScore: 82.5
    )
    viewModel.state = .loaded(patterns)

    #expect(viewModel.consistencyScore == 82.5)
  }

  @Test("consistencyScore returns zero when not loaded")
  @MainActor
  func consistencyScore_returnsZeroWhenNotLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = TemporalPatternsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    #expect(viewModel.consistencyScore == 0.0)
  }

  // MARK: - Retry Tests

  @Test("viewModel retry calls loadTemporalPatterns")
  @MainActor
  func viewModel_retryCallsLoadTemporalPatterns() async {
    let mockService = MockAnalyticsService()
    mockService.errorToThrow = NSError(domain: "test", code: -1)

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = true
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = TemporalPatternsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    await viewModel.loadTemporalPatterns(
      startDate: Self.testStartDate,
      endDate: Self.testEndDate
    )
    #expect(mockService.getTemporalPatternsCallCount == 1)

    // Clear error and retry
    mockService.errorToThrow = nil
    mockService.temporalPatternsToReturn = TemporalPatterns(
      hourlyDistribution: [],
      consistencyScore: 60.0
    )

    await viewModel.retry(startDate: Self.testStartDate, endDate: Self.testEndDate)

    #expect(mockService.getTemporalPatternsCallCount == 2)
    if case .loaded = viewModel.state {
      // Success
    } else {
      Issue.record("Expected loaded state after retry")
    }
  }

  // MARK: - Backend Success Without Local Fallback Tests

  @Test("viewModel uses backend successfully without trying local")
  @MainActor
  func viewModel_usesBackendWithoutTryingLocal() async {
    let mockService = MockAnalyticsService()
    let backendPatterns = TemporalPatterns(
      hourlyDistribution: [
        HourlyDistributionItem(hour: 12, count: 10),
      ],
      consistencyScore: 90.0
    )
    mockService.temporalPatternsToReturn = backendPatterns

    let mockCalculator = MockLocalAnalyticsCalculator()
    let mockRepository = MockJournalRepository()

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = true
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = TemporalPatternsViewModel(
      analyticsService: mockService,
      localCalculator: mockCalculator,
      journalRepository: mockRepository,
      syncSettings: syncSettings
    )

    await viewModel.loadTemporalPatterns(
      startDate: Self.testStartDate,
      endDate: Self.testEndDate
    )

    if case let .loaded(patterns) = viewModel.state {
      #expect(patterns == backendPatterns)
      #expect(mockService.getTemporalPatternsCallCount == 1)
      #expect(mockCalculator.calculateTemporalPatternsCallCount == 0)
      #expect(mockRepository.fetchAllCallCount == 0)
    } else {
      Issue.record("Expected loaded state, got \(viewModel.state)")
    }
  }

  // MARK: - Date Parameter Tests

  @Test("viewModel passes correct dates to local calculator")
  @MainActor
  func viewModel_passesCorrectDatesToLocalCalculator() async {
    let mockService = MockAnalyticsService()

    let mockCalculator = MockLocalAnalyticsCalculator()
    let localPatterns = TemporalPatterns(
      hourlyDistribution: [],
      consistencyScore: 50.0
    )
    mockCalculator.temporalPatternsToReturn = localPatterns

    let mockRepository = MockJournalRepository()
    mockRepository.entriesToReturn = [
      LocalJournalEntry(createdAt: Date(), userID: 1, curriculumID: 1, strategyID: nil),
    ]

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = false
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = TemporalPatternsViewModel(
      analyticsService: mockService,
      localCalculator: mockCalculator,
      journalRepository: mockRepository,
      syncSettings: syncSettings
    )

    await viewModel.loadTemporalPatterns(
      startDate: Self.testStartDate,
      endDate: Self.testEndDate
    )

    #expect(mockCalculator.lastStartDate == Self.testStartDate)
    #expect(mockCalculator.lastEndDate == Self.testEndDate)
  }
}
