import SwiftUI

/// Drill-down list showing the specific journal entries that contributed
/// to an analytics statistic. Rendered when a user taps a tappable
/// analytics row (strategy, phase, hour, …).
///
/// Loads entries from the repository on `.task`, applies the supplied
/// `JournalEntryDrilldownFilter`, and renders a compact list with
/// timestamp plus emotion/strategy name resolution via the catalog.
struct JournalEntryListView: View {
  let filter: JournalEntryDrilldownFilter
  let journalRepository: JournalRepositoryProtocol
  let catalog: CatalogResponseModel

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
        ErrorState(message: loadError)
      } else if filteredEntries.isEmpty {
        EmptyState()
      } else {
        List(filteredEntries) { entry in
          EntryRow(
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
      entries = try journalRepository.fetchAll()
    } catch {
      loadError = error.localizedDescription
    }
    isLoading = false
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

// MARK: - Row

private struct EntryRow: View {
  let entry: LocalJournalEntry
  let expressionById: [Int: String]
  let strategyNameById: [Int: String]

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(entry.createdAt, format: .dateTime.month().day().hour().minute())
        .font(.caption)
        .fontWeight(.semibold)

      if let expression {
        Text(expression)
          .font(.caption2)
          .foregroundColor(.secondary)
          .lineLimit(1)
      }

      if let strategyName {
        HStack(spacing: 4) {
          Image(systemName: "leaf")
            .font(.system(size: 9))
            .foregroundColor(.secondary)
          Text(strategyName)
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
      }
    }
    .padding(.vertical, 2)
  }

  private var expression: String? {
    guard let cid = entry.curriculumID else { return nil }
    return expressionById[cid]
  }

  private var strategyName: String? {
    guard let sid = entry.strategyID else { return nil }
    return strategyNameById[sid]
  }
}

private struct EmptyState: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "tray")
        .font(.title)
        .foregroundColor(.secondary)
      Text("No entries yet")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

private struct ErrorState: View {
  let message: String

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "exclamationmark.triangle")
        .font(.title)
        .foregroundColor(.orange)
      Text(message)
        .font(.caption2)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
