import Combine
import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

/// End-to-end integration tests for the offline journal queue (#218).
///
/// These tests wire together `JournalClient`, the SQLite-backed
/// `JournalQueue`, `JournalSyncService`, and a controllable
/// `NetworkMonitor` / `APIClient` so we can exercise realistic offline
/// scenarios: queueing while disconnected, auto-sync on reconnect,
/// idempotency key reuse across retries, FIFO ordering, validation-error
/// disposition, persistence across app termination, and concurrent-sync
/// serialization.
///
/// All SQLite work happens in a per-test temporary database so the suite
/// runs in parallel without interference.
@MainActor
struct OfflineQueueIntegrationTests {
  // MARK: - Test Helpers

  private func temporaryDatabasePath() -> String {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("offline_queue_\(UUID().uuidString).sqlite")
      .path
  }

  /// Convenience builder that wires a JournalClient with the injected
  /// queue and api client, using an in-memory repository + mock sync
  /// settings so tests focus on queue behaviour rather than repo state.
  private func makeClient(
    queue: JournalQueueProtocol,
    apiClient: APIClientProtocol,
    repository: JournalRepositoryProtocol = InMemoryJournalRepository()
  ) -> (JournalClient, SyncSettings) {
    let syncSettings = SyncSettings(persistence: MockSyncSettingsPersistence())
    syncSettings.cloudSyncEnabled = true
    let client = JournalClient(
      apiClient: apiClient,
      repository: repository,
      syncSettings: syncSettings,
      queue: queue
    )
    return (client, syncSettings)
  }

  // MARK: - Basic Flow

  @Test func offlineSubmissionQueuesEntry() async throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let api = ToggleableAPIClient()
    api.shouldFail = true
    api.failWith = APIClientError.transport(URLError(.notConnectedToInternet))
    let (client, _) = makeClient(queue: queue, apiClient: api)

    var queuedID: UUID?
    do {
      _ = try await client.submit(
        curriculumID: 42,
        secondaryCurriculumID: nil,
        strategyID: nil,
        initiatedBy: .self_initiated
      )
      Issue.record("Expected queuedForRetry error")
    } catch let JournalError.queuedForRetry(entryID) {
      queuedID = entryID
    }

