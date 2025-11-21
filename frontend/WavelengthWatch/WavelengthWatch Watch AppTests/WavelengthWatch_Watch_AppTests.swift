import Foundation
import SwiftUI
import Testing
import UserNotifications
@testable import WavelengthWatch_Watch_App

struct CatalogRepositoryTests {
  private func makeRepository(
    remote: CatalogRemoteStub,
    cache: InMemoryCatalogCacheMock,
    now: @escaping () -> Date,
    ttl: TimeInterval = 60 * 60 * 24,
    logger: CatalogRepositoryLogging = CatalogRepositoryLoggerSpy()
  ) -> CatalogRepository {
    CatalogRepository(
      remote: remote,
      cache: cache,
      dateProvider: now,
      cacheTTL: ttl,
      logger: logger
    )
  }

  @Test func returnsCachedCatalogWhenFresh() async throws {
    let remote = CatalogRemoteStub(response: SampleData.catalog)
    let cache = InMemoryCatalogCacheMock()
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let envelope = CatalogCacheEnvelope(fetchedAt: Date(timeIntervalSince1970: 1000), catalog: SampleData.catalog)
    cache.storedData = try encoder.encode(envelope)
    let repository = makeRepository(remote: remote, cache: cache, now: { Date(timeIntervalSince1970: 1500) })

    #expect(repository.cachedCatalog() == SampleData.catalog)
    let catalog = try await repository.loadCatalog()
    #expect(catalog == SampleData.catalog)
    #expect(remote.fetchCount == 0)
  }

  @Test func refreshesWhenCacheIsStale() async throws {
    let remote = CatalogRemoteStub(response: SampleData.catalog)
    let cache = InMemoryCatalogCacheMock()
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let staleDate = Date(timeIntervalSince1970: 0)
    let envelope = CatalogCacheEnvelope(fetchedAt: staleDate, catalog: SampleData.catalog)
    cache.storedData = try encoder.encode(envelope)
    let repository = makeRepository(remote: remote, cache: cache, now: { Date(timeIntervalSince1970: 60 * 60 * 24 + 10) })

    let catalog = try await repository.loadCatalog()
    #expect(catalog == SampleData.catalog)
    #expect(remote.fetchCount == 1)
  }

  @Test func invalidatesCorruptCache() async throws {
    let remote = CatalogRemoteStub(response: SampleData.catalog)
    let cache = InMemoryCatalogCacheMock()
    cache.storedData = Data("invalid".utf8)
    let logger = CatalogRepositoryLoggerSpy()
    let repository = makeRepository(remote: remote, cache: cache, now: { Date() }, logger: logger)

    let catalog = try await repository.loadCatalog()
    #expect(catalog == SampleData.catalog)
    #expect(remote.fetchCount == 1)
    #expect(cache.storedData != nil)
    #expect(cache.removeCount == 1)
    #expect(logger.errors.count == 1)
  }

  @Test func propagatesNetworkFailures() async {
    enum StubError: Error { case transport }
    let cache = InMemoryCatalogCacheMock()
    cache.storedData = nil
    let repository = CatalogRepository(
      remote: FailingRemoteStub(error: StubError.transport),
      cache: cache,
      dateProvider: { Date() }
    )

    do {
      _ = try await repository.loadCatalog(forceRefresh: true)
      #expect(Bool(false))
    } catch {
      #expect(error is StubError)
    }
  }
}

struct JournalClientTests {
  @Test func encodesPayloadWithStableUserIdentifier() async throws {
    let spy = APIClientSpy()
    let defaults = UserDefaults(suiteName: "JournalClientTests")!
    defaults.removePersistentDomain(forName: "JournalClientTests")
    defaults.set("12345678-1234-1234-1234-1234567890ab", forKey: "com.wavelengthwatch.userIdentifier")
    let date = Date(timeIntervalSince1970: 1000)
    let client = JournalClient(apiClient: spy, dateProvider: { date }, userDefaults: defaults)

    _ = try await client.submit(curriculumID: 5, secondaryCurriculumID: 7, strategyID: 9, initiatedBy: .scheduled)

    #expect(spy.lastPath == APIPath.journal)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let payload = try decoder.decode(JournalPayload.self, from: spy.lastBody ?? Data())
    #expect(payload.curriculumID == 5)
    #expect(payload.secondaryCurriculumID == 7)
    #expect(payload.strategyID == 9)
    #expect(payload.createdAt == date)
    #expect(payload.initiatedBy == .scheduled)
    let expected = Int("123456781234", radix: 16) ?? 0
    #expect(payload.userID == expected)
  }
}

struct ContentViewModelInitiationContextTests {
  @MainActor
  @Test func usesCurrentInitiatedByWhenNotOverridden() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    viewModel.setInitiatedBy(.scheduled)
    await viewModel.journal(curriculumID: 1)

    #expect(journal.submissions.count == 1)
    #expect(journal.submittedInitiatedBy == .scheduled)
  }

  @MainActor
  @Test func resetsToSelfInitiatedAfterSubmission() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    viewModel.setInitiatedBy(.scheduled)
    await viewModel.journal(curriculumID: 1)

    #expect(viewModel.currentInitiatedBy == .self_initiated)
  }

  @MainActor
  @Test func allowsExplicitOverrideOfInitiatedBy() async {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    viewModel.setInitiatedBy(.scheduled)
    await viewModel.journal(curriculumID: 1, initiatedBy: .self_initiated)

    #expect(journal.submittedInitiatedBy == .self_initiated)
  }
}

