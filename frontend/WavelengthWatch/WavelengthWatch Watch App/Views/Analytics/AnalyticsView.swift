import SwiftUI

struct AnalyticsView: View {
  @StateObject private var viewModel: AnalyticsViewModel
  @EnvironmentObject var contentViewModel: ContentViewModel

  // Store repositories for passing to detail hub
  let journalRepository: JournalRepositoryProtocol
  let catalogRepository: CatalogRepositoryProtocol

  /// Creates an AnalyticsView with offline analytics support.
  ///
  /// Offline analytics require a cached catalog. If `catalogRepository.cachedCatalog()`
  /// returns nil, analytics will only work when the backend is reachable. For full
  /// offline functionality, ensure the catalog is loaded before navigating to analytics.
  ///
  /// - Parameters:
  ///   - journalRepository: Repository for fetching local journal entries
  ///   - catalogRepository: Repository with cached catalog (required for offline analytics)
  init(
    journalRepository: JournalRepositoryProtocol,
    catalogRepository: CatalogRepositoryProtocol
  ) {
    self.journalRepository = journalRepository
    self.catalogRepository = catalogRepository

    let configuration = AppConfiguration()
    let apiClient = APIClient(baseURL: configuration.apiBaseURL)
    let analyticsService = AnalyticsService(apiClient: apiClient)

    // Create local calculator with cached catalog for offline support
    let localCalculator: LocalAnalyticsCalculatorProtocol? = {
      guard let catalog = catalogRepository.cachedCatalog() else {
        return nil
      }
      return LocalAnalyticsCalculator(catalog: catalog)
    }()

    _viewModel = StateObject(
      wrappedValue: AnalyticsViewModel(
        analyticsService: analyticsService,
        localCalculator: localCalculator,
        journalRepository: journalRepository,
        catalogRepository: catalogRepository
      )
    )
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        switch viewModel.state {
        case .idle, .loading:
          loadingView
        case let .loaded(overview):
          loadedView(overview: overview)
        case let .error(message):
          errorView(message: message)
        }
      }
      .padding()
    }
    .navigationTitle("Analytics")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      if case .idle = viewModel.state {
        await viewModel.loadAnalytics()
      }
    }
  }

  // MARK: - Loading View

  var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .progressViewStyle(.circular)
        .tint(.white)

      Text("Loading analytics...")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.top, 40)
  }

  // MARK: - Error View

  func errorView(message: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 40))
        .foregroundColor(.orange)

      Text("Error")
        .font(.headline)

      Text(message)
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

      Button("Retry") {
        Task { await viewModel.retry() }
      }
      .buttonStyle(.borderedProminent)
    }
    .padding(.top, 40)
  }

  // MARK: - Loaded View

  func loadedView(overview: AnalyticsOverview) -> some View {
    VStack(spacing: 20) {
      if overview.totalEntries == 0 {
        emptyStateView
      } else {
        checkInActivitySection(overview: overview)
        emotionalHealthSection(overview: overview)

        if let layerId = overview.dominantLayerId,
           let phaseId = overview.dominantPhaseId
        {
          currentStateSection(layerId: layerId, phaseId: phaseId)
        }

        quickStatsSection(overview: overview)
        detailedInsightsButton
      }
    }
  }

  // MARK: - Empty State

  var emptyStateView: some View {
    VStack(spacing: 16) {
      Image(systemName: "chart.bar")
        .font(.system(size: 48))
        .foregroundColor(.blue.opacity(0.6))

      Text("No Data Yet")
        .font(.headline)

      Text("Start logging your emotions to see insights and patterns.")
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding(.top, 40)
  }
}
