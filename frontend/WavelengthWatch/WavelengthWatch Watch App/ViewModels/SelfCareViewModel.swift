import Foundation

/// View model for self-care analytics screen.
///
/// Fetches and manages self-care analytics data with offline-first support.
/// Uses backend API when cloud sync is enabled, falls back to local calculator
/// when backend fails, or uses local calculator exclusively when cloud sync
/// is disabled.
///
/// ## Data Strategy
/// - Cloud sync enabled: Try backend first, fall back to local on error
/// - Cloud sync disabled: Use local calculator exclusively
/// - Requires local calculator and journal repository for offline support
@MainActor
final class SelfCareViewModel: ObservableObject {
  enum LoadingState: Equatable {
    case idle
    case loading
    case loaded(SelfCareAnalytics)
    case error(String)
  }

  @Published var state: LoadingState = .idle

  // MARK: - Computed Properties

  var topStrategies: [TopStrategyItem] {
    guard case let .loaded(selfCare) = state else {
      return []
    }
    return selfCare.topStrategies
  }

  var diversityScore: Double {
    guard case let .loaded(selfCare) = state else {
      return 0.0
    }
    return selfCare.diversityScore
  }

  var totalStrategyEntries: Int {
    guard case let .loaded(selfCare) = state else {
      return 0
    }
    return selfCare.totalStrategyEntries
  }

  // MARK: - Dependencies

  private let analyticsService: AnalyticsServiceProtocol
  private let localCalculator: LocalAnalyticsCalculatorProtocol?
  private let journalRepository: JournalRepositoryProtocol?
  private let syncSettings: SyncSettings
  private let userId: Int

  // MARK: - Initialization

  init(
    analyticsService: AnalyticsServiceProtocol,
    localCalculator: LocalAnalyticsCalculatorProtocol? = nil,
    journalRepository: JournalRepositoryProtocol? = nil,
    syncSettings: SyncSettings = SyncSettings(),
    userId: Int = 0
  ) {
    self.analyticsService = analyticsService
    self.localCalculator = localCalculator
    self.journalRepository = journalRepository
    self.syncSettings = syncSettings
    self.userId = userId
  }

  // MARK: - Public Methods

  /// Loads self-care analytics data.
  ///
  /// Strategy depends on cloud sync setting:
  /// - Cloud sync enabled: Try backend first, fall back to local on error
  /// - Cloud sync disabled: Use local calculator exclusively
  ///
  /// - Parameter limit: Maximum number of top strategies to return
  func loadSelfCare(limit: Int) async {
    state = .loading

    if syncSettings.cloudSyncEnabled {
      await loadWithBackendFallback(limit: limit)
    } else {
      await loadFromLocalOnly(limit: limit)
    }
  }

  /// Retries loading self-care analytics after an error.
  ///
  /// - Parameter limit: Maximum number of top strategies to return
  func retry(limit: Int) async {
    await loadSelfCare(limit: limit)
  }

  // MARK: - Private Methods

  /// Loads from backend with fallback to local calculator.
  private func loadWithBackendFallback(limit: Int) async {
    do {
      let selfCare = try await analyticsService.getSelfCare(userId: userId, limit: limit)
      state = .loaded(selfCare)
    } catch {
      // Try local fallback if available
      if let localSelfCare = tryLocalCalculation(limit: limit) {
        state = .loaded(localSelfCare)
      } else {
        state = .error("Failed to load self-care analytics: \(error.localizedDescription)")
      }
    }
  }

  /// Loads exclusively from local calculator.
  private func loadFromLocalOnly(limit: Int) async {
    if let localSelfCare = tryLocalCalculation(limit: limit) {
      state = .loaded(localSelfCare)
    } else {
      state = .error("Local analytics not available. Please enable cloud sync or try again later.")
    }
  }

  /// Attempts to calculate self-care analytics from local storage.
  ///
  /// - Parameter limit: Maximum number of top strategies to return
  /// - Returns: Locally calculated self-care analytics if components available, nil otherwise
  private func tryLocalCalculation(limit: Int) -> SelfCareAnalytics? {
    guard
      let calculator = localCalculator,
      let repository = journalRepository
    else {
      return nil
    }

    do {
      let entries = try repository.fetchAll()
      return calculator.calculateSelfCare(entries: entries, limit: limit)
    } catch {
      print("Local self-care calculation failed: \(error.localizedDescription)")
      return nil
    }
  }
}
