import Foundation

enum EntryType: String, Codable {
  case emotion
  case rest
}

enum InitiatedBy: String, Codable {
  case self_initiated = "self"
  case scheduled
}

struct JournalResponseModel: Codable, Equatable {
  let id: Int
  let curriculumID: Int?
  let secondaryCurriculumID: Int?
  let strategyID: Int?
  let initiatedBy: InitiatedBy
  let entryType: EntryType

  enum CodingKeys: String, CodingKey {
    case id
    case curriculumID = "curriculum_id"
    case secondaryCurriculumID = "secondary_curriculum_id"
    case strategyID = "strategy_id"
    case initiatedBy = "initiated_by"
    case entryType = "entry_type"
  }
}

struct JournalPayload: Codable {
  let createdAt: Date
  let userID: Int
  let curriculumID: Int?
  let secondaryCurriculumID: Int?
  let strategyID: Int?
  let initiatedBy: InitiatedBy
  let entryType: EntryType

  enum CodingKeys: String, CodingKey {
    case createdAt = "created_at"
    case userID = "user_id"
    case curriculumID = "curriculum_id"
    case secondaryCurriculumID = "secondary_curriculum_id"
    case strategyID = "strategy_id"
    case initiatedBy = "initiated_by"
    case entryType = "entry_type"
  }
}

/// Header name used to send idempotency keys with journal POST requests.
///
/// Matches the backend journal router which reads the `X-Idempotency-Key`
/// header to deduplicate replayed submissions.
enum JournalRequestHeader {
  static let idempotencyKey = "X-Idempotency-Key"
}

/// Errors surfaced by the journal submission flow.
///
/// Distinguishes between transient network failures that have been queued for
/// background retry and permanent failures that the user should be informed of.
enum JournalError: Error, Equatable {
  /// The submission was saved locally and queued for retry once connectivity
  /// returns. The associated UUID identifies the enqueued local entry.
  case queuedForRetry(entryID: UUID)
}

protocol JournalClientProtocol {
  @discardableResult
  func submit(
    curriculumID: Int,
    secondaryCurriculumID: Int?,
    strategyID: Int?,
    initiatedBy: InitiatedBy
  ) async throws -> LocalJournalEntry

  @discardableResult
  func submitRestPeriod(
    initiatedBy: InitiatedBy
  ) async throws -> LocalJournalEntry
}

/// Journal client with local-first architecture and offline queueing.
///
/// This client saves all journal entries to local SQLite storage first,
/// then optionally syncs to the backend server if cloud sync is enabled.
/// When a sync attempt fails with a retryable error (network, 5xx) and a
/// queue is supplied, the entry is enqueued for background retry and the
/// caller receives `JournalError.queuedForRetry` so the UI can present a
/// distinct "saved locally" message.
///
/// ## Local-First Behavior
/// 1. Creates LocalJournalEntry and saves to repository (always)
/// 2. If cloudSyncEnabled, attempts backend sync with an idempotency key
/// 3. Updates local entry with sync status and server ID
/// 4. Returns the local entry (with or without successful sync)
///
/// ## Offline Support
/// Entries are always saved locally, even when offline or sync fails.
/// Retryable failures are enqueued in `JournalQueue` and retried by
/// `JournalSyncService`. Non-retryable failures mark the entry as failed.
///
/// ## Actor Isolation
/// Isolated to `@MainActor` so it can interoperate safely with the
/// `@MainActor`-isolated `JournalQueue` without cross-actor bridging.
@MainActor
final class JournalClient: JournalClientProtocol {
  private let apiClient: APIClientProtocol
  private let repository: JournalRepositoryProtocol
  private let syncSettings: SyncSettings
  private let queue: JournalQueueProtocol?
  private let dateProvider: () -> Date
  private let userDefaults: UserDefaults
  private let userDefaultsKey = "com.wavelengthwatch.userIdentifier"

