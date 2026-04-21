import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

/// Comprehensive tests for JournalClient local-first behavior and sync scenarios.
@MainActor
struct JournalClientLocalFirstTests {
  // MARK: - Local Save Tests

  @Test func localSaveSucceedsEvenWhenSyncFails() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = FailingAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )

    // Entry should be saved locally despite sync failure
    #expect(entry.curriculumID == 42)
    #expect(entry.syncStatus == SyncStatus.failed)
    #expect(try repository.count() == 1)
    #expect(try repository.fetch(id: entry.id) != nil)
  }

  @Test func localSaveFailsIfRepositoryThrows() async throws {
    let repository = FailingJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    let apiClient = SuccessfulAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    await #expect(throws: JournalDatabaseError.self) {
      try await client.submit(
        curriculumID: 42,
        secondaryCurriculumID: nil,
        strategyID: nil,
        initiatedBy: .self_initiated
      )
    }
  }

  // MARK: - Sync Status Transition Tests

  @Test func syncStatusStartsAsPending() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = false
    let apiClient = SuccessfulAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )

    #expect(entry.syncStatus == SyncStatus.pending)
    #expect(entry.serverId == nil)
  }

  @Test func syncStatusTransitionsToPendingToSynced() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = SuccessfulAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: 10,
      strategyID: 5,
      initiatedBy: .self_initiated
    )

    #expect(entry.syncStatus == SyncStatus.synced)
    #expect(entry.serverId == 999)
    #expect(try repository.fetch(id: entry.id)?.syncStatus == SyncStatus.synced)
  }

  @Test func syncStatusTransitionsToPendingToFailed() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = FailingAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )

    #expect(entry.syncStatus == .failed)
    #expect(entry.lastSyncAttempt != nil)
    #expect(try repository.fetch(id: entry.id)?.syncStatus == SyncStatus.failed)
  }

  // MARK: - Cloud Sync Enabled/Disabled Tests

  @Test func syncDoesNotOccurWhenCloudSyncDisabled() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = false
    let apiClient = TrackingAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )

    #expect(entry.syncStatus == SyncStatus.pending)
    #expect(apiClient.postCalls.count == 0)
    #expect(try repository.count() == 1)
  }

  @Test func syncOccursWhenCloudSyncEnabled() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = TrackingAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: 10,
      strategyID: 5,
      initiatedBy: .scheduled
    )

    #expect(apiClient.postCalls.count == 1)
    #expect(apiClient.postCalls[0].path == "/api/v1/journal")
    #expect(entry.syncStatus == SyncStatus.synced)
  }

  // MARK: - Server ID Persistence Tests

  @Test func serverIDPersistedAfterSuccessfulSync() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = SuccessfulAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )

    #expect(entry.serverId == 999)
    let storedEntry = try repository.fetch(id: entry.id)
    #expect(storedEntry?.serverId == 999)
  }

  // MARK: - REST Entry Tests

  @Test func submitRestPeriod_createsRestEntryWithoutCurriculum() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = false
    let apiClient = SuccessfulAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submitRestPeriod(initiatedBy: .self_initiated)

    #expect(entry.entryType == .rest)
    #expect(entry.curriculumID == nil)
    #expect(entry.isRestEntry == true)
    #expect(entry.syncStatus == .pending)
    #expect(try repository.count() == 1)
  }

  @Test func submitRestPeriod_syncsWhenCloudSyncEnabled() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = RestAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submitRestPeriod(initiatedBy: .self_initiated)

    #expect(entry.entryType == .rest)
    #expect(entry.syncStatus == .synced)
    #expect(entry.serverId == 888)
    #expect(apiClient.postCalls.count == 1)
  }

  @Test func submitRestPeriod_savesLocallyEvenWhenSyncFails() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = FailingAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submitRestPeriod(initiatedBy: .self_initiated)

    #expect(entry.entryType == .rest)
    #expect(entry.syncStatus == .failed)
    #expect(try repository.count() == 1)
  }
}

