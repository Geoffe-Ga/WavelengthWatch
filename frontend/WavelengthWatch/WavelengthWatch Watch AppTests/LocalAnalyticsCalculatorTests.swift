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
            strategies: []
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
            strategies: []
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

  @Test("calculateOverview calculates medicinal ratio correctly")
  func calculateOverview_calculatesMedicinalRatio() {
    let calculator = LocalAnalyticsCalculator(catalog: testCatalog)
    let now = Date()
    // 2 medicinal (IDs 1, 3), 1 toxic (ID 2) = 66.67%
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

    #expect(abs(result.medicinalRatio - 66.67) < 0.1)
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
}
