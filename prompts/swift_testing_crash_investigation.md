# 2025-10-29: Swift Testing SIGSEGV Crash Investigation

**Status**: 🔴 CRITICAL — Tests still crashing after @MainActor refactoring
**Discovery Date**: October 29, 2025
**Context**: MainActor refactoring (Phases 1-4) completed but tests STILL crash

---

## Executive Summary

**The @MainActor refactoring did NOT resolve the test crashes.** All Swift Testing unit tests (82 tests) continue to fail with SIGSEGV before execution even begins. The error signature shows "operation never finished bootstrapping," indicating the test runner itself is crashing during initialization, not during test execution.

**Root cause is NOT @MainActor** — it's a deeper Swift Testing + watchOS Simulator incompatibility.

---

## Test Results (October 29, 2025, 08:55 AM)

### Build Status
✅ **Build: SUCCESS** — All targets compile without errors

### Test Status
❌ **Tests: FAILED** — All unit tests crash with SIGSEGV
✅ **UI Tests: PASSED** — 3/3 UI tests pass successfully

### Unit Test Crash Pattern

**Every Swift Testing test suite crashes identically:**

```
Run test suite [TestSuiteName] encountered an error
(Early unexpected exit, operation never finished bootstrapping - no restart will be attempted.
(Underlying Error: Test crashed with signal segv.))
```

**Affected test suites** (12 of 12):
1. MysticalJournalIconTests
2. CatalogRepositoryTests
3. AppConfigurationTests
4. ContentViewModelInitiationContextTests
5. JournalUIInteractionTests
6. NotificationDelegateTests
7. ScheduleViewModelTests
8. JournalClientTests
9. JournalScheduleTests
10. PhaseNavigatorTests
11. NotificationSchedulerTests
12. ContentViewModelTests

**Test cases that fail** (20+ tests, all with 0.000 seconds execution time):
- All tests fail immediately before any code executes
- Execution time of 0.000 seconds indicates crash during test runner initialization
- No test code is ever reached

### UI Tests (Working Correctly)

✅ 3/3 UI tests pass:
- `WavelengthWatch_Watch_AppUITests.testExample()` — PASSED (2.172s)
- `WavelengthWatch_Watch_AppUITests.testLaunchPerformance()` — PASSED (21.320s)
- `WavelengthWatch_Watch_AppUITestsLaunchTests.testLaunch()` — PASSED (3.822s + 3.156s)

**Key insight**: XCTest-based UI tests work fine. Only Swift Testing framework crashes.

---

## Critical Observations

### 1. The Problem Is Swift Testing, Not @MainActor

**Evidence:**
- @MainActor was removed from all classes (Phases 1-4 complete)
- @MainActor only exists on individual methods now
- Tests still crash with identical signature
- **Conclusion**: @MainActor was a red herring

### 2. Crash Happens BEFORE Test Execution

**Evidence:**
- Error message: "operation never finished bootstrapping"
- All test cases show 0.000 seconds execution time
- No test code is reached
- **Conclusion**: Swift Testing runtime itself is crashing during initialization

### 3. XCTest Works, Swift Testing Doesn't

**Evidence:**
- All 3 UI tests (XCTest framework) pass
- All 82 unit tests (Swift Testing framework) crash
- **Conclusion**: This is a Swift Testing + watchOS Simulator incompatibility

### 4. Parallelization May Be a Factor

**Evidence:**
- Tests run on "Clone 1", "Clone 3" of simulator
- Multiple test suites started simultaneously
- watchOS Simulator may not support Swift Testing parallelization
- **Conclusion**: Test runner parallelization may be triggering the crash

---

## Root Cause Hypothesis

**Swift Testing framework is incompatible with watchOS Simulator at the runtime level.**

The crash occurs during the test runner's bootstrap phase, before any test code executes. This suggests:

1. **Swift Testing runtime initialization fails on watchOS Simulator**
2. **Parallelization of test execution may trigger simulator instability**
3. **watchOS Simulator may lack support for Swift Testing's concurrency model**

The @MainActor refactoring was based on incorrect hypothesis that actor isolation was the issue. The real issue is that Swift Testing's test runner itself cannot initialize properly on watchOS Simulator.

---

## Failed Approach: @MainActor Refactoring

**Phases 1-4 completed:**
- ContentViewModel refactored (893a308)
- ScheduleViewModel refactored (439df51)
- NotificationDelegate refactored (d23aadb)
- All tests updated to remove @MainActor

**Result: NO IMPROVEMENT**
- Tests still crash with identical error
- @MainActor was not the root cause
- Refactoring provided architectural benefits but didn't fix testing

---

## Solution Paths

### Path 1: Convert to XCTest (HIGH EFFORT, HIGH SUCCESS PROBABILITY)

**Rationale:**
- UI tests using XCTest work perfectly
- XCTest has proven watchOS Simulator compatibility
- 82 tests need conversion from Swift Testing → XCTest

**Implementation:**
- Replace `@Test` with XCTest `func test*()` pattern
- Replace `#expect` with `XCTAssert*` macros
- Change test struct to class inheriting from `XCTestCase`
- Update async test handling

**Pros:**
- Proven to work (UI tests pass)
- Well-documented framework
- Stable on watchOS Simulator

**Cons:**
- High effort (82 tests to convert)
- Less modern API than Swift Testing
- Loses Swift Testing benefits (parameterized tests, better syntax)

**Estimated effort:** 4-6 hours

---

### Path 2: Disable Test Parallelization (LOW EFFORT, UNCERTAIN SUCCESS)

**Rationale:**
- Tests run on multiple simulator "clones"
- Parallelization may be triggering watchOS Simulator instability
- Test plan can be configured to run serially

