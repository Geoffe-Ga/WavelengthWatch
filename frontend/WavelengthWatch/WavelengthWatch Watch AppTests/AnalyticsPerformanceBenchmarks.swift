import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

/// Micro-benchmarks for `LocalAnalyticsCalculator` used to locate hotspots
/// without Instruments access.
///
/// These tests are **disabled by default** so they do not slow down the
/// regular test suite. Enable them by setting `WWATCH_BENCHMARK=1` in the
/// scheme's environment or the shell that invokes `xcodebuild`:
///
/// ```
/// WWATCH_BENCHMARK=1 frontend/WavelengthWatch/run-tests-individually.sh \
///   AnalyticsPerformanceBenchmarks
/// ```
///
/// The suite lives in the test target and is never compiled into the shipping
/// app bundle — it adds zero weight to the production binary.
///
/// Results are written to stdout as a tab-separated table so the log can be
/// diffed between runs:
///
/// ```
/// METHOD                  N      MIN_MS   MEAN_MS  P95_MS
/// calculateOverview       1000   12.4     13.1     14.8
/// calculateLongestStreak  1000   6.2      6.7      7.3
/// ```
@Suite(
  "AnalyticsPerformanceBenchmarks",
  .disabled(
    if: ProcessInfo.processInfo.environment["WWATCH_BENCHMARK"] != "1",
    "Set WWATCH_BENCHMARK=1 to run analytics benchmarks"
  )
)
struct AnalyticsPerformanceBenchmarks {
  // MARK: - Configuration

  /// Entry counts to sweep. Keeps runtime bounded even on 38mm hardware.
  static let entryCounts: [Int] = [100, 500, 1000, 2500]

  /// Iterations per measurement. We report the minimum to suppress jitter
  /// from GC, thermal throttling, and simulator scheduling.
  static let iterations: Int = 7

  // MARK: - Fixtures

  /// Deterministic catalog: 6 layers x 4 phases x (3 medicinal + 3 toxic)
  /// curriculum entries + 4 strategies per phase.
  /// Mirrors the real catalog's cardinality without pulling bundled JSON.
  static let catalog: CatalogResponseModel = makeCatalog()

  static func makeCatalog() -> CatalogResponseModel {
    let phaseNames = ["Rising", "Peaking", "Falling", "Resting"]
    var layers: [CatalogLayerModel] = []
    var curriculumId = 1
    var strategyId = 1_000
    for layerId in 1 ... 6 {
      var phases: [CatalogPhaseModel] = []
      for (phaseIdx, phaseName) in phaseNames.enumerated() {
        let phaseId = (layerId - 1) * 4 + phaseIdx + 1
        var medicinal: [CatalogCurriculumEntryModel] = []
        var toxic: [CatalogCurriculumEntryModel] = []
        for i in 0 ..< 3 {
          medicinal.append(CatalogCurriculumEntryModel(
            id: curriculumId,
            dosage: .medicinal,
            expression: "M-L\(layerId)-P\(phaseIdx)-\(i)"
          ))
          curriculumId += 1
          toxic.append(CatalogCurriculumEntryModel(
            id: curriculumId,
            dosage: .toxic,
            expression: "T-L\(layerId)-P\(phaseIdx)-\(i)"
          ))
          curriculumId += 1
        }
        var strategies: [CatalogStrategyModel] = []
        for i in 0 ..< 4 {
          strategies.append(CatalogStrategyModel(
            id: strategyId,
            strategy: "S-L\(layerId)-P\(phaseIdx)-\(i)",
            color: "#000000"
          ))
          strategyId += 1
        }
        phases.append(CatalogPhaseModel(
          id: phaseId,
          name: phaseName,
          medicinal: medicinal,
          toxic: toxic,
          strategies: strategies
        ))
      }
      layers.append(CatalogLayerModel(
        id: layerId,
        color: "#000000",
        title: "Layer\(layerId)",
        subtitle: "Subtitle\(layerId)",
        phases: phases
      ))
    }
    return CatalogResponseModel(phaseOrder: phaseNames, layers: layers)
  }

