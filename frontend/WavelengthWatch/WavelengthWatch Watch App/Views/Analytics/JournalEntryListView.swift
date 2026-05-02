import SwiftUI

/// Drill-down list showing the specific journal entries that contributed
/// to an analytics statistic. Rendered when a user taps a tappable
/// analytics row (strategy, phase, hour, …).
///
/// Loads entries from the repository on `.task`, applies the supplied
/// `JournalEntryDrilldownFilter`, and renders a compact list with
/// timestamp plus emotion/strategy name resolution via the catalog.
///
/// When `dateRange` is supplied, the load path uses
/// `fetchByDateRange(from:to:)` so the drill-down list only contains
/// entries from the same window the analytics stat was computed over.
/// Time-bound surfaces (e.g. `TemporalPatternsView` hourly rows) must
/// pass this; surfaces that are inherently all-time (strategy / phase
/// / layer drill-downs) leave it nil.
struct JournalEntryListView: View {
  let filter: JournalEntryDrilldownFilter
  let journalRepository: JournalRepositoryProtocol
  let catalog: CatalogResponseModel
  let dateRange: (startDate: Date, endDate: Date)?

  init(
    filter: JournalEntryDrilldownFilter,
    journalRepository: JournalRepositoryProtocol,
    catalog: CatalogResponseModel,
    dateRange: (startDate: Date, endDate: Date)? = nil
  ) {
    self.filter = filter
    self.journalRepository = journalRepository
    self.catalog = catalog
    self.dateRange = dateRange
  }

  @State private var entries: [LocalJournalEntry] = []
  @State private var isLoading = true
  @State private var loadError: String?

  /// Emotion expression keyed by curriculum ID.
  private var expressionById: [Int: String] {
    JournalEntryListView.buildExpressionLookup(catalog: catalog)
  }

  /// Strategy name keyed by strategy ID.
  private var strategyNameById: [Int: String] {
    JournalEntryListView.buildStrategyLookup(catalog: catalog)
  }

  /// Curriculum → phase ID mapping for `byPhase` filtering.
  private var curriculumPhaseById: [Int: Int] {
    JournalEntryListView.buildCurriculumPhaseLookup(catalog: catalog)
  }

  /// Curriculum → layer ID mapping for `byLayer` filtering.
  private var curriculumLayerById: [Int: Int] {
    JournalEntryListView.buildCurriculumLayerLookup(catalog: catalog)
  }

  var body: some View {
    Group {
      if isLoading {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let loadError {
        JournalEntryListErrorStateView(message: loadError)
      } else if filteredEntries.isEmpty {
        JournalEntryListEmptyStateView()
      } else {
        List(filteredEntries) { entry in
          JournalEntryRowView(
            entry: entry,
            expressionById: expressionById,
            strategyNameById: strategyNameById
          )
        }
      }
    }
    .navigationTitle(filter.title)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await load()
    }
  }

  /// Entries after the drill-down filter is applied, newest first.
  var filteredEntries: [LocalJournalEntry] {
    entries.filter {
      filter.matches(
        $0,
        curriculumPhaseById: curriculumPhaseById,
        curriculumLayerById: curriculumLayerById
      )
    }
  }

  private func load() async {
    isLoading = true
    loadError = nil
    do {
      entries = try fetchEntries()
    } catch {
      loadError = error.localizedDescription
    }
    isLoading = false
  }

  /// Picks the repository method based on whether a date range was supplied.
  /// Exposed (internal) for unit testing the dispatch logic without needing
  /// to spin up SwiftUI's `.task` lifecycle.
  func fetchEntries() throws -> [LocalJournalEntry] {
    if let dateRange {
      return try journalRepository.fetchByDateRange(
        from: dateRange.startDate,
        to: dateRange.endDate
      )
    }
    return try journalRepository.fetchAll()
  }

  // MARK: - Lookup builders (exposed for testing)

  static func buildExpressionLookup(catalog: CatalogResponseModel) -> [Int: String] {
    var result: [Int: String] = [:]
    for layer in catalog.layers {
      for phase in layer.phases {
        for entry in phase.medicinal + phase.toxic {
          result[entry.id] = entry.expression
        }
      }
    }
    return result
  }

  static func buildStrategyLookup(catalog: CatalogResponseModel) -> [Int: String] {
    var result: [Int: String] = [:]
    for layer in catalog.layers {
      for phase in layer.phases {
        for strategy in phase.strategies {
          result[strategy.id] = strategy.strategy
        }
      }
    }
    return result
  }

  static func buildCurriculumPhaseLookup(catalog: CatalogResponseModel) -> [Int: Int] {
    var result: [Int: Int] = [:]
    for layer in catalog.layers {
      for phase in layer.phases {
        for entry in phase.medicinal + phase.toxic {
          result[entry.id] = phase.id
        }
      }
    }
    return result
  }

  static func buildCurriculumLayerLookup(catalog: CatalogResponseModel) -> [Int: Int] {
    var result: [Int: Int] = [:]
    for layer in catalog.layers {
      for phase in layer.phases {
        for entry in phase.medicinal + phase.toxic {
          result[entry.id] = layer.id
        }
      }
    }
    return result
  }
}
