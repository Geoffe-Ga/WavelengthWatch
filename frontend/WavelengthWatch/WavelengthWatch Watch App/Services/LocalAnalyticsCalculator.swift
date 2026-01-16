import Foundation

/// Metadata for curriculum items needed for analytics calculations.
struct CurriculumInfo {
  let expression: String
  let layerId: Int
  let phaseId: Int
  let dosage: CatalogDosage
}

/// Metadata for strategy items needed for analytics calculations.
struct StrategyInfo {
  let strategy: String
}

/// Protocol for local analytics calculation operations.
protocol LocalAnalyticsCalculatorProtocol {
  func calculateOverview(
    entries: [LocalJournalEntry],
    startDate: Date,
    endDate: Date
  ) -> AnalyticsOverview

  func calculateEmotionalLandscape(
    entries: [LocalJournalEntry],
    limit: Int
  ) -> EmotionalLandscape

  func calculateSelfCare(
    entries: [LocalJournalEntry],
    limit: Int
  ) -> SelfCareAnalytics
}

/// Calculates analytics from local journal entries without backend dependency.
///
/// This calculator provides offline-first analytics by computing metrics
/// directly from local SQLite data using algorithms ported from the backend.
/// It requires the embedded catalog for curriculum lookups (layer, phase, dosage).
///
/// ## Usage
/// ```swift
/// let calculator = LocalAnalyticsCalculator(catalog: embeddedCatalog)
/// let overview = calculator.calculateOverview(
///   entries: localEntries,
///   startDate: startDate,
///   endDate: endDate
/// )
/// ```
final class LocalAnalyticsCalculator: LocalAnalyticsCalculatorProtocol {
  private let curriculumLookup: [Int: CurriculumInfo]
  private let strategyLookup: [Int: StrategyInfo]

  /// Creates a calculator with catalog-based curriculum and strategy lookup.
  ///
  /// - Parameter catalog: The catalog response model containing all curriculum data.
  init(catalog: CatalogResponseModel) {
    var curriculumDict: [Int: CurriculumInfo] = [:]
    var strategyDict: [Int: StrategyInfo] = [:]

    for layer in catalog.layers {
      for phase in layer.phases {
        for entry in phase.medicinal + phase.toxic {
          curriculumDict[entry.id] = CurriculumInfo(
            expression: entry.expression,
            layerId: layer.id,
            phaseId: phase.id,
            dosage: entry.dosage
          )
        }

        for strategy in phase.strategies {
          strategyDict[strategy.id] = StrategyInfo(
            strategy: strategy.strategy
          )
        }
      }
    }

    self.curriculumLookup = curriculumDict
    self.strategyLookup = strategyDict
  }

  // MARK: - Public API

  func calculateOverview(
    entries: [LocalJournalEntry],
    startDate: Date,
    endDate: Date
  ) -> AnalyticsOverview {
    guard !entries.isEmpty else {
      return AnalyticsOverview(
        totalEntries: 0,
        currentStreak: 0,
        longestStreak: 0,
        avgFrequency: 0.0,
        lastCheckIn: nil,
        medicinalRatio: 0.0,
        medicinalTrend: 0.0,
        dominantLayerId: nil,
        dominantPhaseId: nil,
        uniqueEmotions: 0,
        strategiesUsed: 0,
        secondaryEmotionsPct: 0.0
      )
    }

    let totalEntries = entries.count

    // Sort by created date descending for streak and last check-in
    let sortedEntries = entries.sorted { $0.createdAt > $1.createdAt }
    let lastCheckIn = sortedEntries.first?.createdAt

    // Streak calculations
    let timestamps = sortedEntries.map(\.createdAt)
    let currentStreak = calculateCurrentStreak(timestamps: timestamps, endDate: endDate)
    let longestStreak = calculateLongestStreak(timestamps: timestamps)

    // Average frequency
    let calendar = Calendar.current
    let daysInPeriod = calendar.dateComponents([.day], from: startDate, to: endDate).day! + 1
    let avgFrequency = Double(totalEntries) / Double(daysInPeriod)

    // Medicinal ratio
    let medicinalRatio = calculateMedicinalRatio(entries: entries)

    // Medicinal trend (compare to previous period)
    let duration = endDate.timeIntervalSince(startDate)
    let prevStartDate = startDate.addingTimeInterval(-duration)
    let prevEndDate = startDate
    let medicinalTrend = calculateMedicinalTrend(
      entries: entries,
      currentStart: startDate,
      currentEnd: endDate,
      prevStart: prevStartDate,
      prevEnd: prevEndDate
    )

    // Dominant layer and phase (last 7 days)
    let sevenDaysAgo = endDate.addingTimeInterval(-7 * 86400)
    let recentEntries = entries.filter { $0.createdAt >= sevenDaysAgo && $0.createdAt <= endDate }
    let (dominantLayerId, dominantPhaseId) = getDominantLayerAndPhase(entries: recentEntries)

    // Unique emotions (distinct curriculum IDs)
    let uniqueEmotions = Set(entries.map(\.curriculumID)).count

    // Strategies used (distinct strategy IDs, excluding nil)
    let strategiesUsed = Set(entries.compactMap(\.strategyID)).count

    // Secondary emotions percentage (as decimal 0-1, not 0-100)
    let entriesWithSecondary = entries.count(where: { $0.secondaryCurriculumID != nil })
    let secondaryEmotionsPct = totalEntries > 0
      ? Double(entriesWithSecondary) / Double(totalEntries)
      : 0.0

    return AnalyticsOverview(
      totalEntries: totalEntries,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      avgFrequency: avgFrequency,
      lastCheckIn: lastCheckIn,
      medicinalRatio: medicinalRatio,
      medicinalTrend: medicinalTrend,
      dominantLayerId: dominantLayerId,
      dominantPhaseId: dominantPhaseId,
      uniqueEmotions: uniqueEmotions,
      strategiesUsed: strategiesUsed,
      secondaryEmotionsPct: secondaryEmotionsPct
    )
  }

