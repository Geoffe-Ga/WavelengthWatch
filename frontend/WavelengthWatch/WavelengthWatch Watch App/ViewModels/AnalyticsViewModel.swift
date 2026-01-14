import Foundation

/// View model for analytics overview screen.
///
/// Fetches and manages analytics data from the backend with local fallback,
/// handling loading states, errors, and empty data scenarios.
///
/// ## Data Strategy
/// - Tries backend first for fresh data
/// - Falls back to local calculation if backend fails
/// - Requires local calculator, journal repository, and catalog for offline support
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
  private let userDefaults: UserDefaults
  private let userDefaultsKey = "com.wavelengthwatch.userIdentifier"

  init(
    analyticsService: AnalyticsServiceProtocol,
    localCalculator: LocalAnalyticsCalculatorProtocol? = nil,
    journalRepository: JournalRepositoryProtocol? = nil,
    catalogRepository: CatalogRepositoryProtocol? = nil,
    userDefaults: UserDefaults = .standard
  ) {
    self.analyticsService = analyticsService
    self.localCalculator = localCalculator
    self.journalRepository = journalRepository
    self.catalogRepository = catalogRepository
    self.userDefaults = userDefaults
  }

  /// Fetches analytics overview data from backend with local fallback.
  ///
  /// Strategy:
  /// 1. Try backend first for fresh data
  /// 2. If backend fails and local components available, calculate from local storage
  /// 3. If both fail, report error
  func loadAnalytics() async {
    state = .loading

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
