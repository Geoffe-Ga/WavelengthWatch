# Analytics Epic - Missing Issues Documentation

**Created**: 2026-01-16
**Purpose**: Comprehensive issue descriptions for completing Analytics Epic #187
**Status**: Ready for issue creation

---

## Overview

This document contains detailed descriptions for 11 new issues needed to complete the Analytics Epic. These issues address critical gaps identified in the epic analysis, particularly around offline-first analytics support and frontend integration.

---

## Category 1: Offline Calculator Extensions (HIGH PRIORITY)

### Issue TBD-A: Extend LocalAnalyticsCalculator for Self-Care Analytics

**Labels**: `enhancement`, `analytics`, `offline-first`, `Phase 3`
**Milestone**: Analytics Feature
**Related**: Epic #187, Issue #202, Issue #231

**Description**:

Extend `LocalAnalyticsCalculator` to support self-care analytics calculations, enabling offline functionality for strategy usage insights.

**Current State**:
- `LocalAnalyticsCalculator.swift` currently implements only `calculateOverview()` and `calculateEmotionalLandscape()`
- Backend endpoint `/api/v1/analytics/self-care` exists and is fully functional (lines 596-704 in `backend/routers/analytics.py`)
- Frontend has no local calculation support for self-care metrics

**Requirements**:

Add new protocol method and implementation to `LocalAnalyticsCalculatorProtocol`:

```swift
func calculateSelfCare(
  entries: [LocalJournalEntry],
  limit: Int
) -> SelfCareAnalytics
```

**Implementation Scope**:

1. **Protocol Extension** (`Services/LocalAnalyticsCalculator.swift`)
   - Add `calculateSelfCare()` method to `LocalAnalyticsCalculatorProtocol`

2. **Calculator Implementation**
   - Implement strategy frequency calculation (top N strategies by count)
   - Calculate strategy diversity score (unique strategies / total entries with strategies)
   - Return `SelfCareAnalytics` model matching backend schema

3. **Algorithm Alignment**
   - Port logic from backend endpoint (`analytics.py:596-704`)
   - Ensure percentage calculations match (0-100 scale, not 0-1)
   - Sort strategies by count descending

**Success Criteria**:
- [ ] Protocol includes `calculateSelfCare()` method
- [ ] Implementation returns identical results to backend for same dataset
- [ ] Handles edge cases: no strategies, all entries have same strategy, etc.
- [ ] Unit tests cover all calculation paths

**Privacy Requirement**:
This addresses spec requirement (line 498): "On-Device First: Compute simple metrics on-device when possible"

---

### Issue TBD-B: Extend LocalAnalyticsCalculator for Temporal Patterns

**Labels**: `enhancement`, `analytics`, `offline-first`, `Phase 4`
**Milestone**: Analytics Feature
**Related**: Epic #187, Issue #205, Issue #231

**Description**:

Extend `LocalAnalyticsCalculator` to support temporal pattern analytics, enabling offline functionality for time-of-day and consistency insights.

**Current State**:
- Backend endpoint `/api/v1/analytics/temporal` exists (lines 707-751 in `backend/routers/analytics.py`)
- No local calculation support exists
- Frontend would require backend connection to display temporal patterns

**Requirements**:

Add new protocol method and implementation:

```swift
func calculateTemporalPatterns(
  entries: [LocalJournalEntry]
) -> TemporalPatterns
```

**Implementation Scope**:

1. **Protocol Extension**
   - Add `calculateTemporalPatterns()` to `LocalAnalyticsCalculatorProtocol`

2. **Calculator Implementation**
   - Hourly distribution: Group entries by hour of day (0-23)
   - Consistency score: Days with entries / total days in period (as percentage 0-100)
   - Longest streak: Already implemented via `calculateLongestStreak()`, reuse
   - Current streak: Already implemented via `calculateCurrentStreak()`, reuse

3. **Time Zone Handling**
   - Use device's local time zone for hour extraction
   - Extract hour from `LocalJournalEntry.createdAt` using `Calendar.current`

**Success Criteria**:
- [ ] Hourly distribution aggregates entries by local hour
- [ ] Consistency score matches backend calculation
- [ ] Streak values match existing calculator methods
- [ ] Unit tests cover different time zones and edge cases

