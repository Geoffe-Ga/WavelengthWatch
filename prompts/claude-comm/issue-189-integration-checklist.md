# Issue #189: Integration Checklist

**Use this checklist to complete the manual Xcode integration.**

---

## Pre-Integration Checklist

- [x] Tests written FIRST (19 tests, 491 lines)
- [x] Implementation complete (503 lines)
- [x] Models defined (107 lines)
- [x] Test suite added to run script
- [x] Documentation created

---

## Xcode Integration Steps

### Step 1: Open Xcode
```bash
cd /Users/geoffgallinger/Projects/WavelengthWatchRoot
open frontend/WavelengthWatch/WavelengthWatch.xcodeproj
```

- [ ] Xcode opened successfully

### Step 2: Verify File Synchronization

**Expected Behavior**: Files should appear automatically in navigator due to file-system-synchronized groups.

Check for these files in Xcode navigator:
- [ ] `Models/JournalQueueModels.swift`
- [ ] `Services/JournalQueue.swift`
- [ ] `Tests/JournalQueueTests.swift`

**If files don't appear**:
1. Right-click `Models` folder → "Synchronize with Disk"
2. Right-click `Services` folder → "Synchronize with Disk"
3. Right-click `Tests` folder → "Synchronize with Disk"

### Step 3: Verify Target Membership

For **JournalQueueModels.swift**:
1. Select file in navigator
2. Open File Inspector (⌥⌘1)
3. Check Target Membership section:
   - [ ] `WavelengthWatch Watch App` is checked
   - [ ] `WavelengthWatch Watch AppTests` is checked

For **JournalQueue.swift**:
1. Select file in navigator
2. Open File Inspector (⌥⌘1)
3. Check Target Membership section:
   - [ ] `WavelengthWatch Watch App` is checked
   - [ ] `WavelengthWatch Watch AppTests` is checked

For **JournalQueueTests.swift**:
1. Select file in navigator
2. Open File Inspector (⌥⌘1)
3. Check Target Membership section:
   - [ ] `WavelengthWatch Watch App` is UNCHECKED
   - [ ] `WavelengthWatch Watch AppTests` is CHECKED

### Step 4: Build Project

1. Select `WavelengthWatch Watch App` scheme
2. Product → Clean Build Folder (⇧⌘K)
3. Product → Build (⌘B)

- [ ] Build succeeded with no errors
- [ ] Build succeeded with no warnings

**If build fails**, check:
- File encoding (should be UTF-8)
- SwiftFormat compliance
- Import statements
- Target membership

---

## Quality Gates

### Gate 1: Unit Tests

```bash
cd /Users/geoffgallinger/Projects/WavelengthWatchRoot
frontend/WavelengthWatch/run-tests-individually.sh JournalQueueTests
```

Expected output:
```
Building for testing...
✅ Build complete.

Running 1 test suite(s) individually...
=====================================

Testing: JournalQueueTests
✅ JournalQueueTests PASSED

=====================================
Test Results Summary:
  Passed: 1/1
  Failed: 0

✅ All test suites passed!
```

- [ ] All 19 tests passed
- [ ] No test failures
- [ ] No test warnings

**If tests fail**:
1. Review failure output
2. Check test log: `/tmp/watchos_tests/JournalQueueTests.log`
3. Fix issues in implementation
4. Re-run tests

### Gate 2: SwiftFormat

```bash
cd /Users/geoffgallinger/Projects/WavelengthWatchRoot
swiftformat --lint frontend
```

Expected output: No formatting issues

- [ ] SwiftFormat passes with no issues

**If formatting issues found**:
```bash
swiftformat frontend
git diff  # Review changes
git add -u  # Stage formatting fixes
```

### Gate 3: Pre-commit Hooks

```bash
cd /Users/geoffgallinger/Projects/WavelengthWatchRoot
pre-commit run --all-files
```

Expected: All hooks pass

- [ ] `swiftformat-lint` passed
- [ ] `trailing-whitespace` passed
- [ ] `end-of-file-fixer` passed
- [ ] `check-yaml` passed
- [ ] `check-added-large-files` passed
- [ ] `ruff (lint)` passed
- [ ] `ruff (format)` passed
- [ ] `mypy` passed

**If hooks fail**:
1. Review failure output
2. Fix issues automatically: `pre-commit run --all-files --hook-stage manual`
3. Review changes: `git diff`
4. Stage fixes: `git add -u`
5. Re-run: `pre-commit run --all-files`

