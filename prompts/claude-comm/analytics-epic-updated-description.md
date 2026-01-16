# Analytics Feature Epic - Updated Description

**Purpose**: Copy-paste this as the new description for issue #187
**Date**: 2026-01-16

---

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

**Note**: Phase 2 PRs need review/merge before continuing.

### Phase 3: Self-Care Insights 🔄 **IN PROGRESS** (1/6 issues, 17%)
- ✅ #202 - Backend: Self-care analytics endpoint (CLOSED - complete)
- ⏳ Issue TBD-A - Extend LocalAnalyticsCalculator for self-care analytics
- ⏳ Issue TBD-D - Create SelfCareViewModel with offline fallback
- ⏳ #203 - Frontend: Strategy usage view (needs ViewModel integration)
- ⏳ #204 - Frontend: Strategy recommendations

### Phase 4: Temporal Patterns & Growth 🔄 **IN PROGRESS** (2/8 issues, 25%)
- ✅ #205 - Backend: Temporal patterns endpoint (CLOSED - complete)
- ✅ #206 - Backend: Growth indicators endpoint (CLOSED - complete)
- ⏳ Issue TBD-B - Extend LocalAnalyticsCalculator for temporal patterns
- ⏳ Issue TBD-C - Extend LocalAnalyticsCalculator for growth indicators
- ⏳ Issue TBD-E - Create TemporalPatternsViewModel with offline fallback
- ⏳ Issue TBD-F - Create GrowthIndicatorsViewModel with offline fallback
- ⏳ #207 - Frontend: Temporal patterns view (needs ViewModel integration)
- ⏳ #208 - Frontend: Growth indicators view (needs ViewModel integration)

### Phase 5: Polish & Optimization ⏳ **NOT STARTED** (0/7 issues, 0%)
- ⏳ #209 - Performance optimization and caching
- ⏳ #210 - Empty states and loading states
- ⏳ #211 - Animations and transitions
- ⏳ #212 - Accessibility audit
- ⏳ Issue TBD-H - Load testing with 1000+ journal entries
- ⏳ Issue TBD-I - Profile analytics performance on real device
- ⏳ Issue TBD-J - Optimize local SQLite queries for analytics

### Integration ⏳ **NOT STARTED**
- ⏳ Issue TBD-G - Integrate all analytics views into navigation hierarchy

### Future Enhancements (Not Blocking Epic)
- ⏳ Issue TBD-K - Drill-down navigation to journal entry details (DEFERRED to post-launch)

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

## Critical Gaps Identified (Analysis: 2026-01-16)

### 1. Offline-First Requirement Not Fully Met ⚠️
**Spec Requirement** (line 498): "On-Device First: Compute simple metrics on-device when possible"

**Current State**: `LocalAnalyticsCalculator` only supports 2 of 5 analytics types (overview, emotional-landscape).

**Impact**: Users without backend sync cannot access self-care, temporal, or growth analytics.

**Resolution**: Issues TBD-A, TBD-B, TBD-C extend calculator for remaining analytics types.

### 2. Frontend Views Unreachable ⚠️
**Current State**: Views exist for Phases 3-4 but have no ViewModels and no navigation integration.

**Impact**: Backend endpoints cannot be accessed from UI.

**Resolution**: Issues TBD-D, TBD-E, TBD-F create ViewModels + Issue TBD-G adds navigation.

### 3. Success Metrics Untested ⚠️
**Spec Requirement**: "Analytics load in <2 seconds" (line 331), "No crashes with 1000+ entries"

**Current State**: No performance testing or scale validation performed.

**Resolution**: Issues TBD-H, TBD-I, TBD-J validate performance and optimize queries.

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
- ✅ Users can view analytics without backend (Phases 1-2 only)
- ⏳ Users can view analytics without backend (ALL phases) - **BLOCKED by TBD-A/B/C**
- ⏳ All 5 backend endpoints reachable from UI - **BLOCKED by TBD-G**
- ⏳ Analytics load in <2 seconds - **NEEDS VALIDATION (TBD-H/I)**
- ✅ No crashes with empty journal
- ⏳ No crashes with 1000+ entries - **NEEDS VALIDATION (TBD-H)**

### Spec Compliance
- ✅ Privacy-first architecture (local SQLite + opt-in sync)
- ⏳ On-device calculation for all analytics - **PARTIAL (2/5 types complete)**
- ✅ Terminology correct ("Modes" not "Layers")
- ⏳ Performance targets met - **NEEDS VALIDATION**

### Quality Gates
- ⏳ Performance tested with 1000+ entries (Issue TBD-H)
- ⏳ Empty state handling for all views (Phase 5, #210)
- ⏳ Error handling for all views (implicit in ViewModel issues)
- ⏳ Accessibility audit complete (Phase 5, #212)

**Epic cannot be closed until all "Functional Completeness" and "Spec Compliance" criteria are met.**

---

## Reference Documents

- **Spec**: `prompts/plans/analytics-feature-spec.md` (v1.1)
- **Analysis**: `prompts/claude-comm/analytics-epic-missing-issues.md` (2026-01-16)
- **Issue Actions**: `prompts/claude-comm/analytics-epic-issue-actions.md`
- **Related Code**: `backend/models.py`, `backend/routers/analytics.py`, `JournalClient.swift`, `LocalAnalyticsCalculator.swift`

---

## Implementation Priority

For efficient completion, implement issues in this order:

1. **Unblock Phase 2**: Review/merge PRs #228, #229, #230
2. **Offline Extensions**: TBD-A, TBD-B, TBD-C (critical spec requirement)
3. **ViewModels**: TBD-D, TBD-E, TBD-F (enable frontend access)
4. **Navigation**: TBD-G (make features accessible to users)
5. **Performance**: TBD-H, TBD-I, TBD-J (validation & optimization)
6. **Polish**: #209, #210, #211, #212 (final quality pass)
7. **Future**: TBD-K (post-launch enhancement)

**Estimated Effort for Blocking Issues**: 3-4 weeks (TBD-A through TBD-G)
