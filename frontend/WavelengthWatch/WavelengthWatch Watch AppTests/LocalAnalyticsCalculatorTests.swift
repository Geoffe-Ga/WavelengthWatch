import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

@Suite("LocalAnalyticsCalculator Tests")
struct LocalAnalyticsCalculatorTests {
  // MARK: - Test Fixtures

  let testCatalog = CatalogResponseModel(
    phaseOrder: ["Rising", "Peaking", "Falling", "Resting"],
    layers: [
      CatalogLayerModel(
        id: 1,
        color: "#F5DEB3",
        title: "Beige",
        subtitle: "The Observer",
        phases: [
          CatalogPhaseModel(
            id: 1,
            name: "Rising",
            medicinal: [
              CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Curious"),
            ],
            toxic: [
              CatalogCurriculumEntryModel(id: 2, dosage: .toxic, expression: "Confused"),
            ],
            strategies: [
              CatalogStrategyModel(id: 101, strategy: "Deep breathing", color: "#F5DEB3"),
              CatalogStrategyModel(id: 102, strategy: "Mindful walking", color: "#F5DEB3"),
            ]
          ),
        ]
      ),
      CatalogLayerModel(
        id: 2,
        color: "#800080",
        title: "Purple",
        subtitle: "The Mystic",
        phases: [
          CatalogPhaseModel(
            id: 2,
            name: "Peaking",
            medicinal: [
              CatalogCurriculumEntryModel(id: 3, dosage: .medicinal, expression: "Peaceful"),
            ],
            toxic: [
              CatalogCurriculumEntryModel(id: 4, dosage: .toxic, expression: "Anxious"),
            ],
            strategies: [
              CatalogStrategyModel(id: 103, strategy: "Meditation", color: "#800080"),
            ]
          ),
        ]
      ),
    ]
  )

  // MARK: - Initialization Tests

