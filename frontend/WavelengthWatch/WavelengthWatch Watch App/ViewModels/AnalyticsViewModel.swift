import Foundation

/// View model for analytics overview screen.
///
/// Fetches and manages analytics data from the backend, handling loading
/// states, errors, and empty data scenarios.
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
  private let userDefaults: UserDefaults
  private let userDefaultsKey = "com.wavelengthwatch.userIdentifier"

  init(
    analyticsService: AnalyticsServiceProtocol,
    userDefaults: UserDefaults = .standard
  ) {
    self.analyticsService = analyticsService
    self.userDefaults = userDefaults
  }

  /// Fetches analytics overview data from the backend.
  func loadAnalytics() async {
    state = .loading

    do {
      let userId = numericUserIdentifier()
      let overview = try await analyticsService.getOverview(userId: userId)
      state = .loaded(overview)
    } catch {
      state = .error("Failed to load analytics: \(error.localizedDescription)")
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
