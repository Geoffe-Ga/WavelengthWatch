import SwiftUI

/// Analytics detail hub providing navigation to all detailed analytics sections.
///
/// This hub acts as a navigation center for accessing:
/// - Self-Care Insights (strategy usage and diversity)
/// - Temporal Patterns (time-of-day distribution and consistency)
/// - Growth Indicators (medicinal trend, layer/phase coverage)
///
/// ## Dependencies
/// Requires journal and catalog repositories for offline-first analytics support.
/// ViewModels are created with backend + local calculator fallback.
struct AnalyticsDetailHubView: View {
  private let journalRepository: JournalRepositoryProtocol
  private let catalogRepository: CatalogRepositoryProtocol
  private let syncSettings: SyncSettings

  init(
    journalRepository: JournalRepositoryProtocol,
    catalogRepository: CatalogRepositoryProtocol,
    syncSettings: SyncSettings = SyncSettings()
  ) {
    self.journalRepository = journalRepository
    self.catalogRepository = catalogRepository
    self.syncSettings = syncSettings
  }

  var body: some View {
    List {
      // TODO: Add Emotional Landscape when view is available (Phase 2, PRs #228-230)
      // NavigationLink("Emotional Landscape", destination: EmotionalLandscapeDetailView(...))

      NavigationLink(destination: selfCareDetailView) {
        Label {
          VStack(alignment: .leading, spacing: 2) {
            Text("Self-Care Insights")
              .font(.body)
            Text("Strategy usage & diversity")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        } icon: {
          Image(systemName: "heart.circle.fill")
            .foregroundColor(.blue)
        }
      }

      NavigationLink(destination: temporalPatternsDetailView) {
        Label {
          VStack(alignment: .leading, spacing: 2) {
            Text("Temporal Patterns")
              .font(.body)
            Text("Time-of-day insights")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        } icon: {
          Image(systemName: "clock.fill")
            .foregroundColor(.purple)
        }
      }

      NavigationLink(destination: growthIndicatorsDetailView) {
        Label {
          VStack(alignment: .leading, spacing: 2) {
            Text("Growth Indicators")
              .font(.body)
            Text("Progress & exploration")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        } icon: {
          Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
            .foregroundColor(.green)
        }
      }
    }
    .navigationTitle("Detailed Insights")
    .navigationBarTitleDisplayMode(.inline)
  }

  // MARK: - Detail Views

  private var selfCareDetailView: some View {
    SelfCareDetailView(
      journalRepository: journalRepository,
      catalogRepository: catalogRepository,
      syncSettings: syncSettings
    )
  }

  private var temporalPatternsDetailView: some View {
    TemporalPatternsDetailView(
      journalRepository: journalRepository,
      catalogRepository: catalogRepository,
      syncSettings: syncSettings
    )
  }

  private var growthIndicatorsDetailView: some View {
    GrowthIndicatorsDetailView(
      journalRepository: journalRepository,
      catalogRepository: catalogRepository,
      syncSettings: syncSettings
    )
  }
}

// MARK: - Self-Care Detail View

/// Detailed self-care analytics view with ViewModel integration.
private struct SelfCareDetailView: View {
  @StateObject private var viewModel: SelfCareViewModel

  init(
    journalRepository: JournalRepositoryProtocol,
    catalogRepository: CatalogRepositoryProtocol,
    syncSettings: SyncSettings
  ) {
    let configuration = AppConfiguration()
    let apiClient = APIClient(baseURL: configuration.apiBaseURL)
    let analyticsService = AnalyticsService(apiClient: apiClient)

    let localCalculator: LocalAnalyticsCalculatorProtocol? = {
      guard let catalog = catalogRepository.cachedCatalog() else {
        return nil
      }
      return LocalAnalyticsCalculator(catalog: catalog)
    }()

    _viewModel = StateObject(
      wrappedValue: SelfCareViewModel(
        analyticsService: analyticsService,
        localCalculator: localCalculator,
        journalRepository: journalRepository,
        syncSettings: syncSettings
      )
    )
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        switch viewModel.state {
        case .idle, .loading:
          loadingView
        case let .loaded(analytics):
          StrategyUsageView(analytics: analytics)
            .padding()
        case let .error(message):
          errorView(message: message, retry: { await viewModel.retry(limit: 10) })
        }
      }
    }
    .navigationTitle("Self-Care Insights")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      if case .idle = viewModel.state {
        await viewModel.loadSelfCare(limit: 10)
      }
    }
  }
}