/// Tests that verify JournalClient's integration with the offline journal
/// queue when a queue is provided — the #215 integration point.
@MainActor
struct JournalClientQueueIntegrationTests {
  // MARK: - Retryable Errors Queue

  @Test func submit_retryableTransportError_enqueuesEntry() async throws {
    let repository = InMemoryJournalRepository()
    let queue = InMemoryJournalQueueSpy()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = StubAPIClientSpy(postResult: .failure(APIClientError.transport(URLError(.notConnectedToInternet))))
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings,
      queue: queue
    )

    var queuedID: UUID?
    do {
      _ = try await client.submit(
        curriculumID: 42,
        secondaryCurriculumID: nil,
        strategyID: nil,
        initiatedBy: .self_initiated
      )
      Issue.record("Expected queuedForRetry error to be thrown")
    } catch let JournalError.queuedForRetry(entryID) {
      queuedID = entryID
    }

    let unwrappedID = try #require(queuedID)
    #expect(queue.enqueuedEntries.count == 1)
    #expect(queue.enqueuedEntries.first?.id == unwrappedID)
    // Entry is still saved locally.
    try #expect(repository.count() == 1)
    // Repository entry remains pending so sync service can retry.
    try #expect(repository.fetch(id: unwrappedID)?.syncStatus == .pending)
  }

  @Test func submit_retryableServerError_enqueuesEntry() async throws {
    let repository = InMemoryJournalRepository()
    let queue = InMemoryJournalQueueSpy()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = StubAPIClientSpy(postResult: .failure(APIClientError.badResponse(503)))
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings,
      queue: queue
    )

    await #expect(throws: JournalError.self) {
      _ = try await client.submit(
        curriculumID: 42,
        secondaryCurriculumID: nil,
        strategyID: nil,
        initiatedBy: .self_initiated
      )
    }
    #expect(queue.enqueuedEntries.count == 1)
  }

  // MARK: - Non-Retryable Errors

  @Test func submit_nonRetryableValidationError_doesNotQueue() async throws {
    let repository = InMemoryJournalRepository()
    let queue = InMemoryJournalQueueSpy()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = StubAPIClientSpy(postResult: .failure(APIClientError.badResponse(422)))
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings,
      queue: queue
    )

    await #expect(throws: APIClientError.self) {
      _ = try await client.submit(
        curriculumID: 42,
        secondaryCurriculumID: nil,
        strategyID: nil,
        initiatedBy: .self_initiated
      )
    }

    #expect(queue.enqueuedEntries.isEmpty)
    // Entry was saved locally but marked failed.
    #expect(try repository.count() == 1)
    let entries = try repository.fetchAll()
    #expect(entries.first?.syncStatus == .failed)
  }

  // MARK: - Successful Sync Path

  @Test func submit_successfulSync_doesNotQueue() async throws {
    let repository = InMemoryJournalRepository()
    let queue = InMemoryJournalQueueSpy()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = SuccessfulAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings,
      queue: queue
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )

    #expect(entry.syncStatus == .synced)
    #expect(queue.enqueuedEntries.isEmpty)
  }

  // MARK: - Idempotency Key

  @Test func submit_sendsIdempotencyKeyHeader() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = HeaderCapturingAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )

    let headers = try #require(apiClient.capturedHeaders)
    let key = try #require(headers[JournalRequestHeader.idempotencyKey])
    #expect(key == entry.id.uuidString)
    // Key must be a valid UUID per backend validation rules.
    #expect(UUID(uuidString: key) != nil)
  }

  @Test func submit_idempotencyKey_matchesLocalEntryID() async throws {
    let repository = InMemoryJournalRepository()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = HeaderCapturingAPIClientSpy()
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings
    )

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )

    // The key is derived deterministically from the local entry ID, so retry
    // attempts from the sync service can reuse it and trigger backend dedup.
    #expect(apiClient.capturedHeaders?[JournalRequestHeader.idempotencyKey] == entry.id.uuidString)
  }

  // MARK: - REST Entries

  @Test func submitRestPeriod_retryableError_enqueuesRestEntry() async throws {
    let repository = InMemoryJournalRepository()
    let queue = InMemoryJournalQueueSpy()
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let apiClient = StubAPIClientSpy(postResult: .failure(APIClientError.badResponse(502)))
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings,
      queue: queue
    )

    await #expect(throws: JournalError.self) {
      _ = try await client.submitRestPeriod(initiatedBy: .self_initiated)
    }

    #expect(queue.enqueuedEntries.count == 1)
    #expect(queue.enqueuedEntries.first?.entryType == .rest)
  }
}

