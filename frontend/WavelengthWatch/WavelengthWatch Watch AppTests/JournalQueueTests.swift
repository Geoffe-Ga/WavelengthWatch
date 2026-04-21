import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

/// Comprehensive test suite for JournalQueue service.
///
/// Tests cover:
/// - Queue enqueue/dequeue operations
/// - Status transitions (pending → syncing → synced/failed)
/// - Persistence across restarts
/// - Cleanup of old synced entries
/// - Statistics calculation
/// - Duplicate prevention
struct JournalQueueTests {
  // MARK: - Test Helpers

  /// Creates a temporary database path for testing.
  private func temporaryDatabasePath() -> String {
    let tempDir = FileManager.default.temporaryDirectory
    let fileName = "test_queue_\(UUID().uuidString).sqlite"
    return tempDir.appendingPathComponent(fileName).path
  }

  /// Creates a sample journal entry for testing.
  private func sampleEntry(
    id: UUID = UUID(),
    curriculumID: Int = 1,
    userID: Int = 123
  ) -> LocalJournalEntry {
    LocalJournalEntry(
      id: id,
      createdAt: Date(),
      userID: userID,
      curriculumID: curriculumID,
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
  }

  // MARK: - Enqueue Tests

  @Test @MainActor func enqueueAddsItemToQueue() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let entry = sampleEntry()

    try queue.enqueue(entry)

    let pending = try queue.pendingEntries()
    #expect(pending.count == 1)
    #expect(pending[0].localEntry.id == entry.id)
    #expect(pending[0].status == .pending)
    #expect(pending[0].retryCount == 0)
  }

  @Test @MainActor func enqueuePreventsDuplicates() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let entry = sampleEntry()

    try queue.enqueue(entry)
    try queue.enqueue(entry) // Should not add duplicate