  /// Generates `count` synthetic entries spread across a 30-day window
  /// ending at `endDate`. Uses a seeded LCG so results are reproducible.
  static func makeEntries(count: Int, endDate: Date) -> [LocalJournalEntry] {
    var rng: UInt64 = 0xDEAD_BEEF_CAFE_F00D
    func next() -> UInt64 {
      // Linear-congruential; good enough for workload shape, not crypto.
      rng = rng &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
      return rng
    }

    // 36 medicinal + 36 toxic = 72 curriculum IDs. 96 strategy IDs (1000..1095).
    let curriculumIds = Array(1 ... 72)
    let strategyIds = Array(1_000 ... 1_095)
    let windowSeconds = 30.0 * 86_400.0

    var entries: [LocalJournalEntry] = []
    entries.reserveCapacity(count)
    for _ in 0 ..< count {
      let offset = Double(next() % 1_000_000) / 1_000_000.0 * windowSeconds
      let created = endDate.addingTimeInterval(-offset)
      let primary = curriculumIds[Int(next() % UInt64(curriculumIds.count))]
      let hasSecondary = (next() % 3) == 0
      let secondary = hasSecondary
        ? curriculumIds[Int(next() % UInt64(curriculumIds.count))]
        : nil
      let hasStrategy = (next() % 2) == 0
      let strategy = hasStrategy
        ? strategyIds[Int(next() % UInt64(strategyIds.count))]
        : nil
      let isRest = (next() % 20) == 0
      entries.append(LocalJournalEntry(
        createdAt: created,
        userID: 1,
        curriculumID: isRest ? nil : primary,
        secondaryCurriculumID: isRest ? nil : secondary,
        strategyID: strategy,
        entryType: isRest ? .rest : .emotion
      ))
    }
    return entries
  }

  // MARK: - Measurement Helpers

  /// Runs `body` `iterations` times and returns (min, mean, p95) in ms.
  private func measure(
    iterations: Int = AnalyticsPerformanceBenchmarks.iterations,
    _ body: () -> Void
  ) -> (minMs: Double, meanMs: Double, p95Ms: Double) {
    var samples: [Double] = []
    samples.reserveCapacity(iterations)
    // Warmup to prime caches / dispatch tables.
    body()
    let clock = ContinuousClock()
    for _ in 0 ..< iterations {
      let elapsed = clock.measure { body() }
      let ms = Double(elapsed.components.seconds) * 1_000
        + Double(elapsed.components.attoseconds) / 1e15
      samples.append(ms)
    }
    samples.sort()
    let minMs = samples.first ?? 0
    let meanMs = samples.reduce(0, +) / Double(samples.count)
    let p95Idx = min(samples.count - 1, Int(Double(samples.count) * 0.95))
    let p95Ms = samples[p95Idx]
    return (minMs, meanMs, p95Ms)
  }

  private func report(
    method: String,
    n: Int,
    result: (minMs: Double, meanMs: Double, p95Ms: Double)
  ) {
    // Tab-separated for easy parsing; prefixed so grep can isolate them.
    let line = String(
      format: "BENCH\t%@\t%d\t%.3f\t%.3f\t%.3f",
      method,
      n,
      result.minMs,
      result.meanMs,
      result.p95Ms
    )
    print(line)
  }

  // MARK: - Benchmarks

  @Test("benchmark calculateOverview across entry counts")
  func bench_calculateOverview() {
    let calculator = LocalAnalyticsCalculator(catalog: Self.catalog)
    let endDate = Date()
    let startDate = endDate.addingTimeInterval(-30 * 86_400)
    print("BENCH_HEADER\tmethod\tN\tmin_ms\tmean_ms\tp95_ms")
    for n in Self.entryCounts {
      let entries = Self.makeEntries(count: n, endDate: endDate)
      let result = measure {
        _ = calculator.calculateOverview(
          entries: entries,
          startDate: startDate,
          endDate: endDate
        )
      }
      report(method: "calculateOverview", n: n, result: result)
      // Loose upper bound: 250 ms even at 2500 entries on slowest sim.
      #expect(result.minMs < 250.0, "Overview too slow at N=\(n)")
    }
  }