// MARK: - Temporal Patterns Detail View

/// Detailed temporal patterns analytics view with ViewModel integration.
private struct TemporalPatternsDetailView: View {
  @StateObject private var viewModel: TemporalPatternsViewModel

  init(
    journalRepository: JournalRepositoryProtocol,
    catalogRepository: CatalogRepositoryProtocol,
    syncSettings: SyncSettings
  ) {
    let configuration = AppConfiguration()
    let apiClient = APIClient(baseURL: configuration.apiBaseURL)
    let analyticsService = AnalyticsService(apiClient: apiClient)

    let localCalculator: LocalAnalyticsCalculatorProtocol? = {
      guard let catalog = catalogRepository.cachedCatalog() else {
        return nil
      }
      return LocalAnalyticsCalculator(catalog: catalog)
    }()

    _viewModel = StateObject(
      wrappedValue: TemporalPatternsViewModel(
        analyticsService: analyticsService,
        localCalculator: localCalculator,
        journalRepository: journalRepository,
        syncSettings: syncSettings
      )
    )
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        switch viewModel.state {
        case .idle, .loading:
          loadingView
        case let .loaded(patterns):
          TemporalPatternsView(patterns: patterns)
            .padding()
        case let .error(message):
          errorView(
            message: message,
            retry: {
              await viewModel.retry(
                startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30 days ago
                endDate: Date()
              )
            }
          )
        }
      }
    }
    .navigationTitle("Temporal Patterns")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      if case .idle = viewModel.state {
        // Default to last 30 days
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-30 * 24 * 60 * 60)
        await viewModel.loadTemporalPatterns(startDate: startDate, endDate: endDate)
      }
    }
  }
}

// MARK: - Growth Indicators Detail View

/// Detailed growth indicators analytics view with ViewModel integration.
private struct GrowthIndicatorsDetailView: View {
  @StateObject private var viewModel: GrowthIndicatorsViewModel

  init(
    journalRepository: JournalRepositoryProtocol,
    catalogRepository: CatalogRepositoryProtocol,
    syncSettings: SyncSettings
  ) {
    let configuration = AppConfiguration()
    let apiClient = APIClient(baseURL: configuration.apiBaseURL)
    let analyticsService = AnalyticsService(apiClient: apiClient)

    let localCalculator: LocalAnalyticsCalculatorProtocol? = {
      guard let catalog = catalogRepository.cachedCatalog() else {
        return nil
      }
      return LocalAnalyticsCalculator(catalog: catalog)
    }()

    _viewModel = StateObject(
      wrappedValue: GrowthIndicatorsViewModel(
        analyticsService: analyticsService,
        localCalculator: localCalculator,
        journalRepository: journalRepository,
        syncSettings: syncSettings
      )
    )
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        switch viewModel.state {
        case .idle, .loading:
          loadingView
        case let .loaded(indicators):
          GrowthIndicatorsView(indicators: indicators)
            .padding()
        case let .error(message):
          errorView(
            message: message,
            retry: {
              await viewModel.retry(
                startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30 days ago
                endDate: Date()
              )
            }
          )
        }
      }
    }
    .navigationTitle("Growth Indicators")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      if case .idle = viewModel.state {
        // Default to last 30 days
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-30 * 24 * 60 * 60)
        await viewModel.loadGrowthIndicators(startDate: startDate, endDate: endDate)
      }
    }
  }
}

// MARK: - Shared UI Components

private var loadingView: some View {
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

private func errorView(message: String, retry: @escaping () async -> Void) -> some View {
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
      Task { await retry() }
    }
    .buttonStyle(.borderedProminent)
  }
  .padding(.top, 40)
}
