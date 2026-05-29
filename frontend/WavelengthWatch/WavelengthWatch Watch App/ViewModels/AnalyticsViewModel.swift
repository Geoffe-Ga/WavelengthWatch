import Foundation

/// View model for the analytics overview screen.
///
/// Chooses its data source based on `SyncSettings.cloudSyncEnabled`
/// (per #187: "analytics read from local SQLite DB — works for both modes"):
/// - **Cloud sync on**: tries backend first, falls back to the local
///   calculator on a thrown error.
/// - **Cloud sync off**: reads exclusively from the local calculator.
///   Hitting the backend in local-only mode would return an empty overview
///   (nothing has been synced for this user), making the screen appear empty.
///
/// Note: `SyncSettings` is read at each `loadAnalytics()` call, not observed.
/// If the user toggles sync while the screen is open, the new mode applies on
/// the next load/retry.
@MainActor
final class AnalyticsViewModel: ObservableObject {
  enum LoadingState: Equatable {
    case idle
    case loading
    case loaded(AnalyticsOverview)
    case error(String)
  }

  @Published private(set) var state: LoadingState = .idle

  private let analyticsService: AnalyticsServiceProtocol
  private let localCalculator: LocalAnalyticsCalculatorProtocol?
  private let journalRepository: JournalRepositoryProtocol?
  private let catalogRepository: CatalogRepositoryProtocol?
  private let syncSettings: SyncSettings
  private let userDefaults: UserDefaults
  private let userDefaultsKey = "com.wavelengthwatch.userIdentifier"

  init(
    analyticsService: AnalyticsServiceProtocol,
    localCalculator: LocalAnalyticsCalculatorProtocol? = nil,
    journalRepository: JournalRepositoryProtocol? = nil,
    catalogRepository: CatalogRepositoryProtocol? = nil,
    syncSettings: SyncSettings = SyncSettings(),
    userDefaults: UserDefaults = .standard
  ) {
    self.analyticsService = analyticsService
    self.localCalculator = localCalculator
    self.journalRepository = journalRepository
    self.catalogRepository = catalogRepository
    self.syncSettings = syncSettings
    self.userDefaults = userDefaults
  }

  /// Loads analytics overview, choosing the data source by the user's sync
  /// preference (per #187: "analytics read from local SQLite DB — works for
  /// both modes").
  ///
  /// - Cloud sync **enabled**: try backend first, fall back to local on error.
  /// - Cloud sync **disabled**: use the local calculator exclusively. Hitting
  ///   the backend in local-only mode would return zero entries for this user
  ///   (sync is off, nothing's there), making the screen appear empty even
  ///   though local SQLite has the user's data.
  func loadAnalytics() async {
    state = .loading

    if syncSettings.cloudSyncEnabled {
      await loadWithBackendFallback()
    } else {
      await loadFromLocalOnly()
    }
  }

  /// Loads from backend with fallback to local calculator on backend error.
  private func loadWithBackendFallback() async {
    do {
      let userId = numericUserIdentifier()
      let overview = try await analyticsService.getOverview(userId: userId)
      state = .loaded(overview)
    } catch {
      // Try local fallback if available
      if let localOverview = await tryLocalCalculation() {
        state = .loaded(localOverview)
      } else {
        state = .error("Failed to load analytics: \(error.localizedDescription)")
      }
    }
  }

  /// Loads exclusively from the local calculator (cloud sync disabled mode).
  private func loadFromLocalOnly() async {
    if let localOverview = await tryLocalCalculation() {
      state = .loaded(localOverview)
    } else {
      // Reached only when the view is constructed without local components
      // (a wiring bug, not user-facing). Avoid telling a user who deliberately
      // disabled cloud sync to "enable cloud sync".
      state = .error("Analytics are temporarily unavailable. Please try again later.")
    }
  }

  /// Attempts to calculate analytics from local storage.
  ///
  /// - Returns: Locally calculated overview if all components available, nil otherwise
  private func tryLocalCalculation() async -> AnalyticsOverview? {
    guard
      let calculator = localCalculator,
      let repository = journalRepository,
      let catalogRepo = catalogRepository,
      let catalog = catalogRepo.cachedCatalog()
    else {
      return nil
    }

    do {
      let entries = try repository.fetchAll()
      let endDate = Date()
      let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate

      return calculator.calculateOverview(
        entries: entries,
        startDate: startDate,
        endDate: endDate
      )
    } catch {
      print("⚠️ Local analytics calculation failed: \(error.localizedDescription)")
      return nil
    }
  }

  /// Retries loading analytics after an error.
  func retry() async {
    await loadAnalytics()
  }

  // MARK: - Private Helpers

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
}
