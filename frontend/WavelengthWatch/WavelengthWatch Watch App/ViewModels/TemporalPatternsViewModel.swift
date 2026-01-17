import Foundation

/// View model for temporal patterns analytics screen.
///
/// Fetches and manages temporal patterns analytics data with offline-first support.
/// Uses backend API when cloud sync is enabled, falls back to local calculator
/// when backend fails, or uses local calculator exclusively when cloud sync
/// is disabled.
///
/// ## Data Strategy
/// - Cloud sync enabled: Try backend first, fall back to local on error
/// - Cloud sync disabled: Use local calculator exclusively
/// - Requires local calculator and journal repository for offline support
@MainActor
final class TemporalPatternsViewModel: ObservableObject {
  enum LoadingState: Equatable {
    case idle
    case loading
    case loaded(TemporalPatterns)
    case error(String)
  }

  @Published var state: LoadingState = .idle

  // MARK: - Computed Properties

  var hourlyDistribution: [HourlyDistributionItem] {
    guard case let .loaded(patterns) = state else {
      return []
    }
    return patterns.hourlyDistribution
  }

  var consistencyScore: Double {
    guard case let .loaded(patterns) = state else {
      return 0.0
    }
    return patterns.consistencyScore
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

  /// Loads temporal patterns analytics data.
  ///
  /// Strategy depends on cloud sync setting:
  /// - Cloud sync enabled: Try backend first, fall back to local on error
  /// - Cloud sync disabled: Use local calculator exclusively
  ///
  /// - Parameters:
  ///   - startDate: Start of the date range for analysis
  ///   - endDate: End of the date range for analysis
  func loadTemporalPatterns(startDate: Date, endDate: Date) async {
    state = .loading

    if syncSettings.cloudSyncEnabled {
      await loadWithBackendFallback(startDate: startDate, endDate: endDate)
    } else {
      await loadFromLocalOnly(startDate: startDate, endDate: endDate)
    }
  }

  /// Retries loading temporal patterns analytics after an error.
  ///
  /// - Parameters:
  ///   - startDate: Start of the date range for analysis
  ///   - endDate: End of the date range for analysis
  func retry(startDate: Date, endDate: Date) async {
    await loadTemporalPatterns(startDate: startDate, endDate: endDate)
  }

  // MARK: - Private Methods

  /// Loads from backend with fallback to local calculator.
  private func loadWithBackendFallback(startDate: Date, endDate: Date) async {
    do {
      let patterns = try await analyticsService.getTemporalPatterns(
        userId: userId,
        startDate: startDate,
        endDate: endDate
      )
      state = .loaded(patterns)
    } catch {
      // Try local fallback if available
      if let localPatterns = tryLocalCalculation(startDate: startDate, endDate: endDate) {
        state = .loaded(localPatterns)
      } else {
        state = .error("Failed to load temporal patterns: \(error.localizedDescription)")
      }
    }
  }

  /// Loads exclusively from local calculator.
  private func loadFromLocalOnly(startDate: Date, endDate: Date) async {
    if let localPatterns = tryLocalCalculation(startDate: startDate, endDate: endDate) {
      state = .loaded(localPatterns)
    } else {
      state = .error("Local analytics not available. Please enable cloud sync or try again later.")
    }
  }

  /// Attempts to calculate temporal patterns from local storage.
  ///
  /// - Parameters:
  ///   - startDate: Start of the date range for analysis
  ///   - endDate: End of the date range for analysis
  /// - Returns: Locally calculated temporal patterns if components available, nil otherwise
  private func tryLocalCalculation(startDate: Date, endDate: Date) -> TemporalPatterns? {
    guard
      let calculator = localCalculator,
      let repository = journalRepository
    else {
      return nil
    }

    do {
      let entries = try repository.fetchAll()
      return calculator.calculateTemporalPatterns(
        entries: entries,
        startDate: startDate,
        endDate: endDate
      )
    } catch {
      print("Local temporal patterns calculation failed: \(error.localizedDescription)")
      return nil
    }
  }
}