**Privacy Requirement**:
Enables offline temporal insights per spec line 498.

---

### Issue TBD-C: Extend LocalAnalyticsCalculator for Growth Indicators

**Labels**: `enhancement`, `analytics`, `offline-first`, `Phase 4`
**Milestone**: Analytics Feature
**Related**: Epic #187, Issue #206, Issue #231

**Description**:

Extend `LocalAnalyticsCalculator` to support growth indicator analytics, enabling offline functionality for long-term trend insights.

**Current State**:
- Backend endpoint `/api/v1/analytics/growth` exists (lines 754-826 in `backend/routers/analytics.py`)
- No local calculation support exists
- Frontend cannot display growth metrics without backend

**Requirements**:

Add new protocol method and implementation:

```swift
func calculateGrowthIndicators(
  entries: [LocalJournalEntry],
  startDate: Date,
  endDate: Date
) -> GrowthIndicators
```

**Implementation Scope**:

1. **Protocol Extension**
   - Add `calculateGrowthIndicators()` to `LocalAnalyticsCalculatorProtocol`

2. **Calculator Implementation**
   - **Medicinal trend**: Calculate 30-day moving average of medicinal ratio
     - Group entries by day
     - For each day, compute medicinal ratio over preceding 30 days
     - Return final trend value (percentage change)
   - **Layer diversity**: Count unique layers accessed in period
   - **Phase coverage**: Count unique phases logged (0-6 range)

3. **Algorithm Complexity**
   - Moving average calculation requires sliding window over daily buckets
   - Reuse `calculateMedicinalRatio()` helper for daily ratios

**Success Criteria**:
- [ ] Medicinal trend calculation matches backend algorithm
- [ ] Layer diversity counts distinct layers from primary emotions
- [ ] Phase coverage counts distinct phases (0-6)
- [ ] Handles sparse data (gaps in entries)
- [ ] Unit tests verify moving average math

**Privacy Requirement**:
Completes offline-first requirement for all analytics endpoints per spec.

---

## Category 2: ViewModel + Integration Work (MEDIUM PRIORITY)

### Issue TBD-D: Create SelfCareViewModel with Offline Fallback

**Labels**: `enhancement`, `analytics`, `frontend`, `Phase 3`
**Milestone**: Analytics Feature
**Related**: Epic #187, Issue #203, Issue TBD-A

**Description**:

Create `SelfCareViewModel` to manage self-care analytics data fetching with offline-first fallback strategy.

**Current State**:
- Backend endpoint `/api/v1/analytics/self-care` exists
- `StrategyUsageView.swift` exists but is not functional (no ViewModel)
- View is not integrated into navigation hierarchy

**Requirements**:

1. **Create ViewModel** (`ViewModels/SelfCareViewModel.swift`)
   ```swift
   @MainActor
   final class SelfCareViewModel: ObservableObject {
     @Published var analytics: SelfCareAnalytics?
     @Published var isLoading: Bool = false
     @Published var error: Error?

     func fetchAnalytics(startDate: Date, endDate: Date, limit: Int)
   }
   ```

2. **Offline-First Strategy**
   - Check `SyncSettings.isCloudSyncEnabled`
   - If enabled: Fetch from backend via `AnalyticsService`
   - If disabled OR backend fails: Calculate locally using `LocalAnalyticsCalculator`
   - Mirror strategy used in `AnalyticsViewModel` (lines 40-90)

3. **Error Handling**
   - Graceful degradation: If backend fails, fall back to local
   - Set `error` only if both backend AND local calculation fail
   - Loading states for async operations

**Success Criteria**:
- [ ] ViewModel fetches from backend when cloud sync enabled
- [ ] Falls back to local calculation when offline or sync disabled
- [ ] Handles loading, success, and error states
- [ ] Unit tests cover both fetch paths

**Integration Note**:
This ViewModel will be used by `StrategyUsageView.swift` (existing file).

---

### Issue TBD-E: Create TemporalPatternsViewModel with Offline Fallback

**Labels**: `enhancement`, `analytics`, `frontend`, `Phase 4`
**Milestone**: Analytics Feature
**Related**: Epic #187, Issue #207, Issue TBD-B

**Description**:

Create `TemporalPatternsViewModel` to manage temporal analytics data fetching with offline-first fallback.