  @Test("benchmark calculateEmotionalLandscape across entry counts")
  func bench_calculateEmotionalLandscape() {
    let calculator = LocalAnalyticsCalculator(catalog: Self.catalog)
    let endDate = Date()
    for n in Self.entryCounts {
      let entries = Self.makeEntries(count: n, endDate: endDate)
      let result = measure {
        _ = calculator.calculateEmotionalLandscape(entries: entries, limit: 10)
      }
      report(method: "calculateEmotionalLandscape", n: n, result: result)
      #expect(result.minMs < 200.0, "EmotionalLandscape too slow at N=\(n)")
    }
  }

  @Test("benchmark calculateSelfCare across entry counts")
  func bench_calculateSelfCare() {
    let calculator = LocalAnalyticsCalculator(catalog: Self.catalog)
    let endDate = Date()
    for n in Self.entryCounts {
      let entries = Self.makeEntries(count: n, endDate: endDate)
      let result = measure {
        _ = calculator.calculateSelfCare(entries: entries, limit: 10)
      }
      report(method: "calculateSelfCare", n: n, result: result)
      #expect(result.minMs < 200.0, "SelfCare too slow at N=\(n)")
    }
  }

  @Test("benchmark calculateTemporalPatterns across entry counts")
  func bench_calculateTemporalPatterns() {
    let calculator = LocalAnalyticsCalculator(catalog: Self.catalog)
    let endDate = Date()
    let startDate = endDate.addingTimeInterval(-30 * 86_400)
    for n in Self.entryCounts {
      let entries = Self.makeEntries(count: n, endDate: endDate)
      let result = measure {
        _ = calculator.calculateTemporalPatterns(
          entries: entries,
          startDate: startDate,
          endDate: endDate
        )
      }
      report(method: "calculateTemporalPatterns", n: n, result: result)
      #expect(result.minMs < 200.0, "TemporalPatterns too slow at N=\(n)")
    }
  }

  @Test("benchmark calculateGrowthIndicators across entry counts")
  func bench_calculateGrowthIndicators() {
    let calculator = LocalAnalyticsCalculator(catalog: Self.catalog)
    let endDate = Date()
    let startDate = endDate.addingTimeInterval(-30 * 86_400)
    for n in Self.entryCounts {
      let entries = Self.makeEntries(count: n, endDate: endDate)
      let result = measure {
        _ = calculator.calculateGrowthIndicators(
          entries: entries,
          startDate: startDate,
          endDate: endDate
        )
      }
      report(method: "calculateGrowthIndicators", n: n, result: result)
      #expect(result.minMs < 200.0, "GrowthIndicators too slow at N=\(n)")
    }
  }

  /// Composite scenario: simulate a user switching time periods which
  /// recomputes all five analytics surfaces back-to-back.
  @Test("benchmark full analytics refresh (all 5 surfaces)")
  func bench_fullRefresh() {
    let calculator = LocalAnalyticsCalculator(catalog: Self.catalog)
    let endDate = Date()
    let startDate = endDate.addingTimeInterval(-30 * 86_400)
    for n in Self.entryCounts {
      let entries = Self.makeEntries(count: n, endDate: endDate)
      let result = measure {
        _ = calculator.calculateOverview(
          entries: entries,
          startDate: startDate,
          endDate: endDate
        )
        _ = calculator.calculateEmotionalLandscape(entries: entries, limit: 10)
        _ = calculator.calculateSelfCare(entries: entries, limit: 10)
        _ = calculator.calculateTemporalPatterns(
          entries: entries,
          startDate: startDate,
          endDate: endDate
        )
        _ = calculator.calculateGrowthIndicators(
          entries: entries,
          startDate: startDate,
          endDate: endDate
        )
      }
      report(method: "fullRefresh", n: n, result: result)
      // Target from issue #258: a full analytics session should be snappy.
      #expect(result.minMs < 1_000.0, "Full refresh too slow at N=\(n)")
    }
  }
}
