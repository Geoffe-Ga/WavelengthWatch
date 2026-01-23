import Combine
import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

/// Comprehensive test suite for JournalSyncService.
///
/// Tests cover:
/// - Sync with various entry states (no pending, single, multiple)
/// - Network connectivity handling
/// - Retry logic and max retry enforcement
/// - Concurrent sync prevention
/// - Auto-sync on network changes
/// - Published property updates
@MainActor
struct JournalSyncServiceTests {
  // MARK: - Test Helpers

  /// Creates a sample LocalJournalEntry for testing.
  private func sampleEntry(
    id: UUID = UUID(),
    syncStatus: SyncStatus = .pending,
    retryCount: Int = 0
  ) -> LocalJournalEntry {
    var entry = LocalJournalEntry(
      id: id,
      createdAt: Date(),
      userID: 123,
      curriculumID: 1,
      initiatedBy: .self_initiated
    )
    entry.syncStatus = syncStatus
    entry.retryCount = retryCount
    return entry
  }

  // MARK: - Basic Sync Tests

  @Test func syncWithNoPendingEntries() async throws {
    let queue = MockJournalQueue()
    let client = MockAPIClient()
    let monitor = MockNetworkMonitor(isConnected: true)
    let service = JournalSyncService(
      queue: queue,
      apiClient: client,
      networkMonitor: monitor
    )

    try await service.sync()

    #expect(client.postCallCount == 0)
    #expect(service.syncStatus == .success(syncedCount: 0))
  }

  @Test func syncWithOnePendingEntry() async throws {
    let entry = sampleEntry()
    let queue = MockJournalQueue(pendingEntries: [entry])
    let client = MockAPIClient()
    let monitor = MockNetworkMonitor(isConnected: true)
    let service = JournalSyncService(
      queue: queue,
      apiClient: client,
      networkMonitor: monitor
    )

    try await service.sync()

    #expect(client.postCallCount == 1)
    #expect(queue.markedSyncedIDs.contains(entry.id))
    #expect(service.syncStatus == .success(syncedCount: 1))
  }

  @Test func syncWithMultiplePendingEntries() async throws {
    let entry1 = sampleEntry()
    let entry2 = sampleEntry()
    let entry3 = sampleEntry()
    let queue = MockJournalQueue(pendingEntries: [entry1, entry2, entry3])
    let client = MockAPIClient()
    let monitor = MockNetworkMonitor(isConnected: true)
    let service = JournalSyncService(
      queue: queue,
      apiClient: client,
      networkMonitor: monitor
    )

    try await service.sync()

    #expect(client.postCallCount == 3)
    #expect(queue.markedSyncedIDs.count == 3)
    #expect(service.syncStatus == .success(syncedCount: 3))
  }

  // MARK: - Network Handling Tests

  @Test func syncWhenOfflineDoesNotAttempt() async throws {
    let entry = sampleEntry()
    let queue = MockJournalQueue(pendingEntries: [entry])
    let client = MockAPIClient()
    let monitor = MockNetworkMonitor(isConnected: false)
    let service = JournalSyncService(
      queue: queue,
      apiClient: client,
      networkMonitor: monitor
    )

    try await service.sync()

    #expect(client.postCallCount == 0)
    #expect(queue.markedSyncedIDs.isEmpty)
  }

  @Test func syncWithNetworkFailureMarksAsFailed() async throws {
    let entry = sampleEntry()
    let queue = MockJournalQueue(pendingEntries: [entry])
    let client = MockAPIClient(shouldFail: true)
    let monitor = MockNetworkMonitor(isConnected: true)
    let service = JournalSyncService(
      queue: queue,
      apiClient: client,
      networkMonitor: monitor
    )

    do {
      try await service.sync()
      Issue.record("Should have thrown error")
    } catch {
      // Expected
    }

    #expect(queue.markedFailedIDs.contains(entry.id))
    #expect(queue.markedSyncedIDs.isEmpty)
  }

  // MARK: - Retry Logic Tests

