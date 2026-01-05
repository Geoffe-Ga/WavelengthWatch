import Foundation
import SQLite3

/// Errors that can occur during database operations.
enum JournalDatabaseError: Error, Equatable {
  case failedToOpenDatabase(String)
  case failedToCreateTable(String)
  case failedToInsert(String)
  case failedToUpdate(String)
  case failedToDelete(String)
  case failedToQuery(String)
  case invalidData(String)
  case databaseNotOpen
}

/// Low-level SQLite database wrapper for journal entry storage.
///
/// This class provides direct SQLite operations using the C API via Foundation.
/// It's designed to be lightweight and efficient for watchOS constraints.
///
/// ## Thread Safety
/// The database is opened with SQLITE_OPEN_FULLMUTEX for multi-threaded safety.
/// However, operations should be coordinated through the repository layer
/// to ensure consistent state and avoid race conditions in business logic.
///
/// ## Schema Version
/// The database includes a version table for future migrations.
final class JournalDatabase {
  /// Current schema version for migration tracking.
  static let schemaVersion = 1

  /// SQLite database pointer.
  private var db: OpaquePointer?

  /// Path to the database file.
  let databasePath: String

  /// Whether the database is currently open.
  var isOpen: Bool { db != nil }

  /// Creates a JournalDatabase instance with the specified path.
  ///
  /// - Parameter path: Path to the SQLite database file.
  ///   Defaults to the app's documents directory.
  init(path: String? = nil) {
    if let path {
      self.databasePath = path
    } else {
      let documentsPath = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
      ).first!
      self.databasePath = documentsPath.appendingPathComponent("journal.sqlite").path
    }
  }

  deinit {
    close()
  }

  /// Opens the database connection and creates tables if needed.
  ///
  /// - Throws: `JournalDatabaseError` if opening or setup fails.
  func open() throws {
    guard db == nil else { return }

    var dbPointer: OpaquePointer?
    let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
    let result = sqlite3_open_v2(databasePath, &dbPointer, flags, nil)

    guard result == SQLITE_OK else {
      let message = dbPointer != nil ? String(cString: sqlite3_errmsg(dbPointer)) : "Unknown error"
      // Clean up the pointer if it was allocated despite the error
      if let dbPointer {
        sqlite3_close(dbPointer)
      }
      throw JournalDatabaseError.failedToOpenDatabase(message)
    }

    guard let dbPointer else {
      throw JournalDatabaseError.failedToOpenDatabase("Database pointer is nil despite SQLITE_OK")
    }

    db = dbPointer
    try createTables()
  }

  /// Closes the database connection.
  func close() {
    guard let db else { return }
    sqlite3_close(db)
    self.db = nil
  }

  /// Creates required tables if they don't exist.
  private func createTables() throws {
    guard let db else { throw JournalDatabaseError.databaseNotOpen }

    // Schema version table
    let versionSQL = """
      CREATE TABLE IF NOT EXISTS schema_version (
        version INTEGER PRIMARY KEY
      );
      INSERT OR IGNORE INTO schema_version (version) VALUES (\(Self.schemaVersion));
    """

    // Journal entries table with indexes for common queries
    let journalSQL = """
      CREATE TABLE IF NOT EXISTS journal_entry (
        id TEXT PRIMARY KEY,
        server_id INTEGER,
        created_at REAL NOT NULL,
        user_id INTEGER NOT NULL,
        curriculum_id INTEGER NOT NULL,
        secondary_curriculum_id INTEGER,
        strategy_id INTEGER,
        initiated_by TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        last_sync_attempt REAL
      );

      CREATE INDEX IF NOT EXISTS idx_journal_user_created
        ON journal_entry(user_id, created_at DESC);

      CREATE INDEX IF NOT EXISTS idx_journal_sync_status
        ON journal_entry(sync_status);

      CREATE INDEX IF NOT EXISTS idx_journal_curriculum
        ON journal_entry(curriculum_id);

      CREATE UNIQUE INDEX IF NOT EXISTS idx_journal_server_id
        ON journal_entry(server_id) WHERE server_id IS NOT NULL;
    """

    var errorMessage: UnsafeMutablePointer<CChar>?

    if sqlite3_exec(db, versionSQL, nil, nil, &errorMessage) != SQLITE_OK {
      let message = errorMessage.map { String(cString: $0) } ?? "Unknown error"
      sqlite3_free(errorMessage)
      throw JournalDatabaseError.failedToCreateTable(message)
    }

    if sqlite3_exec(db, journalSQL, nil, nil, &errorMessage) != SQLITE_OK {
      let message = errorMessage.map { String(cString: $0) } ?? "Unknown error"
      sqlite3_free(errorMessage)
      throw JournalDatabaseError.failedToCreateTable(message)
    }
  }

  /// Inserts a new journal entry.
  ///
  /// - Parameter entry: The entry to insert.
  /// - Throws: `JournalDatabaseError` if insertion fails.
  func insert(_ entry: LocalJournalEntry) throws {
    guard let db else { throw JournalDatabaseError.databaseNotOpen }

    let sql = """
      INSERT INTO journal_entry (
        id, server_id, created_at, user_id, curriculum_id,
        secondary_curriculum_id, strategy_id, initiated_by,
        sync_status, last_sync_attempt
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """

    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalDatabaseError.failedToInsert(message)
    }
    defer { sqlite3_finalize(statement) }

    // Bind values
    sqlite3_bind_text(statement, 1, entry.id.uuidString, -1, SQLITE_TRANSIENT)
    if let serverId = entry.serverId {
      sqlite3_bind_int64(statement, 2, Int64(serverId))
    } else {
      sqlite3_bind_null(statement, 2)
    }
    sqlite3_bind_double(statement, 3, entry.createdAt.timeIntervalSince1970)
    sqlite3_bind_int64(statement, 4, Int64(entry.userID))
    sqlite3_bind_int64(statement, 5, Int64(entry.curriculumID))
    if let secondary = entry.secondaryCurriculumID {
      sqlite3_bind_int64(statement, 6, Int64(secondary))
    } else {
      sqlite3_bind_null(statement, 6)
    }
    if let strategy = entry.strategyID {
      sqlite3_bind_int64(statement, 7, Int64(strategy))
    } else {
      sqlite3_bind_null(statement, 7)
    }
    sqlite3_bind_text(statement, 8, entry.initiatedBy.rawValue, -1, SQLITE_TRANSIENT)
    sqlite3_bind_text(statement, 9, entry.syncStatus.rawValue, -1, SQLITE_TRANSIENT)
    if let lastSync = entry.lastSyncAttempt {
      sqlite3_bind_double(statement, 10, lastSync.timeIntervalSince1970)
    } else {
      sqlite3_bind_null(statement, 10)
    }

    guard sqlite3_step(statement) == SQLITE_DONE else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalDatabaseError.failedToInsert(message)
    }
  }

  /// Updates an existing journal entry.
  ///
  /// - Parameter entry: The entry to update (matched by id).
  /// - Throws: `JournalDatabaseError` if update fails.
  func update(_ entry: LocalJournalEntry) throws {
    guard let db else { throw JournalDatabaseError.databaseNotOpen }

    let sql = """
      UPDATE journal_entry SET
        server_id = ?,
        sync_status = ?,
        last_sync_attempt = ?
      WHERE id = ?
    """

    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalDatabaseError.failedToUpdate(message)
    }
    defer { sqlite3_finalize(statement) }

    if let serverId = entry.serverId {
      sqlite3_bind_int64(statement, 1, Int64(serverId))
    } else {
      sqlite3_bind_null(statement, 1)
    }
    sqlite3_bind_text(statement, 2, entry.syncStatus.rawValue, -1, SQLITE_TRANSIENT)
    if let lastSync = entry.lastSyncAttempt {
      sqlite3_bind_double(statement, 3, lastSync.timeIntervalSince1970)
    } else {
      sqlite3_bind_null(statement, 3)
    }
    sqlite3_bind_text(statement, 4, entry.id.uuidString, -1, SQLITE_TRANSIENT)

    guard sqlite3_step(statement) == SQLITE_DONE else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalDatabaseError.failedToUpdate(message)
    }
  }

  /// Deletes a journal entry by ID.
  ///
  /// - Parameter id: The UUID of the entry to delete.
  /// - Throws: `JournalDatabaseError` if deletion fails.
  func delete(id: UUID) throws {
    guard let db else { throw JournalDatabaseError.databaseNotOpen }

    let sql = "DELETE FROM journal_entry WHERE id = ?"

    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalDatabaseError.failedToDelete(message)
    }
    defer { sqlite3_finalize(statement) }

    sqlite3_bind_text(statement, 1, id.uuidString, -1, SQLITE_TRANSIENT)

    guard sqlite3_step(statement) == SQLITE_DONE else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalDatabaseError.failedToDelete(message)
    }
  }

  /// Fetches all journal entries, ordered by creation date (newest first).
  ///
  /// - Returns: Array of all journal entries.
  /// - Throws: `JournalDatabaseError` if query fails.
  func fetchAll() throws -> [LocalJournalEntry] {
    guard let db else { throw JournalDatabaseError.databaseNotOpen }

    let sql = "SELECT * FROM journal_entry ORDER BY created_at DESC"

    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalDatabaseError.failedToQuery(message)
    }
    defer { sqlite3_finalize(statement) }

    var entries: [LocalJournalEntry] = []
    while sqlite3_step(statement) == SQLITE_ROW {
      if let entry = try parseEntry(from: statement) {
        entries.append(entry)
      }
    }

    return entries
  }

  /// Fetches entries with a specific sync status.
  ///
  /// - Parameter status: The sync status to filter by.
  /// - Returns: Array of matching entries.
  /// - Throws: `JournalDatabaseError` if query fails.
  func fetchByStatus(_ status: SyncStatus) throws -> [LocalJournalEntry] {
    guard let db else { throw JournalDatabaseError.databaseNotOpen }

    let sql = "SELECT * FROM journal_entry WHERE sync_status = ? ORDER BY created_at DESC"

    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalDatabaseError.failedToQuery(message)
    }
    defer { sqlite3_finalize(statement) }

    sqlite3_bind_text(statement, 1, status.rawValue, -1, SQLITE_TRANSIENT)

    var entries: [LocalJournalEntry] = []
    while sqlite3_step(statement) == SQLITE_ROW {
      if let entry = try parseEntry(from: statement) {
        entries.append(entry)
      }
    }

    return entries
  }

  /// Fetches a single entry by ID.
  ///
  /// - Parameter id: The UUID of the entry to fetch.
  /// - Returns: The entry if found, nil otherwise.
  /// - Throws: `JournalDatabaseError` if query fails.
  func fetch(id: UUID) throws -> LocalJournalEntry? {
    guard let db else { throw JournalDatabaseError.databaseNotOpen }

    let sql = "SELECT * FROM journal_entry WHERE id = ?"

    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalDatabaseError.failedToQuery(message)
    }
    defer { sqlite3_finalize(statement) }

    sqlite3_bind_text(statement, 1, id.uuidString, -1, SQLITE_TRANSIENT)

    guard sqlite3_step(statement) == SQLITE_ROW else {
      return nil
    }

    return try parseEntry(from: statement)
  }

  /// Returns the total count of entries.
  ///
  /// - Returns: Number of entries in the database.
  /// - Throws: `JournalDatabaseError` if query fails.
  func count() throws -> Int {
    guard let db else { throw JournalDatabaseError.databaseNotOpen }

    let sql = "SELECT COUNT(*) FROM journal_entry"

    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
      let message = String(cString: sqlite3_errmsg(db))
      throw JournalDatabaseError.failedToQuery(message)
    }
    defer { sqlite3_finalize(statement) }

    guard sqlite3_step(statement) == SQLITE_ROW else {
      return 0
    }

    return Int(sqlite3_column_int64(statement, 0))
  }

  /// Parses a LocalJournalEntry from a SQLite statement row.
  private func parseEntry(from statement: OpaquePointer?) throws -> LocalJournalEntry? {
    guard let statement else { return nil }

    // Column indices
    let idCol = 0
    let serverIdCol = 1
    let createdAtCol = 2
    let userIdCol = 3
    let curriculumIdCol = 4
    let secondaryCurriculumIdCol = 5
    let strategyIdCol = 6
    let initiatedByCol = 7
    let syncStatusCol = 8
    let lastSyncAttemptCol = 9

    // Parse required fields
    guard let idString = sqlite3_column_text(statement, Int32(idCol)).map({ String(cString: $0) }),
          let id = UUID(uuidString: idString)
    else {
      throw JournalDatabaseError.invalidData("Invalid or missing ID")
    }

    let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, Int32(createdAtCol)))
    let userID = Int(sqlite3_column_int64(statement, Int32(userIdCol)))
    let curriculumID = Int(sqlite3_column_int64(statement, Int32(curriculumIdCol)))

    guard let initiatedByString = sqlite3_column_text(statement, Int32(initiatedByCol)).map({ String(cString: $0) }),
          let initiatedBy = InitiatedBy(rawValue: initiatedByString)
    else {
      throw JournalDatabaseError.invalidData("Invalid initiated_by value")
    }

    guard let syncStatusString = sqlite3_column_text(statement, Int32(syncStatusCol)).map({ String(cString: $0) }),
          let syncStatus = SyncStatus(rawValue: syncStatusString)
    else {
      throw JournalDatabaseError.invalidData("Invalid sync_status value")
    }

    // Parse optional fields
    var entry = LocalJournalEntry(
      id: id,
      createdAt: createdAt,
      userID: userID,
      curriculumID: curriculumID,
      secondaryCurriculumID: sqlite3_column_type(statement, Int32(secondaryCurriculumIdCol)) != SQLITE_NULL
        ? Int(sqlite3_column_int64(statement, Int32(secondaryCurriculumIdCol)))
        : nil,
      strategyID: sqlite3_column_type(statement, Int32(strategyIdCol)) != SQLITE_NULL
        ? Int(sqlite3_column_int64(statement, Int32(strategyIdCol)))
        : nil,
      initiatedBy: initiatedBy
    )

    entry.serverId = sqlite3_column_type(statement, Int32(serverIdCol)) != SQLITE_NULL
      ? Int(sqlite3_column_int64(statement, Int32(serverIdCol)))
      : nil
    entry.syncStatus = syncStatus
    entry.lastSyncAttempt = sqlite3_column_type(statement, Int32(lastSyncAttemptCol)) != SQLITE_NULL
      ? Date(timeIntervalSince1970: sqlite3_column_double(statement, Int32(lastSyncAttemptCol)))
      : nil

    return entry
  }
}

// MARK: - SQLITE_TRANSIENT Helper

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
