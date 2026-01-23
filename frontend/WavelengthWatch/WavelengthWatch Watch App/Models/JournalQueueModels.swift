import Foundation

/// Status of a journal entry in the sync queue.
enum QueueStatus: String, Codable {
  /// Entry is waiting to be synced.
  case pending

  /// Entry is currently being synced to the backend.
  case syncing

  /// Entry has been successfully synced to the backend.
  case synced

  /// Sync attempt failed, will retry later.
  case failed
}

/// A journal entry in the sync queue with metadata for tracking sync state.
struct JournalQueueItem: Identifiable {
  /// Unique identifier (same as the local entry ID).
  let id: UUID

  /// The actual journal entry to sync.
  let localEntry: LocalJournalEntry

  /// Current sync status.
  var status: QueueStatus

  /// Number of times sync has been attempted and failed.
  var retryCount: Int

  /// Timestamp of the last sync attempt.
  var lastAttempt: Date?

  /// When this item was added to the queue.
  let createdAt: Date

  /// Creates a new queue item from a journal entry.
  ///
  /// - Parameter entry: The journal entry to enqueue
  init(entry: LocalJournalEntry) {
    self.id = entry.id
    self.localEntry = entry
    self.status = .pending
    self.retryCount = 0
    self.lastAttempt = nil
    self.createdAt = Date()
  }

  /// Creates a queue item with explicit values (for testing/reconstruction).
  init(
    id: UUID,
    localEntry: LocalJournalEntry,
    status: QueueStatus,
    retryCount: Int,
    lastAttempt: Date?,
    createdAt: Date
  ) {
    self.id = id
    self.localEntry = localEntry
    self.status = status
    self.retryCount = retryCount
    self.lastAttempt = lastAttempt
    self.createdAt = createdAt
  }
}

/// Statistics about the journal sync queue.
struct QueueStatistics {
  /// Number of entries waiting to sync.
  let pending: Int

  /// Number of entries currently being synced.
  let syncing: Int

  /// Number of successfully synced entries.
  let synced: Int

  /// Number of entries that failed to sync.
  let failed: Int

  /// Total number of entries in the queue.
  var total: Int {
    pending + syncing + synced + failed
  }
}

/// Errors that can occur during journal queue operations.
enum JournalQueueError: Error, Equatable {
  /// Failed to open or create the database.
  case databaseError(String)

  /// Failed to insert an entry into the queue.
  case insertFailed(String)

  /// Failed to update an entry's status.
  case updateFailed(String)

  /// Failed to query the queue.
  case queryFailed(String)

  /// The requested entry was not found in the queue.
  case entryNotFound(UUID)

  /// Invalid data encountered during deserialization.
  case invalidData(String)
}
