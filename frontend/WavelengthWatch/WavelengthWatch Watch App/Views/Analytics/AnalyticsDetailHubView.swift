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

  // MARK: - Analytics Components

  /// Shared analytics service instance for all detail views
  private let analyticsService: AnalyticsService

  /// Local calculator for offline-first support (nil if catalog not cached)
  private let localCalculator: LocalAnalyticsCalculatorProtocol?

  /// Phases from cached catalog for resolving phase names in views
  private let phases: [CatalogPhaseModel]

  /// Full cached catalog for drill-down context (nil when catalog not cached)
  private let cachedCatalog: CatalogResponseModel?

  init(
    journalRepository: JournalRepositoryProtocol,
    catalogRepository: CatalogRepositoryProtocol,
    syncSettings: SyncSettings = SyncSettings()
  ) {
    self.journalRepository = journalRepository
    self.catalogRepository = catalogRepository
    self.syncSettings = syncSettings

    // Create shared service components once
    let configuration = AppConfiguration()
    let apiClient = APIClient(baseURL: configuration.apiBaseURL)
    self.analyticsService = AnalyticsService(apiClient: apiClient)

    let cachedCatalog = catalogRepository.cachedCatalog()
    self.cachedCatalog = cachedCatalog
    self.localCalculator = cachedCatalog.map { LocalAnalyticsCalculator(catalog: $0) }
    self.phases = cachedCatalog?.layers.first?.phases ?? []
  }

  /// Drill-down context for views that support tap-to-filter. Nil when
  /// the catalog is not cached (drill-down stays disabled in that case).
  private var drilldownContext: JournalDrilldownContext? {
    cachedCatalog.map {
      JournalDrilldownContext(journalRepository: journalRepository, catalog: $0)
    }
  }

  // MARK: - Helpers

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
      analyticsService: analyticsService,
      localCalculator: localCalculator,
      journalRepository: journalRepository,
      syncSettings: syncSettings,
      phases: phases,
      drilldownContext: drilldownContext
    )
  }

  private var temporalPatternsDetailView: some View {
    TemporalPatternsDetailView(
      analyticsService: analyticsService,
      localCalculator: localCalculator,
      journalRepository: journalRepository,
      syncSettings: syncSettings,
      dateRange: defaultDateRange,
      phases: phases,
      drilldownContext: drilldownContext
    )
  }

  private var growthIndicatorsDetailView: some View {
    GrowthIndicatorsDetailView(
      analyticsService: analyticsService,
      localCalculator: localCalculator,
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
  private let phases: [CatalogPhaseModel]
  private let drilldownContext: JournalDrilldownContext?

  init(
    analyticsService: AnalyticsService,
    localCalculator: LocalAnalyticsCalculatorProtocol?,
    journalRepository: JournalRepositoryProtocol,
    syncSettings: SyncSettings,
    phases: [CatalogPhaseModel],
    drilldownContext: JournalDrilldownContext?
  ) {
    self.phases = phases
    self.drilldownContext = drilldownContext
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
          StrategyUsageView(
            analytics: analytics,
            phases: phases,
            drilldownContext: drilldownContext
          )
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
  private let phases: [CatalogPhaseModel]
  private let drilldownContext: JournalDrilldownContext?

  init(
    analyticsService: AnalyticsService,
    localCalculator: LocalAnalyticsCalculatorProtocol?,
    journalRepository: JournalRepositoryProtocol,
    syncSettings: SyncSettings,
    dateRange: (startDate: Date, endDate: Date),
    phases: [CatalogPhaseModel],
    drilldownContext: JournalDrilldownContext?
  ) {
    self.dateRange = dateRange
    self.phases = phases
    self.drilldownContext = drilldownContext

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
          TemporalPatternsView(
            patterns: patterns,
            phases: phases,
            drilldownContext: drilldownContext,
            dateRange: dateRange
          )
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
    analyticsService: AnalyticsService,
    localCalculator: LocalAnalyticsCalculatorProtocol?,
    journalRepository: JournalRepositoryProtocol,
    syncSettings: SyncSettings,
    dateRange: (startDate: Date, endDate: Date)
  ) {
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
