import Foundation
import SQLite3

/// SQLite-based queue service for offline journal entries.
///
/// This service manages a persistent queue of journal entries that need to be
/// synced to the backend. It tracks sync status, retry counts, and provides
/// cleanup capabilities for successfully synced entries.
///
/// ## Design
/// - **Offline-first**: All operations persist to SQLite immediately
/// - **Status tracking**: pending → syncing → synced/failed
/// - **Retry management**: Tracks retry counts for failed sync attempts
/// - **Cleanup**: Removes old synced entries to prevent database bloat
///
/// ## Thread Safety
/// The underlying SQLite database is opened with SQLITE_OPEN_FULLMUTEX for
/// multi-threaded safety. However, callers should coordinate operations
/// through a single queue or actor to ensure consistent application state.
///
/// ## Usage
/// ```swift
/// let queue = try JournalQueue()
///
/// // Add entry to queue
/// try queue.enqueue(entry)
///
/// // Get pending entries for sync
/// let pending = try queue.pendingEntries()
///
/// // Mark as syncing
/// try queue.markSyncing(id: entry.id)
///
/// // Mark as synced or failed
/// try queue.markSynced(id: entry.id)
/// // or
/// try queue.markFailed(id: entry.id, error: syncError)
///
/// // Cleanup old synced entries
/// try queue.cleanupSynced(olderThan: 30)
/// ```
@MainActor
final class JournalQueue: ObservableObject {
  // MARK: - Private Properties

  /// SQLite database pointer.
  ///
  /// Marked nonisolated(unsafe) to allow access from deinit.
  /// Safe because:
  /// - SQLite opened with FULLMUTEX is thread-safe
  /// - deinit only called when no other references exist
  private nonisolated(unsafe) var db: OpaquePointer?

  /// Path to the database file.
  private let databasePath: String

  /// Whether the database is currently open.
  private var isOpen: Bool { db != nil }

  // MARK: - Initialization

  /// Creates a JournalQueue with the specified database path.
  ///
  /// - Parameter databasePath: Path to the SQLite database file.
  ///   If nil, uses the app's documents directory.
  /// - Throws: `JournalQueueError` if database setup fails.
  init(databasePath: String? = nil) throws {
    if let databasePath {
      self.databasePath = databasePath
    } else {
      guard
        let documentsPath = FileManager.default.urls(
          for: .documentDirectory,
          in: .userDomainMask
        ).first
      else {
        throw JournalQueueError.databaseError(
          "Could not access documents directory"
        )
      }
      self.databasePath = documentsPath
        .appendingPathComponent("journal_queue.sqlite")
        .path
    }

    try openDatabase()
    try createTables()
  }

  deinit {
    closeDatabase()
  }

  // MARK: - Public Methods

  /// Adds a journal entry to the sync queue.
  ///
  /// If the entry already exists in the queue (by ID), this is a no-op.
  ///
  /// - Parameter entry: The journal entry to enqueue.
  /// - Throws: `JournalQueueError` if insertion fails.
  func enqueue(_ entry: LocalJournalEntry) throws {
    guard let db else {
      throw JournalQueueError.databaseError("Database not open")
    }

    // Check if entry already exists
    if try exists(id: entry.id) {
      return // Prevent duplicates
    }

    let sql = """
      INSERT INTO journal_queue (
        id, local_entry_data, status, retry_count, last_attempt, created_at
      ) VALUES (?, ?, ?, ?, ?, ?)
    """

    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalQueueError.insertFailed(message)
    }
    defer { sqlite3_finalize(statement) }

    // Encode the LocalJournalEntry to JSON
    let encoder = JSONEncoder()
    let entryData = try encoder.encode(entry)

