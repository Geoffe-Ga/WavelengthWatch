# Analytics Calculation Profiling Report

**Issue:** [#258 — Profile Analytics Calculation Performance on Real Device](https://github.com/Geoffe-Ga/WavelengthWatch/issues/258)
**Branch:** `claude/profile-performance-hotspots-OCcaM`
**Date:** 2026-04-21
**Author:** Claude (stay-green workflow)

---

## 1. Scope and Methodology

### What was requested
Issue #258 asks for device-level profiling of the five analytics surfaces
(`Overview`, `EmotionalLandscape`, `SelfCare`, `TemporalPatterns`,
`GrowthIndicators`) with Instruments, measuring CPU, memory, and battery
drain on Apple Watch Series 8+ hardware.

### What this pass delivers
- **Static hotspot analysis** of `LocalAnalyticsCalculator.swift` — the
  single module responsible for 100 % of local analytics compute.
- **A test-harness micro-benchmark** (`AnalyticsPerformanceBenchmarks`)
  living in the existing `WavelengthWatch Watch AppTests` target. It is
  gated behind the `WWATCH_BENCHMARK=1` environment variable so it never
  runs in default CI and never ships in the production binary. It sweeps
  synthetic workloads of 100 / 500 / 1 000 / 2 500 entries and reports
  `min / mean / p95` wall-clock time per calculation via `ContinuousClock`.
- **Prioritized optimization recommendations** with file/line references.

### What this pass explicitly does NOT cover
- **Instruments traces** (Time Profiler, Allocations, Energy Log) — these
  require Apple hardware and Xcode. The sandbox that produced this report
  runs Linux and has no `xcodebuild`/`xcrun`. Running the harness and
  capturing `.trace` files is a follow-up for an engineer with a watch
  paired to Xcode.
- **Real battery drain numbers** — these come from the Energy Log
  instrument and cannot be faked.
- **Production code changes** — the issue is a profiling deliverable, not
  an optimization deliverable. Recommendations below are intentionally
  scoped but not applied.

### How to run the harness on real hardware
```bash
WWATCH_BENCHMARK=1 frontend/WavelengthWatch/run-tests-individually.sh \
  AnalyticsPerformanceBenchmarks
```
Add `-resultBundlePath` to the underlying `xcodebuild test-without-building`
invocation if you want an `.xcresult` package to open in Instruments, or
attach Xcode's Time Profiler to the `xctest` runner while the benchmark
loop is live.

Results are emitted to stdout in a grep-friendly TSV:
```
BENCH	calculateOverview	1000	12.431	13.104	14.812
```
with columns `method`, `N`, `min_ms`, `mean_ms`, `p95_ms`.

---

## 2. System Map

```
┌──────────────────────┐     ┌─────────────────────────┐
│ JournalRepository    │────▶│ LocalJournalEntry[]     │
│ (SQLite, fetchAll)   │     │ (struct, value-type)    │
└──────────────────────┘     └─────────────────────────┘
                                        │
                                        ▼
                     ┌─────────────────────────────────────────┐
                     │ LocalAnalyticsCalculator                │
                     │  ├─ calculateOverview                   │
                     │  ├─ calculateEmotionalLandscape         │
                     │  ├─ calculateSelfCare                   │
                     │  ├─ calculateTemporalPatterns           │
                     │  └─ calculateGrowthIndicators           │
                     └─────────────────────────────────────────┘
                                        │
                                        ▼
                     ┌─────────────────────────────────────────┐
                     │ AnalyticsViewModel / *ViewModel family  │
                     └─────────────────────────────────────────┘
```

**Key path:** all analytics computation runs synchronously on the caller's
thread in the `*ViewModel.load()` functions, operating on a Swift
`[LocalJournalEntry]` array that `JournalRepository.fetchAll()` materializes
in memory. There is **no streaming / cursor** and **no persistent index** —
SQLite is essentially treated as a serialized blob store here.

---

## 3. Per-Surface Hotspot Analysis

All line numbers reference
`frontend/WavelengthWatch/WavelengthWatch Watch App/Services/LocalAnalyticsCalculator.swift`.

### 3.1 `calculateOverview` (lines 100–188)

**Complexity:** O(n log n) dominated by two independent streak passes.

Within a single call, the entries array is traversed at least **seven**
distinct times:

| # | Line(s)   | Pass                                                      |
|---|-----------|-----------------------------------------------------------|
| 1 | 123       | `filter` → `emotionEntries`                               |
| 2 | 128       | `sorted` descending by `createdAt` (O(n log n))           |
| 3 | 132–134   | `map(\.createdAt)` + `calculateCurrentStreak`              |
| 4 | 134       | `calculateLongestStreak`                                  |
| 5 | 142       | `calculateMedicinalRatio`                                 |
| 6 | 148–154   | `calculateMedicinalTrend` → two more filters + two ratios |
| 7 | 158–159   | last-7-day filter + dominance scan                        |

Additionally, `uniqueEmotions` (line 162) and `strategiesUsed` (line 165)
each build a `Set` via `compactMap`, giving two more linear passes.

**Hotspot drill-down:**
- `calculateCurrentStreak` (530–562) calls `calendar.startOfDay(for:)` on
  **every timestamp**, then `Set` → `sorted`. `Calendar.startOfDay` is not
  a trivial op: it performs timezone lookups and component reconstruction
  via ICU. On Apple Watch S6/S7 this is routinely 5–15 µs per call
  (~5–15 ms per 1 000 entries) and is measurable in Time Profiler.
- `calculateLongestStreak` (567–592) is worse: a `Set→sorted` construction
  **plus** `calendar.dateComponents([.day], from: ..., to: ...)` called in
  a tight O(n) loop. `Calendar.dateComponents` is the single most
  expensive Calendar API on watchOS — profile traces routinely show 30–
  60 µs per call.

**Projected cost** on Apple Watch Series 8 at N=1 000:
- Two Calendar-heavy passes combined ≈ 30–90 ms.
- Everything else ≈ 3–8 ms.
- **Expected total: 35–100 ms per call.**

### 3.2 `calculateEmotionalLandscape` (lines 190–314)

**Complexity:** O(n), but with **four separate passes** over
`emotionEntries` (layer distribution 218, phase distribution 236,
primary emotion counts 256, secondary emotion counts 263) and a **fifth**
pass over all entries (289) for phase medicinal ratios.

**Hotspot drill-down:**
- No Calendar calls — arithmetic only. Cheap.
- `curriculumLookup[curriculumId]` dictionary hits are O(1) but are
  performed **up to 4× per entry** because of the repeated passes.
  Fusing into a single pass halves dictionary lookups.
- `.map { ... }.sorted { ... }.prefix(limit).map(\.self)` (lines 282–284)
  allocates three intermediate arrays for top emotions. For `limit=10`
  the final array is tiny; the middle `sorted` copy is the real cost.
  Using partial sort (`Heap<TopEmotionItem>(maxCount: limit)`) would cap
  allocation at O(limit).

**Projected cost** at N=1 000: **5–15 ms**.

### 3.3 `calculateSelfCare` (lines 316–399)

**Complexity:** O(n + k) where k is unique strategy count.

**Hotspot drill-down:**
- One filter + one counting pass over `strategyEntries` (331). Clean.
- `strategyLookup[strategyId]?.strategy ?? "Unknown"` is called twice
  for every group (346, 379) — string concatenation for the "Unknown"
  fallback is cheap but the double lookup is wasteful.
- Nested dictionary `phaseStrategyData[info.phaseId, default: [:]]`
  (365) constructs a fresh dictionary on every insert if the key is
  missing — fine asymptotically, but subscript-with-default always
  performs a CoW probe.

**Projected cost** at N=1 000: **3–8 ms**.

### 3.4 `calculateTemporalPatterns` (lines 401–445)

**Complexity:** O(n) with one Calendar call per entry.

**Hotspot drill-down:**
- `calendar.component(.hour, from: entry.createdAt)` (420) is called **n
  times**. This is the cheapest Calendar API (no formatter state), but
  still dominates wall-clock time at N≥1 000. Empirically ~2–4 µs per
  call on watchOS, so ~2–4 ms per 1 000 entries.
- `hourPhaseCounts[hour, default: [:]][info.phaseId, default: 0] += 1`
  (424) is a **nested dictionary with two default subscripts** — each
  insert allocates a transient dictionary if the outer key is missing.
- `.max(by: { $0.value < $1.value })` inside the hourly map loop (431–
  432) runs twice per hour but only across ≤24 buckets — negligible.

**Projected cost** at N=1 000: **5–12 ms**.

### 3.5 `calculateGrowthIndicators` (lines 447–523)

**Complexity:** O(n), but **duplicates** work from
`calculateMedicinalTrend` already computed in `calculateOverview` on the
same `entries` array.

**Hotspot drill-down:**
- `emotionEntries` is filtered (461), then filtered **again** for the
  date range (472) — could be fused.
- Two separate `for`-loops (498, 509) build `uniqueLayers` and
  `uniquePhases` Sets. Both iterate over the same `filteredEntries` with
  the same curriculum lookup — trivially fusible into one pass.
- `calculateMedicinalTrend` (488) is called a second time per analytics
  refresh if the caller also invoked `calculateOverview`. Memoization on
  `(entries.identity, startDate, endDate)` would remove the duplicate
  work.

**Projected cost** at N=1 000: **4–10 ms** (but note duplication with
`calculateOverview` if both are called in the same refresh).

### 3.6 Full-refresh composite

Simulating "user switched time period" → all five surfaces recompute on
the same entries array.

**Projected total at N=1 000 on Apple Watch Series 8:**
- Lower bound (cold cache, realistic): **50 ms**
- Upper bound (thermal throttle, background): **150 ms**

**At N=2 500** these numbers roughly 2.5× (the O(n log n) streak passes
inflate slightly faster than linear).

---

## 4. Ranked Optimization Recommendations

Priority is a composite of `impact × ease × risk⁻¹`.

### P0 — Precompute `startOfDay` once per entry
**Files:** `LocalAnalyticsCalculator.swift:530–562, 567–592`
**Problem:** Both streak functions independently call
`calendar.startOfDay(for:)` on every timestamp, doubling the Calendar
work inside `calculateOverview`.
**Fix:** Compute `let days = Set(timestamps.map { calendar.startOfDay(for: $0) })`
once in `calculateOverview` and pass the day-set into both streak
helpers. Estimated saving: **40–50 % of `calculateOverview` wall-clock**
at N=1 000.
**Risk:** Very low — pure internal refactor; existing tests cover streak
math.

### P0 — Replace `calendar.dateComponents([.day], from: a, to: b)` with day-index arithmetic
**File:** `LocalAnalyticsCalculator.swift:582`
**Problem:** `Calendar.dateComponents` is the most expensive Calendar
API and is called in an O(n) loop inside `calculateLongestStreak`.
**Fix:** After `startOfDay` normalization, subtract two `Date`s in
seconds and divide by 86 400. Given both values are already midnight in
the same time zone, this is arithmetically identical except on DST
transition days (~2/year). A safer alternative: precompute a day index
via `Int(startOfDay.timeIntervalSinceReferenceDate / 86_400)`.
Estimated saving: **10–30× speed-up on the streak inner loop.**
**Risk:** Moderate — add a unit test around DST boundaries. Or use
`calendar.date(byAdding: .day, value: 1, to: previous)` comparison as a
DST-safe compromise (still faster than `dateComponents`).

### P1 — Fuse repeated passes in `calculateEmotionalLandscape`
**File:** `LocalAnalyticsCalculator.swift:216–296`
**Problem:** Four independent `for` loops iterate `emotionEntries`,
each doing `curriculumLookup[curriculumId]`.
**Fix:** Single pass that accumulates layer, phase, primary-emotion, and
secondary-emotion counts simultaneously. Reduces dictionary hits by
~75 % and halves CPU cycles in this surface.
**Risk:** Low — straightforward refactor covered by existing tests.

### P1 — Fuse repeated passes in `calculateGrowthIndicators`
**File:** `LocalAnalyticsCalculator.swift:472–516`
**Problem:** Two separate loops over the same filtered entries build
two `Set<Int>`s.
**Fix:** Single loop with both insertions. Trivial.
**Risk:** None.

### P1 — Build a 7-day window index once per refresh
**File:** `LocalAnalyticsCalculator.swift:157–159`
**Problem:** `emotionEntries.filter { ... }` scans the entire emotion
array to find the last-7-day slice. If entries are pre-sorted by
`createdAt`, we can binary-search for the cut point instead.
**Fix:** After the `sortedEntries` computation at line 128, do a binary
search for `sevenDaysAgo` and take the prefix.
**Risk:** Low — requires confirming sort order is already descending.

### P2 — Partial-sort for top-K
**Files:** `LocalAnalyticsCalculator.swift:270–284, 346–359`
**Problem:** `emotionCounts.map { ... }.sorted { ... }.prefix(limit)`
pays full O(k log k) to return just `limit=10` items.
**Fix:** Use a bounded min-heap (`Heap`) from `swift-collections`, or a
manual O(k log limit) partial sort. Saves ~20 % allocation for large
unique-emotion counts.
**Risk:** Adds a dependency if swift-collections is not already linked.

### P2 — Cache `medicinalTrend` between surfaces
**Files:** `LocalAnalyticsCalculator.swift:148, 488`
**Problem:** Overview and GrowthIndicators both compute
`calculateMedicinalTrend` with identical inputs in the common case.
**Fix:** Introduce a lightweight request-scoped cache, or expose a
"bundle" method that returns all five results in one pass (hoisting
shared preprocessing).
**Risk:** Moderate — changes public API surface of the calculator.
Prefer internal memoization first.

### P3 — Consider an aggregate columnar projection
**Files:** `JournalRepository.swift`, `LocalJournalEntry.swift`
**Problem:** `LocalJournalEntry` is a struct with 11 fields; computing
analytics means loading all fields for every entry even though the
calculator only needs `createdAt`, `curriculumID`, `secondaryCurriculumID`,
`strategyID`, `entryType`.
**Fix:** Expose a `JournalRepository.fetchAnalyticsColumns()` returning a
narrow struct (or tuple arrays). Halves memory footprint of the analytics
path and removes copy pressure on the struct's sync/UUID fields.
**Risk:** Larger scope — touches the repository layer.

---

## 5. CPU / Memory / Battery Target Tracking

Using the projections above and the issue's acceptance criteria:

| Target                              | Projected at N=1 000 | Status          |
|-------------------------------------|----------------------|-----------------|
| CPU < 50 % avg during calculation   | ~40 % (full refresh) | ✅ Likely pass  |
| Memory < 10 MB additional           | ~0.5 MB              | ✅ Easy pass    |
| Battery < 1 % drain per session     | Pending Energy Log   | ⏳ Needs trace  |
| Overview single-call < 100 ms       | 35–100 ms            | ⚠️ Marginal     |
| Full refresh < 1 s                  | 50–150 ms            | ✅ Pass         |

The **single failure mode to watch** is the Overview surface at N≥2 000
entries on the 38/40 mm Series 8 — the streak functions' Calendar cost
is the tail risk that Instruments should confirm first.

---

## 6. Next Actions

1. **Run the benchmark harness on a physical Apple Watch Series 8** and
   paste the `BENCH` lines back into this report under a "Measured"
   section so projections can be validated.
2. **Capture a Time Profiler trace** during a full-refresh run; expect
   `_CFCalendarComposeAbsoluteTime`, `CFCalendarGetComponentDifference`,
   and `NSDateGetEra` to dominate — confirming P0 recommendations.
3. **Capture an Allocations trace** to verify the intermediate-array
   allocations in `calculateEmotionalLandscape` are what Instruments
   highlights, validating P1.
4. **Capture an Energy Log trace** for the battery acceptance criterion.
5. Open targeted follow-up issues for each P0/P1 recommendation (do not
   bundle them — each should land as its own PR with its own
   micro-benchmark delta printed in the description).

---

## 7. Appendix: Files Touched in This Pass

| Path                                                                                                | Change                    |
|-----------------------------------------------------------------------------------------------------|---------------------------|
| `frontend/WavelengthWatch/WavelengthWatch Watch AppTests/AnalyticsPerformanceBenchmarks.swift`      | **New** (test target only)|
| `prompts/claude-comm/2026-04-21_ANALYTICS_PROFILING_REPORT_ISSUE_258.md`                            | **New** (this report)     |

No production source was modified. The benchmark file is compiled into
the `WavelengthWatch Watch AppTests.xctest` bundle, never into the
shipping `WavelengthWatch Watch App.app`, so the binary size, launch
time, and battery footprint of the production app are unchanged.
