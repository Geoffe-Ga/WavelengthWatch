import Foundation

/// Sync status for local journal entries.
///
/// Tracks whether an entry has been synced to the backend server.
/// Used only when cloud sync is enabled in settings.
enum SyncStatus: String, Codable {
  /// Entry exists only locally, not yet synced to backend.
  case pending

  /// Entry has been successfully synced to backend.
  case synced

  /// Sync attempted but failed; will retry on next sync cycle.
  case failed
}

/// Local journal entry stored in on-device SQLite database.
///
/// This model mirrors the backend `Journal` schema but includes additional
/// metadata for sync tracking. It serves as the primary data source for
/// analytics and journal history, with optional backend sync when enabled.
///
/// ## Design Decisions
/// - `id`: Uses UUID for offline-first creation (no backend dependency)
/// - `serverId`: Backend-assigned ID after successful sync (nil until synced)
/// - `syncStatus`: Tracks sync state for background sync operations
/// - `lastSyncAttempt`: Enables intelligent retry backoff
struct LocalJournalEntry: Codable, Identifiable, Equatable {
  /// Local unique identifier (UUID for offline-first creation).
  let id: UUID

  /// Backend-assigned ID after successful sync. Nil until synced.
  var serverId: Int?

  /// When the entry was created (user's local time).
  let createdAt: Date

  /// Pseudo-unique user identifier derived from device.
  let userID: Int

  /// Primary emotion curriculum ID (required).
  let curriculumID: Int

  /// Secondary emotion curriculum ID (optional).
  let secondaryCurriculumID: Int?

  /// Self-care strategy ID (optional).
  let strategyID: Int?

  /// How the entry was initiated.
  let initiatedBy: InitiatedBy

  /// Current sync status with backend.
  var syncStatus: SyncStatus

  /// Last time sync was attempted (for retry backoff).
  var lastSyncAttempt: Date?

  /// Creates a new local journal entry with pending sync status.
  ///
  /// - Parameters:
  ///   - id: Local UUID (defaults to new UUID)
  ///   - createdAt: Entry creation timestamp
  ///   - userID: Pseudo-unique user identifier
  ///   - curriculumID: Primary emotion curriculum ID
  ///   - secondaryCurriculumID: Optional secondary emotion
  ///   - strategyID: Optional self-care strategy
  ///   - initiatedBy: Entry initiation source
  init(
    id: UUID = UUID(),
    createdAt: Date,
    userID: Int,
    curriculumID: Int,
    secondaryCurriculumID: Int? = nil,
    strategyID: Int? = nil,
    initiatedBy: InitiatedBy = .self_initiated
  ) {
    self.id = id
    self.serverId = nil
    self.createdAt = createdAt
    self.userID = userID
    self.curriculumID = curriculumID
    self.secondaryCurriculumID = secondaryCurriculumID
    self.strategyID = strategyID
    self.initiatedBy = initiatedBy
    self.syncStatus = .pending
    self.lastSyncAttempt = nil
  }

  /// Creates an entry from a backend response after successful sync.
  ///
  /// - Parameters:
  ///   - response: Backend response model
  ///   - localEntry: Original local entry being synced
  /// - Returns: Updated entry with server ID and synced status
  static func synced(
    from response: JournalResponseModel,
    localEntry: LocalJournalEntry
  ) -> LocalJournalEntry {
    var entry = localEntry
    entry.serverId = response.id
    entry.syncStatus = .synced
    entry.lastSyncAttempt = Date()
    return entry
  }
}

// MARK: - Hashable

extension LocalJournalEntry: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: - CustomStringConvertible

extension LocalJournalEntry: CustomStringConvertible {
  var description: String {
    "LocalJournalEntry(id: \(id.uuidString.prefix(8))..., curriculum: \(curriculumID), sync: \(syncStatus))"
  }
}
