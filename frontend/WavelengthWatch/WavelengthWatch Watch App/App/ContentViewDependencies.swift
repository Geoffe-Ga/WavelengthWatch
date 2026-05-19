import Foundation

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
  let networkMonitor: NetworkMonitor
  let journalQueue: JournalQueue
  let syncService: JournalSyncService
  let journalClient: JournalClientProtocol
  let journalRepository: JournalRepositoryProtocol
  let catalogRepository: CatalogRepositoryProtocol
  let initialLayer: Int
  let initialPhase: Int

  /// Builds the live dependency graph: real API, on-disk SQLite,
  /// real network monitor. Used by the app's runtime entry point.
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
    let initialLayer = UserDefaults.standard.integer(forKey: "selectedLayerIndex")
    let initialPhase = UserDefaults.standard.integer(forKey: "selectedPhaseIndex")
    let viewModel = ContentViewModel(
      catalogRepository: catalogRepository,
      journalRepository: journalRepository,
      journalClient: journalClient,
      initialLayerIndex: initialLayer,
      initialPhaseIndex: initialPhase
    )
    let flowCoordinator = FlowCoordinator(contentViewModel: viewModel)
    let syncSettingsViewModel = SyncSettingsViewModel(syncSettings: syncSettings)
    return ContentViewDependencies(
      viewModel: viewModel,
      flowCoordinator: flowCoordinator,
      syncSettingsViewModel: syncSettingsViewModel,
      networkMonitor: networkMonitor,
      journalQueue: journalQueue,
      syncService: syncService,
      journalClient: journalClient,
      journalRepository: journalRepository,
      catalogRepository: catalogRepository,
      initialLayer: initialLayer,
      initialPhase: initialPhase
    )
  }

  // MARK: - Repository / queue construction

  /// Opens the on-disk SQLite journal repository, falling back to
  /// in-memory storage if open fails (SwiftUI previews, test harness,
  /// or a corrupted database file). The fallback keeps the app
  /// functional but entries logged in the session don't persist.
  private static func makeJournalRepository() -> JournalRepositoryProtocol {
    let persistentRepo = JournalRepository()
    do {
      try persistentRepo.open()
      return persistentRepo
    } catch {
      print("⚠️ Failed to open journal database: \(error). Falling back to in-memory storage.")
      return InMemoryJournalRepository()
    }
  }

  /// Builds a `JournalQueue` with progressive fallback: documents
  /// directory → `NSTemporaryDirectory` → in-memory SQLite. The
  /// in-memory leg has no filesystem dependency, so it cannot fail in
  /// normal operation; if even that throws, the device is in a state
  /// where no offline persistence is possible and crashing surfaces
  /// the problem rather than silently dropping entries.
  private static func makeJournalQueue() -> JournalQueue {
    do {
      return try JournalQueue()
    } catch {
      print("⚠️ Documents-dir journal queue init failed: \(error). Trying temp dir.")
    }
    let fallbackPath = NSTemporaryDirectory() + "journal_queue_fallback.sqlite"
    do {
      return try JournalQueue(databasePath: fallbackPath)
    } catch {
      print("⚠️ Temp-dir journal queue init failed: \(error). Falling back to in-memory.")
    }
    do {
      return try JournalQueue(databasePath: ":memory:")
    } catch {
      fatalError("In-memory journal queue init failed unexpectedly: \(error)")
    }
  }
}
