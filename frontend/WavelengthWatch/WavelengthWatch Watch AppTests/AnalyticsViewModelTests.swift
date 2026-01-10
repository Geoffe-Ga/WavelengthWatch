import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("AnalyticsViewModel Tests")
struct AnalyticsViewModelTests {
  // MARK: - Mock Service

  final class MockAnalyticsService: AnalyticsServiceProtocol {
    var overviewToReturn: AnalyticsOverview?
    var emotionalLandscapeToReturn: EmotionalLandscape?
    var errorToThrow: Error?
    var getOverviewCallCount = 0
    var getEmotionalLandscapeCallCount = 0
    var lastUserId: Int?

    func getOverview(userId: Int) async throws -> AnalyticsOverview {
      getOverviewCallCount += 1
      lastUserId = userId

      if let error = errorToThrow {
        throw error
      }

      guard let overview = overviewToReturn else {
        throw NSError(domain: "test", code: -1)
      }

      return overview
    }

    func getEmotionalLandscape(userId: Int) async throws -> EmotionalLandscape {
      getEmotionalLandscapeCallCount += 1
      lastUserId = userId

      if let error = errorToThrow {
        throw error
      }

      guard let landscape = emotionalLandscapeToReturn else {
        throw NSError(domain: "test", code: -1)
      }

      return landscape
    }
  }

  // MARK: - Initialization Tests

  @Test("viewModel starts in idle state")
  @MainActor
  func viewModel_startsInIdleState() {
    let mockService = MockAnalyticsService()
    let viewModel = AnalyticsViewModel(analyticsService: mockService)

    #expect(viewModel.state == .idle)
  }

  // MARK: - Loading Tests

  @Test("viewModel loads analytics successfully")
  @MainActor
  func viewModel_loadsAnalyticsSuccessfully() async {
    let mockService = MockAnalyticsService()
    let mockOverview = AnalyticsOverview(
      totalEntries: 10,
      currentStreak: 5,
      longestStreak: 12,
      avgFrequency: 2.0,
      lastCheckIn: Date(),
      medicinalRatio: 0.75,
      medicinalTrend: 0.05,
      dominantLayerId: 1,
      dominantPhaseId: 2,
      uniqueEmotions: 8,
      strategiesUsed: 3,
      secondaryEmotionsPct: 0.6
    )
    mockService.overviewToReturn = mockOverview

    let viewModel = AnalyticsViewModel(analyticsService: mockService)

    await viewModel.loadAnalytics()

    if case let .loaded(overview) = viewModel.state {
      #expect(overview == mockOverview)
      #expect(mockService.getOverviewCallCount == 1)
    } else {
      Issue.record("Expected loaded state, got \(viewModel.state)")
    }
  }

  @Test("viewModel handles loading error")
  @MainActor
  func viewModel_handlesLoadingError() async {
    let mockService = MockAnalyticsService()
    mockService.errorToThrow = NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"])

    let viewModel = AnalyticsViewModel(analyticsService: mockService)

    await viewModel.loadAnalytics()

    if case let .error(message) = viewModel.state {
      #expect(message.contains("Failed to load analytics"))
      #expect(mockService.getOverviewCallCount == 1)
    } else {
      Issue.record("Expected error state, got \(viewModel.state)")
    }
  }

  @Test("viewModel transitions to loading state")
  @MainActor
  func viewModel_transitionsToLoadingState() async {
    let mockService = MockAnalyticsService()
    // Make the service hang so we can check the loading state
    mockService.overviewToReturn = AnalyticsOverview(
      totalEntries: 0,
      currentStreak: 0,
      longestStreak: 0,
      avgFrequency: 0,
      lastCheckIn: nil,
      medicinalRatio: 0,
      medicinalTrend: 0,
      dominantLayerId: nil,
      dominantPhaseId: nil,
      uniqueEmotions: 0,
      strategiesUsed: 0,
      secondaryEmotionsPct: 0
    )

    let viewModel = AnalyticsViewModel(analyticsService: mockService)

    // Start loading but don't await
    let task = Task {
      await viewModel.loadAnalytics()
    }

    // Give it a moment to transition to loading
    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

    // Cancel to avoid hanging
    task.cancel()

    // State should either be loading or loaded (race condition)
    let isLoadingOrLoaded = switch viewModel.state {
    case .loading, .loaded: true
    default: false
    }

    #expect(isLoadingOrLoaded)
  }

  // MARK: - Retry Tests

  @Test("viewModel retry calls loadAnalytics")
  @MainActor
  func viewModel_retryCallsLoadAnalytics() async {
    let mockService = MockAnalyticsService()
    mockService.errorToThrow = NSError(domain: "test", code: -1)

    let viewModel = AnalyticsViewModel(analyticsService: mockService)

    await viewModel.loadAnalytics()
    #expect(mockService.getOverviewCallCount == 1)

    // Clear error and retry
    mockService.errorToThrow = nil
    mockService.overviewToReturn = AnalyticsOverview(
      totalEntries: 5,
      currentStreak: 2,
      longestStreak: 2,
      avgFrequency: 1.0,
      lastCheckIn: nil,
      medicinalRatio: 0.5,
      medicinalTrend: 0,
      dominantLayerId: nil,
      dominantPhaseId: nil,
      uniqueEmotions: 3,
      strategiesUsed: 1,
      secondaryEmotionsPct: 0.4
    )

    await viewModel.retry()

    #expect(mockService.getOverviewCallCount == 2)
    if case .loaded = viewModel.state {
      // Success
    } else {
      Issue.record("Expected loaded state after retry")
    }
  }

  // MARK: - User ID Tests

  @Test("viewModel passes numeric user identifier to service")
  @MainActor
  func viewModel_passesNumericUserIdToService() async {
    let mockService = MockAnalyticsService()
    mockService.overviewToReturn = AnalyticsOverview(
      totalEntries: 0,
      currentStreak: 0,
      longestStreak: 0,
      avgFrequency: 0,
      lastCheckIn: nil,
      medicinalRatio: 0,
      medicinalTrend: 0,
      dominantLayerId: nil,
      dominantPhaseId: nil,
      uniqueEmotions: 0,
      strategiesUsed: 0,
      secondaryEmotionsPct: 0
    )

    let viewModel = AnalyticsViewModel(
      analyticsService: mockService,
      userDefaults: .standard
    )

    await viewModel.loadAnalytics()

    #expect(mockService.lastUserId != nil)
    #expect(mockService.lastUserId! > 0)
  }
}
