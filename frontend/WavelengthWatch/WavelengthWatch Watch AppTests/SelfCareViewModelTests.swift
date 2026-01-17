import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("SelfCareViewModel Tests")
struct SelfCareViewModelTests {
  // MARK: - Mock Service

  final class MockAnalyticsService: AnalyticsServiceProtocol {
    var selfCareToReturn: SelfCareAnalytics?
    var errorToThrow: Error?
    var getSelfCareCallCount = 0
    var lastUserId: Int?
    var lastLimit: Int?

    func getOverview(userId: Int) async throws -> AnalyticsOverview {
      fatalError("Not implemented in this test")
    }

    func getEmotionalLandscape(userId: Int) async throws -> EmotionalLandscape {
      fatalError("Not implemented in this test")
    }

    func getSelfCare(userId: Int, limit: Int) async throws -> SelfCareAnalytics {
      getSelfCareCallCount += 1
      lastUserId = userId
      lastLimit = limit

      if let error = errorToThrow {
        throw error
      }

      guard let selfCare = selfCareToReturn else {
        throw NSError(domain: "test", code: -1)
      }

      return selfCare
    }
  }

  // MARK: - Mock Local Calculator

  final class MockLocalAnalyticsCalculator: LocalAnalyticsCalculatorProtocol {
    var selfCareToReturn: SelfCareAnalytics?
    var calculateSelfCareCallCount = 0
    var lastEntries: [LocalJournalEntry]?
    var lastLimit: Int?

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
      calculateSelfCareCallCount += 1
      lastEntries = entries
      lastLimit = limit
      return selfCareToReturn ?? SelfCareAnalytics(
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
      fatalError("Not implemented in this test")
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

  // MARK: - Initialization Tests

  @Test("viewModel starts in idle state")
  @MainActor
  func viewModel_startsInIdleState() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)
    let viewModel = SelfCareViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    #expect(viewModel.state == .idle)
  }

  // MARK: - Loading Tests (Cloud Sync Enabled)

  @Test("viewModel loads self-care from backend when cloud sync enabled")
  @MainActor
  func viewModel_loadsFromBackendWhenCloudSyncEnabled() async {
    let mockService = MockAnalyticsService()
    let mockSelfCare = SelfCareAnalytics(
      topStrategies: [
        TopStrategyItem(strategyId: 1, strategy: "Breathe", count: 5, percentage: 50.0),
      ],
      diversityScore: 25.0,
      totalStrategyEntries: 10
    )
    mockService.selfCareToReturn = mockSelfCare

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = true
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = SelfCareViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings,
      userId: 123
    )

    await viewModel.loadSelfCare(limit: 5)

    if case let .loaded(selfCare) = viewModel.state {
      #expect(selfCare == mockSelfCare)
      #expect(mockService.getSelfCareCallCount == 1)
      #expect(mockService.lastUserId == 123)
      #expect(mockService.lastLimit == 5)
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
    let localSelfCare = SelfCareAnalytics(
      topStrategies: [
        TopStrategyItem(strategyId: 2, strategy: "Meditate", count: 3, percentage: 30.0),
      ],
      diversityScore: 20.0,
      totalStrategyEntries: 10
    )
    mockCalculator.selfCareToReturn = localSelfCare

    let mockRepository = MockJournalRepository()
    mockRepository.entriesToReturn = [
      LocalJournalEntry(createdAt: Date(), userID: 1, curriculumID: 1, strategyID: 2),
    ]

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = true
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = SelfCareViewModel(
      analyticsService: mockService,
      localCalculator: mockCalculator,
      journalRepository: mockRepository,
      syncSettings: syncSettings
    )

    await viewModel.loadSelfCare(limit: 5)

    if case let .loaded(selfCare) = viewModel.state {
      #expect(selfCare == localSelfCare)
      #expect(mockService.getSelfCareCallCount == 1)
      #expect(mockCalculator.calculateSelfCareCallCount == 1)
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
    mockService.selfCareToReturn = SelfCareAnalytics(
      topStrategies: [],
      diversityScore: 0.0,
      totalStrategyEntries: 0
    )

    let mockCalculator = MockLocalAnalyticsCalculator()
    let localSelfCare = SelfCareAnalytics(
      topStrategies: [
        TopStrategyItem(strategyId: 3, strategy: "Journal", count: 7, percentage: 70.0),
      ],
      diversityScore: 15.0,
      totalStrategyEntries: 10
    )
    mockCalculator.selfCareToReturn = localSelfCare

    let mockRepository = MockJournalRepository()
    mockRepository.entriesToReturn = [
      LocalJournalEntry(createdAt: Date(), userID: 1, curriculumID: 1, strategyID: 3),
    ]

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = false
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = SelfCareViewModel(
      analyticsService: mockService,
      localCalculator: mockCalculator,
      journalRepository: mockRepository,
      syncSettings: syncSettings
    )

    await viewModel.loadSelfCare(limit: 5)

    if case let .loaded(selfCare) = viewModel.state {
      #expect(selfCare == localSelfCare)
      #expect(mockService.getSelfCareCallCount == 0) // Backend NOT called
      #expect(mockCalculator.calculateSelfCareCallCount == 1)
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

    let viewModel = SelfCareViewModel(
      analyticsService: mockService,
      localCalculator: nil,
      journalRepository: mockRepository,
      syncSettings: syncSettings
    )

    await viewModel.loadSelfCare(limit: 5)

    if case let .error(message) = viewModel.state {
      #expect(message.contains("Failed to load"))
      #expect(mockService.getSelfCareCallCount == 1)
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

    let viewModel = SelfCareViewModel(
      analyticsService: mockService,
      localCalculator: nil,
      journalRepository: nil,
      syncSettings: syncSettings
    )

    await viewModel.loadSelfCare(limit: 5)

    if case let .error(message) = viewModel.state {
      #expect(message.contains("Local analytics"))
    } else {
      Issue.record("Expected error state, got \(viewModel.state)")
    }
  }

  // MARK: - Computed Properties Tests

  @Test("topStrategies returns correct items when loaded")
  @MainActor
  func topStrategies_returnsItemsWhenLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = SelfCareViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    let strategies = [
      TopStrategyItem(strategyId: 1, strategy: "Breathe", count: 5, percentage: 50.0),
      TopStrategyItem(strategyId: 2, strategy: "Meditate", count: 3, percentage: 30.0),
    ]
    let selfCare = SelfCareAnalytics(
      topStrategies: strategies,
      diversityScore: 25.0,
      totalStrategyEntries: 10
    )
    viewModel.state = .loaded(selfCare)

    #expect(viewModel.topStrategies == strategies)
  }

  @Test("topStrategies returns empty array when not loaded")
  @MainActor
  func topStrategies_returnsEmptyWhenNotLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = SelfCareViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    #expect(viewModel.topStrategies.isEmpty)
  }

  @Test("diversityScore returns correct value when loaded")
  @MainActor
  func diversityScore_returnsValueWhenLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = SelfCareViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    let selfCare = SelfCareAnalytics(
      topStrategies: [],
      diversityScore: 42.5,
      totalStrategyEntries: 10
    )
    viewModel.state = .loaded(selfCare)

    #expect(viewModel.diversityScore == 42.5)
  }