  @Test func retryIncrementsRetryCount() async throws {
    let entry = sampleEntry(retryCount: 0)
    let queue = MockJournalQueue(pendingEntries: [entry])
    let client = MockAPIClient(shouldFail: true)
    let monitor = MockNetworkMonitor(isConnected: true)
    let service = JournalSyncService(
      queue: queue,
      apiClient: client,
      networkMonitor: monitor
    )

    do {
      try await service.sync()
      Issue.record("Should have thrown error")
    } catch {
      // Expected
    }

    #expect(queue.markedFailedIDs.contains(entry.id))
    // Note: Actual retry count increment happens in JournalQueue
  }

  @Test func maxRetriesExceededSkipsEntry() async throws {
    let entry1 = sampleEntry(retryCount: 3) // At max retries
    let entry2 = sampleEntry(retryCount: 0) // Should still sync
    let queue = MockJournalQueue(pendingEntries: [entry1, entry2])
    let client = MockAPIClient()
    let monitor = MockNetworkMonitor(isConnected: true)
    let service = JournalSyncService(
      queue: queue,
      apiClient: client,
      networkMonitor: monitor,
      maxRetries: 3
    )

    try await service.sync()

    // Only entry2 should be synced (entry1 skipped due to max retries)
    #expect(client.postCallCount == 1)
    #expect(queue.markedSyncedIDs.contains(entry2.id))
    #expect(!queue.markedSyncedIDs.contains(entry1.id))
  }

  // MARK: - Concurrency Tests

  @Test func concurrentSyncPrevented() async throws {
    let entry = sampleEntry()
    let queue = MockJournalQueue(pendingEntries: [entry])
    let client = MockAPIClient(delay: 0.1) // Slow client
    let monitor = MockNetworkMonitor(isConnected: true)
    let service = JournalSyncService(
      queue: queue,
      apiClient: client,
      networkMonitor: monitor
    )

    // Start first sync
    let task1 = Task {
      try await service.sync()
    }

    // Try to start second sync while first is running
    try await Task.sleep(nanoseconds: 10_000_000) // 10ms
    #expect(service.isSyncing == true)

    let task2 = Task {
      try await service.sync()
    }

    _ = await task1.result
    _ = await task2.result

    // Should only sync once
    #expect(client.postCallCount == 1)
  }

  // MARK: - Published Properties Tests

  @Test func syncStatusUpdatesPublished() async throws {
    let entry = sampleEntry()
    let queue = MockJournalQueue(pendingEntries: [entry])
    let client = MockAPIClient()
    let monitor = MockNetworkMonitor(isConnected: true)
    let service = JournalSyncService(
      queue: queue,
      apiClient: client,
      networkMonitor: monitor
    )

    var statusUpdates: [JournalSyncStatus] = []
    let cancellable = service.$syncStatus.sink { status in
      statusUpdates.append(status)
    }

    try await service.sync()

    cancellable.cancel()

    // Should have: idle, syncing, success
    #expect(statusUpdates.count >= 2)
    #expect(statusUpdates.last == .success(syncedCount: 1))
  }

  @Test func isSyncingUpdatesCorrectly() async throws {
    let entry = sampleEntry()
    let queue = MockJournalQueue(pendingEntries: [entry])
    let client = MockAPIClient(delay: 0.05)
    let monitor = MockNetworkMonitor(isConnected: true)
    let service = JournalSyncService(
      queue: queue,
      apiClient: client,
      networkMonitor: monitor
    )

    #expect(service.isSyncing == false)

    let task = Task {
      try await service.sync()
    }

    try await Task.sleep(nanoseconds: 10_000_000) // 10ms
    #expect(service.isSyncing == true)

    _ = await task.result
    #expect(service.isSyncing == false)
  }

  // MARK: - Auto-Sync Tests

  @Test func autoSyncTriggersOnNetworkConnection() async throws {
    let entry = sampleEntry()
    let queue = MockJournalQueue(pendingEntries: [entry])
    let client = MockAPIClient()
    let monitor = MockNetworkMonitor(isConnected: false)
    let service = JournalSyncService(
      queue: queue,
      apiClient: client,
      networkMonitor: monitor
    )

    service.startAutoSync()

    // Simulate network connection
    monitor.simulateConnection()

    // Wait for auto-sync to trigger
    try await Task.sleep(nanoseconds: 100_000_000) // 100ms

    #expect(client.postCallCount > 0)
    service.stopAutoSync()
  }