**Current State**:
- Backend endpoint `/api/v1/analytics/temporal` exists
- `TemporalPatternsView.swift` exists but is not functional
- No ViewModel or navigation integration

**Requirements**:

1. **Create ViewModel** (`ViewModels/TemporalPatternsViewModel.swift`)
   ```swift
   @MainActor
   final class TemporalPatternsViewModel: ObservableObject {
     @Published var patterns: TemporalPatterns?
     @Published var isLoading: Bool = false
     @Published var error: Error?

     func fetchPatterns(startDate: Date, endDate: Date)
   }
   ```

2. **Offline-First Strategy**
   - Check `SyncSettings.isCloudSyncEnabled`
   - Backend fetch via `AnalyticsService` OR local calculation via `LocalAnalyticsCalculator`
   - Graceful fallback on network errors

3. **Time Period Filtering**
   - Support 7/30/all-time filters (persist selection in `UserDefaults`)
   - Match filter behavior from `AnalyticsViewModel`

**Success Criteria**:
- [ ] Dual fetch strategy (backend + local fallback)
- [ ] Time period filter integration
- [ ] Loading and error states
- [ ] Unit tests for both fetch modes

---

### Issue TBD-F: Create GrowthIndicatorsViewModel with Offline Fallback

**Labels**: `enhancement`, `analytics`, `frontend`, `Phase 4`
**Milestone**: Analytics Feature
**Related**: Epic #187, Issue #208, Issue TBD-C

**Description**:

Create `GrowthIndicatorsViewModel` to manage growth analytics data fetching with offline-first fallback.

**Current State**:
- Backend endpoint `/api/v1/analytics/growth` exists
- `GrowthIndicatorsView.swift` exists but is not functional
- No ViewModel or navigation integration

**Requirements**:

1. **Create ViewModel** (`ViewModels/GrowthIndicatorsViewModel.swift`)
   ```swift
   @MainActor
   final class GrowthIndicatorsViewModel: ObservableObject {
     @Published var indicators: GrowthIndicators?
     @Published var isLoading: Bool = false
     @Published var error: Error?

     func fetchIndicators(startDate: Date, endDate: Date)
   }
   ```

2. **Offline-First Strategy**
   - Backend fetch OR local calculation based on `SyncSettings`
   - Fallback on network errors

3. **Long-Term Data Handling**
   - Growth indicators often span >30 days of data
   - Ensure efficient local calculation for large datasets
   - Consider caching computed results

**Success Criteria**:
- [ ] Dual fetch strategy implemented
- [ ] Efficient for large datasets (1000+ entries)
- [ ] Loading and error states
- [ ] Unit tests

---

### Issue TBD-G: Integrate All Analytics Views into Navigation Hierarchy

**Labels**: `enhancement`, `analytics`, `frontend`, `ux`
**Milestone**: Analytics Feature
**Related**: Epic #187, Issues #203, #207, #208

**Description**:

Wire up all analytics views into the navigation hierarchy, making them accessible from the Analytics tab.

**Current State**:
- Phase 1 (Overview) is integrated and functional
- Phase 2 (Emotional Landscape) views exist in PRs #228, #229, #230 but not merged
- Phase 3-4 views (`StrategyUsageView`, `TemporalPatternsView`, `GrowthIndicatorsView`) exist but unreachable

**Requirements**:

1. **Navigation Structure**
   - `AnalyticsOverviewView` (exists, shows summary)
   - Tap "View Detailed Insights" → `AnalyticsDetailHubView` (NEW)
   - Hub contains navigation to:
     - Emotional Landscape
     - Self-Care Insights
     - Temporal Patterns
     - Growth Indicators

2. **Create Analytics Hub** (`Views/Analytics/AnalyticsDetailHubView.swift`)
   ```swift
   struct AnalyticsDetailHubView: View {
     var body: some View {
       List {
         NavigationLink("Emotional Landscape", destination: EmotionalLandscapeView(...))
         NavigationLink("Self-Care Insights", destination: StrategyUsageView(...))
         NavigationLink("Temporal Patterns", destination: TemporalPatternsView(...))
         NavigationLink("Growth Indicators", destination: GrowthIndicatorsView(...))
       }
     }
   }
   ```