  func calculateEmotionalLandscape(
    entries: [LocalJournalEntry],
    limit: Int
  ) -> EmotionalLandscape {
    guard !entries.isEmpty else {
      return EmotionalLandscape(
        layerDistribution: [],
        phaseDistribution: [],
        topEmotions: []
      )
    }

    let totalEntries = entries.count

    // Calculate layer distribution
    var layerCounts: [Int: Int] = [:]
    for entry in entries {
      if let info = curriculumLookup[entry.curriculumID] {
        layerCounts[info.layerId, default: 0] += 1
      }
    }

    let layerDistribution = layerCounts.map { layerId, count in
      LayerDistributionItem(
        layerId: layerId,
        count: count,
        percentage: (Double(count) / Double(totalEntries)) * 100
      )
    }.sorted { $0.layerId < $1.layerId }

    // Calculate phase distribution
    var phaseCounts: [Int: Int] = [:]
    for entry in entries {
      if let info = curriculumLookup[entry.curriculumID] {
        phaseCounts[info.phaseId, default: 0] += 1
      }
    }

    let phaseDistribution = phaseCounts.map { phaseId, count in
      PhaseDistributionItem(
        phaseId: phaseId,
        count: count,
        percentage: (Double(count) / Double(totalEntries)) * 100
      )
    }.sorted { $0.phaseId < $1.phaseId }

    // Calculate top emotions (combine primary + secondary)
    var emotionCounts: [Int: Int] = [:]

    // Count primary emotions
    for entry in entries {
      emotionCounts[entry.curriculumID, default: 0] += 1
    }

    // Count secondary emotions
    for entry in entries {
      if let secondaryId = entry.secondaryCurriculumID {
        emotionCounts[secondaryId, default: 0] += 1
      }
    }

    // Build top emotions list with curriculum info
    let topEmotions = emotionCounts
      .compactMap { curriculumId, count -> TopEmotionItem? in
        guard let info = curriculumLookup[curriculumId] else { return nil }
        return TopEmotionItem(
          curriculumId: curriculumId,
          expression: info.expression,
          layerId: info.layerId,
          phaseId: info.phaseId,
          dosage: info.dosage.rawValue,
          count: count
        )
      }
      .sorted { $0.count > $1.count } // Sort by count descending
      .prefix(limit) // Apply limit
      .map(\.self) // Convert back to array

    return EmotionalLandscape(
      layerDistribution: layerDistribution,
      phaseDistribution: phaseDistribution,
      topEmotions: topEmotions
    )
  }

  func calculateSelfCare(
    entries: [LocalJournalEntry],
    limit: Int
  ) -> SelfCareAnalytics {
    // Filter entries with non-nil strategy IDs
    let strategyEntries = entries.filter { $0.strategyID != nil }

    guard !strategyEntries.isEmpty else {
      return SelfCareAnalytics(
        topStrategies: [],
        diversityScore: 0.0,
        totalStrategyEntries: 0
      )
    }

    // Count strategy occurrences
    var strategyCounts: [Int: Int] = [:]
    for entry in strategyEntries {
      if let strategyId = entry.strategyID {
        strategyCounts[strategyId, default: 0] += 1
      }
    }

    let totalStrategyEntries = strategyEntries.count

    // Calculate diversity score: (unique strategies / total entries) * 100
    let uniqueStrategies = strategyCounts.count
    let diversityScore = (Double(uniqueStrategies) / Double(totalStrategyEntries)) * 100

    // Build top strategies list with strategy text from lookup
    let topStrategiesList = strategyCounts.map { strategyId, count in
      let strategyText = strategyLookup[strategyId]?.strategy ?? "Unknown"
      let percentage = (Double(count) / Double(totalStrategyEntries)) * 100

      return TopStrategyItem(
        strategyId: strategyId,
        strategy: strategyText,
        count: count,
        percentage: percentage
      )
    }
    .sorted { $0.count > $1.count } // Sort by count descending
    .prefix(limit) // Apply limit
    .map(\.self) // Convert back to array

    return SelfCareAnalytics(
      topStrategies: topStrategiesList,
      diversityScore: diversityScore,
      totalStrategyEntries: totalStrategyEntries
    )
  }