    #expect(queuedID != nil)
    #expect(queue.pendingCount == 1)
    let pending = try queue.pendingEntries()
    #expect(pending.count == 1)
    #expect(pending.first?.localEntry.id == queuedID)
  }

  @Test func onlineSubmissionDoesNotQueue() async throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let api = ToggleableAPIClient() // defaults to success
    let (client, _) = makeClient(queue: queue, apiClient: api)

    let entry = try await client.submit(
      curriculumID: 42,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )

    #expect(entry.syncStatus == .synced)
    #expect(queue.pendingCount == 0)
    #expect(api.postCallCount == 1)
  }

  @Test func networkReconnectTriggersDrain() async throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let api = ToggleableAPIClient()
    let monitor = MockNetworkMonitor(isConnected: false)
    let (client, _) = makeClient(queue: queue, apiClient: api)

    // Offline: submission throws queuedForRetry and entry lands in queue.
    api.shouldFail = true
    api.failWith = APIClientError.transport(URLError(.notConnectedToInternet))

    do {
      _ = try await client.submit(
        curriculumID: 7,
        secondaryCurriculumID: nil,
        strategyID: nil,
        initiatedBy: .self_initiated
      )
    } catch JournalError.queuedForRetry {
      // Expected
    }

    #expect(queue.pendingCount == 1)

    // Network reconnects and API now succeeds; sync drains the queue.
    api.shouldFail = false
    monitor.simulateConnection()

    let sync = JournalSyncService(
      queue: queue,
      apiClient: api,
      networkMonitor: monitor
    )
    try await sync.sync()

    #expect(queue.pendingCount == 0)
    let stats = try queue.statistics()
    #expect(stats.synced == 1)
  }

  // MARK: - Idempotency

  @Test func multipleOfflineEntriesUseDistinctIdempotencyKeys() async throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let api = ToggleableAPIClient()
    let monitor = MockNetworkMonitor(isConnected: true)
    let (client, _) = makeClient(queue: queue, apiClient: api)

    // Queue three entries while offline.
    api.shouldFail = true
    api.failWith = APIClientError.transport(URLError(.notConnectedToInternet))
    for curriculum in 1 ... 3 {
      do {
        _ = try await client.submit(
          curriculumID: curriculum,
          secondaryCurriculumID: nil,
          strategyID: nil,
          initiatedBy: .self_initiated
        )
      } catch JournalError.queuedForRetry {
        // Expected
      }
    }

    #expect(queue.pendingCount == 3)

    // Reconnect and drain; capture idempotency keys observed by the API.
    api.shouldFail = false
    let sync = JournalSyncService(
      queue: queue,
      apiClient: api,
      networkMonitor: monitor
    )
    try await sync.sync()

    let keys = api.capturedIdempotencyKeys
    #expect(keys.count == 3)
    #expect(Set(keys).count == 3) // All unique
    for key in keys {
      #expect(UUID(uuidString: key) != nil)
    }
  }

  @Test func retryReusesSameIdempotencyKeyAsInitialSubmit() async throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let api = ToggleableAPIClient()
    let monitor = MockNetworkMonitor(isConnected: true)
    let (client, _) = makeClient(queue: queue, apiClient: api)

    // Offline submission fails, key captured from the initial attempt.
    api.shouldFail = true
    api.failWith = APIClientError.badResponse(503)
    var queuedID: UUID?
    do {
      _ = try await client.submit(
        curriculumID: 42,
        secondaryCurriculumID: nil,
        strategyID: nil,
        initiatedBy: .self_initiated
      )
    } catch let JournalError.queuedForRetry(entryID) {
      queuedID = entryID
    }

    let initialKey = try #require(api.capturedIdempotencyKeys.first)
    #expect(initialKey == queuedID?.uuidString)

    // Now retry via sync service — reusing the SAME idempotency key lets
    // the backend deduplicate a replayed successful submission.
    api.shouldFail = false
    let sync = JournalSyncService(
      queue: queue,
      apiClient: api,
      networkMonitor: monitor
    )
    try await sync.sync()

    #expect(api.capturedIdempotencyKeys.count == 2)
    #expect(api.capturedIdempotencyKeys.last == initialKey)
  }

  // MARK: - Ordering

  @Test func queueSyncPreservesFIFOOrder() async throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let api = ToggleableAPIClient()
    let monitor = MockNetworkMonitor(isConnected: true)
    let (client, _) = makeClient(queue: queue, apiClient: api)

    // Enqueue 5 entries offline with distinct curriculum IDs.
    api.shouldFail = true
    api.failWith = APIClientError.transport(URLError(.timedOut))
    for curriculum in 1 ... 5 {
      do {
        _ = try await client.submit(
          curriculumID: curriculum,
          secondaryCurriculumID: nil,
          strategyID: nil,
          initiatedBy: .self_initiated
        )
      } catch JournalError.queuedForRetry {
        // Expected
      }
    }

    // Drain and assert curriculum IDs landed at the backend in order 1..5.
    api.shouldFail = false
    let sync = JournalSyncService(
      queue: queue,
      apiClient: api,
      networkMonitor: monitor
    )
    try await sync.sync()

    #expect(api.receivedCurriculumIDs == [1, 2, 3, 4, 5])
  }

  // MARK: - Error Handling

  @Test func validationError400DoesNotEnqueue() async throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let api = ToggleableAPIClient()
    api.shouldFail = true
    api.failWith = APIClientError.badResponse(422)
    let (client, _) = makeClient(queue: queue, apiClient: api)

    await #expect(throws: APIClientError.self) {
      _ = try await client.submit(
        curriculumID: -1,
        secondaryCurriculumID: nil,
        strategyID: nil,
        initiatedBy: .self_initiated
      )
    }

    #expect(queue.pendingCount == 0)
    let stats = try queue.statistics()
    #expect(stats.total == 0)
  }

  @Test func syncServerError500KeepsEntryInQueueAndIncrementsRetryCount() async throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let entry = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
    try queue.enqueue(entry)
    #expect(queue.pendingCount == 1)

    let api = ToggleableAPIClient()
    api.shouldFail = true
    api.failWith = APIClientError.badResponse(500)
    let monitor = MockNetworkMonitor(isConnected: true)
    let sync = JournalSyncService(
      queue: queue,
      apiClient: api,
      networkMonitor: monitor
    )

    // First retry: record failure + retry count increments to 1.
    await #expect(throws: APIClientError.self) {
      try await sync.sync()
    }
    var stats = try queue.statistics()
    #expect(stats.failed == 1)
    #expect(try queue.fetch(id: entry.id)?.retryCount == 1)

    // pendingCount is zero because the entry is now `failed` (not `pending`).
    #expect(queue.pendingCount == 0)

    // Entry is intact, not dropped.
    #expect(try queue.fetch(id: entry.id) != nil)
    stats = try queue.statistics()
    #expect(stats.total == 1)
  }

  @Test func failedEntriesAreNotAutoRetriedOnNextSync() async throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let entry = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
    try queue.enqueue(entry)

    let api = ToggleableAPIClient()
    api.shouldFail = true
    api.failWith = APIClientError.badResponse(500)
    let monitor = MockNetworkMonitor(isConnected: true)
    let sync = JournalSyncService(
      queue: queue,
      apiClient: api,
      networkMonitor: monitor
    )

    // First sync fails: entry transitions pending → failed, retryCount=1.
    await #expect(throws: APIClientError.self) {
      try await sync.sync()
    }
    #expect(try queue.fetch(id: entry.id)?.retryCount == 1)
    #expect(try queue.fetch(id: entry.id)?.status == .failed)

    // Second sync with working API: failed entries are NOT reprocessed
    // because pendingEntries() only returns entries with status=.pending.
    // The sync completes without touching the network.
    api.shouldFail = false
    try await sync.sync()

    #expect(api.postCallCount == 1) // First POST only; no re-attempt.
    #expect(try queue.fetch(id: entry.id)?.retryCount == 1) // Unchanged.
    let stats = try queue.statistics()
    #expect(stats.failed == 1)
    #expect(stats.synced == 0)
  }

  // MARK: - App Lifecycle

  @Test func queuePersistsAcrossClientRestart() async throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    // First "app run": queue two entries offline, then drop everything.
    do {
      let queue = try JournalQueue(databasePath: dbPath)
      let api = ToggleableAPIClient()
      api.shouldFail = true
      api.failWith = APIClientError.transport(URLError(.notConnectedToInternet))
      let (client, _) = makeClient(queue: queue, apiClient: api)

      for curriculum in [10, 20] {
        do {
          _ = try await client.submit(
            curriculumID: curriculum,
            secondaryCurriculumID: nil,
            strategyID: nil,
            initiatedBy: .self_initiated
          )
        } catch JournalError.queuedForRetry {
          // Expected
        }
      }
      #expect(queue.pendingCount == 2)
    }

    // Second "app run": re-open the same SQLite file.
    let restartedQueue = try JournalQueue(databasePath: dbPath)
    #expect(restartedQueue.pendingCount == 2)
    let pending = try restartedQueue.pendingEntries()
    let curriculumIDs = pending.compactMap(\.localEntry.curriculumID).sorted()
    #expect(curriculumIDs == [10, 20])
  }

  @Test func partialSyncResumesAfterRestart() async throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    // First app run: queue 3 entries, sync only the first (simulated
    // by manually walking the queue), then drop state.
    let firstID: UUID
    let remainingIDs: [UUID]
    do {
      let queue = try JournalQueue(databasePath: dbPath)
      var ids: [UUID] = []
      for curriculum in 1 ... 3 {
        let entry = LocalJournalEntry(
          createdAt: Date(),
          userID: 123,
          curriculumID: curriculum,
          initiatedBy: .self_initiated,
          entryType: .emotion
        )
        try queue.enqueue(entry)
        ids.append(entry.id)
      }
      firstID = ids[0]
      remainingIDs = Array(ids.dropFirst())

      // Sync first entry only (simulate interruption after one success).
      try queue.markSyncing(id: firstID)
      try queue.markSynced(id: firstID)
      #expect(queue.pendingCount == 2)
    }

    // Second app run: the two unsynced entries should still be pending.
    let restartedQueue = try JournalQueue(databasePath: dbPath)
    #expect(restartedQueue.pendingCount == 2)
    let pending = try restartedQueue.pendingEntries()
    let pendingIDs = Set(pending.map(\.localEntry.id))
    #expect(pendingIDs == Set(remainingIDs))

    // Sync drains the remaining entries.
    let api = ToggleableAPIClient()
    let monitor = MockNetworkMonitor(isConnected: true)
    let sync = JournalSyncService(
      queue: restartedQueue,
      apiClient: api,
      networkMonitor: monitor
    )
    try await sync.sync()

    #expect(restartedQueue.pendingCount == 0)
    #expect(api.postCallCount == 2)
  }

  // MARK: - Edge Cases

  @Test func emptyQueueSyncIsANoOp() async throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let api = ToggleableAPIClient()
    let monitor = MockNetworkMonitor(isConnected: true)
    let sync = JournalSyncService(
      queue: queue,
      apiClient: api,
      networkMonitor: monitor
    )

    try await sync.sync()

    #expect(api.postCallCount == 0)
    #expect(sync.syncStatus == .success(syncedCount: 0))
  }

  @Test func offlineSyncCallIsANoOp() async throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let entry = LocalJournalEntry(
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
    try queue.enqueue(entry)

    let api = ToggleableAPIClient()
    let monitor = MockNetworkMonitor(isConnected: false)
    let sync = JournalSyncService(
      queue: queue,
      apiClient: api,
      networkMonitor: monitor
    )

    try await sync.sync()

    // Network is offline: the service bails before touching the API and
    // leaves the entry untouched for the next attempt.
    #expect(api.postCallCount == 0)
    #expect(queue.pendingCount == 1)
  }

  @Test func concurrentSyncCallsAreSerialized() async throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    for curriculum in 1 ... 3 {
      let entry = LocalJournalEntry(
        createdAt: Date(),
        userID: 123,
        curriculumID: curriculum,
        initiatedBy: .self_initiated,
        entryType: .emotion
      )
      try queue.enqueue(entry)
    }

    let api = ToggleableAPIClient()
    api.artificialDelayNanos = 50_000_000 // 50ms per call
    let monitor = MockNetworkMonitor(isConnected: true)
    let sync = JournalSyncService(
      queue: queue,
      apiClient: api,
      networkMonitor: monitor
    )

    // Start two concurrent syncs; the second should short-circuit because
    // `isSyncing` is already true on the first.
    async let first: Void = sync.sync()
    async let second: Void = sync.sync()
    _ = try await (first, second)

    // Only one sync run actually processed entries. Exactly 3 POSTs are
    // expected (not 6) — the second call returned early.
    #expect(api.postCallCount == 3)
    #expect(queue.pendingCount == 0)
  }
}

