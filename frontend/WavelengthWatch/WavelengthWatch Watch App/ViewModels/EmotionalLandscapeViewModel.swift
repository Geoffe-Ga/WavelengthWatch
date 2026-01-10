import Foundation

/// ViewModel for managing emotional landscape analytics state
@MainActor
final class EmotionalLandscapeViewModel: ObservableObject {
  // MARK: - State

  enum LoadingState: Equatable {
    case idle
    case loading
    case loaded(EmotionalLandscape)
    case error(Error)

    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
      switch (lhs, rhs) {
      case (.idle, .idle):
        true
      case (.loading, .loading):
        true
      case let (.loaded(l), .loaded(r)):
        l == r
      case let (.error(l as NSError), .error(r as NSError)):
        l.code == r.code && l.domain == r.domain
      default:
        false
      }
    }
  }

  // MARK: - Published Properties

  @Published var state: LoadingState = .idle

  // MARK: - Computed Properties

  var layerDistribution: [LayerDistributionItem] {
    guard case let .loaded(landscape) = state else {
      return []
    }
    return landscape.layerDistribution
  }

  var phaseDistribution: [PhaseDistributionItem] {
    guard case let .loaded(landscape) = state else {
      return []
    }
    return landscape.phaseDistribution
  }

  var topEmotions: [TopEmotionItem] {
    guard case let .loaded(landscape) = state else {
      return []
    }
    return landscape.topEmotions
  }

  // MARK: - Dependencies

  private let analyticsService: AnalyticsServiceProtocol
  private let userId: Int

  // MARK: - Initialization

  init(analyticsService: AnalyticsServiceProtocol, userId: Int) {
    self.analyticsService = analyticsService
    self.userId = userId
  }

  // MARK: - Public Methods

  func load() async {
    state = .loading

    do {
      let landscape = try await analyticsService.getEmotionalLandscape(userId: userId)
      state = .loaded(landscape)
    } catch {
      state = .error(error)
    }
  }
}