**Implementation:**
- Edit test plan to disable parallel execution
- Configure in Xcode scheme or add `.testplan` file
- Set "Execute in Parallel" to false

**Pros:**
- Very low effort (configuration change)
- If successful, keeps Swift Testing framework
- Modern API preserved

**Cons:**
- May not fix the issue (crash is during bootstrap, not execution)
- Tests will run slower
- Uncertain if this is the root cause

**Estimated effort:** 30 minutes

---

### Path 3: File Radar with Apple (NO IMMEDIATE SOLUTION)

**Rationale:**
- This appears to be a genuine Swift Testing + watchOS Simulator bug
- Apple needs to fix the framework
- Community awareness may surface workarounds

**Implementation:**
- Create minimal reproduction case
- File bug report with Apple (Feedback Assistant)
- Cross-post to Swift Forums for visibility

**Pros:**
- May result in Apple fix
- Community may have workarounds

**Cons:**
- No immediate solution
- Unknown timeline for fix
- Blocks all testing until resolved

---

### Path 4: Run Tests on Physical Device (MEDIUM EFFORT, UNCERTAIN SUCCESS)

**Rationale:**
- Issue may be specific to watchOS Simulator
- Physical Apple Watch may not have the same Swift Testing runtime bug

**Implementation:**
- Configure test scheme for physical device
- Pair Apple Watch with development machine
- Run tests on actual hardware

**Pros:**
- May work if bug is simulator-specific
- Tests actual deployment target

**Cons:**
- Requires physical Apple Watch
- Slower test execution
- Less practical for CI/CD
- Uncertain if physical device works

**Estimated effort:** 1-2 hours (assuming device available)

---

## Recommended Action Plan

### Phase 1: Quick Validation (30 minutes)

**Disable test parallelization first** — lowest effort, may work:

1. Edit Xcode scheme for "WavelengthWatch Watch App"
2. Go to Test action → Options
3. Uncheck "Execute in parallel"
4. Run tests again
5. **If this works**: Document and move on
6. **If this fails**: Proceed to Phase 2

---

### Phase 2: Convert to XCTest (4-6 hours)

**If parallelization fix fails, convert tests to XCTest:**

1. **Start with one test file** (e.g., ContentViewModelTests)
   - Convert struct → class inheriting XCTestCase
   - Replace @Test → func test*()
   - Replace #expect → XCTAssert*
   - Verify tests pass

2. **Automate conversion** for remaining 11 test files
   - Create regex/script to speed up conversion
   - Batch convert similar test patterns

3. **Verify all tests pass**
   - Run full test suite
   - Confirm no SIGSEGV crashes
   - Validate test coverage maintained

4. **Update documentation**
   - Document XCTest requirement for watchOS
   - Update CLAUDE.md with testing guidance
   - Note Swift Testing incompatibility

---

### Phase 3: Report to Apple (1 hour)

**After conversion, file bug report:**

1. Create minimal reproduction case
   - Single Swift Testing test on watchOS Simulator
   - Document crash signature
   - Include Xcode version, OS versions

2. File Feedback Assistant report
   - Title: "Swift Testing crashes on watchOS Simulator during bootstrap"
   - Include sysdiagnose, crash logs
   - Reference this investigation

3. Post to Swift Forums
   - Alert community
   - Check if others have workarounds
   - Link to Feedback Assistant ID

---

## Success Criteria

**Tests must:**
- ✅ Execute without SIGSEGV crashes
- ✅ Run on watchOS Simulator
- ✅ Complete in reasonable time (< 5 minutes)
- ✅ Integrate with CI/CD
- ✅ Provide reliable feedback for TDD workflow

**Acceptable trade-offs:**
- ❌ Using XCTest instead of Swift Testing (less modern, but stable)
- ❌ Serial execution instead of parallel (slower, but works)
- ❌ Slightly more verbose test syntax (XCTest macros vs #expect)

---

## Key Learnings

### 1. Always Verify Hypothesis with Experiments

The @MainActor refactoring was based on assumption that actor isolation was causing crashes. Should have:
- Tested parallelization settings first
- Tried XCTest conversion on one test suite
- Validated hypothesis before full refactoring

### 2. Framework Maturity Matters

Swift Testing is new (introduced 2024). watchOS Simulator support may lag:
- Stick with proven frameworks (XCTest) for critical infrastructure
- Early adoption of new testing frameworks carries risk
- watchOS is lower priority than iOS for Apple frameworks

### 3. Error Messages Can Be Misleading

"Test crashed with signal segv" suggested code issue, but:
- Crash was in test runner, not test code
- Bootstrap failure indicated framework bug
- 0.000 second execution time was key clue

---

## Next Steps

**IMMEDIATE** (next 30 minutes):
1. Disable test parallelization in Xcode scheme
2. Run tests and observe results
3. If successful, document and close this investigation
4. If unsuccessful, proceed to XCTest conversion

**SHORT TERM** (next session):
1. Convert ContentViewModelTests to XCTest as proof-of-concept
2. If successful, batch convert remaining test files
3. Verify all tests pass
4. Update documentation

**LONG TERM** (next sprint):
1. File Apple Feedback Assistant report
2. Post to Swift Forums
3. Monitor for Apple response or community workarounds
4. Consider revisiting Swift Testing when watchOS support matures

---

## Conclusion

The MainActor refactoring plan was based on incorrect hypothesis. **Swift Testing itself is incompatible with watchOS Simulator**, crashing during test runner initialization before any test code executes.

**The path forward is either:**
1. Disable parallelization (quick test)
2. Convert to XCTest (proven to work)
3. Wait for Apple to fix Swift Testing on watchOS

**Recommended**: Try parallelization fix first (30 min), then convert to XCTest if that fails (4-6 hours). This will unblock testing and enable TDD workflow while Apple addresses the framework bug.
