# 2025-10-29: Incremental Test Fix Plan

## Objective

Walk through each commit from 54a965a (tests passing ✅) to current HEAD (tests crashing ❌), fixing test issues incrementally at each step until we reach a fully working state.

## Strategy

1. Start at commit 54a965a where tests pass
2. Apply the next commit (ddb61de)
3. Run tests to check if they still pass
4. If tests fail/crash, identify and fix the issue
5. Commit the fix
6. Repeat for each subsequent commit until we reach current HEAD

## Commit Sequence to Process

From 54a965a to current HEAD, here are the commits in order:

```bash
git log --oneline --reverse 54a965a..refactor/testable-viewmodels
```

Expected commits (from earlier investigation):
1. `ddb61de` - feat(journal): Add initiated_by field to Journal model
2. `eb485b3` - feat(journal): Add JournalSchedule model for scheduling prompts
3. `8c38c7d` - feat(journal): Add schedule settings UI and view model
4. `b0c2642` - feat(journal): Add notification scheduler service
5. `d053151` - feat(journal): Add notification tap handling with tests
6. `a8452c2` - feat(journal): Add initiation context tracking
7. `dcbf815` - feat(ui): Add three-dot menu
8. ... (more commits)
9. `628f1ce` - fix(notifications): Address PR review feedback (**Known breaking commit**)
10. ... (more commits)
11. `893a308` - refactor(tests): Phase 1 - Make ContentViewModel testable
12. `439df51` - refactor(tests): Phase 2 - Make ScheduleViewModel testable
13. `d23aadb` - refactor(tests): Phase 4 - Remove @MainActor from ViewModels
14. `e7b7d5a` - fix(app): Move notification delegate setup to onAppear (current HEAD)

## Known Issues to Watch For

### Issue #1: Commit 628f1ce - @StateObject Access in init()
**What breaks**: This commit adds `NotificationDelegateShim.shared.delegate = notificationDelegate` to the App's `init()`, accessing `@StateObject` before SwiftUI initializes it.

**How to fix**: Move delegate setup to `.onAppear` block:
```swift
var body: some Scene {
  WindowGroup {
    ContentView()
      .environmentObject(notificationDelegate)
      .onAppear {
        NotificationDelegateShim.shared.delegate = notificationDelegate
        UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared
      }
  }
}
```

### Issue #2: @MainActor on ObservableObject Classes
**What breaks**: Adding `@MainActor` to entire ViewModel classes can cause crashes with `@StateObject` in test environment.

**How to fix**: Use `nonisolated init()` + `@MainActor` on individual methods:
```swift
final class SomeViewModel: ObservableObject {
  nonisolated init() {}

  @MainActor
  func someMethod() { }
}
```

### Issue #3: Unknown Issue Causing Current HEAD Crashes
**Status**: Still needs investigation - tests crash at current HEAD even after fixes #1 and #2 are applied.

**Approach**: Will discover this incrementally as we walk through commits.

## Execution Plan

### Phase 1: Setup and Baseline (10 min)
1. ✅ Checkout 54a965a
2. ✅ Confirm tests pass
3. Create a new branch for incremental fixes: `fix/incremental-test-fixes`

### Phase 2: Process Each Commit (Est. 2-4 hours)
For each commit from ddb61de to e7b7d5a:

1. **Apply commit**: `git cherry-pick <commit-sha>`
2. **Run tests**: `xcodebuild test -scheme "WavelengthWatch Watch App" -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)"`
3. **Check result**:
   - If tests pass ✅: Continue to next commit
   - If tests fail/crash ❌: Proceed to fix
4. **Fix if needed**:
   - Identify the specific cause (SIGSEGV location, file causing crash)
   - Apply minimal fix to make tests pass
   - Document the fix in this file
   - Commit the fix: `git commit -m "fix(tests): [description of fix]"`
5. **Verify**: Re-run tests to confirm they pass
6. **Document**: Add entry to "Fixes Applied" section below

### Phase 3: Merge and Validate (30 min)
1. When we reach current HEAD functionality, run full test suite
2. Compare final state with `refactor/testable-viewmodels` HEAD
3. Create PR from `fix/incremental-test-fixes` to `refactor/testable-viewmodels`

## Fixes Applied

### Commit: [SHA] - [Title]
**Problem**: [Description of test failure]
**Root Cause**: [What caused the issue]
**Fix**: [What was changed]
**Verification**: [Test results after fix]

---

## Notes

- **Exit criteria for each commit**: Tests must pass (exit code 0, all test suites complete without SIGSEGV)
- **If stuck**: Document the blocker and move to analysis mode
- **Time budget**: If a single commit takes >30 min to fix, escalate for strategic decision

## Current Status

**Last completed**: 54a965a ✅ (tests passing)
**Next commit**: ddb61de (not yet applied)
**Fixes applied**: 0
**Commits processed**: 0/~30

---

## Alternative Approaches (If This Fails)

If the incremental approach becomes impractical:

1. **Binary search approach**: Use `git bisect` to find the exact breaking commit(s)
2. **Selective revert**: Revert known problematic commits and re-implement features correctly
3. **Fresh start**: Take working ViewModels from refactor branch and carefully re-add notification system

---

## Success Criteria

- ✅ All tests pass at every commit
- ✅ Reach feature parity with `refactor/testable-viewmodels` HEAD
- ✅ Tests run without SIGSEGV crashes
- ✅ CI pipeline passes
- ✅ App launches successfully in test environment
