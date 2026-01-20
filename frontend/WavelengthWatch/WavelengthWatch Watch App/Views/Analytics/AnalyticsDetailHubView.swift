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
  // MARK: - Constants

  fileprivate static let defaultTopStrategiesLimit = 10
  fileprivate static let defaultDateRangeDays = 30

  // MARK: - Dependencies

  let journalRepository: JournalRepositoryProtocol
  let catalogRepository: CatalogRepositoryProtocol
  let syncSettings: SyncSettings

  init(
    journalRepository: JournalRepositoryProtocol,
    catalogRepository: CatalogRepositoryProtocol,
    syncSettings: SyncSettings = SyncSettings()
  ) {
    self.journalRepository = journalRepository
    self.catalogRepository = catalogRepository
    self.syncSettings = syncSettings
  }

  // MARK: - Helpers

  /// Creates analytics service and local calculator for offline-first support.
  ///
  /// - Returns: Tuple of (service, calculator) where calculator is nil if catalog not cached
  private func makeAnalyticsComponents() -> (
    service: AnalyticsService,
    calculator: LocalAnalyticsCalculatorProtocol?
  ) {
    let configuration = AppConfiguration()
    let apiClient = APIClient(baseURL: configuration.apiBaseURL)
    let analyticsService = AnalyticsService(apiClient: apiClient)

    let localCalculator = catalogRepository.cachedCatalog()
      .map { LocalAnalyticsCalculator(catalog: $0) }

    return (analyticsService, localCalculator)
  }

  /// Calculates default date range for temporal/growth analytics.
  ///
  /// - Returns: Tuple of (startDate, endDate) for last 30 days
  private var defaultDateRange: (startDate: Date, endDate: Date) {
    let endDate = Date()
    let startDate = Calendar.current.date(
      byAdding: .day,
      value: -Self.defaultDateRangeDays,
      to: endDate
    ) ?? endDate
    return (startDate, endDate)
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
      makeComponents: makeAnalyticsComponents,
      journalRepository: journalRepository,
      syncSettings: syncSettings
    )
  }

  private var temporalPatternsDetailView: some View {
    TemporalPatternsDetailView(
      makeComponents: makeAnalyticsComponents,
      journalRepository: journalRepository,
      syncSettings: syncSettings,
      dateRange: defaultDateRange
    )
  }

  private var growthIndicatorsDetailView: some View {
    GrowthIndicatorsDetailView(
      makeComponents: makeAnalyticsComponents,
      journalRepository: journalRepository,
      syncSettings: syncSettings,
      dateRange: defaultDateRange
    )
  }
}

// MARK: - Self-Care Detail View

/// Detailed self-care analytics view with ViewModel integration.
private struct SelfCareDetailView: View {
  @StateObject private var viewModel: SelfCareViewModel

  init(
    makeComponents: () -> (AnalyticsService, LocalAnalyticsCalculatorProtocol?),
    journalRepository: JournalRepositoryProtocol,
    syncSettings: SyncSettings
  ) {
    let (analyticsService, localCalculator) = makeComponents()

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
          AnalyticsLoadingStates.loadingView
        case let .loaded(analytics):
          StrategyUsageView(analytics: analytics)
            .padding()
        case let .error(message):
          AnalyticsLoadingStates.errorView(
            message: message,
            retry: { await viewModel.retry(limit: AnalyticsDetailHubView.defaultTopStrategiesLimit) }
          )
        }
      }
    }
    .navigationTitle("Self-Care Insights")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      if case .idle = viewModel.state {
        await viewModel.loadSelfCare(limit: AnalyticsDetailHubView.defaultTopStrategiesLimit)
      }
    }
  }
}

// MARK: - Temporal Patterns Detail View

/// Detailed temporal patterns analytics view with ViewModel integration.
private struct TemporalPatternsDetailView: View {
  @StateObject private var viewModel: TemporalPatternsViewModel
  private let dateRange: (startDate: Date, endDate: Date)

  init(
    makeComponents: () -> (AnalyticsService, LocalAnalyticsCalculatorProtocol?),
    journalRepository: JournalRepositoryProtocol,
    syncSettings: SyncSettings,
    dateRange: (startDate: Date, endDate: Date)
  ) {
    let (analyticsService, localCalculator) = makeComponents()
    self.dateRange = dateRange

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
          AnalyticsLoadingStates.loadingView
        case let .loaded(patterns):
          TemporalPatternsView(patterns: patterns)
            .padding()
        case let .error(message):
          AnalyticsLoadingStates.errorView(
            message: message,
            retry: {
              await viewModel.retry(
                startDate: dateRange.startDate,
                endDate: dateRange.endDate
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
        await viewModel.loadTemporalPatterns(
          startDate: dateRange.startDate,
          endDate: dateRange.endDate
        )
      }
    }
  }
}

// MARK: - Growth Indicators Detail View

/// Detailed growth indicators analytics view with ViewModel integration.
private struct GrowthIndicatorsDetailView: View {
  @StateObject private var viewModel: GrowthIndicatorsViewModel
  private let dateRange: (startDate: Date, endDate: Date)

  init(
    makeComponents: () -> (AnalyticsService, LocalAnalyticsCalculatorProtocol?),
    journalRepository: JournalRepositoryProtocol,
    syncSettings: SyncSettings,
    dateRange: (startDate: Date, endDate: Date)
  ) {
    let (analyticsService, localCalculator) = makeComponents()
    self.dateRange = dateRange

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
          AnalyticsLoadingStates.loadingView
        case let .loaded(indicators):
          GrowthIndicatorsView(indicators: indicators)
            .padding()
        case let .error(message):
          AnalyticsLoadingStates.errorView(
            message: message,
            retry: {
              await viewModel.retry(
                startDate: dateRange.startDate,
                endDate: dateRange.endDate
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
        await viewModel.loadGrowthIndicators(
          startDate: dateRange.startDate,
          endDate: dateRange.endDate
        )
      }
    }
  }
}

// MARK: - Shared UI Components

/// Shared loading and error states for analytics detail views.
///
/// Extracted to avoid duplication across SelfCare, Temporal, and Growth detail views.
private enum AnalyticsLoadingStates {
  static var loadingView: some View {
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

  static func errorView(message: String, retry: @escaping () async -> Void) -> some View {
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
}