  @Test("diversityScore returns zero when not loaded")
  @MainActor
  func diversityScore_returnsZeroWhenNotLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = SelfCareViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    #expect(viewModel.diversityScore == 0.0)
  }

  @Test("totalStrategyEntries returns correct value when loaded")
  @MainActor
  func totalStrategyEntries_returnsValueWhenLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = SelfCareViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    let selfCare = SelfCareAnalytics(
      topStrategies: [],
      diversityScore: 25.0,
      totalStrategyEntries: 42
    )
    viewModel.state = .loaded(selfCare)

    #expect(viewModel.totalStrategyEntries == 42)
  }

  @Test("totalStrategyEntries returns zero when not loaded")
  @MainActor
  func totalStrategyEntries_returnsZeroWhenNotLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = SelfCareViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    #expect(viewModel.totalStrategyEntries == 0)
  }

  // MARK: - Retry Tests

  @Test("viewModel retry calls loadSelfCare")
  @MainActor
  func viewModel_retryCallsLoadSelfCare() async {
    let mockService = MockAnalyticsService()
    mockService.errorToThrow = NSError(domain: "test", code: -1)

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = true
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = SelfCareViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    await viewModel.loadSelfCare(limit: 5)
    #expect(mockService.getSelfCareCallCount == 1)

    // Clear error and retry
    mockService.errorToThrow = nil
    mockService.selfCareToReturn = SelfCareAnalytics(
      topStrategies: [],
      diversityScore: 10.0,
      totalStrategyEntries: 5
    )

    await viewModel.retry(limit: 5)

    #expect(mockService.getSelfCareCallCount == 2)
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
    let backendSelfCare = SelfCareAnalytics(
      topStrategies: [
        TopStrategyItem(strategyId: 1, strategy: "Walk", count: 10, percentage: 100.0),
      ],
      diversityScore: 10.0,
      totalStrategyEntries: 10
    )
    mockService.selfCareToReturn = backendSelfCare

    let mockCalculator = MockLocalAnalyticsCalculator()
    let mockRepository = MockJournalRepository()

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = true
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = SelfCareViewModel(
      analyticsService: mockService,
      localCalculator: mockCalculator,
      journalRepository: mockRepository,
      syncSettings: syncSettings
    )

    await viewModel.loadSelfCare(limit: 5)

    if case let .loaded(selfCare) = viewModel.state {
      #expect(selfCare == backendSelfCare)
      #expect(mockService.getSelfCareCallCount == 1)
      #expect(mockCalculator.calculateSelfCareCallCount == 0)
      #expect(mockRepository.fetchAllCallCount == 0)
    } else {
      Issue.record("Expected loaded state, got \(viewModel.state)")
    }
  }
}
