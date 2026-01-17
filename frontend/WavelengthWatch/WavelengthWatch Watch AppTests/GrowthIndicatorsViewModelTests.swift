import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("GrowthIndicatorsViewModel Tests")
struct GrowthIndicatorsViewModelTests {
  // MARK: - Mock Service

  final class MockAnalyticsService: AnalyticsServiceProtocol {
    var growthIndicatorsToReturn: GrowthIndicators?
    var errorToThrow: Error?
    var getGrowthIndicatorsCallCount = 0
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
      fatalError("Not implemented in this test")
    }

    func getGrowthIndicators(
      userId: Int,
      startDate: Date,
      endDate: Date
    ) async throws -> GrowthIndicators {
      getGrowthIndicatorsCallCount += 1
      lastUserId = userId
      lastStartDate = startDate
      lastEndDate = endDate

      if let error = errorToThrow {
        throw error
      }

      guard let indicators = growthIndicatorsToReturn else {
        throw NSError(domain: "test", code: -1)
      }

      return indicators
    }
  }

  // MARK: - Mock Local Calculator

  final class MockLocalAnalyticsCalculator: LocalAnalyticsCalculatorProtocol {
    var growthIndicatorsToReturn: GrowthIndicators?
    var calculateGrowthIndicatorsCallCount = 0
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
      fatalError("Not implemented in this test")
    }

    func calculateGrowthIndicators(
      entries: [LocalJournalEntry],
      startDate: Date,
      endDate: Date
    ) -> GrowthIndicators {
      calculateGrowthIndicatorsCallCount += 1
      lastEntries = entries
      lastStartDate = startDate
      lastEndDate = endDate
      return growthIndicatorsToReturn ?? GrowthIndicators(
        medicinalTrend: 0.0,
        layerDiversity: 0,
        phaseCoverage: 0
      )
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
    let viewModel = GrowthIndicatorsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    #expect(viewModel.state == .idle)
  }

  // MARK: - Loading Tests (Cloud Sync Enabled)

  @Test("viewModel loads growth indicators from backend when cloud sync enabled")
  @MainActor
  func viewModel_loadsFromBackendWhenCloudSyncEnabled() async {
    let mockService = MockAnalyticsService()
    let startDate = Date()
    let endDate = Date().addingTimeInterval(86400)
    let mockIndicators = GrowthIndicators(
      medicinalTrend: 0.15,
      layerDiversity: 3,
      phaseCoverage: 5
    )
    mockService.growthIndicatorsToReturn = mockIndicators

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = true
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = GrowthIndicatorsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings,
      userId: 123
    )

    await viewModel.loadGrowthIndicators(startDate: startDate, endDate: endDate)

    if case let .loaded(indicators) = viewModel.state {
      #expect(indicators == mockIndicators)
      #expect(mockService.getGrowthIndicatorsCallCount == 1)
      #expect(mockService.lastUserId == 123)
      #expect(mockService.lastStartDate == startDate)
      #expect(mockService.lastEndDate == endDate)
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
    let localIndicators = GrowthIndicators(
      medicinalTrend: 0.20,
      layerDiversity: 4,
      phaseCoverage: 6
    )
    mockCalculator.growthIndicatorsToReturn = localIndicators

    let mockRepository = MockJournalRepository()
    mockRepository.entriesToReturn = [
      LocalJournalEntry(createdAt: Date(), userID: 1, curriculumID: 1, strategyID: nil),
    ]

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = true
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let startDate = Date()
    let endDate = Date().addingTimeInterval(86400)

    let viewModel = GrowthIndicatorsViewModel(
      analyticsService: mockService,
      localCalculator: mockCalculator,
      journalRepository: mockRepository,
      syncSettings: syncSettings
    )

    await viewModel.loadGrowthIndicators(startDate: startDate, endDate: endDate)

    if case let .loaded(indicators) = viewModel.state {
      #expect(indicators == localIndicators)
      #expect(mockService.getGrowthIndicatorsCallCount == 1)
      #expect(mockCalculator.calculateGrowthIndicatorsCallCount == 1)
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
    mockService.growthIndicatorsToReturn = GrowthIndicators(
      medicinalTrend: 0.0,
      layerDiversity: 0,
      phaseCoverage: 0
    )

    let mockCalculator = MockLocalAnalyticsCalculator()
    let localIndicators = GrowthIndicators(
      medicinalTrend: 0.25,
      layerDiversity: 5,
      phaseCoverage: 7
    )
    mockCalculator.growthIndicatorsToReturn = localIndicators

    let mockRepository = MockJournalRepository()
    mockRepository.entriesToReturn = [
      LocalJournalEntry(createdAt: Date(), userID: 1, curriculumID: 1, strategyID: nil),
    ]

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = false
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let startDate = Date()
    let endDate = Date().addingTimeInterval(86400)

    let viewModel = GrowthIndicatorsViewModel(
      analyticsService: mockService,
      localCalculator: mockCalculator,
      journalRepository: mockRepository,
      syncSettings: syncSettings
    )

    await viewModel.loadGrowthIndicators(startDate: startDate, endDate: endDate)

    if case let .loaded(indicators) = viewModel.state {
      #expect(indicators == localIndicators)
      #expect(mockService.getGrowthIndicatorsCallCount == 0) // Backend NOT called
      #expect(mockCalculator.calculateGrowthIndicatorsCallCount == 1)
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

    let startDate = Date()
    let endDate = Date().addingTimeInterval(86400)

    let viewModel = GrowthIndicatorsViewModel(
      analyticsService: mockService,
      localCalculator: nil,
      journalRepository: mockRepository,
      syncSettings: syncSettings
    )

    await viewModel.loadGrowthIndicators(startDate: startDate, endDate: endDate)

    if case let .error(message) = viewModel.state {
      #expect(message.contains("Failed to load"))
      #expect(mockService.getGrowthIndicatorsCallCount == 1)
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

    let startDate = Date()
    let endDate = Date().addingTimeInterval(86400)

    let viewModel = GrowthIndicatorsViewModel(
      analyticsService: mockService,
      localCalculator: nil,
      journalRepository: nil,
      syncSettings: syncSettings
    )

    await viewModel.loadGrowthIndicators(startDate: startDate, endDate: endDate)

    if case let .error(message) = viewModel.state {
      #expect(message.contains("Local analytics"))
    } else {
      Issue.record("Expected error state, got \(viewModel.state)")
    }
  }

  // MARK: - Computed Properties Tests

  @Test("medicinalTrend returns correct value when loaded")
  @MainActor
  func medicinalTrend_returnsValueWhenLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = GrowthIndicatorsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    let indicators = GrowthIndicators(
      medicinalTrend: 0.42,
      layerDiversity: 3,
      phaseCoverage: 5
    )
    viewModel.state = .loaded(indicators)

    #expect(viewModel.medicinalTrend == 0.42)
  }

  @Test("medicinalTrend returns zero when not loaded")
  @MainActor
  func medicinalTrend_returnsZeroWhenNotLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = GrowthIndicatorsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    #expect(viewModel.medicinalTrend == 0.0)
  }

  @Test("layerDiversity returns correct value when loaded")
  @MainActor
  func layerDiversity_returnsValueWhenLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = GrowthIndicatorsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    let indicators = GrowthIndicators(
      medicinalTrend: 0.30,
      layerDiversity: 6,
      phaseCoverage: 8
    )
    viewModel.state = .loaded(indicators)

    #expect(viewModel.layerDiversity == 6)
  }

  @Test("layerDiversity returns zero when not loaded")
  @MainActor
  func layerDiversity_returnsZeroWhenNotLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = GrowthIndicatorsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    #expect(viewModel.layerDiversity == 0)
  }

  @Test("phaseCoverage returns correct value when loaded")
  @MainActor
  func phaseCoverage_returnsValueWhenLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = GrowthIndicatorsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    let indicators = GrowthIndicators(
      medicinalTrend: 0.20,
      layerDiversity: 4,
      phaseCoverage: 9
    )
    viewModel.state = .loaded(indicators)

    #expect(viewModel.phaseCoverage == 9)
  }

  @Test("phaseCoverage returns zero when not loaded")
  @MainActor
  func phaseCoverage_returnsZeroWhenNotLoaded() {
    let mockService = MockAnalyticsService()
    let mockPersistence = MockSyncSettingsPersistence()
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let viewModel = GrowthIndicatorsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    #expect(viewModel.phaseCoverage == 0)
  }

  // MARK: - Retry Tests

  @Test("viewModel retry calls loadGrowthIndicators")
  @MainActor
  func viewModel_retryCallsLoadGrowthIndicators() async {
    let mockService = MockAnalyticsService()
    mockService.errorToThrow = NSError(domain: "test", code: -1)

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = true
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let startDate = Date()
    let endDate = Date().addingTimeInterval(86400)

    let viewModel = GrowthIndicatorsViewModel(
      analyticsService: mockService,
      syncSettings: syncSettings
    )

    await viewModel.loadGrowthIndicators(startDate: startDate, endDate: endDate)
    #expect(mockService.getGrowthIndicatorsCallCount == 1)

    // Clear error and retry
    mockService.errorToThrow = nil
    mockService.growthIndicatorsToReturn = GrowthIndicators(
      medicinalTrend: 0.10,
      layerDiversity: 2,
      phaseCoverage: 4
    )

    await viewModel.retry(startDate: startDate, endDate: endDate)

    #expect(mockService.getGrowthIndicatorsCallCount == 2)
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
    let backendIndicators = GrowthIndicators(
      medicinalTrend: 0.35,
      layerDiversity: 6,
      phaseCoverage: 8
    )
    mockService.growthIndicatorsToReturn = backendIndicators

    let mockCalculator = MockLocalAnalyticsCalculator()
    let mockRepository = MockJournalRepository()

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = true
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let startDate = Date()
    let endDate = Date().addingTimeInterval(86400)

    let viewModel = GrowthIndicatorsViewModel(
      analyticsService: mockService,
      localCalculator: mockCalculator,
      journalRepository: mockRepository,
      syncSettings: syncSettings
    )

    await viewModel.loadGrowthIndicators(startDate: startDate, endDate: endDate)

    if case let .loaded(indicators) = viewModel.state {
      #expect(indicators == backendIndicators)
      #expect(mockService.getGrowthIndicatorsCallCount == 1)
      #expect(mockCalculator.calculateGrowthIndicatorsCallCount == 0)
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
    let mockIndicators = GrowthIndicators(
      medicinalTrend: 0.15,
      layerDiversity: 4,
      phaseCoverage: 6
    )
    mockCalculator.growthIndicatorsToReturn = mockIndicators

    let mockRepository = MockJournalRepository()
    mockRepository.entriesToReturn = [
      LocalJournalEntry(createdAt: Date(), userID: 1, curriculumID: 1, strategyID: nil),
    ]

    let mockPersistence = MockSyncSettingsPersistence()
    mockPersistence.boolValues[SyncSettings.cloudSyncEnabledKey] = false
    let syncSettings = SyncSettings(persistence: mockPersistence)

    let startDate = Date()
    let endDate = Date().addingTimeInterval(86400 * 7) // 7 days later

    let viewModel = GrowthIndicatorsViewModel(
      analyticsService: mockService,
      localCalculator: mockCalculator,
      journalRepository: mockRepository,
      syncSettings: syncSettings
    )

    await viewModel.loadGrowthIndicators(startDate: startDate, endDate: endDate)

    #expect(mockCalculator.lastStartDate == startDate)
    #expect(mockCalculator.lastEndDate == endDate)
  }
}
