# Backlog Prioritization Plan
**Date**: 2026-01-05

## Backlog Grooming Summary

### Closed Issues: None Required
All merged PRs have already had their associated issues closed. The backlog is clean with only 2 open issues remaining.

### Open Issues (2 Total)

#### Issue #183: Strategy cards render tiny due to unclamped scroll position bindings
- **Status**: Being fixed by PR #184 (currently in review)
- **Priority**: HIGH (P0)
- **Blockers**: Awaiting CI pass and LGTM
- **Next Action**: Merge PR #184 after CI green + LGTM, then close issue

#### Issue #182: Card shifts left ~2 pixels approximately 1 second after loading when scrolling up
- **Status**: Open, not yet started
- **Priority**: MEDIUM (P1) - Polish/UX issue
- **Type**: Bug - UI timing/animation issue
- **Complexity**: Low-Medium
- **Root Cause Hypothesis**: Layer indicator overlay show/hide animation causing layout shift
- **Parallelizable**: Yes - can be worked on independently

## Prioritization

### Immediate Priority (Next PR)
**Issue #182** - Card shifts left ~2 pixels after 1 second when scrolling up
- **Why High Priority**:
  - Only remaining open issue after #183 is resolved
  - Affects core UX (user sees jarring visual shift)
  - Well-defined reproduction steps and hypothesis
  - Clean slate to fix without conflicts

- **Estimated Complexity**: Low-Medium
  - Clear hypothesis: layer indicator animation timing
  - Isolated to ContentView.swift layer indicator overlay
  - Likely involves animation/timing adjustments

- **Testing Strategy**:
  - Manual testing: scroll upward, observe timing of shift
  - Test with layer indicator disabled to confirm root cause
  - Verify fix doesn't affect indicator functionality

- **Success Criteria**:
  - Cards render in final position immediately
  - No delayed horizontal shift observable
  - Layer indicator animation still works correctly
  - All existing tests pass

### Future Work (Post-Issue #182)
Once both issues are resolved, the backlog will be **empty**. Potential next steps:
1. Review analytics implementation roadmap
2. Plan App Store submission requirements
3. Performance optimization opportunities
4. Feature backlog review with stakeholders

## Parallelization Assessment

**Current State**: Only 1 actionable issue (#182) after PR #184 merges
- Cannot parallelize with only 1 issue remaining
- Focus on delivering high-quality fix for #182
- Use TDD approach as specified

**Recommendation**:
- Complete PR #184 merge first
- Then focus exclusively on #182 with full attention
- Apply TDD rigorously: write failing test, implement fix, iterate until green

## Next Steps

1. ✅ Groom backlog - COMPLETE (no issues to close)
2. ✅ Create prioritization plan - COMPLETE (this document)
3. ⏳ Resolve merge conflicts on PR #184 - COMPLETE
4. ⏳ Push and wait for CI on PR #184 - IN PROGRESS
5. ⏳ Merge PR #184 after LGTM and CI pass
6. ⏳ Close issue #183
7. ⏳ Begin work on issue #182 using TDD
8. ⏳ Submit PR for #182
9. ⏳ Iterate until green and LGTM

---

**Summary**: Clean backlog with clear path forward. One issue in review, one issue ready for implementation. No blockers, no wont-do items, no technical debt accumulation.
