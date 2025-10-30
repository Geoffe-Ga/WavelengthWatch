# 2025-10-29: Comprehensive Test Crash Analysis - Multiple Root Causes

**Status**: 🔴 CRITICAL — TWO INDEPENDENT BUGS CAUSING CRASHES
**Discovery**: Tests were ALREADY broken before refactoring branch
**Context**: PR #54 introduced BOTH bugs; refactoring fixed ONE but not the other

---

## Executive Summary

**Tests have been crashing since PR #54 was merged (Oct 28, 2025 commit 263e847).**

The refactor/testable-viewmodels branch fixed ONE of TWO bugs, which is why tests still crash.

### The Two Independent Bugs

| Bug # | Issue | Introduced | Fixed? |
|-------|-------|------------|--------|
| 1 | `@MainActor @Test` in Swift Testing tests | PR #54 (263e847) | ✅ YES (refactor branch) |
| 2 | `@StateObject` accessed in `init()` before initialization | PR #54 (263e847) | ❌ NO (still present) |

**Both bugs must be fixed for tests to pass.**

---

## Bug #1: @MainActor on Swift Testing Tests ✅ FIXED

### The Problem (Introduced in PR #54)

PR #54 added tests with `@MainActor @Test` decoration:

```swift
// From PR #54 - WavelengthWatch_Watch_AppTests.swift
struct NotificationDelegateTests {
  @MainActor  // ← Swift Testing + @MainActor + watchOS Simulator = CRASH
  @Test func handlesScheduledNotificationResponse() {
```

**11 tests affected:**
- NotificationDelegateTests: 3 tests
- ContentViewModelInitiationContextTests: 3 tests
- ScheduleViewModelTests: 5 tests

### Why It Crashes

Swift Testing framework cannot properly execute `@MainActor @Test` methods on watchOS Simulator. The test runner crashes during bootstrap with "operation never finished bootstrapping."

### The Fix (Applied in refactor/testable-viewmodels)

Refactoring commits removed `@MainActor` from:
- Test methods (all 11 affected tests)
- ViewModel classes (ContentViewModel, ScheduleViewModel, NotificationDelegate)
- Added `nonisolated init` to ViewModels
- Added `@MainActor` to individual methods

**Result**: Bug #1 is FIXED on current branch.

---

## Bug #2: @StateObject Accessed in init() ❌ NOT FIXED

### The Problem (Introduced in PR #54, Still Present)

PR #54 added this code to `WavelengthWatchApp.swift`:

```swift
@main
struct WavelengthWatch_Watch_AppApp: App {
  @StateObject private var notificationDelegate = NotificationDelegate()

  init() {
    // ❌ BUG: Accessing @StateObject before SwiftUI initializes it!
    NotificationDelegateShim.shared.delegate = notificationDelegate
    UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared
    configureNotificationCategories()
  }
}
```

### Why It Crashes

**SwiftUI property wrapper initialization order**:
1. `init()` is called
2. Inside `init()`, code tries to access `notificationDelegate`
3. But `@StateObject` properties aren't initialized until AFTER `init()` completes
4. Accessing uninitialized memory → SIGSEGV (segmentation fault)
5. Tests crash because they bootstrap the app

### Before PR #54 (Working State)

```swift
// commit 263e847^1 (before PR merge) - SIMPLE, NO BUGS
@main
struct WavelengthWatch_Watch_AppApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
```

No `@StateObject`, no `init()`, no crash.

### Why Refactoring Didn't Fix It

The refactoring focused on removing `@MainActor` from classes. It did NOT address the `@StateObject` access bug in the app's `init()`.

Current state (still broken):
```swift
@StateObject private var notificationDelegate = NotificationDelegate()  // ← Still here

init() {
  NotificationDelegateShim.shared.delegate = notificationDelegate  // ← Still accessing it!
}
```

---

## Evidence Timeline

### Sept 10, 2025: Project Created
- App file was simple, no notification delegate
- Swift Testing tests worked fine
- No crashes reported

### Oct 24-27, 2025: PR #54 Development
- Added notification system
- Added `@StateObject` to app
- Added `init()` that accesses `@StateObject`
- Added tests with `@MainActor @Test`
- **Tests started crashing** (both bugs introduced)

### Oct 28, 2025: PR #54 Merged (263e847)
- Documentation added: "Tests with `@MainActor` may fail" (commit 1b7a8f4)
- Known issue documented but not fixed
- Tests remained broken

### Oct 28-29, 2025: refactor/testable-viewmodels Branch
- Fixed Bug #1 (`@MainActor @Test`)
- Did NOT fix Bug #2 (`@StateObject` in `init()`)
- Tests still crash because Bug #2 remains

---

## Why Tests Still Crash After Refactoring

**Both bugs cause SIGSEGV during test bootstrap:**

1. **Bug #1** (Fixed): `@MainActor @Test` → Swift Testing runtime crashes
2. **Bug #2** (Not Fixed): `@StateObject` access → Memory access violation crashes

With Bug #1 fixed, Bug #2 is now the sole remaining cause.

---

## The Complete Fix (Two-Part Solution)

### Part 1: Keep the Refactoring ✅ DONE

The `@MainActor` refactoring was correct and should be kept:
- ViewModels use `nonisolated init` + method-level `@MainActor`
- Tests don't use `@MainActor @Test`
- This is good architecture regardless of Bug #2

### Part 2: Fix @StateObject Access ❌ TODO

Move delegate setup from `init()` to proper SwiftUI lifecycle:

```swift
@main
struct WavelengthWatch_Watch_AppApp: App {
  @StateObject private var notificationDelegate = NotificationDelegate()

  init() {
    // ✅ Only configure categories (doesn't access notificationDelegate)
    configureNotificationCategories()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(notificationDelegate)
        .onAppear {
          // ✅ Safe: @StateObject is initialized by this point
          NotificationDelegateShim.shared.delegate = notificationDelegate
          UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared
        }
    }
  }

  private func configureNotificationCategories() {
    let logEmotionsAction = UNNotificationAction(
      identifier: "LOG_EMOTIONS",
      title: "Log Emotions",
      options: [.foreground]
    )

    let category = UNNotificationCategory(
      identifier: "JOURNAL_CHECKIN",
      actions: [logEmotionsAction],
      intentIdentifiers: [],
      options: []
    )

    UNUserNotificationCenter.current().setNotificationCategories([category])
  }
}
```

**Changes:**
1. Remove delegate setup lines from `init()`
2. Keep `configureNotificationCategories()` in `init()` (safe, doesn't access @StateObject)
3. Add `.onAppear {}` to body with delegate setup

---

## Testing the Fix

### Step 1: Apply Part 2 Fix

Edit `WavelengthWatchApp.swift` per above.

### Step 2: Run Tests

```bash
xcodebuild test \
  -scheme "WavelengthWatch Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)"
```

### Step 3: Verify Success Criteria

- [ ] Exit code 0 (no crashes)
- [ ] All 82+ unit tests execute
- [ ] Test execution time > 0.000 seconds
- [ ] No "operation never finished bootstrapping" errors
- [ ] No SIGSEGV crashes
- [ ] All 3 UI tests still pass

---

## Why This Was Confusing

### Misleading Clues

1. **"Swift Testing crashes"** → Partially true (Bug #1), but Bug #2 also crashes
2. **"@MainActor incompatible"** → True for tests (Bug #1), but Bug #2 exists too
3. **"XCTest vs Swift Testing conflict"** → Red herring, they're in separate targets
4. **"Tests worked before"** → True, but broken SINCE PR #54, not since refactoring

### The Real Timeline

```
Sept 10: ✅ Tests working (no notification system)
         ↓
Oct 28:  ❌ PR #54 merged (both bugs introduced)
         ❌ Tests broken
         ↓
Oct 28-29: Refactoring (fixed Bug #1 only)
         ❌ Tests still broken (Bug #2 remains)
```

---

## Implementation Plan

### Phase 1: Apply Part 2 Fix (5 minutes)

Edit `WavelengthWatchApp.swift`:
- Move delegate setup from `init()` to `.onAppear {}`

### Phase 2: Test (5 minutes)

Run full test suite and verify all tests pass.

### Phase 3: Commit (5 minutes)

```bash
git add frontend/WavelengthWatch/WavelengthWatch\ Watch\ App/WavelengthWatchApp.swift
git commit -m "fix(app): Move notification delegate setup to onAppear

Fixes SIGSEGV crash caused by accessing @StateObject in init() before
SwiftUI initializes property wrappers.

This was Bug #2 of two bugs introduced in PR #54:
- Bug #1: @MainActor @Test (fixed in earlier commits)
- Bug #2: @StateObject access in init() (fixed in this commit)

Root cause: WavelengthWatchApp.swift:16 accessed notificationDelegate
(@StateObject) in init(), but @StateObject properties aren't initialized
until after init() completes. This caused segmentation fault during app
bootstrap, manifesting as all tests crashing.

Solution: Move delegate setup to .onAppear {} where @StateObject is
guaranteed to be initialized.

Result: All 82+ tests now execute successfully.

Fixes crash introduced in PR #54 (263e847)."
```

---

## Key Learnings

### 1. Always Check Historical Context

Don't assume current branch introduced the bug. Check:
- When did tests last pass?
- What changed between working and broken states?
- Is the bug new or pre-existing?

### 2. Look for Multiple Root Causes

One symptom (SIGSEGV) can have multiple causes:
- Bug #1: Framework limitation
- Bug #2: Property initialization order

Fixing one doesn't guarantee fixing all.

### 3. Test Incrementally

After fixing Bug #1, should have tested immediately to discover Bug #2.

### 4. SwiftUI Property Wrapper Lifecycle

❌ **Never access @StateObject/@State/@ObservedObject in init()**

✅ **Use .onAppear {} or .task {} for setup code**

This is a common SwiftUI pitfall.

---

## Conclusion

**Two independent bugs caused test crashes:**
1. ✅ **Bug #1**: `@MainActor @Test` — Fixed by refactoring
2. ❌ **Bug #2**: `@StateObject` in `init()` — Needs Part 2 fix

**Both bugs were introduced in PR #54. Neither existed before.**

The refactoring branch fixed Bug #1 correctly and should be kept. Now we need to apply the Part 2 fix for Bug #2.

**Total time to complete fix**: 15 minutes
**Total time to discover root causes**: ~2 hours (learning experience!)

---

## Next Actions

**IMMEDIATE** (this session):
1. Apply Part 2 fix to `WavelengthWatchApp.swift`
2. Run tests and verify they pass
3. Commit fix

**SHORT TERM** (next session):
1. Add pre-commit hook to catch `@StateObject` access in `init()`
2. Document SwiftUI property wrapper lifecycle in CLAUDE.md
3. Update test documentation with resolution details

**LONG TERM**:
1. Consider linting rules for SwiftUI lifecycle bugs
2. Add CI check that tests actually run (not just compile)
3. Monitor Swift Testing releases for watchOS improvements