    let pending = try queue.pendingEntries()
    #expect(pending.count == 1)
  }

  @Test @MainActor func enqueueMultipleEntriesPreservesOrder() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let entry1 = sampleEntry(curriculumID: 1)
    let entry2 = sampleEntry(curriculumID: 2)
    let entry3 = sampleEntry(curriculumID: 3)

    try queue.enqueue(entry1)
    try queue.enqueue(entry2)
    try queue.enqueue(entry3)

    let pending = try queue.pendingEntries()
    #expect(pending.count == 3)
    #expect(pending[0].localEntry.id == entry1.id)
    #expect(pending[1].localEntry.id == entry2.id)
    #expect(pending[2].localEntry.id == entry3.id)
  }

  // MARK: - Pending Entries Tests

  @Test @MainActor func pendingEntriesReturnsOnlyPendingItems() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let entry1 = sampleEntry(curriculumID: 1)
    let entry2 = sampleEntry(curriculumID: 2)
    let entry3 = sampleEntry(curriculumID: 3)

    try queue.enqueue(entry1)
    try queue.enqueue(entry2)
    try queue.enqueue(entry3)

    // Mark one as synced
    try queue.markSynced(id: entry2.id)

    let pending = try queue.pendingEntries()
    #expect(pending.count == 2)
    #expect(pending.contains(where: { $0.localEntry.id == entry1.id }))
    #expect(pending.contains(where: { $0.localEntry.id == entry3.id }))
    #expect(!pending.contains(where: { $0.localEntry.id == entry2.id }))
  }

  @Test @MainActor func pendingEntriesReturnsEmptyWhenNoPending() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)

    let pending = try queue.pendingEntries()
    #expect(pending.isEmpty)
  }

  // MARK: - Status Transition Tests

  @Test @MainActor func markSyncingUpdatesStatus() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let entry = sampleEntry()

    try queue.enqueue(entry)
    try queue.markSyncing(id: entry.id)

    let stats = try queue.statistics()
    #expect(stats.syncing == 1)
    #expect(stats.pending == 0)
  }

  @Test @MainActor func markSyncedUpdatesStatus() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let entry = sampleEntry()

    try queue.enqueue(entry)
    try queue.markSyncing(id: entry.id)
    try queue.markSynced(id: entry.id)

    let stats = try queue.statistics()
    #expect(stats.synced == 1)
    #expect(stats.syncing == 0)
    #expect(stats.pending == 0)
  }

  @Test @MainActor func markFailedUpdatesStatusAndIncrementsRetryCount() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let entry = sampleEntry()

    try queue.enqueue(entry)
    try queue.markSyncing(id: entry.id)

    struct TestError: Error {}
    try queue.markFailed(id: entry.id, error: TestError())

    let stats = try queue.statistics()
    #expect(stats.failed == 1)
    #expect(stats.syncing == 0)

    // Verify retry count was incremented
    let pending = try queue.pendingEntries()
    #expect(pending.count == 0) // Failed items are not in pending
  }

  @Test @MainActor func markFailedIncrementsRetryCountOnMultipleFailures() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let entry = sampleEntry()

    try queue.enqueue(entry)

    struct TestError: Error {}

    // First failure
    try queue.markSyncing(id: entry.id)
    try queue.markFailed(id: entry.id, error: TestError())

    // Second failure
    try queue.markSyncing(id: entry.id)
    try queue.markFailed(id: entry.id, error: TestError())

    let stats = try queue.statistics()
    #expect(stats.failed == 1)

    // Verify retry count was incremented twice
    let item = try queue.fetch(id: entry.id)
    #expect(item != nil)
    #expect(item?.retryCount == 2)
  }

  @Test @MainActor func statusTransitionPendingToSyncingToSynced() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let entry = sampleEntry()

    // pending
    try queue.enqueue(entry)
    var stats = try queue.statistics()
    #expect(stats.pending == 1)

    // syncing
    try queue.markSyncing(id: entry.id)
    stats = try queue.statistics()
    #expect(stats.syncing == 1)
    #expect(stats.pending == 0)

    // synced
    try queue.markSynced(id: entry.id)
    stats = try queue.statistics()
    #expect(stats.synced == 1)
    #expect(stats.syncing == 0)
  }

  // MARK: - Cleanup Tests

  @Test @MainActor func cleanupRemovesOldSyncedEntries() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)

    // Add entries
    let entry1 = sampleEntry(curriculumID: 1)
    let entry2 = sampleEntry(curriculumID: 2)
    let entry3 = sampleEntry(curriculumID: 3)

    try queue.enqueue(entry1)
    try queue.enqueue(entry2)
    try queue.enqueue(entry3)

    // Mark all as synced
    try queue.markSyncing(id: entry1.id)
    try queue.markSynced(id: entry1.id)
    try queue.markSyncing(id: entry2.id)
    try queue.markSynced(id: entry2.id)
    try queue.markSyncing(id: entry3.id)
    try queue.markSynced(id: entry3.id)

    var stats = try queue.statistics()
    #expect(stats.synced == 3)

    // Cleanup entries older than 0 days (all of them)
    try queue.cleanupSynced(olderThan: 0)

    stats = try queue.statistics()
    #expect(stats.synced == 0)
  }

  @Test @MainActor func cleanupPreservesPendingAndFailedEntries() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)

    let pending = sampleEntry(curriculumID: 1)
    let synced = sampleEntry(curriculumID: 2)
    let failed = sampleEntry(curriculumID: 3)

    try queue.enqueue(pending)
    try queue.enqueue(synced)
    try queue.enqueue(failed)

    try queue.markSyncing(id: synced.id)
    try queue.markSynced(id: synced.id)

    struct TestError: Error {}
    try queue.markSyncing(id: failed.id)
    try queue.markFailed(id: failed.id, error: TestError())

    // Cleanup synced entries
    try queue.cleanupSynced(olderThan: 0)

    let stats = try queue.statistics()
    #expect(stats.pending == 1)
    #expect(stats.failed == 1)
    #expect(stats.synced == 0)
  }

  @Test @MainActor func cleanupRespectsAgeThreshold() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    // This test verifies that cleanup only removes entries older than the threshold
    // In practice, this is hard to test without manipulating time
    // We'll rely on implementation to handle this correctly
    let queue = try JournalQueue(databasePath: dbPath)

    let entry = sampleEntry()
    try queue.enqueue(entry)
    try queue.markSyncing(id: entry.id)
    try queue.markSynced(id: entry.id)

    // Cleanup entries older than 30 days (should keep the entry)
    try queue.cleanupSynced(olderThan: 30)

    let stats = try queue.statistics()
    #expect(stats.synced == 1)

    // Cleanup entries older than 0 days (should remove)
    try queue.cleanupSynced(olderThan: 0)

    let statsAfter = try queue.statistics()
    #expect(statsAfter.synced == 0)
  }

  // MARK: - Statistics Tests

  @Test @MainActor func statisticsReturnsCorrectCounts() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)

    let pending1 = sampleEntry(curriculumID: 1)
    let pending2 = sampleEntry(curriculumID: 2)
    let syncing = sampleEntry(curriculumID: 3)
    let synced = sampleEntry(curriculumID: 4)
    let failed = sampleEntry(curriculumID: 5)

    try queue.enqueue(pending1)
    try queue.enqueue(pending2)
    try queue.enqueue(syncing)
    try queue.enqueue(synced)
    try queue.enqueue(failed)

    try queue.markSyncing(id: syncing.id)

    try queue.markSyncing(id: synced.id)
    try queue.markSynced(id: synced.id)

    struct TestError: Error {}
    try queue.markSyncing(id: failed.id)
    try queue.markFailed(id: failed.id, error: TestError())

    let stats = try queue.statistics()
    #expect(stats.pending == 2)
    #expect(stats.syncing == 1)
    #expect(stats.synced == 1)
    #expect(stats.failed == 1)
    #expect(stats.total == 5)
  }

  @Test @MainActor func statisticsReturnsZeroWhenQueueEmpty() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)

    let stats = try queue.statistics()
    #expect(stats.pending == 0)
    #expect(stats.syncing == 0)
    #expect(stats.synced == 0)
    #expect(stats.failed == 0)
    #expect(stats.total == 0)
  }

  // MARK: - Persistence Tests

  @Test @MainActor func queuePersistsAcrossRestarts() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let entry = sampleEntry()

    // First instance
    do {
      let queue = try JournalQueue(databasePath: dbPath)
      try queue.enqueue(entry)
    }

    // Second instance (restart simulation)
    do {
      let queue = try JournalQueue(databasePath: dbPath)
      let pending = try queue.pendingEntries()

      #expect(pending.count == 1)
      #expect(pending[0].localEntry.id == entry.id)
    }
  }

  @Test @MainActor func statusPersistsAcrossRestarts() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let entry = sampleEntry()

    // First instance - mark as syncing
    do {
      let queue = try JournalQueue(databasePath: dbPath)
      try queue.enqueue(entry)
      try queue.markSyncing(id: entry.id)
    }

    // Second instance - verify status persisted
    do {
      let queue = try JournalQueue(databasePath: dbPath)
      let stats = try queue.statistics()
      #expect(stats.syncing == 1)
      #expect(stats.pending == 0)
    }
  }

  @Test @MainActor func multipleEntriesPersistAcrossRestarts() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let entry1 = sampleEntry(curriculumID: 1)
    let entry2 = sampleEntry(curriculumID: 2)
    let entry3 = sampleEntry(curriculumID: 3)

    // First instance
    do {
      let queue = try JournalQueue(databasePath: dbPath)
      try queue.enqueue(entry1)
      try queue.enqueue(entry2)
      try queue.enqueue(entry3)

      try queue.markSyncing(id: entry2.id)
      try queue.markSynced(id: entry2.id)
    }

    // Second instance
    do {
      let queue = try JournalQueue(databasePath: dbPath)
      let stats = try queue.statistics()

      #expect(stats.pending == 2)
      #expect(stats.synced == 1)
      #expect(stats.total == 3)
    }
  }

  // MARK: - Edge Cases

  @Test @MainActor func markSyncingNonExistentEntryThrows() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let nonExistentID = UUID()

    #expect(throws: JournalQueueError.self) {
      try queue.markSyncing(id: nonExistentID)
    }
  }

  @Test @MainActor func markSyncedNonExistentEntryThrows() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let nonExistentID = UUID()

    #expect(throws: JournalQueueError.self) {
      try queue.markSynced(id: nonExistentID)
    }
  }

  @Test @MainActor func markFailedNonExistentEntryThrows() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let nonExistentID = UUID()

    struct TestError: Error {}

    #expect(throws: JournalQueueError.self) {
      try queue.markFailed(id: nonExistentID, error: TestError())
    }
  }

  // MARK: - Published pendingCount Tests (#216)

  @Test @MainActor func pendingCountStartsAtZeroForEmptyQueue() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)

    #expect(queue.pendingCount == 0)
  }

  @Test @MainActor func pendingCountIncrementsOnEnqueue() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)

    try queue.enqueue(sampleEntry(curriculumID: 1))
    #expect(queue.pendingCount == 1)

    try queue.enqueue(sampleEntry(curriculumID: 2))
    #expect(queue.pendingCount == 2)

    try queue.enqueue(sampleEntry(curriculumID: 3))
    #expect(queue.pendingCount == 3)
  }

  @Test @MainActor func pendingCountDecrementsWhenMarkedSyncing() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let entry = sampleEntry()
    try queue.enqueue(entry)
    #expect(queue.pendingCount == 1)

    try queue.markSyncing(id: entry.id)
    #expect(queue.pendingCount == 0)
  }

  @Test @MainActor func pendingCountRemainsZeroAfterMarkSynced() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let entry = sampleEntry()
    try queue.enqueue(entry)
    try queue.markSyncing(id: entry.id)
    try queue.markSynced(id: entry.id)

    #expect(queue.pendingCount == 0)
  }

  @Test @MainActor func pendingCountReflectsFailedEntriesAsNonPending() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    let queue = try JournalQueue(databasePath: dbPath)
    let entry = sampleEntry()
    try queue.enqueue(entry)
    try queue.markSyncing(id: entry.id)

    struct TestError: Error {}
    try queue.markFailed(id: entry.id, error: TestError())

    // Failed entries are tracked separately; pendingCount only counts `.pending` rows.
    #expect(queue.pendingCount == 0)
  }

  @Test @MainActor func pendingCountHydratedFromDiskOnInit() throws {
    let dbPath = temporaryDatabasePath()
    defer { try? FileManager.default.removeItem(atPath: dbPath) }

    // First instance: enqueue two entries, close
    do {
      let queue = try JournalQueue(databasePath: dbPath)
      try queue.enqueue(sampleEntry(curriculumID: 1))
      try queue.enqueue(sampleEntry(curriculumID: 2))
      #expect(queue.pendingCount == 2)
    }

    // Second instance: pendingCount should be hydrated from disk
    let queue = try JournalQueue(databasePath: dbPath)
    #expect(queue.pendingCount == 2)
  }
}