  // MARK: - Private Helpers

  /// Calculates current streak of consecutive days with entries.
  ///
  /// Ported from backend `_calculate_streak()` function.
  private func calculateCurrentStreak(timestamps: [Date], endDate: Date) -> Int {
    guard !timestamps.isEmpty else { return 0 }

    let calendar = Calendar.current

    // Extract unique dates sorted descending
    let dates = Set(timestamps.map { calendar.startOfDay(for: $0) })
      .sorted(by: >)

    let endDateOnly = calendar.startOfDay(for: endDate)
    let yesterday = calendar.date(byAdding: .day, value: -1, to: endDateOnly)!

    // If the most recent entry is not today or yesterday, streak is 0
    guard let mostRecent = dates.first, mostRecent >= yesterday else {
      return 0
    }

    // Count consecutive days
    var streak = 0
    var currentDate = mostRecent

    for date in dates {
      if date == currentDate {
        streak += 1
        currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
      } else if date < currentDate {
        // Gap found
        break
      }
    }

    return streak
  }

  /// Calculates the longest streak of consecutive days with entries.
  ///
  /// Ported from backend `_calculate_longest_streak()` function.
  private func calculateLongestStreak(timestamps: [Date]) -> Int {
    guard !timestamps.isEmpty else { return 0 }

    let calendar = Calendar.current

    // Extract unique dates sorted chronologically
    let dates = Set(timestamps.map { calendar.startOfDay(for: $0) })
      .sorted()

    guard !dates.isEmpty else { return 0 }

    var longest = 1
    var current = 1

    for i in 1 ..< dates.count {
      let daysBetween = calendar.dateComponents([.day], from: dates[i - 1], to: dates[i]).day!
      if daysBetween == 1 {
        current += 1
        longest = max(longest, current)
      } else {
        current = 1
      }
    }

    return longest
  }

  /// Calculates percentage of medicinal entries.
  /// Calculates ratio of medicinal entries as decimal (0-1 range, not 0-100).
  private func calculateMedicinalRatio(entries: [LocalJournalEntry]) -> Double {
    guard !entries.isEmpty else { return 0.0 }

    var medicinalCount = 0
    var totalCount = 0

    for entry in entries {
      if let info = curriculumLookup[entry.curriculumID] {
        totalCount += 1
        if info.dosage == .medicinal {
          medicinalCount += 1
        }
      }
    }

    return totalCount > 0 ? Double(medicinalCount) / Double(totalCount) : 0.0
  }

  /// Calculates change in medicinal ratio from previous period.
  private func calculateMedicinalTrend(
    entries: [LocalJournalEntry],
    currentStart: Date,
    currentEnd: Date,
    prevStart: Date,
    prevEnd: Date
  ) -> Double {
    let currentEntries = entries.filter { $0.createdAt >= currentStart && $0.createdAt <= currentEnd }
    let prevEntries = entries.filter { $0.createdAt >= prevStart && $0.createdAt < prevEnd }

    let currentRatio = calculateMedicinalRatio(entries: currentEntries)
    let prevRatio = calculateMedicinalRatio(entries: prevEntries)

    return currentRatio - prevRatio
  }

  /// Gets most frequent layer and phase from entries.
  private func getDominantLayerAndPhase(entries: [LocalJournalEntry]) -> (Int?, Int?) {
    guard !entries.isEmpty else { return (nil, nil) }

    var layerCounts: [Int: Int] = [:]
    var phaseCounts: [Int: Int] = [:]

    for entry in entries {
      if let info = curriculumLookup[entry.curriculumID] {
        layerCounts[info.layerId, default: 0] += 1
        phaseCounts[info.phaseId, default: 0] += 1
      }
    }

    let dominantLayer = layerCounts.max(by: { $0.value < $1.value })?.key
    let dominantPhase = phaseCounts.max(by: { $0.value < $1.value })?.key

    return (dominantLayer, dominantPhase)
  }
}
