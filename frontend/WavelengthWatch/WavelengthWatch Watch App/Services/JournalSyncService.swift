import Combine
import Foundation

/// Sync status for journal sync operations.
enum JournalSyncStatus: Equatable {
  /// No sync operation in progress.
  case idle

  /// Sync operation in progress with progress percentage.
  case syncing(progress: Double)

  /// Sync completed successfully with count of entries synced.
  case success(syncedCount: Int)

  /// Sync failed with error.
  case error(Error)

  static func == (lhs: JournalSyncStatus, rhs: JournalSyncStatus) -> Bool {
    switch (lhs, rhs) {
    case (.idle, .idle):
      true
    case let (.syncing(p1), .syncing(p2)):
      p1 == p2
    case let (.success(c1), .success(c2)):
      c1 == c2
    case (.error, .error):
      true
    default:
      false
    }
  }
}

/// Service for syncing local journal entries to the backend.
///
/// This service orchestrates background synchronization of journal entries
/// from the local queue to the backend API. It handles:
/// - Network connectivity checks
/// - Retry logic with maximum retry limits
/// - Concurrent sync prevention
/// - Auto-sync on network restoration
/// - Progress tracking and status updates
///
/// ## Usage
/// ```swift
/// let service = JournalSyncService(
///   queue: journalQueue,
///   apiClient: apiClient,
///   networkMonitor: networkMonitor
/// )
///
/// // Manual sync
/// try await service.sync()
///
/// // Enable auto-sync
/// service.startAutoSync()
/// ```
@MainActor
final class JournalSyncService: ObservableObject {
  // MARK: - Published Properties

  /// Whether a sync operation is currently in progress.
  @Published private(set) var isSyncing: Bool = false

  /// Timestamp of the last sync attempt.
  @Published private(set) var lastSyncAttempt: Date?

  /// Current sync status.
  @Published private(set) var syncStatus: JournalSyncStatus = .idle

  // MARK: - Private Properties

  /// Journal queue for accessing pending entries.
  private let queue: JournalQueueProtocol

  /// API client for posting entries to backend.
  private let apiClient: APIClientProtocol

  /// Network monitor for connectivity checks.
  private let networkMonitor: any NetworkMonitorProtocol

  /// Maximum number of retry attempts before giving up.
  private let maxRetries: Int

  /// Subscription for auto-sync on network changes.
  private var autoSyncCancellable: AnyCancellable?

  // MARK: - Initialization

  /// Creates a JournalSyncService with the specified dependencies.
  ///
  /// - Parameters:
  ///   - queue: Journal queue for accessing pending entries
  ///   - apiClient: API client for backend communication
  ///   - networkMonitor: Monitor for network connectivity
  ///   - maxRetries: Maximum retry attempts (default: 3)
  init(
    queue: JournalQueueProtocol,
    apiClient: APIClientProtocol,
    networkMonitor: any NetworkMonitorProtocol,
    maxRetries: Int = 3
  ) {
    self.queue = queue
    self.apiClient = apiClient
    self.networkMonitor = networkMonitor
    self.maxRetries = maxRetries
  }

  // MARK: - Public Methods

  /// Syncs pending journal entries to the backend.
  ///
  /// This method:
  /// 1. Checks network connectivity
  /// 2. Fetches pending entries from queue
  /// 3. Filters out entries exceeding max retries
  /// 4. Posts each entry to the backend
  /// 5. Updates queue status based on results
  ///
  /// - Throws: Errors from queue operations or network requests
  func sync() async throws {
    // Prevent concurrent syncs
    guard !isSyncing else {
      return
    }

    // Check network connectivity
    guard networkMonitor.isConnected else {
      syncStatus = .idle
      return
    }

    isSyncing = true
    lastSyncAttempt = Date()
    defer { isSyncing = false }

    do {
      // Fetch pending entries from queue
      let pending = try queue.pendingEntries()

      // Filter out entries that have exceeded max retries. Use the queue
      // item's persisted `retryCount`, not `localEntry.retryCount` — the
      // latter is the JSON snapshot from when the entry was first enqueued
      // and stays at zero forever, so reading it would silently bypass the
      // retry cap.
      let syncableEntries = pending.filter { $0.retryCount < maxRetries }

      guard !syncableEntries.isEmpty else {
        syncStatus = .success(syncedCount: 0)
        return
      }

      var syncedCount = 0
      var lastError: Error?

      // Sync each entry (continue even if some fail)
      for (index, item) in syncableEntries.enumerated() {
        // Update progress (reaches 1.0 at completion)
        let progress = Double(index + 1) / Double(syncableEntries.count)
        syncStatus = .syncing(progress: progress)

        do {
          // Mark as syncing in queue
          try queue.markSyncing(id: item.id)

          // Create payload from local entry
          let payload = JournalPayload(
            createdAt: item.localEntry.createdAt,
            userID: item.localEntry.userID,
            curriculumID: item.localEntry.curriculumID,
            secondaryCurriculumID: item.localEntry.secondaryCurriculumID,
            strategyID: item.localEntry.strategyID,
            initiatedBy: item.localEntry.initiatedBy,
            entryType: item.localEntry.entryType
          )

          // Post to backend with idempotency key derived from the entry's
          // local UUID. Reusing the key across retry attempts lets the
          // backend deduplicate replayed submissions.
          let _: JournalResponseModel = try await apiClient.post(
            APIPath.journal,
            body: payload,
            headers: [JournalRequestHeader.idempotencyKey: item.localEntry.id.uuidString]
          )

          // Mark as synced in queue
          try queue.markSynced(id: item.id)
          syncedCount += 1
        } catch {
          // Mark as failed in queue (don't let this replace original error)
          do {
            try queue.markFailed(id: item.id, error: error)
          } catch {
            // Queue error - log but don't replace sync error
            print("Failed to mark entry as failed: \(error)")
          }
          lastError = error
          // Continue with next entry instead of throwing
        }
      }

      // Set final status based on results
      if let lastError, syncedCount == 0 {
        // All entries failed
        syncStatus = .error(lastError)
        throw lastError
      } else {
        // Some or all succeeded
        syncStatus = .success(syncedCount: syncedCount)
      }
    } catch {
      syncStatus = .error(error)
      throw error
    }
  }

  /// Starts auto-sync when network becomes available.
  ///
  /// Subscribes to network connectivity changes and automatically triggers
  /// sync when the device connects to a network.
  func startAutoSync() {
    autoSyncCancellable = networkMonitor.isConnectedPublisher
      .removeDuplicates()
      .sink { [weak self] isConnected in
        guard let self else { return }

        Task { @MainActor in
          if isConnected, !self.isSyncing {
            do {
              try await self.sync()
            } catch {
              print("Auto-sync failed: \(error)")
            }
          }
        }
      }
  }

  /// Stops auto-sync.
  ///
  /// Cancels the network monitoring subscription.
  func stopAutoSync() {
    autoSyncCancellable?.cancel()
    autoSyncCancellable = nil
  }
}
