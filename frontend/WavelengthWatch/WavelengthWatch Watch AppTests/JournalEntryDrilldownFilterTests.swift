import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

/// Tests for `JournalEntryDrilldownFilter.matches` predicate and
/// `JournalEntryListView` catalog lookup builders. These cover the
/// drill-down wiring for issue #260.
struct JournalEntryDrilldownFilterTests {
  // MARK: - Helpers

  private static func makeEntry(
    curriculumID: Int? = nil,
    secondaryCurriculumID: Int? = nil,
    strategyID: Int? = nil,
    createdAt: Date = Date()
  ) -> LocalJournalEntry {
    LocalJournalEntry(
      createdAt: createdAt,
      userID: 1,
      curriculumID: curriculumID,
      secondaryCurriculumID: secondaryCurriculumID,
      strategyID: strategyID,
      initiatedBy: .self_initiated,
      entryType: .emotion
    )
  }

  private static let sampleCatalog: CatalogResponseModel = {
    let breathing = CatalogStrategyModel(id: 100, strategy: "Deep breathing", color: "blue")
    let meditation = CatalogStrategyModel(id: 101, strategy: "Meditation", color: "purple")

    let joy = CatalogCurriculumEntryModel(id: 10, dosage: .medicinal, expression: "Joy")
    let calm = CatalogCurriculumEntryModel(id: 11, dosage: .medicinal, expression: "Calm")
    let anger = CatalogCurriculumEntryModel(id: 12, dosage: .toxic, expression: "Rage")
    let grief = CatalogCurriculumEntryModel(id: 20, dosage: .toxic, expression: "Grief")

    let risingPhase = CatalogPhaseModel(
      id: 1,
      name: "Rising",
      medicinal: [joy, calm],
      toxic: [anger],
      strategies: [breathing]
    )
    let peakingPhase = CatalogPhaseModel(
      id: 2,
      name: "Peaking",
      medicinal: [],
      toxic: [grief],
      strategies: [meditation]
    )

    let redLayer = CatalogLayerModel(
      id: 50,
      color: "red",
      title: "Red",
      subtitle: "",
      phases: [risingPhase]
    )
    let purpleLayer = CatalogLayerModel(
      id: 51,
      color: "purple",
      title: "Purple",
      subtitle: "",
      phases: [peakingPhase]
    )

    return CatalogResponseModel(
      phaseOrder: ["Rising", "Peaking"],
      layers: [redLayer, purpleLayer]
    )
  }()

  // MARK: - byStrategy

  @Test("byStrategy matches entries with same strategyID")
  func byStrategy_matchesEntriesWithSameStrategyID() {
    let filter = JournalEntryDrilldownFilter.byStrategy(strategyId: 100, name: "Deep breathing")
    let match = Self.makeEntry(strategyID: 100)
    let other = Self.makeEntry(strategyID: 101)
    let noStrategy = Self.makeEntry(strategyID: nil)

    #expect(filter.matches(match))
    #expect(!filter.matches(other))
    #expect(!filter.matches(noStrategy))
  }

  // MARK: - byPhase

  @Test("byPhase matches via curriculumID → phase lookup")
  func byPhase_matchesViaCurriculumLookup() {
    let filter = JournalEntryDrilldownFilter.byPhase(phaseId: 1, name: "Rising")
    let lookup = JournalEntryListView.buildCurriculumPhaseLookup(catalog: Self.sampleCatalog)

    let rising = Self.makeEntry(curriculumID: 10) // maps to phase 1
    let peaking = Self.makeEntry(curriculumID: 20) // maps to phase 2
    let unknown = Self.makeEntry(curriculumID: 999)
    let noCurriculum = Self.makeEntry(curriculumID: nil)

    #expect(filter.matches(rising, curriculumPhaseById: lookup))
    #expect(!filter.matches(peaking, curriculumPhaseById: lookup))
    #expect(!filter.matches(unknown, curriculumPhaseById: lookup))
    #expect(!filter.matches(noCurriculum, curriculumPhaseById: lookup))
  }

  // MARK: - byLayer

  @Test("byLayer matches via curriculumID → layer lookup")
  func byLayer_matchesViaCurriculumLookup() {
    let filter = JournalEntryDrilldownFilter.byLayer(layerId: 50, name: "Red")
    let lookup = JournalEntryListView.buildCurriculumLayerLookup(catalog: Self.sampleCatalog)

    let red = Self.makeEntry(curriculumID: 10) // maps to layer 50
    let purple = Self.makeEntry(curriculumID: 20) // maps to layer 51

    #expect(filter.matches(red, curriculumLayerById: lookup))
    #expect(!filter.matches(purple, curriculumLayerById: lookup))
  }