    sqlite3_bind_text(statement, 1, entry.id.uuidString, -1, SQLITE_TRANSIENT)
    sqlite3_bind_blob(
      statement,
      2,
      (entryData as NSData).bytes,
      Int32(entryData.count),
      SQLITE_TRANSIENT
    )
    sqlite3_bind_text(statement, 3, QueueStatus.pending.rawValue, -1, SQLITE_TRANSIENT)
    sqlite3_bind_int(statement, 4, 0) // retry_count
    sqlite3_bind_null(statement, 5) // last_attempt
    sqlite3_bind_double(statement, 6, Date().timeIntervalSince1970)

    guard sqlite3_step(statement) == SQLITE_DONE else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalQueueError.insertFailed(message)
    }
  }

  /// Retrieves all pending entries from the queue.
  ///
  /// Returns entries with status `.pending` in the order they were added.
  ///
  /// - Returns: Array of pending queue items.
  /// - Throws: `JournalQueueError` if query fails.
  func pendingEntries() throws -> [JournalQueueItem] {
    try fetchEntries(withStatus: .pending)
  }

  /// Fetches a specific queue item by ID.
  ///
  /// - Parameter id: The entry ID to fetch.
  /// - Returns: The queue item if found, nil otherwise.
  /// - Throws: `JournalQueueError` if query fails.
  func fetch(id: UUID) throws -> JournalQueueItem? {
    guard let db else {
      throw JournalQueueError.databaseError("Database not open")
    }

    let sql = """
      SELECT id, local_entry_data, status, retry_count, last_attempt, created_at
      FROM journal_queue
      WHERE id = ?
    """

    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalQueueError.queryFailed(message)
    }
    defer { sqlite3_finalize(statement) }

    sqlite3_bind_text(statement, 1, id.uuidString, -1, SQLITE_TRANSIENT)

    guard sqlite3_step(statement) == SQLITE_ROW else {
      return nil
    }

    return try parseQueueItem(from: statement)
  }

  /// Marks an entry as currently syncing.
  ///
  /// Updates the status to `.syncing` and records the attempt time.
  ///
  /// - Parameter id: The entry ID to update.
  /// - Throws: `JournalQueueError` if entry not found or update fails.
  func markSyncing(id: UUID) throws {
    try updateStatus(id: id, status: .syncing, incrementRetry: false)
  }

  /// Marks an entry as successfully synced.
  ///
  /// Updates the status to `.synced`.
  ///
  /// - Parameter id: The entry ID to update.
  /// - Throws: `JournalQueueError` if entry not found or update fails.
  func markSynced(id: UUID) throws {
    try updateStatus(id: id, status: .synced, incrementRetry: false)
  }

  /// Marks an entry as failed to sync.
  ///
  /// Updates the status to `.failed`, increments the retry count, and records
  /// the attempt time.
  ///
  /// - Parameters:
  ///   - id: The entry ID to update.
  ///   - error: The error that caused the failure (for logging).
  /// - Throws: `JournalQueueError` if entry not found or update fails.
  func markFailed(id: UUID, error: Error) throws {
    try updateStatus(id: id, status: .failed, incrementRetry: true)
  }

  /// Removes synced entries older than the specified number of days.
  ///
  /// This helps prevent database bloat by removing successfully synced entries
  /// that are no longer needed. Only entries with `.synced` status are removed.
  ///
  /// - Parameter days: Age threshold in days. Entries synced more than this
  ///   many days ago will be removed.
  /// - Throws: `JournalQueueError` if deletion fails.
  func cleanupSynced(olderThan days: Int) throws {
    guard let db else {
      throw JournalQueueError.databaseError("Database not open")
    }

    let cutoffTime = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)

    let sql = """
      DELETE FROM journal_queue
      WHERE status = ? AND created_at < ?
    """

    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalQueueError.queryFailed(message)
    }
    defer { sqlite3_finalize(statement) }

    sqlite3_bind_text(statement, 1, QueueStatus.synced.rawValue, -1, SQLITE_TRANSIENT)
    sqlite3_bind_double(statement, 2, cutoffTime.timeIntervalSince1970)

    guard sqlite3_step(statement) == SQLITE_DONE else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalQueueError.updateFailed(message)
    }
  }

  /// Returns statistics about the queue.
  ///
  /// Provides counts of entries in each status state.
  ///
  /// - Returns: Queue statistics.
  /// - Throws: `JournalQueueError` if query fails.
  func statistics() throws -> QueueStatistics {
    guard let db else {
      throw JournalQueueError.databaseError("Database not open")
    }

    let sql = """
      SELECT status, COUNT(*) FROM journal_queue GROUP BY status
    """

    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalQueueError.queryFailed(message)
    }
    defer { sqlite3_finalize(statement) }

    var counts: [QueueStatus: Int] = [:]

    while sqlite3_step(statement) == SQLITE_ROW {
      guard
        let statusString = sqlite3_column_text(statement, 0).map({ String(cString: $0) }),
        let status = QueueStatus(rawValue: statusString)
      else {
        continue
      }

      let count = Int(sqlite3_column_int(statement, 1))
      counts[status] = count
    }

    return QueueStatistics(
      pending: counts[.pending] ?? 0,
      syncing: counts[.syncing] ?? 0,
      synced: counts[.synced] ?? 0,
      failed: counts[.failed] ?? 0
    )
  }

  // MARK: - Private Methods

  /// Opens the SQLite database connection.
  private func openDatabase() throws {
    guard db == nil else { return }

    var dbPointer: OpaquePointer?
    let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
    let result = sqlite3_open_v2(databasePath, &dbPointer, flags, nil)

    guard result == SQLITE_OK else {
      let message = dbPointer != nil
        ? String(cString: sqlite3_errmsg(dbPointer))
        : "Unknown error"
      if let dbPointer {
        sqlite3_close(dbPointer)
      }
      throw JournalQueueError.databaseError(message)
    }

    guard let dbPointer else {
      throw JournalQueueError.databaseError(
        "Database pointer is nil despite SQLITE_OK"
      )
    }

    db = dbPointer
  }

  /// Closes the database connection.
  ///
  /// Called automatically from deinit. Can also be called explicitly during
  /// testing or specific lifecycle scenarios if needed.
  private nonisolated func closeDatabase() {
    guard let db else { return }
    sqlite3_close(db)
    self.db = nil
  }

  /// Creates the required database tables.
  private func createTables() throws {
    guard let db else {
      throw JournalQueueError.databaseError("Database not open")
    }

    let sql = """
      CREATE TABLE IF NOT EXISTS journal_queue (
        id TEXT PRIMARY KEY,
        local_entry_data BLOB NOT NULL,
        status TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_attempt REAL,
        created_at REAL NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_queue_status
        ON journal_queue(status);

      CREATE INDEX IF NOT EXISTS idx_queue_created_at
        ON journal_queue(created_at);
    """

    var errorMessage: UnsafeMutablePointer<CChar>?

    if sqlite3_exec(db, sql, nil, nil, &errorMessage) != SQLITE_OK {
      let message = errorMessage.map { String(cString: $0) } ?? "Unknown error"
      sqlite3_free(errorMessage)
      throw JournalQueueError.databaseError(message)
    }
  }

  /// Checks if an entry exists in the queue.
  private func exists(id: UUID) throws -> Bool {
    guard let db else {
      throw JournalQueueError.databaseError("Database not open")
    }

    let sql = "SELECT COUNT(*) FROM journal_queue WHERE id = ?"

    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalQueueError.queryFailed(message)
    }
    defer { sqlite3_finalize(statement) }

    sqlite3_bind_text(statement, 1, id.uuidString, -1, SQLITE_TRANSIENT)

    guard sqlite3_step(statement) == SQLITE_ROW else {
      return false
    }

    let count = sqlite3_column_int(statement, 0)
    return count > 0
  }

  /// Updates the status of a queue entry.
  private func updateStatus(
    id: UUID,
    status: QueueStatus,
    incrementRetry: Bool
  ) throws {
    guard let db else {
      throw JournalQueueError.databaseError("Database not open")
    }

    // Verify entry exists
    guard try exists(id: id) else {
      throw JournalQueueError.entryNotFound(id)
    }

    let sql = if incrementRetry {
      """
      UPDATE journal_queue
      SET status = ?, retry_count = retry_count + 1, last_attempt = ?
      WHERE id = ?
      """
    } else {
      """
      UPDATE journal_queue
      SET status = ?, last_attempt = ?
      WHERE id = ?
      """
    }

    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalQueueError.updateFailed(message)
    }
    defer { sqlite3_finalize(statement) }

    sqlite3_bind_text(statement, 1, status.rawValue, -1, SQLITE_TRANSIENT)
    sqlite3_bind_double(statement, 2, Date().timeIntervalSince1970)
    sqlite3_bind_text(statement, 3, id.uuidString, -1, SQLITE_TRANSIENT)

    guard sqlite3_step(statement) == SQLITE_DONE else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalQueueError.updateFailed(message)
    }
  }

  /// Fetches entries with a specific status.
  private func fetchEntries(withStatus status: QueueStatus) throws
    -> [JournalQueueItem]
  {
    guard let db else {
      throw JournalQueueError.databaseError("Database not open")
    }

    let sql = """
      SELECT id, local_entry_data, status, retry_count, last_attempt, created_at
      FROM journal_queue
      WHERE status = ?
      ORDER BY created_at ASC
    """

    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalQueueError.queryFailed(message)
    }
    defer { sqlite3_finalize(statement) }

    sqlite3_bind_text(statement, 1, status.rawValue, -1, SQLITE_TRANSIENT)

    var items: [JournalQueueItem] = []

    while sqlite3_step(statement) == SQLITE_ROW {
      if let item = try parseQueueItem(from: statement) {
        items.append(item)
      }
    }

    return items
  }

  /// Parses a JournalQueueItem from a SQLite statement row.
  private func parseQueueItem(from statement: OpaquePointer?) throws
    -> JournalQueueItem?
  {
    guard let statement else { return nil }

    // Parse ID
    guard
      let idString = sqlite3_column_text(statement, 0).map({ String(cString: $0) }),
      let id = UUID(uuidString: idString)
    else {
      throw JournalQueueError.invalidData("Invalid or missing ID")
    }

    // Parse local entry data (BLOB)
    let blobPointer = sqlite3_column_blob(statement, 1)
    let blobSize = sqlite3_column_bytes(statement, 1)

    guard blobPointer != nil, blobSize > 0 else {
      throw JournalQueueError.invalidData("Invalid or missing entry data")
    }

    let data = Data(bytes: blobPointer!, count: Int(blobSize))
    let decoder = JSONDecoder()
    let localEntry = try decoder.decode(LocalJournalEntry.self, from: data)

    // Parse status
    guard
      let statusString = sqlite3_column_text(statement, 2).map({ String(cString: $0) }),
      let status = QueueStatus(rawValue: statusString)
    else {
      throw JournalQueueError.invalidData("Invalid or missing status")
    }

    // Parse retry count
    let retryCount = Int(sqlite3_column_int(statement, 3))

    // Parse last attempt (optional)
    let lastAttempt: Date? = if sqlite3_column_type(statement, 4) != SQLITE_NULL {
      Date(
        timeIntervalSince1970: sqlite3_column_double(statement, 4)
      )
    } else {
      nil
    }

    // Parse created at
    let createdAt = Date(
      timeIntervalSince1970: sqlite3_column_double(statement, 5)
    )

    return JournalQueueItem(
      id: id,
      localEntry: localEntry,
      status: status,
      retryCount: retryCount,
      lastAttempt: lastAttempt,
      createdAt: createdAt
    )
  }
}

// MARK: - SQLITE_TRANSIENT Helper

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