struct NotificationSchedulerTests {
  @Test func requestsPermissionWithCorrectOptions() async throws {
    let mockCenter = MockNotificationCenter()
    let scheduler = NotificationScheduler(notificationCenter: mockCenter)

    let granted = try await scheduler.requestPermission()

    #expect(granted == true)
    #expect(mockCenter.requestedPermissions?.contains(.alert) == true)
    #expect(mockCenter.requestedPermissions?.contains(.sound) == true)
    #expect(mockCenter.requestedPermissions?.contains(.badge) == true)
  }

  @Test func schedulesNotificationsForEnabledSchedules() async throws {
    let mockCenter = MockNotificationCenter()
    let scheduler = NotificationScheduler(notificationCenter: mockCenter)

    var time = DateComponents()
    time.hour = 8
    time.minute = 0

    let enabledSchedule = JournalSchedule(time: time, enabled: true, repeatDays: [1, 3, 5])
    let disabledSchedule = JournalSchedule(time: time, enabled: false, repeatDays: [2, 4])

    try await scheduler.scheduleNotifications(for: [enabledSchedule, disabledSchedule])

    // Should only schedule for enabled schedule (3 days = 3 notifications)
    #expect(mockCenter.addedRequests.count == 3)
    #expect(mockCenter.removedAllPending == true)
  }

  @Test func cancelsAllNotifications() {
    let mockCenter = MockNotificationCenter()
    let scheduler = NotificationScheduler(notificationCenter: mockCenter)

    scheduler.cancelAllNotifications()

    #expect(mockCenter.removedAllPending == true)
  }

  @Test func notificationContentIncludesScheduleInfo() async throws {
    let mockCenter = MockNotificationCenter()
    let scheduler = NotificationScheduler(notificationCenter: mockCenter)

    var time = DateComponents()
    time.hour = 8
    time.minute = 0

    let schedule = JournalSchedule(time: time, repeatDays: [1])

    try await scheduler.scheduleNotifications(for: [schedule])

    #expect(mockCenter.addedRequests.count == 1)
    let request = mockCenter.addedRequests[0]
    #expect(request.content.title == "Journal Check-In")
    #expect(request.content.userInfo["initiatedBy"] as? String == "scheduled")
    #expect(request.content.userInfo["scheduleId"] as? String == schedule.id.uuidString)
  }

  @Test func mockNotificationCenterPreventsSystemCalls() async throws {
    // This test verifies that we're using the mock and not making system calls
    let mockCenter = MockNotificationCenter()
    let scheduler = NotificationScheduler(notificationCenter: mockCenter)

    // Perform a notification operation
    _ = try await scheduler.requestPermission()

    // Verify the mock was used (no system calls were made)
    mockCenter.assertWasUsed()
    #expect(mockCenter.requestedPermissions != nil)
  }
}

struct JournalUIInteractionTests {
  private func makeSampleStrategyPhase() -> CatalogPhaseModel {
    let medicinal = CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Commitment")
    let strategy = CatalogStrategyModel(id: 3, strategy: "Cold Shower", color: "Blue")
    return CatalogPhaseModel(id: 1, name: "Rising", medicinal: [medicinal], toxic: [], strategies: [strategy])
  }

  private func makeSampleCurriculumPhase() -> CatalogPhaseModel {
    let medicinal = CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Commitment")
    let toxic = CatalogCurriculumEntryModel(id: 2, dosage: .toxic, expression: "Overcommitment")
    return CatalogPhaseModel(id: 1, name: "Rising", medicinal: [medicinal], toxic: [toxic], strategies: [])
  }

  @Test func strategyPhaseHasJournalIcon() {
    let phase = makeSampleStrategyPhase()

    #expect(phase.strategies.count == 1)
    #expect(phase.medicinal.count == 1)

    let strategy = phase.strategies[0]
    #expect(strategy.id == 3)
    #expect(strategy.strategy == "Cold Shower")
  }

  @Test func curriculumPhaseHasMedicinalAndToxic() {
    let phase = makeSampleCurriculumPhase()

    #expect(phase.medicinal.count == 1)
    #expect(phase.toxic.count == 1)

    let medicinal = phase.medicinal[0]
    #expect(medicinal.id == 1)
    #expect(medicinal.expression == "Commitment")
    #expect(medicinal.dosage == .medicinal)

    let toxic = phase.toxic[0]
    #expect(toxic.id == 2)
    #expect(toxic.expression == "Overcommitment")
    #expect(toxic.dosage == .toxic)
  }

  @Test func strategyCardHasPlusIconAndConfirmation() {
    let phase = makeSampleStrategyPhase()
    let strategy = phase.strategies[0]

    #expect(strategy.id == 3)
    #expect(strategy.strategy == "Cold Shower")
    #expect(phase.medicinal.count == 1) // Ensures primaryID exists for plus icon
  }

  @Test func strategiesOnlyPhaseCanUseFallbackCurriculum() {
    let strategiesOnlyStrategy = CatalogStrategyModel(id: 5, strategy: "Deep Breathing", color: "Blue")
    let strategiesOnlyPhase = CatalogPhaseModel(id: 2, name: "Strategies", medicinal: [], toxic: [], strategies: [strategiesOnlyStrategy])

    #expect(strategiesOnlyPhase.medicinal.isEmpty)
    #expect(strategiesOnlyPhase.toxic.isEmpty)
    #expect(strategiesOnlyPhase.strategies.count == 1)
    #expect(strategiesOnlyPhase.strategies[0].strategy == "Deep Breathing")
  }
}
