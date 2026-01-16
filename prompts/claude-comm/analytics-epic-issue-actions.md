# Analytics Epic - Issue Actions Summary

**Date**: 2026-01-16
**Purpose**: Specific actions to take on existing issues #202, #205, #206, #231

---

## Issues to Close

### Issue #202: Backend: Self-care analytics endpoint

**Current Status**: Open
**New Status**: Should be CLOSED
**Reason**: Backend implementation complete

**Evidence**:
- Code location: `backend/routers/analytics.py` lines 596-704
- Endpoint: `GET /api/v1/analytics/self-care`
- Functionality: Strategy frequency, top strategies, diversity score, caching

**Closing Comment** (copy-paste into GitHub):

```markdown
Closing as complete ✅

The `/api/v1/analytics/self-care` endpoint has been fully implemented in `backend/routers/analytics.py` (lines 596-704) with the following functionality:

- ✅ Strategy frequency calculation
- ✅ Top strategies ranking (configurable limit)
- ✅ Strategy diversity score
- ✅ Response caching for performance

**Backend work is complete.** Frontend integration is tracked separately:
- #203 - Frontend: Strategy usage view (needs ViewModel)
- #TBD-A - Extend LocalAnalyticsCalculator for offline self-care analytics
- #TBD-D - Create SelfCareViewModel with offline fallback

This issue covered backend implementation only and is now done.
```

---

### Issue #205: Backend: Temporal patterns endpoint

**Current Status**: Open
**New Status**: Should be CLOSED
**Reason**: Backend implementation complete

**Evidence**:
- Code location: `backend/routers/analytics.py` lines 707-751
- Endpoint: `GET /api/v1/analytics/temporal`
- Functionality: Hourly distribution, consistency score, caching

**Closing Comment** (copy-paste into GitHub):

```markdown
Closing as complete ✅

The `/api/v1/analytics/temporal` endpoint has been fully implemented in `backend/routers/analytics.py` (lines 707-751) with the following functionality:

- ✅ Hourly distribution (entries by hour of day)
- ✅ Consistency score calculation
- ✅ Response caching for performance

**Backend work is complete.** Frontend integration is tracked separately:
- #207 - Frontend: Temporal patterns view (needs ViewModel)
- #TBD-B - Extend LocalAnalyticsCalculator for offline temporal analytics
- #TBD-E - Create TemporalPatternsViewModel with offline fallback

This issue covered backend implementation only and is now done.
```

---

### Issue #206: Backend: Growth indicators endpoint

**Current Status**: Open
**New Status**: Should be CLOSED
**Reason**: Backend implementation complete

**Evidence**:
- Code location: `backend/routers/analytics.py` lines 754-826
- Endpoint: `GET /api/v1/analytics/growth`
- Functionality: Medicinal trend, layer diversity, phase coverage, caching

**Closing Comment** (copy-paste into GitHub):

```markdown
Closing as complete ✅

The `/api/v1/analytics/growth` endpoint has been fully implemented in `backend/routers/analytics.py` (lines 754-826) with the following functionality:

- ✅ Medicinal trend calculation (30-day moving average)
- ✅ Layer diversity metrics
- ✅ Phase coverage calculation
- ✅ Response caching for performance

**Backend work is complete.** Frontend integration is tracked separately:
- #208 - Frontend: Growth indicators view (needs ViewModel)
- #TBD-C - Extend LocalAnalyticsCalculator for offline growth analytics
- #TBD-F - Create GrowthIndicatorsViewModel with offline fallback

This issue covered backend implementation only and is now done.
```

---

## Issue to Clarify (NOT Reopen)

### Issue #231: Implement LocalAnalyticsCalculator for offline analytics

**Current Status**: Closed
**New Status**: Keep CLOSED, add clarifying comment
**Reason**: Partial completion - need to clarify scope and track remaining work separately