3. **Update Existing Views**
   - Modify `AnalyticsOverviewView` to navigate to hub on button tap
   - Ensure all child views receive necessary ViewModels via `.environmentObject()` or direct injection

**Success Criteria**:
- [ ] All analytics sections accessible from Overview
- [ ] Navigation flows correctly (forward and back)
- [ ] ViewModels properly injected
- [ ] UI tests verify navigation paths

**Design Note**:
Follow watchOS navigation patterns (simple list-based hub, not complex tabs).

---

## Category 3: Performance Validation (MEDIUM PRIORITY)

### Issue TBD-H: Load Testing with 1000+ Journal Entries

**Labels**: `testing`, `performance`, `analytics`
**Milestone**: Analytics Feature (Phase 5)
**Related**: Epic #187, Issue #209

**Description**:

Validate analytics performance with large datasets to ensure success metric: "Analytics load in <2 seconds" (spec line 331, epic success metrics).

**Current State**:
- No load testing has been performed
- Success criterion requires <2 second load time
- Unknown behavior with 1000+ entries

**Requirements**:

1. **Create Test Data Generator**
   - Script or test helper to generate N journal entries
   - Distribute entries across layers, phases, dosages
   - Include strategies, secondary emotions
   - Range: 100, 500, 1000, 5000 entries

2. **Performance Test Suite**
   - Measure backend endpoint response times
   - Measure local calculator computation times
   - Measure SwiftUI view rendering times
   - Test all 5 analytics endpoints

3. **Test Scenarios**
   - Cold start (no cache)
   - Warm start (cached data)
   - Offline mode (local calculation only)
   - Different time ranges (7 days, 30 days, all-time)

4. **Performance Targets**
   - Backend response: <500ms for 1000 entries
   - Local calculation: <1 second for 1000 entries
   - View rendering: <500ms
   - **Total load time: <2 seconds** (per spec)

**Success Criteria**:
- [ ] Test suite generates realistic datasets
- [ ] All analytics load <2 seconds with 1000 entries
- [ ] Performance regressions caught by tests
- [ ] Results documented in performance report

**Deliverables**:
- `tests/performance/test_analytics_performance.py` (backend)
- `PerformanceTests.swift` (frontend)
- Performance report markdown file

---

### Issue TBD-I: Profile Analytics Calculation Performance on Real Device

**Labels**: `testing`, `performance`, `analytics`, `watchOS`
**Milestone**: Analytics Feature (Phase 5)
**Related**: Epic #187, Issue #209

**Description**:

Profile analytics calculations on real Apple Watch hardware to identify bottlenecks and optimize for battery/CPU constraints.

**Current State**:
- No device profiling has been performed
- Unknown battery impact of local calculations
- Simulator performance may not reflect real device

**Requirements**:

1. **Device Testing Setup**
   - Test on Apple Watch Series 8+ (minimum target)
   - Use Xcode Instruments for profiling
   - Measure: CPU usage, memory, battery drain

2. **Profiling Scenarios**
   - Local calculation with 1000 entries (all 5 analytics types)
   - Repeated calculations (user switching time periods)
   - Background refresh scenarios

3. **Optimization Targets**
   - CPU: <50% average during calculation
   - Memory: <10MB additional for calculations
   - Battery: <1% drain per analytics session

4. **Identify Hotspots**
   - Use Time Profiler to find slow functions
   - Check for N+1 queries in SQLite lookups
   - Identify unnecessary data copying

**Success Criteria**:
- [ ] Profiling performed on real device
- [ ] CPU/memory/battery within targets
- [ ] Hotspots identified and documented
- [ ] Optimization recommendations created

**Deliverables**:
- Instruments trace files
- Profiling report with screenshots
- Optimization recommendations document

---

### Issue TBD-J: Optimize Local SQLite Queries for Analytics

**Labels**: `enhancement`, `performance`, `analytics`, `database`
**Milestone**: Analytics Feature (Phase 5)
**Related**: Epic #187, Issue #209, Issue TBD-I

**Description**:

Optimize SQLite database schema and queries for efficient analytics calculations on large datasets.

**Current State**:
- `LocalJournalEntry` table exists with basic schema
- No analytics-specific indexes
- Unknown query performance with 1000+ entries

**Requirements**:

1. **Index Analysis**
   - Identify frequently queried columns in analytics calculations
   - Candidates: `createdAt`, `curriculumID`, `strategyID`, `user_id` (if multi-user)
   - Measure query performance before/after indexing

2. **Create Indexes**
   ```sql
   CREATE INDEX IF NOT EXISTS idx_journal_created ON LocalJournalEntry(createdAt);
   CREATE INDEX IF NOT EXISTS idx_journal_curriculum ON LocalJournalEntry(curriculumID);
   CREATE INDEX IF NOT EXISTS idx_journal_strategy ON LocalJournalEntry(strategyID);
   CREATE INDEX IF NOT EXISTS idx_journal_created_curriculum ON LocalJournalEntry(createdAt, curriculumID);
   ```

3. **Query Optimization**
   - Review `JournalDatabase.swift` fetch methods
   - Add filtered fetch methods for analytics (date range queries)
   - Example: `fetchEntries(from:to:) -> [LocalJournalEntry]`

4. **Migration**
   - Create database migration to add indexes
   - Ensure migration runs on app upgrade
   - Test migration on existing databases

**Success Criteria**:
- [ ] Indexes created for analytics-critical columns
- [ ] Query performance improved by >50% with indexes
- [ ] Migration tested on existing databases
- [ ] No breaking changes to existing queries

**Performance Target**:
- Fetch 1000 entries with date filter: <50ms
- Fetch all entries for overview: <100ms

---

## Category 4: Drill-Down Navigation (LOW PRIORITY - Future Enhancement)

### Issue TBD-K: Implement Drill-Down from Analytics to Journal Entry Details

**Labels**: `enhancement`, `analytics`, `ux`, `future`
**Milestone**: Future Enhancements (NOT Analytics Feature)
**Related**: Epic #187, Spec Section 4.4 (line 529)

**Description**:

Enable drill-down navigation from analytics statistics to specific journal entries that contributed to those statistics.

**Current State**:
- Analytics show aggregated statistics (e.g., "Green 24%")
- No way to see underlying journal entries
- Spec describes this pattern (line 244-247) but not in MVP phases

**Requirements**:

1. **Tap Targets**
   - Mode distribution bar → List of entries for that mode
   - Phase distribution bar → List of entries for that phase
   - Top emotion row → List of entries with that emotion
   - Top strategy row → List of entries using that strategy

2. **Create Journal List View**
   ```swift
   struct JournalEntryListView: View {
     let entries: [LocalJournalEntry]
     let title: String  // e.g., "Green Mode Entries"
   }
   ```

3. **Navigation Pattern**
   - Use `NavigationLink` on tappable elements
   - Pass filtered entry list to detail view
   - Show entry timestamp, primary emotion, strategy (if any)

4. **Entry Detail View** (Optional)
   - Tap entry → See full journal entry details
   - Display: timestamp, primary/secondary emotions, strategy, layer, phase
   - Future: Edit/delete capabilities

**Success Criteria**:
- [ ] Drill-down works for modes, phases, emotions, strategies
- [ ] Entry list shows relevant details
- [ ] Navigation flows correctly
- [ ] Graceful handling of large lists (pagination if needed)

**Deferred Rationale**:
This is a "nice-to-have" feature not required for MVP. Spec lists it under "Future Enhancements" (line 529). Can be added post-launch based on user feedback.

**Recommendation**:
Create this issue but label as `future` and do NOT include in Analytics Feature milestone. Track separately for post-launch iteration.

---

## Summary of Issues to Create

| Issue | Title | Priority | Phase | Blocks Epic Completion? |
|-------|-------|----------|-------|-------------------------|
| TBD-A | Extend LocalAnalyticsCalculator for Self-Care | HIGH | Phase 3 | YES (spec requirement) |
| TBD-B | Extend LocalAnalyticsCalculator for Temporal | HIGH | Phase 4 | YES (spec requirement) |
| TBD-C | Extend LocalAnalyticsCalculator for Growth | HIGH | Phase 4 | YES (spec requirement) |
| TBD-D | Create SelfCareViewModel with Offline Fallback | MEDIUM | Phase 3 | YES (functional) |
| TBD-E | Create TemporalPatternsViewModel with Offline Fallback | MEDIUM | Phase 4 | YES (functional) |
| TBD-F | Create GrowthIndicatorsViewModel with Offline Fallback | MEDIUM | Phase 4 | YES (functional) |
| TBD-G | Integrate All Analytics Views into Navigation | MEDIUM | All | YES (functional) |
| TBD-H | Load Testing with 1000+ Entries | MEDIUM | Phase 5 | NO (validation) |
| TBD-I | Profile Performance on Real Device | MEDIUM | Phase 5 | NO (optimization) |
| TBD-J | Optimize SQLite Queries for Analytics | MEDIUM | Phase 5 | NO (optimization) |
| TBD-K | Drill-Down Navigation to Journal Entries | LOW | Future | NO (enhancement) |

