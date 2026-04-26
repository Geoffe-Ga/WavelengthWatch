import Foundation

/// Criteria used to drill down from an analytics surface into the
/// specific journal entries that produced a statistic.
///
/// Each case both **describes** which entries belong in the list and
/// **labels** the destination screen's title. The predicate used for
/// filtering lives on the enum itself so every tap surface and every
/// test resolves membership the same way.
enum JournalEntryDrilldownFilter: Equatable {
  /// Entries whose `strategyID` matches the given ID.
  case byStrategy(strategyId: Int, name: String)

  /// Entries whose primary curriculum belongs to the given phase.
  /// Resolved via a curriculum → phase lookup provided by the caller.
  case byPhase(phaseId: Int, name: String)

  /// Entries whose primary curriculum belongs to the given layer.
  case byLayer(layerId: Int, name: String)

  /// Entries whose primary or secondary curriculum matches the ID.
  case byCurriculum(curriculumId: Int, expression: String)

  /// Entries whose `createdAt` hour-of-day matches.
  case byHour(hour: Int)

  /// Human-readable title to show at the top of the drill-down list.
  var title: String {
    switch self {
    case let .byStrategy(_, name): "Uses of \(name)"
    case let .byPhase(_, name): "\(name) Entries"
    case let .byLayer(_, name): "\(name) Mode Entries"
    case let .byCurriculum(_, expression): "Entries: \(expression)"
    case let .byHour(hour): "Entries at \(HourFormatter.display(hour))"
    }
  }

  /// Whether the given entry should appear in the drill-down list.
  ///
  /// - Parameters:
  ///   - entry: Candidate journal entry.
  ///   - curriculumPhaseById: Mapping from curriculum ID to its phase ID.
  ///   - curriculumLayerById: Mapping from curriculum ID to its layer ID.
  ///   - calendar: Calendar used for the `.byHour` check (defaults to
  ///     the user's current calendar so the bucket matches the
  ///     TemporalPatterns calculation).
  func matches(
    _ entry: LocalJournalEntry,
    curriculumPhaseById: [Int: Int] = [:],
    curriculumLayerById: [Int: Int] = [:],
    calendar: Calendar = .current
  ) -> Bool {
    switch self {
    case let .byStrategy(strategyId, _):
      return entry.strategyID == strategyId
    case let .byPhase(phaseId, _):
      guard let cid = entry.curriculumID, let mapped = curriculumPhaseById[cid] else {
        return false
      }
      return mapped == phaseId
    case let .byLayer(layerId, _):
      guard let cid = entry.curriculumID, let mapped = curriculumLayerById[cid] else {
        return false
      }
      return mapped == layerId
    case let .byCurriculum(curriculumId, _):
      return entry.curriculumID == curriculumId
        || entry.secondaryCurriculumID == curriculumId
    case let .byHour(hour):
      return calendar.component(.hour, from: entry.createdAt) == hour
    }
  }
}