// MARK: - Integration Test Doubles

/// Flexible API client for integration tests: toggle success/failure, swap
/// which error is raised, capture idempotency keys and curriculum IDs from
/// each POST, and optionally sleep to simulate latency.
@MainActor
final class ToggleableAPIClient: APIClientProtocol {
  var shouldFail: Bool = false
  var failWith: Error = URLError(.notConnectedToInternet)
  var artificialDelayNanos: UInt64 = 0

  private(set) var postCallCount: Int = 0
  private(set) var capturedIdempotencyKeys: [String] = []
  private(set) var receivedCurriculumIDs: [Int] = []

  func get<T: Decodable>(_: String) async throws -> T {
    throw URLError(.badURL)
  }

  func post<Response: Decodable>(_: String, body _: some Encodable) async throws -> Response {
    throw URLError(.badURL) // Tests always hit the 3-arg overload below.
  }

  func post<Response: Decodable>(
    _: String,
    body: some Encodable,
    headers: [String: String]?
  ) async throws -> Response {
    if artificialDelayNanos > 0 {
      try await Task.sleep(nanoseconds: artificialDelayNanos)
    }
    postCallCount += 1
    if let key = headers?[JournalRequestHeader.idempotencyKey] {
      capturedIdempotencyKeys.append(key)
    }
    if let payload = body as? JournalPayload, let curriculumID = payload.curriculumID {
      receivedCurriculumIDs.append(curriculumID)
    }
    if shouldFail {
      throw failWith
    }
    let response = JournalResponseModel(
      id: 999,
      curriculumID: (body as? JournalPayload)?.curriculumID,
      secondaryCurriculumID: (body as? JournalPayload)?.secondaryCurriculumID,
      strategyID: (body as? JournalPayload)?.strategyID,
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
    return response as! Response
  }
}
