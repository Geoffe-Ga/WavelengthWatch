# Test Suite Quarantine Investigation - 2025-11-19

## Summary

Investigation into optimizing watchOS test execution by identifying which test suites require individual simulator instances vs. which can run together.

## Background

### Current State

The `run-tests-individually.sh` script runs **all 12 test suites** with separate simulator instances to avoid SIGSEGV crashes. This was implemented in PR #55 (commit b67963d) as a workaround for test crashes.

### Root Cause Discovery

Through analysis of git history, the actual root cause of SIGSEGV crashes was identified:

- **Commit 3945b6a**: "Remove @StateObject access from App init to prevent SIGSEGV crashes"
- **Problem**: Accessing `@StateObject` property in `WavelengthWatchApp.init()` before SwiftUI initialized it
- **Fix**: Removed the property access from `init()`

The blanket "run all suites individually" approach may have been overcautious after this fix.

## Test Suites (12 total)

1. AppConfigurationTests
2. CatalogRepositoryTests
3. PhaseNavigatorTests
4. NotificationDelegateTests
5. NotificationSchedulerTests
6. ContentViewModelTests
7. ContentViewModelInitiationContextTests
8. ScheduleViewModelTests
9. JournalUIInteractionTests
10. JournalScheduleTests
11. JournalClientTests
12. MysticalJournalIconTests

## Hypothesis

Since the root cause (@StateObject initialization) was fixed in commit 3945b6a, most or all test suites may now be able to run together on a single simulator.

## GitHub Issues Created

### [#68 - Optimize watchOS test execution to reduce simulator usage](https://github.com/Geoffe-Ga/WavelengthWatch/issues/68)

**Type**: Epic/Parent issue
**Labels**: `test-suite-quarantine`, `performance`

Parent tracking issue for the entire optimization effort.

**Expected Outcomes**:
- Best case: All suites run together (1 simulator)
- Likely case: Most suites together, 1-2 quarantined (2-3 simulators)
- Worst case: Current behavior (12 simulators)

### [#69 - Investigate which test suites can run concurrently](https://github.com/Geoffe-Ga/WavelengthWatch/issues/69)

**Type**: Investigation task
**Labels**: `test-suite-quarantine`

**Methodology**:
1. **Step 1**: Run all suites together - if success, done
2. **Step 2**: If failures, use binary search to identify problematic suite(s)
3. **Step 3**: Document findings

**Timeline**: 1-2 hours

### [#70 - Update run-tests-individually.sh to group compatible suites](https://github.com/Geoffe-Ga/WavelengthWatch/issues/70)

**Type**: Implementation task
**Labels**: `test-suite-quarantine`, `performance`
**Depends on**: #69

Will update the script to:
- Group stable suites together
- Quarantine only problematic suites
- Maintain CLI backwards compatibility

**Performance Impact**:
- Current: 12 test runs
- With 2 quarantined: 3 test runs (~4x faster)
- With 0 quarantined: 1 test run (~12x faster)

## Historical Context

### Timeline of Test Crashes

1. **Pre-PR #54**: Tests working
2. **PR #54 (commit 263e847)**: Introduced notification system with `@StateObject` access in `init()` → tests broke
3. **Commit 3945b6a**: Fixed `@StateObject` access → SIGSEGV eliminated
4. **Commit b67963d**: Added `run-tests-individually.sh` as safety measure
5. **Now**: Opportunity to optimize based on actual problematic suites

### Key Commits