### Gate 4: Full Test Suite

```bash
cd /Users/geoffgallinger/Projects/WavelengthWatchRoot
frontend/WavelengthWatch/run-tests-individually.sh
```

Expected: All test suites pass (including existing + new JournalQueueTests)

- [ ] All test suites passed
- [ ] No regressions introduced

**If any test suite fails**:
1. Run failing suite individually: `frontend/WavelengthWatch/run-tests-individually.sh <SuiteName>`
2. Review failure details
3. Investigate potential conflicts with new code
4. Fix and re-test

---

## Git Workflow

### Commit Changes

```bash
cd /Users/geoffgallinger/Projects/WavelengthWatchRoot
git status
git add frontend/WavelengthWatch/WavelengthWatch\ Watch\ App/Models/JournalQueueModels.swift
git add frontend/WavelengthWatch/WavelengthWatch\ Watch\ App/Services/JournalQueue.swift
git add frontend/WavelengthWatch/WavelengthWatch\ Watch\ AppTests/JournalQueueTests.swift
git add frontend/WavelengthWatch/run-tests-individually.sh
git add prompts/claude-comm/issue-189-*.md
```

- [ ] Staged all new files
- [ ] Staged test script update
- [ ] Staged documentation

### Create Commit

```bash
git commit -m "feat: Implement JournalQueue service for offline sync (#189)

- Add JournalQueue SQLite-based queue service
- Add JournalQueueModels (QueueStatus, JournalQueueItem, QueueStatistics, JournalQueueError)
- Add 19 comprehensive tests covering all functionality
- Update test script to include JournalQueueTests

Features:
- Offline-first queue for journal entries pending sync
- Status tracking: pending → syncing → synced/failed
- Retry count management for failed syncs
- Cleanup of old synced entries
- Queue statistics

All tests passing, pre-commit hooks satisfied."
```

- [ ] Commit created with descriptive message

### Push Branch

```bash
git push origin feature/issue-189-journal-queue
```

- [ ] Branch pushed to remote

---

## CI Verification

After pushing, monitor GitHub Actions:

- [ ] Backend checks pass
- [ ] SwiftFormat check passes
- [ ] Xcode build passes

**If CI fails**:
1. Review CI logs on GitHub
2. Fix issues locally
3. Commit and push fixes
4. Wait for CI re-run

---

## Create Pull Request

1. Navigate to GitHub repository
2. Click "Compare & pull request" for `feature/issue-189-journal-queue`
3. Fill in PR template:
   - Title: `feat: Implement JournalQueue service (#189)`
   - Description: Reference issue #189, summarize changes
   - Checklist: Mark all completed items
4. Request review from Claude
5. Submit PR

- [ ] PR created
- [ ] Issue #189 referenced
- [ ] Review requested

---

## Claude Review

Wait for automated Claude Code review:

- [ ] Claude review completed
- [ ] All suggestions addressed (if any)
- [ ] LGTM with 0 suggestions

**If Claude has suggestions**:
1. Address each suggestion
2. Commit changes
3. Push to branch
4. Wait for re-review

---

## Final Checklist

- [ ] All quality gates passed (tests, format, pre-commit, CI)
- [ ] Claude review LGTM
- [ ] No merge conflicts
- [ ] Ready to merge

---

## Troubleshooting

### Common Issues

**Issue**: Files don't appear in Xcode navigator
- **Solution**: Synchronize with Disk on parent folder

**Issue**: Build fails with "Cannot find type 'JournalQueue'"
- **Solution**: Check target membership for JournalQueue.swift

**Issue**: Tests fail with "Cannot find 'JournalQueue' in scope"
- **Solution**: Check target membership for JournalQueue.swift (must include test target)

**Issue**: SwiftFormat fails
- **Solution**: Run `swiftformat frontend` to auto-fix, review changes

**Issue**: Pre-commit fails on Python files
- **Solution**: This shouldn't happen (only Swift files changed). Check git status.

**Issue**: CI fails on Xcode build
- **Solution**: Ensure target membership is correct, check for Xcode project file corruption

---

## Success Criteria

All items checked = Issue #189 complete and ready to merge! 🎉

---

## Estimated Time

- Xcode integration: 5-10 minutes
- Test execution: 2-3 minutes
- Quality gates: 5-7 minutes
- Git workflow: 2-3 minutes
- **Total**: ~15-25 minutes