**Blocking Issues**: TBD-A through TBD-G (7 issues) must be completed before epic can be closed.
**Non-Blocking**: TBD-H through TBD-K (4 issues) are quality/enhancement work.

---

## Actions for Existing Issues

### Issues to Close (Backend Already Complete)

**Issue #202: Backend: Self-care analytics endpoint**
- **Status**: Complete (code exists at `analytics.py:596-704`)
- **Closing Comment**:
  ```
  Closing as complete. The `/api/v1/analytics/self-care` endpoint has been implemented in `backend/routers/analytics.py` (lines 596-704) with full functionality:
  - Strategy frequency calculation
  - Top strategies ranking
  - Strategy diversity score
  - Caching support

  Frontend integration tracked in issue #203 and new issue TBD-D (SelfCareViewModel).
  ```

**Issue #205: Backend: Temporal patterns endpoint**
- **Status**: Complete (code exists at `analytics.py:707-751`)
- **Closing Comment**:
  ```
  Closing as complete. The `/api/v1/analytics/temporal` endpoint has been implemented in `backend/routers/analytics.py` (lines 707-751) with full functionality:
  - Hourly distribution
  - Consistency score calculation
  - Caching support

  Frontend integration tracked in issue #207 and new issue TBD-E (TemporalPatternsViewModel).
  ```

**Issue #206: Backend: Growth indicators endpoint**
- **Status**: Complete (code exists at `analytics.py:754-826`)
- **Closing Comment**:
  ```
  Closing as complete. The `/api/v1/analytics/growth` endpoint has been implemented in `backend/routers/analytics.py` (lines 754-826) with full functionality:
  - Medicinal trend (30-day moving average)
  - Layer diversity calculation
  - Phase coverage metrics
  - Caching support

  Frontend integration tracked in issue #208 and new issue TBD-F (GrowthIndicatorsViewModel).
  ```

### Issue to Reopen/Clarify

**Issue #231: Implement LocalAnalyticsCalculator for offline analytics**
- **Current Status**: Closed (assumed complete)
- **Reality**: Only 40% complete (2 of 5 analytics types)
- **Action**: Reopen with comment OR create followup issues TBD-A, TBD-B, TBD-C
- **Recommended Action**: ADD COMMENT, keep closed, new issues track remaining work
- **Comment**:
  ```
  This issue completed `calculateOverview()` and `calculateEmotionalLandscape()` methods, providing offline support for Phases 1-2.

  However, the spec requires offline-first calculation for ALL analytics (spec line 498: "On-Device First: Compute simple metrics on-device when possible").

  Remaining work to achieve full offline support:
  - Issue TBD-A: Extend for self-care analytics
  - Issue TBD-B: Extend for temporal patterns
  - Issue TBD-C: Extend for growth indicators

  These new issues track the completion of the offline-first requirement.
  ```

---

## Epic #187 Description Update

Replace the current epic description with this updated version:

```markdown
# Analytics Feature Epic

Provides users with meaningful insights into their emotional patterns, self-care practices, and developmental trajectory based on journal entries.

## Architecture Decision (BLOCKER) ✅ COMPLETE

**User feedback from spec review**: External storage should be **opt-in**. This requires:
1. ✅ Local SQLite database for on-device journal storage
2. ✅ Feature flag: users choose local-only OR backend sync
3. ✅ Analytics read from local SQLite DB (works for both modes)

**Status**: Architectural foundation complete (Phase 0).

---

## Epic Breakdown

### Phase 0: Data Layer Foundation ✅ **COMPLETE** (4/4 issues)
- ✅ #188 - Implement local SQLite database for on-device journal storage
- ✅ #189 - Implement JournalQueue service with file-based persistence
- ✅ #190 - Implement opt-in backend sync feature flag
- ✅ #191 - Migrate JournalClient to local-first architecture

### Phase 1: Analytics Overview (MVP) ✅ **COMPLETE** (4/4 issues)
- ✅ #192 - Backend: Analytics overview endpoint
- ✅ #193 - Frontend: Analytics overview UI
- ✅ #194 - Circular progress component for medicinal ratio
- ✅ #195 - Streak calculation and display

### Phase 2: Emotional Landscape 🔄 **IN PROGRESS** (4/5 issues, 80%)
- ✅ #196 - Backend: Emotional landscape endpoint
- ✅ #200 - Horizontal bar chart component
- 🔄 #197 - Frontend: Mode distribution view (PR #228 - awaiting merge)
- 🔄 #198 - Frontend: Phase journey view (PR #229 - awaiting merge)
- 🔄 #199 - Frontend: Dosage deep dive (PR #230 - awaiting merge)

**Blocked**: Phase 2 PRs need review/merge before continuing.

### Phase 3: Self-Care Insights 🔄 **IN PROGRESS** (1/6 issues, 17%)
- ✅ #202 - Backend: Self-care analytics endpoint (COMPLETE - closing)
- ⏳ #TBD-A - Extend LocalAnalyticsCalculator for self-care analytics (NEW)
- ⏳ #TBD-D - Create SelfCareViewModel with offline fallback (NEW)
- ⏳ #203 - Frontend: Strategy usage view (needs ViewModel integration)
- ⏳ #204 - Frontend: Strategy recommendations

### Phase 4: Temporal Patterns & Growth 🔄 **IN PROGRESS** (2/8 issues, 25%)
- ✅ #205 - Backend: Temporal patterns endpoint (COMPLETE - closing)
- ✅ #206 - Backend: Growth indicators endpoint (COMPLETE - closing)
- ⏳ #TBD-B - Extend LocalAnalyticsCalculator for temporal patterns (NEW)
- ⏳ #TBD-C - Extend LocalAnalyticsCalculator for growth indicators (NEW)
- ⏳ #TBD-E - Create TemporalPatternsViewModel with offline fallback (NEW)
- ⏳ #TBD-F - Create GrowthIndicatorsViewModel with offline fallback (NEW)
- ⏳ #207 - Frontend: Temporal patterns view (needs ViewModel integration)
- ⏳ #208 - Frontend: Growth indicators view (needs ViewModel integration)

### Phase 5: Polish & Optimization ⏳ **NOT STARTED** (0/7 issues, 0%)
- ⏳ #209 - Performance optimization and caching
- ⏳ #210 - Empty states and loading states
- ⏳ #211 - Animations and transitions
- ⏳ #212 - Accessibility audit
- ⏳ #TBD-H - Load testing with 1000+ entries (NEW)
- ⏳ #TBD-I - Profile performance on real device (NEW)
- ⏳ #TBD-J - Optimize SQLite queries for analytics (NEW)

### Integration ⏳ **NOT STARTED**
- ⏳ #TBD-G - Integrate all analytics views into navigation hierarchy (NEW)

### Future Enhancements (Not Blocking)
- ⏳ #TBD-K - Drill-down navigation to journal entries (DEFERRED)

---

## Progress Summary

**Phase 0**: ✅ 100% (4/4) - Production ready
**Phase 1**: ✅ 100% (4/4) - Production ready
**Phase 2**: 🔄 80% (4/5) - Awaiting PR merges
**Phase 3**: 🔄 17% (1/6) - Backend done, frontend needs work
**Phase 4**: 🔄 25% (2/8) - Backend done, frontend needs work
**Phase 5**: ⏳ 0% (0/7) - Not started
**Integration**: ⏳ 0% (0/1) - Not started

**Overall Epic**: 15 of 34 issues closed (44%)
**Functional Completeness**: ~50% (backend 100%, frontend 40%)

---

## Critical Gaps Identified (2026-01-16)

### 1. Offline-First Requirement Not Met ⚠️
**Spec Requirement** (line 498): "On-Device First: Compute simple metrics on-device when possible"

**Current State**: `LocalAnalyticsCalculator` only supports 2 of 5 analytics types (overview, emotional-landscape).

**Impact**: Users without backend sync cannot access self-care, temporal, or growth analytics.

**Resolution**: Issues TBD-A, TBD-B, TBD-C extend calculator for remaining types.

### 2. Frontend Views Unreachable ⚠️
**Current State**: Views exist for Phases 3-4 but have no ViewModels and no navigation integration.

**Impact**: Backend endpoints cannot be accessed from UI.

**Resolution**: Issues TBD-D, TBD-E, TBD-F (ViewModels) + TBD-G (navigation).

### 3. Success Metrics Untested ⚠️
**Spec Requirement**: "Analytics load in <2 seconds" (line 331), "No crashes with 1000+ entries"

**Current State**: No performance testing or scale validation.

**Resolution**: Issues TBD-H, TBD-I, TBD-J validate performance.

---

## Key Design Decisions (from spec v1.1)

1. **Terminology**: "Modes" not "Layers" in UI
2. **Framing**: Descriptive, not normative (no "ideal" ratios)
3. **Hierarchy**: All modes are equally valid (not spiral progression)
4. **Strategy Effectiveness**: Defer to future (requires follow-up pings)
5. **Privacy**: Local-first, opt-in backend sync
6. **Notifications**: No analytics-triggered notifications
7. **Data Retention**: Forever (unless GDPR request)

---

## Success Metrics (Definition of Done)

### Functional Completeness
- ✅ Users can view analytics without backend connection (Phases 1-2 only)
- ⏳ Users can view analytics without backend connection (ALL phases) - **BLOCKED by TBD-A/B/C**
- ⏳ All 5 backend endpoints reachable from UI - **BLOCKED by TBD-G**
- ⏳ Analytics load in <2 seconds - **NEEDS VALIDATION (TBD-H/I)**
- ✅ No crashes with empty journal
- ⏳ No crashes with 1000+ entries - **NEEDS VALIDATION (TBD-H)**

### Spec Compliance
- ✅ Privacy-first architecture (local SQLite + opt-in sync)
- ⏳ On-device calculation for all analytics - **PARTIAL (2/5 types)**
- ✅ Terminology correct ("Modes" not "Layers")
- ⏳ Performance targets met - **NEEDS VALIDATION**

### Quality Gates
- ⏳ Performance tested with 1000+ entries (TBD-H)
- ⏳ Empty state handling for all views (Phase 5, #210)
- ⏳ Error handling for all views (implicit in ViewModel issues)
- ⏳ Accessibility audit complete (Phase 5, #212)

---

## Reference

- Spec: `prompts/plans/analytics-feature-spec.md` (v1.1)
- Related: Journal system (`backend/models.py`, `JournalClient.swift`)
- Analysis: `prompts/claude-comm/analytics-epic-missing-issues.md`
```

