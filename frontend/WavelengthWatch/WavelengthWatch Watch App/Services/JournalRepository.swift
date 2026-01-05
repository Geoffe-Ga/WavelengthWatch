import Foundation

/// Protocol for journal entry persistence operations.
///
/// Abstracts the database layer for testability and potential
/// future storage backend changes.
protocol JournalRepositoryProtocol {
  /// Saves a new journal entry to local storage.
  func save(_ entry: LocalJournalEntry) throws

  /// Updates an existing entry (primarily for sync status changes).
  func update(_ entry: LocalJournalEntry) throws

  /// Deletes an entry by ID.
  func delete(id: UUID) throws

  /// Fetches a single entry by ID.
  func fetch(id: UUID) throws -> LocalJournalEntry?

  /// Fetches all entries, newest first.
  func fetchAll() throws -> [LocalJournalEntry]

  /// Fetches entries pending sync.
  func fetchPendingSync() throws -> [LocalJournalEntry]

  /// Returns total entry count.
  func count() throws -> Int
}

/// Repository for managing local journal entry storage.
///
/// This class provides a high-level interface for journal entry CRUD operations,
/// abstracting the underlying SQLite database. It ensures thread safety and
/// proper error handling for all database operations.
///
/// ## Usage
/// ```swift
/// let repository = JournalRepository()
/// try repository.open()
///
/// // Save a new entry
/// let entry = LocalJournalEntry(...)
/// try repository.save(entry)
///
/// // Fetch all entries
/// let entries = try repository.fetchAll()
/// ```
///
/// ## Thread Safety
/// SQLite is opened with FULLMUTEX for database-level thread safety,
/// preventing corruption from concurrent access. However, business logic
/// operations (read-modify-write sequences) are not atomic. Callers should
/// coordinate repository operations through a single queue or actor to
/// ensure consistent application state.
final class JournalRepository: JournalRepositoryProtocol {
  private let database: JournalDatabase
  private var isOpen = false

  /// Creates a repository with the default database path.
  convenience init() {
    self.init(database: JournalDatabase())
  }

  /// Creates a repository with a custom database.
  ///
  /// - Parameter database: The database to use for storage.
  init(database: JournalDatabase) {
    self.database = database
  }

  /// Opens the database connection.
  ///
  /// Must be called before any other operations.
  ///
  /// - Throws: `JournalDatabaseError` if opening fails.
  func open() throws {
    guard !isOpen else { return }
    try database.open()
    isOpen = true
  }

  /// Closes the database connection.
  func close() {
    database.close()
    isOpen = false
  }

  /// Saves a new journal entry.
  ///
  /// - Parameter entry: The entry to save.
  /// - Throws: `JournalDatabaseError` if save fails.
  func save(_ entry: LocalJournalEntry) throws {
    try ensureOpen()
    try database.insert(entry)
  }

  /// Updates an existing entry.
  ///
  /// - Parameter entry: The entry to update (matched by ID).
  /// - Throws: `JournalDatabaseError` if update fails.
  func update(_ entry: LocalJournalEntry) throws {
    try ensureOpen()
    try database.update(entry)
  }

  /// Deletes an entry by ID.
  ///
  /// - Parameter id: The UUID of the entry to delete.
  /// - Throws: `JournalDatabaseError` if deletion fails.
  func delete(id: UUID) throws {
    try ensureOpen()
    try database.delete(id: id)
  }

  /// Fetches a single entry by ID.
  ///
  /// - Parameter id: The UUID of the entry to fetch.
  /// - Returns: The entry if found, nil otherwise.
  /// - Throws: `JournalDatabaseError` if query fails.
  func fetch(id: UUID) throws -> LocalJournalEntry? {
    try ensureOpen()
    return try database.fetch(id: id)
  }

  /// Fetches all entries, ordered by creation date (newest first).
  ///
  /// - Returns: Array of all entries.
  /// - Throws: `JournalDatabaseError` if query fails.
  func fetchAll() throws -> [LocalJournalEntry] {
    try ensureOpen()
    return try database.fetchAll()
  }

  /// Fetches entries that are pending sync.
  ///
  /// - Returns: Array of entries with pending or failed sync status.
  /// - Throws: `JournalDatabaseError` if query fails.
  func fetchPendingSync() throws -> [LocalJournalEntry] {
    try ensureOpen()
    let pending = try database.fetchByStatus(.pending)
    let failed = try database.fetchByStatus(.failed)
    return pending + failed
  }

  /// Returns the total count of entries.
  ///
  /// - Returns: Number of entries in the database.
  /// - Throws: `JournalDatabaseError` if query fails.
  func count() throws -> Int {
    try ensureOpen()
    return try database.count()
  }

  /// Ensures the database is open before operations.
  private func ensureOpen() throws {
    if !isOpen {
      try open()
    }
  }
}

// MARK: - In-Memory Repository for Testing

/// In-memory implementation of JournalRepositoryProtocol for testing.
///
/// Stores entries in memory without database file I/O.
final class InMemoryJournalRepository: JournalRepositoryProtocol {
  private var entries: [UUID: LocalJournalEntry] = [:]

  func save(_ entry: LocalJournalEntry) throws {
    entries[entry.id] = entry
  }

  func update(_ entry: LocalJournalEntry) throws {
    entries[entry.id] = entry
  }

  func delete(id: UUID) throws {
    entries.removeValue(forKey: id)
  }

  func fetch(id: UUID) throws -> LocalJournalEntry? {
    entries[id]
  }

  func fetchAll() throws -> [LocalJournalEntry] {
    entries.values.sorted { $0.createdAt > $1.createdAt }
  }

  func fetchPendingSync() throws -> [LocalJournalEntry] {
    entries.values.filter { $0.syncStatus == .pending || $0.syncStatus == .failed }
      .sorted { $0.createdAt > $1.createdAt }
  }

  func count() throws -> Int {
    entries.count
  }

  /// Clears all entries (for test cleanup).
  func clear() {
    entries.removeAll()
  }
}