/// Tests for `APIClientError.isRetryable` classification.
struct APIClientErrorRetryableTests {
  @Test func transportErrorIsRetryable() {
    let error = APIClientError.transport(URLError(.timedOut))
    #expect(error.isRetryable)
  }

  @Test func invalidURLIsNotRetryable() {
    let error = APIClientError.invalidURL("bad")
    #expect(!error.isRetryable)
  }

  @Test func serverError5xxIsRetryable() {
    #expect(APIClientError.badResponse(500).isRetryable)
    #expect(APIClientError.badResponse(502).isRetryable)
    #expect(APIClientError.badResponse(503).isRetryable)
  }

  @Test func timeoutAndThrottleAreRetryable() {
    #expect(APIClientError.badResponse(408).isRetryable)
    #expect(APIClientError.badResponse(429).isRetryable)
  }

  @Test func clientError4xxIsNotRetryable() {
    #expect(!APIClientError.badResponse(400).isRetryable)
    #expect(!APIClientError.badResponse(401).isRetryable)
    #expect(!APIClientError.badResponse(404).isRetryable)
    #expect(!APIClientError.badResponse(422).isRetryable)
  }
}

// MARK: - Queue Integration Test Doubles

/// In-memory spy that records enqueued entries without using SQLite.
/// Conforms to `JournalQueueProtocol` so it can be injected into JournalClient.
final class InMemoryJournalQueueSpy: JournalQueueProtocol {
  var enqueuedEntries: [LocalJournalEntry] = []
  var shouldThrowOnEnqueue = false

  func enqueue(_ entry: LocalJournalEntry) throws {
    if shouldThrowOnEnqueue {
      throw JournalQueueError.insertFailed("spy forced failure")
    }
    enqueuedEntries.append(entry)
  }

  func pendingEntries() throws -> [JournalQueueItem] {
    enqueuedEntries.map { JournalQueueItem(entry: $0) }
  }

  func fetch(id: UUID) throws -> JournalQueueItem? {
    enqueuedEntries.first(where: { $0.id == id }).map { JournalQueueItem(entry: $0) }
  }

  func markSyncing(id _: UUID) throws {}
  func markSynced(id _: UUID) throws {}
  func markFailed(id _: UUID, error _: Error) throws {}
  func cleanupSynced(olderThan _: Int) throws {}

  func statistics() throws -> QueueStatistics {
    QueueStatistics(
      pending: enqueuedEntries.count,
      syncing: 0,
      synced: 0,
      failed: 0
    )
  }
}

/// API client that returns a fixed result (success or specific error) for
/// post calls. Used to exercise retryable vs. non-retryable classification.
final class StubAPIClientSpy: APIClientProtocol {
  private let postResult: Result<JournalResponseModel, Error>

  init(postResult: Result<JournalResponseModel, Error>) {
    self.postResult = postResult
  }

  func get<T: Decodable>(_: String) async throws -> T {
    throw URLError(.badURL)
  }

  func post<Response: Decodable>(_: String, body _: some Encodable) async throws -> Response {
    switch postResult {
    case let .success(response):
      guard let typed = response as? Response else {
        throw URLError(.badServerResponse)
      }
      return typed
    case let .failure(error):
      throw error
    }
  }
}

/// API client that captures the headers passed to post so tests can assert
/// that the idempotency key header is sent with journal submissions.
final class HeaderCapturingAPIClientSpy: APIClientProtocol {
  var capturedHeaders: [String: String]?