---

## Implementation Priority Order

For completing this epic efficiently, implement issues in this order:

1. **Phase 2 Completion** (unblock current PRs)
   - Review/merge PRs #228, #229, #230

2. **Offline Calculator Extensions** (critical spec requirement)
   - TBD-A: Self-care calculator
   - TBD-B: Temporal calculator
   - TBD-C: Growth calculator

3. **ViewModels** (enable frontend access)
   - TBD-D: SelfCareViewModel
   - TBD-E: TemporalPatternsViewModel
   - TBD-F: GrowthIndicatorsViewModel

4. **Navigation Integration** (make features accessible)
   - TBD-G: Navigation hierarchy

5. **Performance Validation** (Phase 5)
   - TBD-H: Load testing
   - TBD-I: Device profiling
   - TBD-J: SQLite optimization

6. **Polish** (Phase 5 remaining)
   - #209: Caching
   - #210: Empty states
   - #211: Animations
   - #212: Accessibility

7. **Future** (post-launch)
   - TBD-K: Drill-down navigation

---

## Conclusion

This epic requires **11 new issues** to address critical gaps in offline-first support and frontend integration. The backend is 100% complete, but the frontend is only ~40% functional.

**Estimated Remaining Effort**: 3-4 weeks to complete blocking issues (TBD-A through TBD-G).

**Epic should NOT be closed until**:
- All 7 blocking issues resolved
- Success metrics validated
- Phase 2 PRs merged
