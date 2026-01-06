import Foundation

enum InitiatedBy: String, Codable {
  case self_initiated = "self"
  case scheduled
}

struct JournalResponseModel: Codable, Equatable {
  let id: Int
  let curriculumID: Int
  let secondaryCurriculumID: Int?
  let strategyID: Int?
  let initiatedBy: InitiatedBy

  enum CodingKeys: String, CodingKey {
    case id
    case curriculumID = "curriculum_id"
    case secondaryCurriculumID = "secondary_curriculum_id"
    case strategyID = "strategy_id"
    case initiatedBy = "initiated_by"
  }
}

struct JournalPayload: Codable {
  let createdAt: Date
  let userID: Int
  let curriculumID: Int
  let secondaryCurriculumID: Int?
  let strategyID: Int?
  let initiatedBy: InitiatedBy

  enum CodingKeys: String, CodingKey {
    case createdAt = "created_at"
    case userID = "user_id"
    case curriculumID = "curriculum_id"
    case secondaryCurriculumID = "secondary_curriculum_id"
    case strategyID = "strategy_id"
    case initiatedBy = "initiated_by"
  }
}

protocol JournalClientProtocol {
  @discardableResult
  func submit(
    curriculumID: Int,
    secondaryCurriculumID: Int?,
    strategyID: Int?,
    initiatedBy: InitiatedBy
  ) async throws -> LocalJournalEntry
}

/// Journal client with local-first architecture.
///
/// This client saves all journal entries to local SQLite storage first,
/// then optionally syncs to the backend server if cloud sync is enabled.
///
/// ## Local-First Behavior
/// 1. Creates LocalJournalEntry and saves to repository (always)
/// 2. If cloudSyncEnabled, attempts backend sync
/// 3. Updates local entry with sync status and server ID
/// 4. Returns the local entry (with or without successful sync)
///
/// ## Offline Support
/// Entries are always saved locally, even when offline or sync fails.
/// Background sync can retry pending/failed entries later.
final class JournalClient: JournalClientProtocol {
  private let apiClient: APIClientProtocol
  private let repository: JournalRepositoryProtocol
  private let syncSettings: SyncSettings
  private let dateProvider: () -> Date
  private let userDefaults: UserDefaults
  private let userDefaultsKey = "com.wavelengthwatch.userIdentifier"

  init(
    apiClient: APIClientProtocol,
    repository: JournalRepositoryProtocol,
    syncSettings: SyncSettings,
    dateProvider: @escaping () -> Date = Date.init,
    userDefaults: UserDefaults = .standard
  ) {
    self.apiClient = apiClient
    self.repository = repository
    self.syncSettings = syncSettings
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
    // 1. Create local entry with pending sync status
    var entry = LocalJournalEntry(
      createdAt: dateProvider(),
      userID: numericUserIdentifier(),
      curriculumID: curriculumID,
      secondaryCurriculumID: secondaryCurriculumID,
      strategyID: strategyID,
      initiatedBy: initiatedBy
    )

    // 2. Save to local repository first (always)
    try repository.save(entry)

    // 3. Attempt backend sync if enabled
    if syncSettings.cloudSyncEnabled {
      do {
        let payload = JournalPayload(
          createdAt: entry.createdAt,
          userID: entry.userID,
          curriculumID: entry.curriculumID,
          secondaryCurriculumID: entry.secondaryCurriculumID,
          strategyID: entry.strategyID,
          initiatedBy: entry.initiatedBy
        )

        let response: JournalResponseModel = try await apiClient.post(APIPath.journal, body: payload)

        // Update entry with server ID and synced status
        entry = LocalJournalEntry.synced(from: response, localEntry: entry)
        try repository.update(entry)
      } catch {
        // Sync failed - mark as failed for retry
        print("⚠️ Journal sync failed for entry \(entry.id): \(error). Entry saved locally with failed sync status.")
        entry.syncStatus = .failed
        entry.lastSyncAttempt = dateProvider()
        try repository.update(entry)

        // Don't throw - entry is still saved locally
        // TODO: Consider adding user-visible feedback (notification badge or status indicator)
      }
    }

    return entry
  }
}