  init(
    apiClient: APIClientProtocol,
    repository: JournalRepositoryProtocol,
    syncSettings: SyncSettings,
    queue: JournalQueueProtocol? = nil,
    dateProvider: @escaping () -> Date = Date.init,
    userDefaults: UserDefaults = .standard
  ) {
    self.apiClient = apiClient
    self.repository = repository
    self.syncSettings = syncSettings
    self.queue = queue
    self.dateProvider = dateProvider
    self.userDefaults = userDefaults
  }

  private func storedUserIdentifier() -> String {
    if let identifier = userDefaults.string(forKey: userDefaultsKey) {
      return identifier
    }
    let identifier = UUID().uuidString
    userDefaults.set(identifier, forKey: userDefaultsKey)
    return identifier
  }

  private func numericUserIdentifier() -> Int {
    let identifier = storedUserIdentifier().replacingOccurrences(of: "-", with: "")
    let prefix = identifier.prefix(12)
    return Int(prefix, radix: 16) ?? 0
  }

  @discardableResult
  func submit(
    curriculumID: Int,
    secondaryCurriculumID: Int?,
    strategyID: Int?,
    initiatedBy: InitiatedBy = .self_initiated
  ) async throws -> LocalJournalEntry {
    let entry = LocalJournalEntry(
      createdAt: dateProvider(),
      userID: numericUserIdentifier(),
      curriculumID: curriculumID,
      secondaryCurriculumID: secondaryCurriculumID,
      strategyID: strategyID,
      initiatedBy: initiatedBy,
      entryType: .emotion
    )

    let payload = JournalPayload(
      createdAt: entry.createdAt,
      userID: entry.userID,
      curriculumID: entry.curriculumID,
      secondaryCurriculumID: entry.secondaryCurriculumID,
      strategyID: entry.strategyID,
      initiatedBy: entry.initiatedBy,
      entryType: .emotion
    )

    return try await persistAndSync(entry: entry, payload: payload)
  }

  @discardableResult
  func submitRestPeriod(
    initiatedBy: InitiatedBy = .self_initiated
  ) async throws -> LocalJournalEntry {
    let entry = LocalJournalEntry(
      createdAt: dateProvider(),
      userID: numericUserIdentifier(),
      curriculumID: nil,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: initiatedBy,
      entryType: .rest
    )

    let payload = JournalPayload(
      createdAt: entry.createdAt,
      userID: entry.userID,
      curriculumID: nil,
      secondaryCurriculumID: nil,
      strategyID: nil,
      initiatedBy: entry.initiatedBy,
      entryType: .rest
    )

    return try await persistAndSync(entry: entry, payload: payload)
  }

  /// Saves the entry locally and, if cloud sync is enabled, attempts to POST
  /// it to the backend. Handles queueing and error classification.
  private func persistAndSync(
    entry: LocalJournalEntry,
    payload: JournalPayload
  ) async throws -> LocalJournalEntry {
    var entry = entry
    try repository.save(entry)

    guard syncSettings.cloudSyncEnabled else {
      return entry
    }

    let idempotencyKey = entry.id.uuidString
    do {
      let response: JournalResponseModel = try await apiClient.post(
        APIPath.journal,
        body: payload,
        headers: [JournalRequestHeader.idempotencyKey: idempotencyKey]
      )
      entry = LocalJournalEntry.synced(from: response, localEntry: entry)
      try repository.update(entry)
      return entry
    } catch {
      let retryable = isRetryable(error)
      if retryable, let queue {
        entry.lastSyncAttempt = dateProvider()
        try repository.update(entry)
        try queue.enqueue(entry)
        throw JournalError.queuedForRetry(entryID: entry.id)
      }

      print("⚠️ Journal sync failed for entry \(entry.id): \(error). Marking entry as failed.")
      entry.syncStatus = .failed
      entry.lastSyncAttempt = dateProvider()
      try repository.update(entry)

      if retryable {
        // No queue configured — preserve legacy behaviour: keep entry locally
        // without throwing so the user still sees a success-ish experience.
        return entry
      }
      throw error
    }
  }

  /// Classifies an error as retryable (network/server) vs permanent (validation).
  private func isRetryable(_ error: Error) -> Bool {
    if let apiError = error as? APIClientError {
      return apiError.isRetryable
    }
    if error is URLError {
      return true
    }
    return false
  }
}