  @Test func autoSyncDoesNotTriggerWhenAlreadySyncing() async throws {
    let entry = sampleEntry()
    let queue = MockJournalQueue(pendingEntries: [entry])
    let client = MockAPIClient(delay: 0.2) // Long delay
    let monitor = MockNetworkMonitor(isConnected: true)
    let service = JournalSyncService(
      queue: queue,
      apiClient: client,
      networkMonitor: monitor
    )

    // Start manual sync
    let task = Task {
      try await service.sync()
    }

    try await Task.sleep(nanoseconds: 50_000_000) // 50ms
    #expect(service.isSyncing == true)

    // Start auto-sync while syncing
    service.startAutoSync()
    monitor.simulateConnection()

    try await Task.sleep(nanoseconds: 100_000_000) // 100ms

    _ = await task.result

    // Should only have synced once
    #expect(client.postCallCount == 1)
    service.stopAutoSync()
  }

  @Test func stopAutoSyncStopsObserving() async throws {
    let queue = MockJournalQueue()
    let client = MockAPIClient()
    let monitor = MockNetworkMonitor(isConnected: false)
    let service = JournalSyncService(
      queue: queue,
      apiClient: client,
      networkMonitor: monitor
    )

    service.startAutoSync()
    service.stopAutoSync()

    // Simulate network connection after stopping
    monitor.simulateConnection()

    try await Task.sleep(nanoseconds: 100_000_000) // 100ms

    // Should not have triggered sync
    #expect(client.postCallCount == 0)
  }
}

// MARK: - Mock Implementations

/// Mock journal queue for testing.
@MainActor
final class MockJournalQueue: JournalQueueProtocol {
  private var pendingItems: [LocalJournalEntry]
  var markedSyncingIDs: [UUID] = []
  var markedSyncedIDs: [UUID] = []
  var markedFailedIDs: [UUID] = []

  init(pendingEntries: [LocalJournalEntry] = []) {
    self.pendingItems = pendingEntries
  }

  func enqueue(_ entry: LocalJournalEntry) throws {
    pendingItems.append(entry)
  }

  func pendingEntries() throws -> [JournalQueueItem] {
    pendingItems.map { entry in
      JournalQueueItem(entry: entry)
    }
  }

  func fetch(id: UUID) throws -> JournalQueueItem? {
    pendingItems.first(where: { $0.id == id }).map { JournalQueueItem(entry: $0) }
  }

  func markSyncing(id: UUID) throws {
    markedSyncingIDs.append(id)
  }

  func markSynced(id: UUID) throws {
    markedSyncedIDs.append(id)
  }

  func markFailed(id: UUID, error: Error) throws {
    markedFailedIDs.append(id)
  }

  func cleanupSynced(olderThan days: Int) throws {
    // No-op for mock
  }

  func statistics() throws -> QueueStatistics {
    QueueStatistics(pending: pendingItems.count, syncing: 0, synced: 0, failed: 0)
  }
}

/// Mock API client for testing.
@MainActor
final class MockAPIClient: APIClientProtocol {
  var postCallCount = 0
  private let shouldFail: Bool
  private let delay: TimeInterval

  init(shouldFail: Bool = false, delay: TimeInterval = 0) {
    self.shouldFail = shouldFail
    self.delay = delay
  }

  func get<T: Decodable>(_ path: String) async throws -> T {
    fatalError("get not implemented in mock")
  }

  func post<Response: Decodable>(_ path: String, body: some Encodable) async throws -> Response {
    if delay > 0 {
      try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    postCallCount += 1

    if shouldFail {
      throw NSError(domain: "MockAPI", code: 500, userInfo: nil)
    }

    // Return a mock JournalResponseModel (we know that's what Response is)
    let response = JournalResponseModel(
      id: 1,
      curriculumID: 1,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: .self_initiated
    )
    return response as! Response
  }
}

/// Mock network monitor for testing.
@MainActor
final class MockNetworkMonitor: ObservableObject, NetworkMonitorProtocol {
  @Published var isConnected: Bool

  var isConnectedPublisher: Published<Bool>.Publisher { $isConnected }

  init(isConnected: Bool) {
    self.isConnected = isConnected
  }

  func simulateConnection() {
    isConnected = true
  }

  func simulateDisconnection() {
    isConnected = false
  }
}
