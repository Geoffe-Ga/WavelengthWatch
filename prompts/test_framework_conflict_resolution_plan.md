# 2025-10-29: Test Framework Conflict Resolution Plan

**Status**: 🔴 CRITICAL — Mixed testing frameworks causing all tests to crash
**Root Cause IDENTIFIED**: Swift Testing tests with `@MainActor` introduced in PR #54
**Solution**: Remove conflicting pattern and consolidate on Swift Testing

---

## Root Cause Analysis

### The Problem Pattern: Swift Testing + @MainActor

**PR #54** (`feature/scheduling-and-menu-only`, merged Oct 28, 2025) introduced **Swift Testing tests decorated with `@MainActor`**, which is incompatible with watchOS Simulator:

```swift
// From NotificationDelegateTests (added in PR #54)
struct NotificationDelegateTests {
  @MainActor  // <-- THIS IS THE INCOMPATIBLE PATTERN
  @Test func handlesScheduledNotificationResponse() {
    // ...
  }
}
```

**Tests that crash** (all added in PR #54):
1. `NotificationDelegateTests` — 3 tests, all with `@MainActor @Test`
2. `ContentViewModelInitiationContextTests` — 3 tests, all with `@MainActor @Test`
3. `ScheduleViewModelTests` — 5 tests, all with `@MainActor @Test`

**Why this breaks everything:**
- Swift Testing worked fine before PR #54 (82+ tests passing)
- PR #54 added Swift Testing tests WITH `@MainActor`
- `@MainActor` on Swift Testing tests causes bootstrap failure on watchOS Simulator
- When Swift Testing crashes, it takes down ALL tests in the target (even ones without `@MainActor`)

### Why XCTest UI Tests Still Work

UI tests use **XCTest** (not Swift Testing) and live in a separate target (`WavelengthWatch Watch AppUITests`). They don't share the broken Swift Testing runtime, so they continue to pass.

---

## The Misguided Refactoring (Oct 28-29)

### What We Did Wrong

Commits `893a308`, `439df51`, `d23aadb` removed `@MainActor` from:
- ViewModel **classes** (ContentViewModel, ScheduleViewModel, NotificationDelegate)
- Non-test code

### Why It Didn't Help

The problem was **`@MainActor` on Swift Testing test methods**, not on production code. Removing it from ViewModels was architectural improvement but didn't fix testing.

### What Must Be Reverted

**All commits on `refactor/testable-viewmodels` branch**:
- `d23aadb` - Phase 4
- `439df51` - Phase 2
- `893a308` - Phase 1
- Any unstaged/uncommitted changes

**Revert to**: `263e847` (PR #54 merge) or earlier clean state

---

## Solution Strategy

### Phase 0: Revert Misguided Refactoring (IMMEDIATE)

**Goal**: Return to known state before incorrect fix

**Actions**:
1. Checkout `main` or parent branch
2. Hard reset `refactor/testable-viewmodels` to `263e847`
3. Delete refactoring commits
4. Verify we're at PR #54 merge state

**Commands**:
```bash
git checkout main  # or parent branch
git branch -D refactor/testable-viewmodels
git checkout -b fix/swift-testing-mainactor-conflict 263e847
```

**Verification**:
- ViewModels have `@MainActor` on classes (original pattern)
- Tests still crash (confirms we're at root cause state)

---

### Phase 1: Identify All @MainActor Tests (30 minutes)

**Goal**: Find every Swift Testing test with `@MainActor` decoration

**Actions**:
1. Grep for `@MainActor` in test files
2. List affected test methods
3. Categorize by type (ViewModel tests, service tests, etc.)

**Commands**:
```bash
cd "frontend/WavelengthWatch/WavelengthWatch Watch AppTests"
grep -n "@MainActor" *.swift
```

**Expected findings** (from PR #54 diff):
- `NotificationDelegateTests`: 3 tests
- `ContentViewModelInitiationContextTests`: 3 tests
- `ScheduleViewModelTests`: 5 tests

**Total**: ~11 tests with `@MainActor @Test` pattern

---

### Phase 2: Remove @MainActor from Test Methods (1 hour)

**Goal**: Eliminate incompatible `@MainActor @Test` pattern

**Pattern transformation**:

```swift
// BEFORE (crashes on watchOS Simulator)
struct SomeTests {
  @MainActor
  @Test func someAsyncTest() async {
    let viewModel = SomeViewModel()
    await viewModel.doSomething()
    #expect(viewModel.state == expected)
  }
}

// AFTER (works on watchOS Simulator)
struct SomeTests {
  @Test func someAsyncTest() async {
    // Wrap MainActor code in explicit isolation
    await MainActor.run {
      let viewModel = SomeViewModel()
      await viewModel.doSomething()
      #expect(viewModel.state == expected)
    }
  }
}
```

**OR, if ViewModels need @MainActor class annotation**:

```swift
struct SomeTests {
  @Test func someAsyncTest() async {
    // Create instance in MainActor context
    let viewModel = await MainActor.run { SomeViewModel() }

    // Call methods in MainActor context
    await viewModel.doSomething()

    // Read properties in MainActor context
    let state = await MainActor.run { viewModel.state }
    #expect(state == expected)
  }
}
```

**Files to edit**:
1. `WavelengthWatch_Watch_AppTests.swift` (NotificationDelegateTests section)
2. `WavelengthWatch_Watch_AppTests.swift` (ContentViewModelInitiationContextTests section)
3. `WavelengthWatch_Watch_AppTests.swift` (ScheduleViewModelTests section)

**Success criteria**:
- Zero `@MainActor @Test` patterns remain
- All test methods use explicit `MainActor.run {}` where needed
- Tests compile without warnings

---

### Phase 3: Fix ViewModel Patterns if Needed (2 hours)

**Goal**: Ensure ViewModels work with test refactoring

**Two possible outcomes**:

#### Outcome A: ViewModels Keep @MainActor on Class

If ViewModels need `@MainActor class` for SwiftUI:

```swift
@MainActor
final class ContentViewModel: ObservableObject {
  // Original pattern, works fine
}
```

Tests must use:
```swift
@Test func testSomething() async {
  let vm = await MainActor.run { ContentViewModel(...) }
  await vm.doSomething()
  let result = await MainActor.run { vm.someProperty }
  #expect(result == expected)
}
```

#### Outcome B: ViewModels Use Nonisolated Init

If tests are too verbose with `MainActor.run` everywhere:

```swift
final class ContentViewModel: ObservableObject {
  nonisolated init(...) {
    // Initialize without MainActor
  }

  @MainActor func doSomething() {
    // Methods still isolated
  }
}
```

Tests can use:
```swift
@Test func testSomething() async {
  let vm = ContentViewModel(...)  // No MainActor.run needed
  await vm.doSomething()
  #expect(vm.someProperty == expected)  // Swift handles isolation
}
```

**Decision point**: Choose based on test verbosity vs ViewModel complexity

**Estimated effort**:
- Outcome A (keep current ViewModels): 0 hours
- Outcome B (refactor ViewModels): 2 hours

---

### Phase 4: Verify All Tests Pass (30 minutes)

**Goal**: Confirm crash is resolved

**Actions**:
1. Run full test suite
2. Verify no SIGSEGV crashes
3. Confirm all Swift Testing tests execute
4. Validate test coverage maintained

**Commands**:
```bash
xcodebuild test \
  -scheme "WavelengthWatch Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)"
```

**Success criteria**:
- Exit code 0 (no crashes)
- All tests show execution time > 0.000s
- Test output shows "Testing succeeded" or specific test failures (not crashes)
- No "operation never finished bootstrapping" errors

**If tests still crash**:
- Check for remaining `@MainActor @Test` patterns
- Verify we're not mixing XCTest + Swift Testing in same target (we're not, UI tests are separate)
- Consider parallelization settings

---

### Phase 5: Remove XCTest UI Tests Infrastructure (Optional, 1 hour)

**Goal**: Consolidate on Swift Testing for all tests

**Context**:
- UI tests (`WavelengthWatch Watch AppUITests` target) use XCTest
- These were added as workaround when Swift Testing crashed
- Now that Swift Testing works, we can consider converting

**Actions (OPTIONAL)**:
1. Evaluate if UI tests should stay as XCTest (they work fine)
2. If converting, rewrite 3 UI tests in Swift Testing
3. Remove `WavelengthWatch Watch AppUITests` target
4. Update test plan/scheme

**Recommendation**: **SKIP THIS PHASE**
- XCTest for UI tests is industry standard
- UI tests are separate concern from unit tests
- No benefit to converting (XCTest works great for UI)
- Focus effort on core unit test stability

---

## Implementation Steps

### Step 1: Clean Revert (IMMEDIATE)

```bash
# Save current work if needed
git stash

# Return to clean state
git checkout main
git branch -D refactor/testable-viewmodels
git checkout -b fix/swift-testing-mainactor-conflict 263e847

# Confirm state
git log --oneline -1
# Should show: 263e847 Merge pull request #54
```

### Step 2: Audit @MainActor Usage

```bash
cd "frontend/WavelengthWatch/WavelengthWatch Watch AppTests"
grep -B2 "@MainActor" WavelengthWatch_Watch_AppTests.swift | grep -E "(@MainActor|@Test|func)"
```

Expected output:
```
@MainActor
@Test func handlesScheduledNotificationResponse() {
--
@MainActor
@Test func ignoresNonScheduledNotifications() {
--
@MainActor
@Test func clearsNotificationState() {
--
(etc for all 11 tests)
```

### Step 3: Remove @MainActor from Tests

Edit `WavelengthWatch_Watch_AppTests.swift`:

**Find and remove** these lines:
```swift
@MainActor  // <-- DELETE THIS LINE
@Test func someTest() {
```

**For each test**, decide if it needs explicit MainActor isolation:

**Tests that DON'T need MainActor.run** (most of them):
```swift
@Test func encodesAndDecodesSchedule() throws {
  // Pure data tests, no ViewModels
}
```

**Tests that DO need MainActor.run** (ViewModel tests):
```swift
@Test func addsScheduleAndPersists() async throws {
  await MainActor.run {
    let viewModel = ScheduleViewModel(...)
    viewModel.addSchedule(...)
    #expect(viewModel.schedules.count == 1)
  }
}
```

### Step 4: Test and Iterate

```bash
# Run tests after each file edit
xcodebuild test -scheme "WavelengthWatch Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)" \
  2>&1 | tee test_results.txt

# Check for crashes
grep -i "sigsegv\|crashed\|bootstrap" test_results.txt
```

If tests still crash:
- Check for remaining `@MainActor @Test` patterns
- Verify ViewModel initialization in tests
- Add more `MainActor.run {}` blocks if needed

### Step 5: Commit and Document

```bash
git add .
git commit -m "fix(tests): Remove @MainActor from Swift Testing test methods

Resolves SIGSEGV crashes on watchOS Simulator by removing incompatible
@MainActor decorations from Swift Testing test methods.

Root cause: PR #54 introduced @MainActor @Test pattern which causes
Swift Testing runtime to crash during bootstrap on watchOS Simulator.

Solution: Remove @MainActor from test methods, use MainActor.run {}
for explicit isolation where needed.

Tests affected:
- NotificationDelegateTests (3 tests)
- ContentViewModelInitiationContextTests (3 tests)
- ScheduleViewModelTests (5 tests)

Result: All 82+ Swift Testing tests now execute successfully.

Fixes #[issue number if exists]"
```

---

## Success Criteria

### Tests Must

- ✅ Execute without SIGSEGV crashes
- ✅ Run on watchOS Simulator
- ✅ Show execution time > 0.000 seconds
- ✅ Complete full suite in < 5 minutes
- ✅ Pass CI checks (when pushed)

### Code Must

- ✅ Have zero `@MainActor @Test` patterns in Swift Testing tests
- ✅ Maintain thread safety for ViewModels
- ✅ Preserve all existing test coverage
- ✅ Compile without warnings

### Documentation Must

- ✅ Explain why `@MainActor @Test` is incompatible with watchOS Simulator
- ✅ Document correct pattern for testing MainActor-isolated code
- ✅ Update CLAUDE.md with testing guidance
- ✅ Archive incorrect refactoring analysis for learning

---

## Risk Mitigation

### What If Tests Still Crash After Removing @MainActor?

**Fallback Plan A**: Explicitly wrap ALL ViewModel code in `MainActor.run`

```swift
@Test func testViewModel() async {
  await MainActor.run {
    let vm = ViewModel()
    vm.doSomething()
    #expect(vm.state == expected)
  }
}
```

**Fallback Plan B**: Convert ViewModels to nonisolated init pattern

(Similar to what we tried before, but with correct understanding this time)

**Fallback Plan C**: File Apple Feedback and convert to XCTest as last resort

### What If Some Tests Need @MainActor on Class?

That's fine for production code:

```swift
@MainActor  // OK for production ViewModels
final class SomeViewModel: ObservableObject {
}
```

Just NOT on Swift Testing test structs/methods:

```swift
@MainActor  // ❌ NEVER on Swift Testing tests
struct SomeTests {
  @MainActor  // ❌ NEVER on Swift Testing test methods
  @Test func something() {
  }
}
```

---

## Timeline Estimate

| Phase | Task | Estimated Time |
|-------|------|----------------|
| 0 | Revert misguided refactoring | 10 minutes |
| 1 | Audit @MainActor usage | 30 minutes |
| 2 | Remove @MainActor from tests | 1 hour |
| 3 | Fix ViewModel patterns (if needed) | 0-2 hours |
| 4 | Verify all tests pass | 30 minutes |
| 5 | Documentation (optional UI test conversion) | SKIP |
| **Total** | | **2-4 hours** |

---

## Key Learnings

### 1. Test Framework Limitations Are Real

Swift Testing is new (2024). watchOS Simulator support for `@MainActor @Test` doesn't exist yet.

**Lesson**: Stick to proven patterns for critical infrastructure until frameworks mature.

### 2. Symptoms != Root Cause

SIGSEGV crash in tests suggested code issue, but:
- Tests worked before PR #54
- UI tests (XCTest) continued working
- Problem was test decoration, not production code

**Lesson**: Always check what changed recently before assuming framework bugs.

### 3. Documentation Is Critical

PR #54 added many tests but didn't document the `@MainActor @Test` pattern decision.

**Lesson**: When using new framework features, document why and any limitations discovered.

---

## Next Steps

**IMMEDIATE** (this session):
1. ✅ Revert refactor/testable-viewmodels branch
2. ✅ Create fix/swift-testing-mainactor-conflict branch
3. ✅ Remove `@MainActor` from Swift Testing test methods
4. ✅ Verify tests pass
5. ✅ Commit fix

**SHORT TERM** (next session):
1. Update CLAUDE.md with Swift Testing + watchOS guidelines
2. Document `@MainActor @Test` incompatibility
3. Add code review checklist for test patterns

**LONG TERM** (future sprints):
1. Monitor Swift Testing releases for watchOS improvements
2. File Apple Feedback if pattern remains broken
3. Consider XCTest for MainActor-heavy code if Swift Testing limitations persist

---

## Conclusion

The test crashes were caused by **`@MainActor @Test` pattern introduced in PR #54**, not by Swift Testing itself or production code architecture.

**The fix is simple**: Remove `@MainActor` decorations from Swift Testing test methods and use explicit `MainActor.run {}` blocks where isolation is needed.

This will restore all 82+ tests to working state while maintaining type safety and thread safety in production code.