**What Was Completed**:
- ✅ `calculateOverview()` - Supports overview analytics offline
- ✅ `calculateEmotionalLandscape()` - Supports emotional landscape offline
- ✅ Protocol definition: `LocalAnalyticsCalculatorProtocol`
- ✅ Curriculum lookup infrastructure

**What Was NOT Completed**:
- ❌ Self-care analytics (strategies)
- ❌ Temporal patterns analytics
- ❌ Growth indicators analytics

**Why This Matters**:
The spec requires offline-first analytics (line 498: "On-Device First: Compute simple metrics on-device when possible"). Without the remaining calculator methods, users who disable backend sync cannot access 60% of analytics features.

**Clarifying Comment** (add to closed issue #231):

```markdown
## Scope Clarification

This issue successfully implemented offline analytics support for **Phases 1-2**:
- ✅ `calculateOverview()` - Fully functional
- ✅ `calculateEmotionalLandscape()` - Fully functional

**However**, the spec requires offline-first calculation for **all analytics** (spec line 498: "On-Device First: Compute simple metrics on-device when possible").

### Remaining Work

To achieve full offline-first compliance, we need to extend `LocalAnalyticsCalculator` for Phases 3-4:

**New Issues Created**:
- #TBD-A - Extend LocalAnalyticsCalculator for self-care analytics
- #TBD-B - Extend LocalAnalyticsCalculator for temporal patterns
- #TBD-C - Extend LocalAnalyticsCalculator for growth indicators

**Impact of Gap**: Currently, users who disable backend sync (via `SyncSettings.isCloudSyncEnabled = false`) can only view overview and emotional landscape analytics. They cannot access:
- Self-care insights (strategy usage, diversity)
- Temporal patterns (time of day, consistency)
- Growth indicators (medicinal trend, layer diversity)

This is a **critical blocker** for the epic's success metric: "Users can view analytics without backend connection" (epic description).

### Recommendation

Keep this issue closed as the work scoped for it is complete. Track the extension work via the new issues listed above. Together, those issues will complete the offline-first requirement.
```

---

## Summary of Actions

| Issue | Action | Reason |
|-------|--------|--------|
| #202 | CLOSE with comment | Backend complete, frontend tracked separately |
| #205 | CLOSE with comment | Backend complete, frontend tracked separately |
| #206 | CLOSE with comment | Backend complete, frontend tracked separately |
| #231 | ADD COMMENT (keep closed) | Clarify partial completion, point to new issues |

---

## Next Steps After Closing/Commenting

1. **Create 11 new issues** using descriptions from `analytics-epic-missing-issues.md`
2. **Update epic #187 description** with revised progress tracking
3. **Review/merge Phase 2 PRs** (#228, #229, #230) to unblock progress
4. **Prioritize blocking issues**: TBD-A through TBD-G must complete before epic can close

---

## How to Use This Document

### For Manual GitHub Actions:

1. Navigate to issue #202 on GitHub
2. Copy the "Closing Comment" text above
3. Paste into a new comment
4. Close the issue
5. Repeat for #205, #206
6. For #231: Add comment but **do NOT reopen**

### For Automated Actions (if using gh CLI):

```bash
# Close #202
gh issue close 202 --comment "$(cat <<'EOF'
Closing as complete ✅
[... paste full comment here ...]
EOF
)"

# Close #205
gh issue close 205 --comment "$(cat <<'EOF'
[... paste comment ...]
EOF
)"

# Close #206
gh issue close 206 --comment "$(cat <<'EOF'
[... paste comment ...]
EOF
)"

# Comment on #231 (keep open)
gh issue comment 231 --body "$(cat <<'EOF'
[... paste comment ...]
EOF
)"
```

---

## Verification Checklist

After completing these actions, verify:

- [ ] Issue #202 is closed with comment
- [ ] Issue #205 is closed with comment
- [ ] Issue #206 is closed with comment
- [ ] Issue #231 has clarifying comment (still closed)
- [ ] 11 new issues created (TBD-A through TBD-K)
- [ ] Epic #187 description updated with new progress tracking
- [ ] Epic shows ~44% complete (15/34 issues)

---