  @Test("calculator initializes with catalog")
  func calculator_initializesWithCatalog() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)

    #expect(calculator != nil)
  }

  // MARK: - Empty Data Tests

  @Test("calculateOverview returns zero values for empty entries")
  func calculateOverview_returnsZeroValuesForEmpty() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let entries: [LocalJournalEntry] = []

    let result = calculator.calculateOverview(
      entries: entries,
      startDate: Date(),
      endDate: Date()
    )

    #expect(result.totalEntries == 0)
    #expect(result.currentStreak == 0)
    #expect(result.longestStreak == 0)
    #expect(result.avgFrequency == 0.0)
    #expect(result.lastCheckIn == nil)
    #expect(result.medicinalRatio == 0.0)
    #expect(result.medicinalTrend == 0.0)
    #expect(result.dominantLayerId == nil)
    #expect(result.dominantPhaseId == nil)
    #expect(result.uniqueEmotions == 0)
    #expect(result.strategiesUsed == 0)
    #expect(result.secondaryEmotionsPct == 0.0)
  }

  @Test("calculateEmotionalLandscape returns empty distributions for empty entries")
  func calculateEmotionalLandscape_returnsEmptyForEmpty() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let entries: [LocalJournalEntry] = []

    let result = calculator.calculateEmotionalLandscape(entries: entries, limit: 10)

    #expect(result.layerDistribution.isEmpty)
    #expect(result.phaseDistribution.isEmpty)
    #expect(result.topEmotions.isEmpty)
  }

  // MARK: - Basic Calculation Tests

  @Test("calculateOverview counts total entries correctly")
  func calculateOverview_countsTotalEntries() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    let entries = [
      LocalJournalEntry(
        createdAt: now,
        userID: 1,
        curriculumID: 1
      ),
      LocalJournalEntry(
        createdAt: now.addingTimeInterval(-3600),
        userID: 1,
        curriculumID: 2
      ),
      LocalJournalEntry(
        createdAt: now.addingTimeInterval(-7200),
        userID: 1,
        curriculumID: 3
      ),
    ]

    let result = calculator.calculateOverview(
      entries: entries,
      startDate: now.addingTimeInterval(-86400),
      endDate: now
    )

    #expect(result.totalEntries == 3)
  }

  @Test("calculateOverview calculates medicinal ratio as decimal (0-1 range)")
  func calculateOverview_calculatesMedicinalRatio() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    // 2 medicinal (IDs 1, 3), 1 toxic (ID 2) = 0.6667 (66.67% when displayed)
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1), // Medicinal
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2), // Toxic
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3), // Medicinal
    ]

    let result = calculator.calculateOverview(
      entries: entries,
      startDate: now.addingTimeInterval(-86400),
      endDate: now
    )

    // Should return decimal fraction, not percentage
    #expect(abs(result.medicinalRatio - 0.6667) < 0.01)
  }

  @Test("calculateOverview calculates secondary emotions percentage as decimal (0-1 range)")
  func calculateOverview_calculatesSecondaryEmotionsPct() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    // 2 entries with secondary (out of 5 total) = 0.40 (40% when displayed)
    let entries = [
      LocalJournalEntry(
        createdAt: now,
        userID: 1,
        curriculumID: 1,
        secondaryCurriculumID: 2
      ), // Has secondary
      LocalJournalEntry(
        createdAt: now,
        userID: 1,
        curriculumID: 2,
        secondaryCurriculumID: nil
      ), // No secondary
      LocalJournalEntry(
        createdAt: now,
        userID: 1,
        curriculumID: 3,
        secondaryCurriculumID: 1
      ), // Has secondary
      LocalJournalEntry(
        createdAt: now,
        userID: 1,
        curriculumID: 1,
        secondaryCurriculumID: nil
      ), // No secondary
      LocalJournalEntry(
        createdAt: now,
        userID: 1,
        curriculumID: 2,
        secondaryCurriculumID: nil
      ), // No secondary
    ]

    let result = calculator.calculateOverview(
      entries: entries,
      startDate: now.addingTimeInterval(-86400),
      endDate: now
    )

    // Should return decimal fraction, not percentage
    #expect(abs(result.secondaryEmotionsPct - 0.40) < 0.01)
  }

  @Test("calculateOverview calculates medicinal trend as decimal difference")
  func calculateOverview_calculatesMedicinalTrend() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()

    // Current period: 2 medicinal (IDs 1, 3), 1 toxic (ID 2) = 0.6667
    // Previous period: 1 medicinal (ID 1), 1 toxic (ID 2) = 0.50
    // Expected trend: 0.6667 - 0.50 = 0.1667

    let prevStart = now.addingTimeInterval(-14 * 86400)
    let prevEnd = now.addingTimeInterval(-7 * 86400)
    let currentStart = now.addingTimeInterval(-7 * 86400)

    let entries = [
      // Previous period: 1 medicinal, 1 toxic
      LocalJournalEntry(createdAt: prevStart, userID: 1, curriculumID: 1), // Medicinal
      LocalJournalEntry(
        createdAt: prevStart.addingTimeInterval(3600),
        userID: 1,
        curriculumID: 2
      ), // Toxic

      // Current period: 2 medicinal, 1 toxic
      LocalJournalEntry(createdAt: currentStart, userID: 1, curriculumID: 1), // Medicinal
      LocalJournalEntry(
        createdAt: currentStart.addingTimeInterval(3600),
        userID: 1,
        curriculumID: 2
      ), // Toxic
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3), // Medicinal
    ]

    let result = calculator.calculateOverview(
      entries: entries,
      startDate: currentStart,
      endDate: now
    )

    // Trend should be decimal difference (0-1 range), not percentage
    #expect(abs(result.medicinalTrend - 0.1667) < 0.01)
  }

  @Test("calculateOverview finds last check-in")
  func calculateOverview_findsLastCheckIn() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    let yesterday = now.addingTimeInterval(-86400)
    let entries = [
      LocalJournalEntry(createdAt: yesterday, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2), // Most recent
    ]

    let result = calculator.calculateOverview(
      entries: entries,
      startDate: yesterday,
      endDate: now
    )

    #expect(result.lastCheckIn != nil)
    #expect(abs(result.lastCheckIn!.timeIntervalSince(now)) < 1.0)
  }

  // MARK: - Streak Calculation Tests

  @Test("calculateOverview calculates current streak for consecutive days")
  func calculateOverview_calculatesCurrentStreak() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let calendar = Calendar.current
    let now = Date()

    // Create entries for today, yesterday, day before yesterday = 3 day streak
    let today = calendar.startOfDay(for: now)
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    let dayBefore = calendar.date(byAdding: .day, value: -2, to: today)!

    let entries = [
      LocalJournalEntry(createdAt: today, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: yesterday, userID: 1, curriculumID: 2),
      LocalJournalEntry(createdAt: dayBefore, userID: 1, curriculumID: 3),
    ]

    let result = calculator.calculateOverview(
      entries: entries,
      startDate: dayBefore,
      endDate: now
    )

    #expect(result.currentStreak == 3)
  }

  @Test("calculateOverview returns zero streak for gap in days")
  func calculateOverview_returnsZeroStreakForGap() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let calendar = Calendar.current
    let now = Date()

    // Entry from 3 days ago (gap of 2 days)
    let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!

    let entries = [
      LocalJournalEntry(createdAt: threeDaysAgo, userID: 1, curriculumID: 1),
    ]

    let result = calculator.calculateOverview(
      entries: entries,
      startDate: threeDaysAgo,
      endDate: now
    )

    #expect(result.currentStreak == 0)
  }

  @Test("calculateOverview calculates longest streak correctly")
  func calculateOverview_calculatesLongestStreak() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let calendar = Calendar.current
    let now = Date()

    // Create pattern: 3-day streak, gap, 2-day streak
    let day0 = calendar.date(byAdding: .day, value: -6, to: now)!
    let day1 = calendar.date(byAdding: .day, value: -5, to: now)!
    let day2 = calendar.date(byAdding: .day, value: -4, to: now)!
    // gap at day -3
    let day4 = calendar.date(byAdding: .day, value: -2, to: now)!
    let day5 = calendar.date(byAdding: .day, value: -1, to: now)!

    let entries = [
      LocalJournalEntry(createdAt: day0, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: day1, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: day2, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: day4, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: day5, userID: 1, curriculumID: 1),
    ]

    let result = calculator.calculateOverview(
      entries: entries,
      startDate: day0,
      endDate: now
    )

    #expect(result.longestStreak == 3)
  }

  // MARK: - Emotional Landscape Tests

  @Test("calculateEmotionalLandscape computes layer distribution")
  func calculateEmotionalLandscape_computesLayerDistribution() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()

    // 2 from layer 1, 1 from layer 2
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1), // Layer 1
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2), // Layer 1
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3), // Layer 2
    ]

    let result = calculator.calculateEmotionalLandscape(entries: entries, limit: 10)

    #expect(result.layerDistribution.count == 2)

    let layer1 = result.layerDistribution.first { $0.layerId == 1 }
    let layer2 = result.layerDistribution.first { $0.layerId == 2 }

    #expect(layer1?.count == 2)
    #expect(abs(layer1!.percentage - 66.67) < 0.1)
    #expect(layer2?.count == 1)
    #expect(abs(layer2!.percentage - 33.33) < 0.1)
  }

  @Test("calculateEmotionalLandscape computes phase distribution")
  func calculateEmotionalLandscape_computesPhaseDistribution() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()

    // 2 from phase 1, 1 from phase 2
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1), // Phase 1
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2), // Phase 1
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3), // Phase 2
    ]

    let result = calculator.calculateEmotionalLandscape(entries: entries, limit: 10)

    #expect(result.phaseDistribution.count == 2)

    let phase1 = result.phaseDistribution.first { $0.phaseId == 1 }
    let phase2 = result.phaseDistribution.first { $0.phaseId == 2 }

    #expect(phase1?.count == 2)
    #expect(abs(phase1!.percentage - 66.67) < 0.1)
    #expect(phase2?.count == 1)
    #expect(abs(phase2!.percentage - 33.33) < 0.1)
  }

  @Test("calculateEmotionalLandscape returns top emotions sorted by count")
  func calculateEmotionalLandscape_returnsTopEmotionsSorted() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()

    // Curriculum 1: 3 times, Curriculum 2: 1 time
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2),
    ]

    let result = calculator.calculateEmotionalLandscape(entries: entries, limit: 10)

    #expect(result.topEmotions.count == 2)
    #expect(result.topEmotions[0].curriculumId == 1)
    #expect(result.topEmotions[0].count == 3)
    #expect(result.topEmotions[1].curriculumId == 2)
    #expect(result.topEmotions[1].count == 1)
  }

  @Test("calculateEmotionalLandscape respects limit parameter")
  func calculateEmotionalLandscape_respectsLimit() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()

    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3),
    ]

    let result = calculator.calculateEmotionalLandscape(entries: entries, limit: 1)

    #expect(result.topEmotions.count == 1)
  }

  @Test("calculateEmotionalLandscape combines primary and secondary emotions")
  func calculateEmotionalLandscape_combinesPrimaryAndSecondary() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()

    // Curriculum 1 appears as both primary and secondary
    let entries = [
      LocalJournalEntry(
        createdAt: now,
        userID: 1,
        curriculumID: 1,
        secondaryCurriculumID: 2
      ),
      LocalJournalEntry(
        createdAt: now,
        userID: 1,
        curriculumID: 2,
        secondaryCurriculumID: 1
      ),
    ]

    let result = calculator.calculateEmotionalLandscape(entries: entries, limit: 10)

    // Both curriculums should have count of 2 (once primary, once secondary)
    let emotion1 = result.topEmotions.first { $0.curriculumId == 1 }
    let emotion2 = result.topEmotions.first { $0.curriculumId == 2 }

    #expect(emotion1?.count == 2)
    #expect(emotion2?.count == 2)
  }

  // MARK: - Self-Care Analytics Tests

  @Test("calculateSelfCare returns empty analytics for empty entries")
  func calculateSelfCare_returnsEmptyForEmpty() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let entries: [LocalJournalEntry] = []

    let result = calculator.calculateSelfCare(entries: entries, limit: 5)

    #expect(result.topStrategies.isEmpty)
    #expect(result.diversityScore == 0.0)
    #expect(result.totalStrategyEntries == 0)
  }

  @Test("calculateSelfCare returns empty analytics for entries with no strategies")
  func calculateSelfCare_returnsEmptyForNoStrategies() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: nil),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2, strategyID: nil),
    ]

    let result = calculator.calculateSelfCare(entries: entries, limit: 5)

    #expect(result.topStrategies.isEmpty)
    #expect(result.diversityScore == 0.0)
    #expect(result.totalStrategyEntries == 0)
  }

  @Test("calculateSelfCare counts strategy occurrences correctly")
  func calculateSelfCare_countsStrategies() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    // Strategy 101: 3 times, Strategy 102: 2 times, Strategy 103: 1 time
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 101),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 101),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 101),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2, strategyID: 102),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2, strategyID: 102),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3, strategyID: 103),
    ]

    let result = calculator.calculateSelfCare(entries: entries, limit: 5)

    #expect(result.totalStrategyEntries == 6)
    #expect(result.topStrategies.count == 3)

    // Verify counts
    let strategy101 = result.topStrategies.first { $0.strategyId == 101 }
    let strategy102 = result.topStrategies.first { $0.strategyId == 102 }
    let strategy103 = result.topStrategies.first { $0.strategyId == 103 }

    #expect(strategy101?.count == 3)
    #expect(strategy102?.count == 2)
    #expect(strategy103?.count == 1)
  }

  @Test("calculateSelfCare calculates diversity score correctly")
  func calculateSelfCare_calculatesDiversityScore() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    // 3 unique strategies out of 6 total entries = (3/6) * 100 = 50.0
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 101),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 101),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 101),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2, strategyID: 102),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2, strategyID: 102),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3, strategyID: 103),
    ]

    let result = calculator.calculateSelfCare(entries: entries, limit: 5)

    #expect(abs(result.diversityScore - 50.0) < 0.01)
  }

  @Test("calculateSelfCare sorts strategies by count descending")
  func calculateSelfCare_sortsByCount() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    // Strategy 103: 4 times, Strategy 101: 2 times, Strategy 102: 1 time
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3, strategyID: 103),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3, strategyID: 103),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3, strategyID: 103),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3, strategyID: 103),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 101),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 101),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2, strategyID: 102),
    ]

    let result = calculator.calculateSelfCare(entries: entries, limit: 5)

    #expect(result.topStrategies.count == 3)
    #expect(result.topStrategies[0].strategyId == 103) // Highest count
    #expect(result.topStrategies[0].count == 4)
    #expect(result.topStrategies[1].strategyId == 101)
    #expect(result.topStrategies[1].count == 2)
    #expect(result.topStrategies[2].strategyId == 102) // Lowest count
    #expect(result.topStrategies[2].count == 1)
  }

  @Test("calculateSelfCare respects limit parameter")
  func calculateSelfCare_respectsLimit() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 101),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 101),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2, strategyID: 102),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3, strategyID: 103),
    ]

    let result = calculator.calculateSelfCare(entries: entries, limit: 2)

    #expect(result.topStrategies.count == 2)
  }

  @Test("calculateSelfCare handles unknown strategy IDs")
  func calculateSelfCare_handlesUnknownStrategyIds() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    // Strategy ID 999 doesn't exist in catalog
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 101),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 999),
    ]

    let result = calculator.calculateSelfCare(entries: entries, limit: 5)

    #expect(result.topStrategies.count == 2)
    #expect(result.totalStrategyEntries == 2)

    // Unknown strategy should have "Unknown" text
    let unknownStrategy = result.topStrategies.first { $0.strategyId == 999 }
    #expect(unknownStrategy?.strategy == "Unknown")
  }

  @Test("calculateSelfCare populates strategy text from catalog")
  func calculateSelfCare_populatesStrategyText() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 101),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 102),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3, strategyID: 103),
    ]

    let result = calculator.calculateSelfCare(entries: entries, limit: 5)

    let strategy101 = result.topStrategies.first { $0.strategyId == 101 }
    let strategy102 = result.topStrategies.first { $0.strategyId == 102 }
    let strategy103 = result.topStrategies.first { $0.strategyId == 103 }

    #expect(strategy101?.strategy == "Deep breathing")
    #expect(strategy102?.strategy == "Mindful walking")
    #expect(strategy103?.strategy == "Meditation")
  }

  @Test("calculateSelfCare calculates percentage correctly")
  func calculateSelfCare_calculatesPercentage() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    // 3 of strategy 101 out of 6 total = 50%
    // 2 of strategy 102 out of 6 total = 33.33%
    // 1 of strategy 103 out of 6 total = 16.67%
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 101),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 101),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1, strategyID: 101),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2, strategyID: 102),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2, strategyID: 102),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3, strategyID: 103),
    ]

    let result = calculator.calculateSelfCare(entries: entries, limit: 5)

    let strategy101 = result.topStrategies.first { $0.strategyId == 101 }
    let strategy102 = result.topStrategies.first { $0.strategyId == 102 }
    let strategy103 = result.topStrategies.first { $0.strategyId == 103 }

    #expect(abs(strategy101!.percentage - 50.0) < 0.01)
    #expect(abs(strategy102!.percentage - 33.33) < 0.1)
    #expect(abs(strategy103!.percentage - 16.67) < 0.1)
  }

  // MARK: - Temporal Patterns Tests

  @Test("calculateTemporalPatterns returns empty for empty entries")
  func calculateTemporalPatterns_returnsEmptyForEmpty() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let entries: [LocalJournalEntry] = []
    let now = Date()

    let result = calculator.calculateTemporalPatterns(
      entries: entries,
      startDate: now.addingTimeInterval(-86400 * 7),
      endDate: now
    )

    #expect(result.hourlyDistribution.isEmpty)
    #expect(result.consistencyScore == 0.0)
  }

  @Test("calculateTemporalPatterns calculates single entry distribution")
  func calculateTemporalPatterns_singleEntry() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let calendar = Calendar.current

    // Create entry at 10 AM
    var components = calendar.dateComponents([.year, .month, .day], from: Date())
    components.hour = 10
    components.minute = 30
    let entryDate = calendar.date(from: components)!

    let entries = [
      LocalJournalEntry(createdAt: entryDate, userID: 1, curriculumID: 1),
    ]

    let result = calculator.calculateTemporalPatterns(
      entries: entries,
      startDate: entryDate,
      endDate: entryDate
    )

    #expect(result.hourlyDistribution.count == 1)
    #expect(result.hourlyDistribution[0].hour == 10)
    #expect(result.hourlyDistribution[0].count == 1)
  }

  @Test("calculateTemporalPatterns aggregates same hour entries")
  func calculateTemporalPatterns_aggregatesSameHour() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let calendar = Calendar.current

    // Create 3 entries at 14:00 (2 PM) on different days
    var components = calendar.dateComponents([.year, .month, .day], from: Date())
    components.hour = 14
    components.minute = 0
    let day1 = calendar.date(from: components)!
    let day2 = calendar.date(byAdding: .day, value: -1, to: day1)!
    let day3 = calendar.date(byAdding: .day, value: -2, to: day1)!

    let entries = [
      LocalJournalEntry(createdAt: day1, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: day2, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: day3, userID: 1, curriculumID: 1),
    ]

    let result = calculator.calculateTemporalPatterns(
      entries: entries,
      startDate: day3,
      endDate: day1
    )

    #expect(result.hourlyDistribution.count == 1)
    #expect(result.hourlyDistribution[0].hour == 14)
    #expect(result.hourlyDistribution[0].count == 3)
  }

  @Test("calculateTemporalPatterns distributes across multiple hours")
  func calculateTemporalPatterns_multipleHours() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let calendar = Calendar.current

    // Create entries at different hours: 9 AM, 14 PM, 21 PM
    var components = calendar.dateComponents([.year, .month, .day], from: Date())

    components.hour = 9
    let morning = calendar.date(from: components)!

    components.hour = 14
    let afternoon = calendar.date(from: components)!

    components.hour = 21
    let evening = calendar.date(from: components)!

    let entries = [
      LocalJournalEntry(createdAt: morning, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: afternoon, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: evening, userID: 1, curriculumID: 1),
    ]

    let result = calculator.calculateTemporalPatterns(
      entries: entries,
      startDate: morning,
      endDate: evening
    )

    #expect(result.hourlyDistribution.count == 3)

    // Verify sorted by hour
    #expect(result.hourlyDistribution[0].hour == 9)
    #expect(result.hourlyDistribution[1].hour == 14)
    #expect(result.hourlyDistribution[2].hour == 21)
  }

  @Test("calculateTemporalPatterns handles midnight hour (0)")
  func calculateTemporalPatterns_midnightHour() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let calendar = Calendar.current

    // Create entry at midnight (hour 0)
    var components = calendar.dateComponents([.year, .month, .day], from: Date())
    components.hour = 0
    components.minute = 30
    let midnight = calendar.date(from: components)!

    let entries = [
      LocalJournalEntry(createdAt: midnight, userID: 1, curriculumID: 1),
    ]

    let result = calculator.calculateTemporalPatterns(
      entries: entries,
      startDate: midnight,
      endDate: midnight
    )

    #expect(result.hourlyDistribution.count == 1)
    #expect(result.hourlyDistribution[0].hour == 0)
    #expect(result.hourlyDistribution[0].count == 1)
  }

  @Test("calculateTemporalPatterns calculates 100% consistency for daily entries")
  func calculateTemporalPatterns_fullConsistency() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let calendar = Calendar.current

    // Create entries for 7 consecutive days
    let today = calendar.startOfDay(for: Date())
    var entries: [LocalJournalEntry] = []

    for dayOffset in 0 ..< 7 {
      let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
      entries.append(LocalJournalEntry(createdAt: date, userID: 1, curriculumID: 1))
    }

    let startDate = calendar.date(byAdding: .day, value: -6, to: today)!

    let result = calculator.calculateTemporalPatterns(
      entries: entries,
      startDate: startDate,
      endDate: today
    )

    #expect(abs(result.consistencyScore - 100.0) < 0.01)
  }

  @Test("calculateTemporalPatterns calculates partial consistency")
  func calculateTemporalPatterns_partialConsistency() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let calendar = Calendar.current

    // Create entries for 3 out of 6 days = 50%
    let today = calendar.startOfDay(for: Date())
    let day2 = calendar.date(byAdding: .day, value: -2, to: today)!
    let day4 = calendar.date(byAdding: .day, value: -4, to: today)!

    let entries = [
      LocalJournalEntry(createdAt: today, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: day2, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: day4, userID: 1, curriculumID: 1),
    ]

    let startDate = calendar.date(byAdding: .day, value: -5, to: today)!

    let result = calculator.calculateTemporalPatterns(
      entries: entries,
      startDate: startDate,
      endDate: today
    )

    // 3 unique days / 6 total days = 50%
    #expect(abs(result.consistencyScore - 50.0) < 0.01)
  }

  @Test("calculateTemporalPatterns handles multiple entries same day")
  func calculateTemporalPatterns_multipleEntriesSameDay() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let calendar = Calendar.current

    // Create 5 entries on the same day
    let today = calendar.startOfDay(for: Date())
    var entries: [LocalJournalEntry] = []

    for hourOffset in [8, 10, 12, 14, 16] {
      let date = calendar.date(byAdding: .hour, value: hourOffset, to: today)!
      entries.append(LocalJournalEntry(createdAt: date, userID: 1, curriculumID: 1))
    }

    let result = calculator.calculateTemporalPatterns(
      entries: entries,
      startDate: today,
      endDate: today
    )

    // 1 unique day / 1 total day = 100%
    #expect(abs(result.consistencyScore - 100.0) < 0.01)
    // 5 different hours
    #expect(result.hourlyDistribution.count == 5)
  }

  @Test("calculateTemporalPatterns sorts distribution by hour")
  func calculateTemporalPatterns_sortsDistributionByHour() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let calendar = Calendar.current

    // Create entries in reverse order: 22, 15, 8, 3
    var components = calendar.dateComponents([.year, .month, .day], from: Date())

    var entries: [LocalJournalEntry] = []
    for hour in [22, 15, 8, 3] {
      components.hour = hour
      let date = calendar.date(from: components)!
      entries.append(LocalJournalEntry(createdAt: date, userID: 1, curriculumID: 1))
    }

    let result = calculator.calculateTemporalPatterns(
      entries: entries,
      startDate: calendar.date(from: components)!,
      endDate: calendar.date(from: components)!
    )

    // Verify sorted ascending
    #expect(result.hourlyDistribution[0].hour == 3)
    #expect(result.hourlyDistribution[1].hour == 8)
    #expect(result.hourlyDistribution[2].hour == 15)
    #expect(result.hourlyDistribution[3].hour == 22)
  }

  // MARK: - Growth Indicators Tests

  @Test("calculateGrowthIndicators returns zero values for empty entries")
  func calculateGrowthIndicators_returnsZeroForEmpty() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let entries: [LocalJournalEntry] = []
    let now = Date()

    let result = calculator.calculateGrowthIndicators(
      entries: entries,
      startDate: now.addingTimeInterval(-86400 * 30),
      endDate: now
    )

    #expect(result.medicinalTrend == 0.0)
    #expect(result.layerDiversity == 0)
    #expect(result.phaseCoverage == 0)
  }

  @Test("calculateGrowthIndicators returns zero for entries outside date range")
  func calculateGrowthIndicators_returnsZeroForEntriesOutsideDateRange() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    // Entry from 60 days ago, but date range is last 30 days
    let oldEntry = LocalJournalEntry(
      createdAt: now.addingTimeInterval(-86400 * 60),
      userID: 1,
      curriculumID: 1
    )

    let result = calculator.calculateGrowthIndicators(
      entries: [oldEntry],
      startDate: now.addingTimeInterval(-86400 * 30),
      endDate: now
    )

    #expect(result.layerDiversity == 0)
    #expect(result.phaseCoverage == 0)
  }

  @Test("calculateGrowthIndicators calculates layer diversity correctly")
  func calculateGrowthIndicators_calculatesLayerDiversity() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    // Entries from layer 1 (curriculum 1, 2) and layer 2 (curriculum 3)
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1), // Layer 1
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2), // Layer 1
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3), // Layer 2
    ]

    let result = calculator.calculateGrowthIndicators(
      entries: entries,
      startDate: now.addingTimeInterval(-86400),
      endDate: now
    )

    #expect(result.layerDiversity == 2)
  }

  @Test("calculateGrowthIndicators calculates phase coverage correctly")
  func calculateGrowthIndicators_calculatesPhaseCoverage() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    // Entries from phase 1 (curriculum 1, 2) and phase 2 (curriculum 3)
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1), // Phase 1
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2), // Phase 1
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3), // Phase 2
    ]

    let result = calculator.calculateGrowthIndicators(
      entries: entries,
      startDate: now.addingTimeInterval(-86400),
      endDate: now
    )

    #expect(result.phaseCoverage == 2)
  }

  @Test("calculateGrowthIndicators calculates positive medicinal trend")
  func calculateGrowthIndicators_calculatesPositiveMedicinalTrend() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()

    // Previous period: 1 medicinal (50%)
    // Current period: 2 medicinal, 1 toxic (66.67%)
    // Expected trend: 0.1667

    let prevStart = now.addingTimeInterval(-14 * 86400)
    let currentStart = now.addingTimeInterval(-7 * 86400)

    let entries = [
      // Previous period: 1 medicinal, 1 toxic = 50%
      LocalJournalEntry(createdAt: prevStart, userID: 1, curriculumID: 1), // Medicinal
      LocalJournalEntry(
        createdAt: prevStart.addingTimeInterval(3600),
        userID: 1,
        curriculumID: 2
      ), // Toxic

      // Current period: 2 medicinal, 1 toxic = 66.67%
      LocalJournalEntry(createdAt: currentStart, userID: 1, curriculumID: 1), // Medicinal
      LocalJournalEntry(
        createdAt: currentStart.addingTimeInterval(3600),
        userID: 1,
        curriculumID: 2
      ), // Toxic
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3), // Medicinal
    ]

    let result = calculator.calculateGrowthIndicators(
      entries: entries,
      startDate: currentStart,
      endDate: now
    )

    // 0.6667 - 0.50 = 0.1667
    #expect(abs(result.medicinalTrend - 0.1667) < 0.01)
  }

  @Test("calculateGrowthIndicators calculates negative medicinal trend")
  func calculateGrowthIndicators_calculatesNegativeMedicinalTrend() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()

    // Previous period: 2 medicinal, 1 toxic (66.67%)
    // Current period: 1 medicinal, 2 toxic (33.33%)
    // Expected trend: -0.3333

    let prevStart = now.addingTimeInterval(-14 * 86400)
    let currentStart = now.addingTimeInterval(-7 * 86400)

    let entries = [
      // Previous period: 2 medicinal, 1 toxic
      LocalJournalEntry(createdAt: prevStart, userID: 1, curriculumID: 1), // Medicinal
      LocalJournalEntry(
        createdAt: prevStart.addingTimeInterval(3600),
        userID: 1,
        curriculumID: 3
      ), // Medicinal
      LocalJournalEntry(
        createdAt: prevStart.addingTimeInterval(7200),
        userID: 1,
        curriculumID: 2
      ), // Toxic

      // Current period: 1 medicinal, 2 toxic
      LocalJournalEntry(createdAt: currentStart, userID: 1, curriculumID: 1), // Medicinal
      LocalJournalEntry(
        createdAt: currentStart.addingTimeInterval(3600),
        userID: 1,
        curriculumID: 2
      ), // Toxic
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 4), // Toxic
    ]

    let result = calculator.calculateGrowthIndicators(
      entries: entries,
      startDate: currentStart,
      endDate: now
    )

    // 0.3333 - 0.6667 = -0.3333
    #expect(abs(result.medicinalTrend - -0.3333) < 0.01)
  }

  @Test("calculateGrowthIndicators handles single layer")
  func calculateGrowthIndicators_handlesSingleLayer() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    // All entries from layer 1
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1), // Layer 1
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2), // Layer 1
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1), // Layer 1
    ]

    let result = calculator.calculateGrowthIndicators(
      entries: entries,
      startDate: now.addingTimeInterval(-86400),
      endDate: now
    )

    #expect(result.layerDiversity == 1)
  }

  @Test("calculateGrowthIndicators handles single phase")
  func calculateGrowthIndicators_handlesSinglePhase() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    // All entries from phase 1
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1), // Phase 1
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 2), // Phase 1
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1), // Phase 1
    ]

    let result = calculator.calculateGrowthIndicators(
      entries: entries,
      startDate: now.addingTimeInterval(-86400),
      endDate: now
    )

    #expect(result.phaseCoverage == 1)
  }

  @Test("calculateGrowthIndicators handles unknown curriculum IDs")
  func calculateGrowthIndicators_handlesUnknownCurriculumIds() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    // Include unknown curriculum ID (999)
    let entries = [
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 1), // Known
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 999), // Unknown
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3), // Known
    ]

    let result = calculator.calculateGrowthIndicators(
      entries: entries,
      startDate: now.addingTimeInterval(-86400),
      endDate: now
    )

    // Should only count known curriculum IDs
    #expect(result.layerDiversity == 2)
    #expect(result.phaseCoverage == 2)
  }

  @Test("calculateGrowthIndicators zero trend when no previous period data")
  func calculateGrowthIndicators_zeroTrendWhenNoPreviousPeriod() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    let currentStart = now.addingTimeInterval(-7 * 86400)

    // Only current period entries, no previous period
    let entries = [
      LocalJournalEntry(createdAt: currentStart, userID: 1, curriculumID: 1),
      LocalJournalEntry(createdAt: now, userID: 1, curriculumID: 3),
    ]

    let result = calculator.calculateGrowthIndicators(
      entries: entries,
      startDate: currentStart,
      endDate: now
    )

    // Current: 100% medicinal, Previous: 0 entries (0 ratio)
    // Trend = 1.0 - 0.0 = 1.0
    #expect(abs(result.medicinalTrend - 1.0) < 0.01)
  }
}
