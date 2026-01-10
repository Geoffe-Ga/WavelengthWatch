import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("EmotionalLandscapeViewModel Tests")
struct EmotionalLandscapeViewModelTests {
  // MARK: - Mock Service

  final class MockAnalyticsService: AnalyticsServiceProtocol {
    var emotionalLandscapeToReturn: EmotionalLandscape?
    var errorToThrow: Error?
    var getEmotionalLandscapeCallCount = 0

    func getOverview(userId: Int) async throws -> AnalyticsOverview {
      fatalError("Not implemented in this test")
    }

    func getEmotionalLandscape(userId: Int) async throws -> EmotionalLandscape {
      getEmotionalLandscapeCallCount += 1

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
    let viewModel = EmotionalLandscapeViewModel(analyticsService: mockService, userId: 1)

    #expect(viewModel.state == .idle)
  }

  // MARK: - Loading Tests

  @Test("viewModel loads emotional landscape successfully")
  @MainActor
  func viewModel_loadsSuccessfully() async {
    let mockService = MockAnalyticsService()
    let mockLandscape = EmotionalLandscape(
      layerDistribution: [
        LayerDistributionItem(layerId: 1, count: 10, percentage: 50.0),
        LayerDistributionItem(layerId: 2, count: 10, percentage: 50.0),
      ],
      phaseDistribution: [
        PhaseDistributionItem(phaseId: 1, count: 15, percentage: 75.0),
        PhaseDistributionItem(phaseId: 2, count: 5, percentage: 25.0),
      ],
      topEmotions: [
        TopEmotionItem(
          curriculumId: 1,
          expression: "Joy",
          layerId: 1,
          phaseId: 1,
          dosage: "Medicinal",
          count: 8
        ),
      ]
    )
    mockService.emotionalLandscapeToReturn = mockLandscape

    let viewModel = EmotionalLandscapeViewModel(analyticsService: mockService, userId: 1)

    await viewModel.load()

    #expect(viewModel.state == .loaded(mockLandscape))
    #expect(mockService.getEmotionalLandscapeCallCount == 1)
  }

  @Test("viewModel handles loading error")
  @MainActor
  func viewModel_handlesError() async {
    let mockService = MockAnalyticsService()
    let error = NSError(domain: "test", code: 404)
    mockService.errorToThrow = error

    let viewModel = EmotionalLandscapeViewModel(analyticsService: mockService, userId: 1)

    await viewModel.load()

    if case let .error(returnedError as NSError) = viewModel.state {
      #expect(returnedError.code == 404)
    } else {
      Issue.record("Expected error state")
    }
  }

  @Test("viewModel transitions to loading state")
  @MainActor
  func viewModel_transitionsToLoadingState() async {
    let mockService = MockAnalyticsService()
    mockService.emotionalLandscapeToReturn = EmotionalLandscape(
      layerDistribution: [],
      phaseDistribution: [],
      topEmotions: []
    )

    let viewModel = EmotionalLandscapeViewModel(analyticsService: mockService, userId: 1)

    let loadTask = Task {
      await viewModel.load()
    }

    // Give it a moment to transition to loading
    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

    // Should be in loading or loaded state
    #expect(viewModel.state != .idle)

    await loadTask.value
  }

  // MARK: - Computed Properties Tests

  @Test("layerDistribution returns correct items when loaded")
  @MainActor
  func layerDistribution_returnsItemsWhenLoaded() {
    let mockService = MockAnalyticsService()
    let items = [
      LayerDistributionItem(layerId: 1, count: 10, percentage: 50.0),
      LayerDistributionItem(layerId: 2, count: 10, percentage: 50.0),
    ]
    let landscape = EmotionalLandscape(
      layerDistribution: items,
      phaseDistribution: [],
      topEmotions: []
    )

    let viewModel = EmotionalLandscapeViewModel(analyticsService: mockService, userId: 1)
    viewModel.state = .loaded(landscape)

    #expect(viewModel.layerDistribution == items)
  }

  @Test("layerDistribution returns empty array when not loaded")
  @MainActor
  func layerDistribution_returnsEmptyWhenNotLoaded() {
    let mockService = MockAnalyticsService()
    let viewModel = EmotionalLandscapeViewModel(analyticsService: mockService, userId: 1)

    #expect(viewModel.layerDistribution.isEmpty)
  }

  @Test("phaseDistribution returns correct items when loaded")
  @MainActor
  func phaseDistribution_returnsItemsWhenLoaded() {
    let mockService = MockAnalyticsService()
    let items = [
      PhaseDistributionItem(phaseId: 1, count: 15, percentage: 75.0),
      PhaseDistributionItem(phaseId: 2, count: 5, percentage: 25.0),
    ]
    let landscape = EmotionalLandscape(
      layerDistribution: [],
      phaseDistribution: items,
      topEmotions: []
    )

    let viewModel = EmotionalLandscapeViewModel(analyticsService: mockService, userId: 1)
    viewModel.state = .loaded(landscape)

    #expect(viewModel.phaseDistribution == items)
  }

  @Test("topEmotions returns correct items when loaded")
  @MainActor
  func topEmotions_returnsItemsWhenLoaded() {
    let mockService = MockAnalyticsService()
    let items = [
      TopEmotionItem(
        curriculumId: 1,
        expression: "Joy",
        layerId: 1,
        phaseId: 1,
        dosage: "Medicinal",
        count: 8
      ),
      TopEmotionItem(
        curriculumId: 2,
        expression: "Sadness",
        layerId: 3,
        phaseId: 2,
        dosage: "Toxic",
        count: 3
      ),
    ]
    let landscape = EmotionalLandscape(
      layerDistribution: [],
      phaseDistribution: [],
      topEmotions: items
    )

    let viewModel = EmotionalLandscapeViewModel(analyticsService: mockService, userId: 1)
    viewModel.state = .loaded(landscape)

    #expect(viewModel.topEmotions == items)
  }
}