- **263e847**: Introduced the bug (PR #54 merge)
- **3945b6a**: Fixed the bug (App initialization)
- **b67963d**: Added individual test runner
- **5ac545b**: Merged PR #55 with test fixes

## Investigation Commands

### Test All Suites Together

```bash
cd frontend/WavelengthWatch
xcodebuild test \
  -scheme "WavelengthWatch Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" \
  2>&1 | tee /tmp/all_suites_test.log

grep -E "(SIGSEGV|crashed|signal|Early unexpected exit)" /tmp/all_suites_test.log
```

### Binary Search Example (if needed)

```bash
# Test first 6 suites
xcodebuild test \
  -scheme "WavelengthWatch Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" \
  -only-testing:"WavelengthWatch Watch AppTests/AppConfigurationTests" \
  -only-testing:"WavelengthWatch Watch AppTests/CatalogRepositoryTests" \
  -only-testing:"WavelengthWatch Watch AppTests/PhaseNavigatorTests" \
  -only-testing:"WavelengthWatch Watch AppTests/NotificationDelegateTests" \
  -only-testing:"WavelengthWatch Watch AppTests/NotificationSchedulerTests" \
  -only-testing:"WavelengthWatch Watch AppTests/ContentViewModelTests"

# Test last 6 suites
xcodebuild test \
  -scheme "WavelengthWatch Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" \
  -only-testing:"WavelengthWatch Watch AppTests/ContentViewModelInitiationContextTests" \
  -only-testing:"WavelengthWatch Watch AppTests/ScheduleViewModelTests" \
  -only-testing:"WavelengthWatch Watch AppTests/JournalUIInteractionTests" \
  -only-testing:"WavelengthWatch Watch AppTests/JournalScheduleTests" \
  -only-testing:"WavelengthWatch Watch AppTests/JournalClientTests" \
  -only-testing:"WavelengthWatch Watch AppTests/MysticalJournalIconTests"
```

Continue subdividing until problematic suite(s) identified.

## Current CI Impact

From `.github/workflows/ci.yml`:
- CI timeout: 25 minutes
- All 12 suites run individually via script
- Each suite boots a new simulator

**Optimization potential**:
- If all suites can run together: ~20 minute savings
- If 2 suites need quarantine: ~15 minute savings

## Results

### Investigation Outcome (2025-11-19)

**Result**: ✅ **ALL test suites can run together successfully**

Tested via:
```bash
xcodebuild test -scheme "WavelengthWatch Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)"
```

**Outcome**:
- All 12 test suites passed
- No SIGSEGV crashes
- No "Early unexpected exit" errors
- Total execution time: ~1 minute (vs. ~12 minutes individually)
- **Performance improvement: ~12x faster**

### Conclusion

The hypothesis was correct: after fixing the `@StateObject` initialization bug in commit 3945b6a, the individual test runner was unnecessarily conservative. All suites can now run together on a single simulator.

## Implementation

Updated `run-tests-individually.sh` to:
- **Default behavior**: Run all suites together (optimized mode)
- **Legacy mode**: `--individual` flag to run suites separately if needed
- **Single suite**: Automatically uses individual mode
- **Backwards compatible**: All original CLI arguments still work

### Performance Impact

- **Before**: 12 test runs @ ~1 min each = ~12 minutes
- **After**: 1 test run = ~1 minute
- **Improvement**: ~12x faster (92% time reduction)

### CI Impact

CI workflow now completes watchOS tests in ~1 minute instead of ~12 minutes, saving ~11 minutes per pipeline run.

## Next Steps

1. ~~Execute investigation per issue #69~~ ✅ Complete
2. ~~Document findings in issue #69~~ ✅ Complete
3. ~~Implement optimized script per issue #70~~ ✅ Complete
4. ~~Update CI workflow if needed~~ ✅ No changes needed (script is backwards compatible)
5. ~~Update CLAUDE.md documentation~~ ✅ Complete

## Success Criteria

- Reduced number of simulator instances during testing
- Faster local test execution
- Faster CI pipeline
- Maintained test reliability (no new failures)
- Clear documentation of which suites need isolation and why

## References

- **Script**: `frontend/WavelengthWatch/run-tests-individually.sh`
- **CI workflow**: `.github/workflows/ci.yml`
- **Documentation**: `CLAUDE.md` (lines 47-48)
- **Fix commit**: 3945b6a
- **Script commit**: b67963d