  func get<T: Decodable>(_: String) async throws -> T {
    throw URLError(.badURL)
  }

  func post<Response: Decodable>(_: String, body _: some Encodable) async throws -> Response {
    // Should not be called — the 3-argument overload below handles requests
    // coming from JournalClient. Keep this here to satisfy the protocol.
    let response = JournalResponseModel(
      id: 999,
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
    guard let typed = response as? Response else {
      throw URLError(.badServerResponse)
    }
    return typed
  }

  func post<Response: Decodable>(
    _: String,
    body _: some Encodable,
    headers: [String: String]?
  ) async throws -> Response {
    capturedHeaders = headers
    let response = JournalResponseModel(
      id: 999,
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
    guard let typed = response as? Response else {
      throw URLError(.badServerResponse)
    }
    return typed
  }
}

// MARK: - Test Doubles

/// API client that always succeeds with a mock response.
final class SuccessfulAPIClientSpy: APIClientProtocol {
  func get<T: Decodable>(_ path: String) async throws -> T {
    throw URLError(.badURL)
  }

  func post<T: Decodable>(_ path: String, body: some Encodable) async throws -> T {
    let response = JournalResponseModel(
      id: 999,
      curriculumID: 42,
      secondaryCurriculumID: 10,
      strategyID: 5,
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
    guard let typed = response as? T else {
      throw URLError(.badServerResponse)
    }
    return typed
  }
}

/// API client that always fails.
final class FailingAPIClientSpy: APIClientProtocol {
  func get<T: Decodable>(_ path: String) async throws -> T {
    throw URLError(.badServerResponse)
  }

  func post<T: Decodable>(_ path: String, body: some Encodable) async throws -> T {
    throw URLError(.badServerResponse)
  }
}

/// API client that tracks calls without making network requests.
final class TrackingAPIClientSpy: APIClientProtocol {
  var postCalls: [(path: String, body: Any)] = []

  func get<T: Decodable>(_ path: String) async throws -> T {
    throw URLError(.badURL)
  }

  func post<T: Decodable>(_ path: String, body: some Encodable) async throws -> T {
    postCalls.append((path, body))
    let response = JournalResponseModel(
      id: 999,
      curriculumID: 42,
      secondaryCurriculumID: 10,
      strategyID: 5,
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
    guard let typed = response as? T else {
      throw URLError(.badServerResponse)
    }
    return typed
  }
}

/// API client that simulates successful REST entry sync.
final class RestAPIClientSpy: APIClientProtocol {
  var postCalls: [(path: String, body: Any)] = []

  func get<T: Decodable>(_ path: String) async throws -> T {
    throw URLError(.badURL)
  }

  func post<T: Decodable>(_ path: String, body: some Encodable) async throws -> T {
    postCalls.append((path, body))
    let response = JournalResponseModel(
      id: 888,
      curriculumID: nil,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated,
      entryType: .rest
    )
    guard let typed = response as? T else {
      throw URLError(.badServerResponse)
    }
    return typed
  }
}

/// Repository that always fails on save.
final class FailingJournalRepository: JournalRepositoryProtocol {
  func save(_ entry: LocalJournalEntry) throws {
    throw JournalDatabaseError.failedToInsert("Simulated failure")
  }

  func update(_ entry: LocalJournalEntry) throws {
    throw JournalDatabaseError.failedToUpdate("Simulated failure")
  }

  func delete(id: UUID) throws {
    throw JournalDatabaseError.failedToDelete("Simulated failure")
  }

  func fetch(id: UUID) throws -> LocalJournalEntry? {
    nil
  }

  func fetchAll() throws -> [LocalJournalEntry] {
    []
  }

  func fetchByDateRange(from _: Date, to _: Date) throws -> [LocalJournalEntry] {
    []
  }

  func fetchPendingSync() throws -> [LocalJournalEntry] {
    []
  }

  func count() throws -> Int {
    0
  }
}
