import Foundation

/// View model for growth indicators analytics screen.
///
/// Fetches and manages growth indicators analytics data with offline-first support.
/// Uses backend API when cloud sync is enabled, falls back to local calculator
/// when backend fails, or uses local calculator exclusively when cloud sync
/// is disabled.
///
/// ## Data Strategy
/// - Cloud sync enabled: Try backend first, fall back to local on error
/// - Cloud sync disabled: Use local calculator exclusively
/// - Requires local calculator and journal repository for offline support
@MainActor
final class GrowthIndicatorsViewModel: ObservableObject {
  enum LoadingState: Equatable {
    case idle
    case loading
    case loaded(GrowthIndicators)
    case error(String)
  }

  @Published var state: LoadingState = .idle

  // MARK: - Computed Properties

  var medicinalTrend: Double {
    guard case let .loaded(indicators) = state else {
      return 0.0
    }
    return indicators.medicinalTrend
  }

  var layerDiversity: Int {
    guard case let .loaded(indicators) = state else {
      return 0
    }
    return indicators.layerDiversity
  }

  var phaseCoverage: Int {
    guard case let .loaded(indicators) = state else {
      return 0
    }
    return indicators.phaseCoverage
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

  /// Loads growth indicators analytics data.
  ///
  /// Strategy depends on cloud sync setting:
  /// - Cloud sync enabled: Try backend first, fall back to local on error
  /// - Cloud sync disabled: Use local calculator exclusively
  ///
  /// - Parameters:
  ///   - startDate: Start of the date range for analysis
  ///   - endDate: End of the date range for analysis
  func loadGrowthIndicators(startDate: Date, endDate: Date) async {
    state = .loading

    if syncSettings.cloudSyncEnabled {
      await loadWithBackendFallback(startDate: startDate, endDate: endDate)
    } else {
      await loadFromLocalOnly(startDate: startDate, endDate: endDate)
    }
  }

  /// Retries loading growth indicators analytics after an error.
  ///
  /// - Parameters:
  ///   - startDate: Start of the date range for analysis
  ///   - endDate: End of the date range for analysis
  func retry(startDate: Date, endDate: Date) async {
    await loadGrowthIndicators(startDate: startDate, endDate: endDate)
  }

  // MARK: - Private Methods

  /// Loads from backend with fallback to local calculator.
  private func loadWithBackendFallback(startDate: Date, endDate: Date) async {
    do {
      let indicators = try await analyticsService.getGrowthIndicators(
        userId: userId,
        startDate: startDate,
        endDate: endDate
      )
      state = .loaded(indicators)
    } catch {
      // Try local fallback if available
      if let localIndicators = tryLocalCalculation(startDate: startDate, endDate: endDate) {
        state = .loaded(localIndicators)
      } else {
        state = .error("Failed to load growth indicators: \(error.localizedDescription)")
      }
    }
  }

  /// Loads exclusively from local calculator.
  private func loadFromLocalOnly(startDate: Date, endDate: Date) async {
    if let localIndicators = tryLocalCalculation(startDate: startDate, endDate: endDate) {
      state = .loaded(localIndicators)
    } else {
      state = .error("Local analytics not available. Please enable cloud sync or try again later.")
    }
  }

  /// Attempts to calculate growth indicators from local storage.
  ///
  /// - Parameters:
  ///   - startDate: Start of the date range for analysis
  ///   - endDate: End of the date range for analysis
  /// - Returns: Locally calculated growth indicators if components available, nil otherwise
  private func tryLocalCalculation(startDate: Date, endDate: Date) -> GrowthIndicators? {
    guard
      let calculator = localCalculator,
      let repository = journalRepository
    else {
      return nil
    }

    do {
      let entries = try repository.fetchAll()
      return calculator.calculateGrowthIndicators(
        entries: entries,
        startDate: startDate,
        endDate: endDate
      )
    } catch {
      print("Local growth indicators calculation failed: \(error.localizedDescription)")
      return nil
    }
  }
}
