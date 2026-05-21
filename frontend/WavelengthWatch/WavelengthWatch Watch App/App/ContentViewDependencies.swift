import Foundation
import os

/// Bundle of everything `ContentView` needs to wire up its root view
/// hierarchy: the live API client, repositories, queue, journal client,
/// sync service, content view-model, flow coordinator, and the
/// AppStorage-backed initial layer / phase selections.
///
/// Lives outside `ContentView` so the dependency-construction logic
/// (which has progressive fallback paths for SQLite open failures and
/// the offline journal queue) doesn't dominate the view's `init`. The
/// view then just unpacks the bundle into its `@StateObject` /
/// `@State` wrappers.
///
/// Marked `@MainActor` because the constructed types (`NetworkMonitor`,
/// `JournalClient`, `JournalSyncService`, `FlowCoordinator`,
/// `SyncSettingsViewModel`, `JournalQueue`) are themselves main-actor
/// isolated under Swift 6; building them from a nonisolated context
/// would be a data-race error. `ContentView.init` is `@MainActor` so
/// callers naturally satisfy the requirement.
@MainActor
struct ContentViewDependencies {
  let viewModel: ContentViewModel
  let flowCoordinator: FlowCoordinator
  let syncSettingsViewModel: SyncSettingsViewModel
  /// Shared sync-preferences store backing both `journalClient` and
  /// `syncSettingsViewModel`. Exposed on the bundle so a test config can
  /// inject a known state without reconstructing the whole graph.
  let syncSettings: SyncSettings
  let networkMonitor: NetworkMonitor
  let journalQueue: JournalQueue
  let syncService: JournalSyncService
  let journalClient: JournalClientProtocol
  let journalRepository: JournalRepositoryProtocol
  let catalogRepository: CatalogRepositoryProtocol
  /// Owns the dual-axis navigation selection and its reconciliation with
  /// `viewModel`; `ContentView` holds it as its single navigation state.
  let navigationViewModel: NavigationViewModel

  private static let logger = Logger(
    subsystem: "com.wavelengthwatch.watch",
    category: "ContentViewDependencies"
  )

  /// Filesystem path for the temp-directory journal-queue fallback,
  /// composed via `URL` so it stays correct even if `NSTemporaryDirectory`
  /// ever stops returning a trailing-slash path.
  static let tempJournalQueueFallbackPath = URL(
    fileURLWithPath: NSTemporaryDirectory(),
    isDirectory: true
  )
  .appendingPathComponent("journal_queue_fallback.sqlite")
  .path

  /// Builds the live dependency graph: real API, on-disk SQLite,
  /// real network monitor. Used by the app's runtime entry point.
  @MainActor
  static func live() -> ContentViewDependencies {
    let configuration = AppConfiguration()
    let apiClient = APIClient(baseURL: configuration.apiBaseURL)
    let catalogRepository = CatalogRepository(
      remote: CatalogAPIService(apiClient: apiClient),
      cache: FileCatalogCacheStore()
    )
    let journalRepository = Self.makeJournalRepository()
    let syncSettings = SyncSettings()
    let journalQueue = Self.makeJournalQueue()
    let networkMonitor = NetworkMonitor()
    let journalClient = JournalClient(
      apiClient: apiClient,
      repository: journalRepository,
      syncSettings: syncSettings,
      queue: journalQueue
    )
    let syncService = JournalSyncService(
      queue: journalQueue,
      apiClient: apiClient,
      networkMonitor: networkMonitor
    )
    let initialLayer = UserDefaults.standard.integer(forKey: AppStorageKeys.selectedLayerIndex)
    let storedPhase = UserDefaults.standard.integer(forKey: AppStorageKeys.selectedPhaseIndex)
    let viewModel = ContentViewModel(
      catalogRepository: catalogRepository,
      journalRepository: journalRepository,
      journalClient: journalClient,
      initialLayerIndex: initialLayer,
      initialPhaseIndex: storedPhase
    )
    let flowCoordinator = FlowCoordinator(contentViewModel: viewModel)
    let syncSettingsViewModel = SyncSettingsViewModel(syncSettings: syncSettings)
    let navigationViewModel = NavigationViewModel(
      contentViewModel: viewModel,
      initialLayer: initialLayer,
      // +1: the infinite-scroll TabView treats index 0 as a "lead-in"
      // page; ContentViewModel holds the canonical zero-indexed phase.
      initialPhaseSelection: storedPhase + 1
    )
    return ContentViewDependencies(
      viewModel: viewModel,
      flowCoordinator: flowCoordinator,
      syncSettingsViewModel: syncSettingsViewModel,
      syncSettings: syncSettings,
      networkMonitor: networkMonitor,
      journalQueue: journalQueue,
      syncService: syncService,
      journalClient: journalClient,
      journalRepository: journalRepository,
      catalogRepository: catalogRepository,
      navigationViewModel: navigationViewModel
    )
  }

  // MARK: - Repository / queue construction

  /// Opens the on-disk SQLite journal repository, falling back to
  /// in-memory storage if open fails (SwiftUI previews, test harness,
  /// or a corrupted database file). The fallback keeps the app
  /// functional but entries logged in the session don't persist.
  ///
  /// `openPersistent` is injectable so the fallback branch can be tested
  /// without a genuinely corrupt database file.
  @MainActor
  static func makeJournalRepository(
    openPersistent: () throws -> JournalRepositoryProtocol = {
      let repository = JournalRepository()
      try repository.open()
      return repository
    }
  ) -> JournalRepositoryProtocol {
    do {
      return try openPersistent()
    } catch {
      logger.warning(
        "Journal database open failed: \(error.localizedDescription, privacy: .public). Falling back to in-memory storage."
      )
      return InMemoryJournalRepository()
    }
  }

  /// Builds a `JournalQueue` with progressive fallback: documents
  /// directory → `NSTemporaryDirectory` → in-memory SQLite. The
  /// in-memory leg has no filesystem dependency, so it cannot fail in
  /// normal operation; if even that throws, the device is in a state
  /// where no offline persistence is possible and crashing surfaces
  /// the problem rather than silently dropping entries.
  ///
  /// The three legs are injectable so the fallthrough order can be
  /// tested without genuinely unwritable directories.
  ///
  /// The closure parameters are `@MainActor` because their default values
  /// construct the main-actor-isolated `JournalQueue`, and default-argument
  /// expressions evaluate outside the enclosing type's actor isolation —
  /// the annotation on the function alone does not reach them.
  @MainActor
  static func makeJournalQueue(
    documentsQueue: @MainActor () throws -> JournalQueue = { try JournalQueue() },
    tempQueue: @MainActor () throws -> JournalQueue = {
      try JournalQueue(databasePath: tempJournalQueueFallbackPath)
    },
    inMemoryQueue: @MainActor () throws -> JournalQueue = {
      try JournalQueue(databasePath: ":memory:")
    }
  ) -> JournalQueue {
    do {
      return try documentsQueue()
    } catch {
      logger.warning(
        "Documents-dir journal queue init failed: \(error.localizedDescription, privacy: .public). Trying temp dir."
      )
    }
    do {
      return try tempQueue()
    } catch {
      logger.warning(
        "Temp-dir journal queue init failed: \(error.localizedDescription, privacy: .public). Falling back to in-memory."
      )
    }
    do {
      return try inMemoryQueue()
    } catch {
      fatalError("In-memory journal queue init failed unexpectedly: \(error)")
    }
  }
}
