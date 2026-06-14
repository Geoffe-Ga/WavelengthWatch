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
  private let syncSettings: SyncSettings
  private let userDefaults: UserDefaults
  private let userDefaultsKey = "com.wavelengthwatch.userIdentifier"

  init(
    analyticsService: AnalyticsServiceProtocol,
    localCalculator: LocalAnalyticsCalculatorProtocol? = nil,
    journalRepository: JournalRepositoryProtocol? = nil,
    syncSettings: SyncSettings = SyncSettings(),
    userDefaults: UserDefaults = .standard
  ) {
    self.analyticsService = analyticsService
    self.localCalculator = localCalculator
    self.journalRepository = journalRepository
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

  /// Why a local analytics calculation couldn't be produced. Surfaced in the
  /// user-facing error so a blind "unavailable" no longer hides the cause (#470).
  private enum LocalCalculationError: Error {
    case noCalculator // no in-memory or cached catalog to build the calculator
    case noRepository // journal storage not wired
    case fetchFailed(String) // reading journal entries threw

    var reason: String {
      switch self {
      case .noCalculator: "no catalog is loaded yet"
      case .noRepository: "journal storage is unavailable"
      case let .fetchFailed(message): "couldn't read journal entries — \(message)"
      }
    }
  }

  /// Loads from backend with fallback to local calculator on backend error.
  private func loadWithBackendFallback() async {
    do {
      let userId = numericUserIdentifier()
      let overview = try await analyticsService.getOverview(userId: userId)
      state = .loaded(overview)
    } catch {
      do {
        state = try .loaded(calculateLocally())
      } catch {
        state = .error(
          "Failed to load analytics: \(error.localizedDescription) "
            + "(local: \(localReason(error)))"
        )
      }
    }
  }

  /// Loads exclusively from the local calculator (cloud sync disabled mode).
  private func loadFromLocalOnly() async {
    do {
      state = try .loaded(calculateLocally())
    } catch {
      state = .error(
        "Analytics are temporarily unavailable. Please try again later. "
          + "(\(localReason(error)))"
      )
    }
  }

  /// Calculates analytics from local storage, throwing a `LocalCalculationError`
  /// that names the failing step so the cause is never silently swallowed.
  private func calculateLocally() throws -> AnalyticsOverview {
    guard let calculator = localCalculator else { throw LocalCalculationError.noCalculator }
    guard let repository = journalRepository else { throw LocalCalculationError.noRepository }

    let entries: [LocalJournalEntry]
    do {
      entries = try repository.fetchAll()
    } catch {
      throw LocalCalculationError.fetchFailed(error.localizedDescription)
    }

    let endDate = Date()
    let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
    return calculator.calculateOverview(
      entries: entries,
      startDate: startDate,
      endDate: endDate
    )
  }

  /// Human-readable reason for a local-calculation failure.
  private func localReason(_ error: Error) -> String {
    (error as? LocalCalculationError)?.reason ?? error.localizedDescription
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