  // MARK: - byCurriculum

  @Test("byCurriculum matches primary or secondary curriculum ID")
  func byCurriculum_matchesPrimaryOrSecondary() {
    let filter = JournalEntryDrilldownFilter.byCurriculum(curriculumId: 10, expression: "Joy")

    let primaryMatch = Self.makeEntry(curriculumID: 10)
    let secondaryMatch = Self.makeEntry(curriculumID: 11, secondaryCurriculumID: 10)
    let noMatch = Self.makeEntry(curriculumID: 11, secondaryCurriculumID: 12)

    #expect(filter.matches(primaryMatch))
    #expect(filter.matches(secondaryMatch))
    #expect(!filter.matches(noMatch))
  }

  // MARK: - byHour

  @Test("byHour matches entries whose createdAt hour equals the filter hour")
  func byHour_matchesEntriesInTheSameHourBucket() {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "America/Los_Angeles")!

    let nine = cal.date(from: DateComponents(year: 2026, month: 4, day: 21, hour: 9, minute: 30))!
    let ten = cal.date(from: DateComponents(year: 2026, month: 4, day: 21, hour: 10, minute: 0))!

    let filter = JournalEntryDrilldownFilter.byHour(hour: 9)

    #expect(filter.matches(Self.makeEntry(createdAt: nine), calendar: cal))
    #expect(!filter.matches(Self.makeEntry(createdAt: ten), calendar: cal))
  }

  // MARK: - Title

  @Test("title reflects filter case")
  func title_reflectsFilterCase() {
    #expect(JournalEntryDrilldownFilter.byStrategy(strategyId: 1, name: "X").title == "Uses of X")
    #expect(JournalEntryDrilldownFilter.byPhase(phaseId: 1, name: "Rising").title == "Rising Entries")
    #expect(JournalEntryDrilldownFilter.byLayer(layerId: 1, name: "Red").title == "Red Mode Entries")
    #expect(JournalEntryDrilldownFilter.byCurriculum(curriculumId: 1, expression: "Joy").title == "Entries: Joy")
    #expect(JournalEntryDrilldownFilter.byHour(hour: 0).title == "Entries at 12 AM")
    #expect(JournalEntryDrilldownFilter.byHour(hour: 13).title == "Entries at 1 PM")
  }

  // MARK: - Lookup Builders

  @Test("buildExpressionLookup maps curriculum IDs to expressions")
  func buildExpressionLookup_mapsCurriculumIDsToExpressions() {
    let lookup = JournalEntryListView.buildExpressionLookup(catalog: Self.sampleCatalog)

    #expect(lookup[10] == "Joy")
    #expect(lookup[11] == "Calm")
    #expect(lookup[12] == "Rage")
    #expect(lookup[20] == "Grief")
    #expect(lookup[999] == nil)
  }

  @Test("buildStrategyLookup maps strategy IDs to names")
  func buildStrategyLookup_mapsStrategyIDsToNames() {
    let lookup = JournalEntryListView.buildStrategyLookup(catalog: Self.sampleCatalog)

    #expect(lookup[100] == "Deep breathing")
    #expect(lookup[101] == "Meditation")
    #expect(lookup[999] == nil)
  }

  @Test("buildCurriculumPhaseLookup maps curriculum IDs to their phase")
  func buildCurriculumPhaseLookup_mapsCurriculumIDsToPhase() {
    let lookup = JournalEntryListView.buildCurriculumPhaseLookup(catalog: Self.sampleCatalog)

    #expect(lookup[10] == 1)
    #expect(lookup[11] == 1)
    #expect(lookup[12] == 1)
    #expect(lookup[20] == 2)
  }

  @Test("buildCurriculumLayerLookup maps curriculum IDs to their layer")
  func buildCurriculumLayerLookup_mapsCurriculumIDsToLayer() {
    let lookup = JournalEntryListView.buildCurriculumLayerLookup(catalog: Self.sampleCatalog)

    #expect(lookup[10] == 50)
    #expect(lookup[11] == 50)
    #expect(lookup[12] == 50)
    #expect(lookup[20] == 51)
  }
}
