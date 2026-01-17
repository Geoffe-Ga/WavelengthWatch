# Issue #250: Self-Care Analytics - TDD Workflow Checklist

## Current Status: ✅ IMPLEMENTATION COMPLETE - READY FOR TESTING

---

## Phase 1: Implementation (COMPLETE ✅)

- [x] **Step 1**: Write all tests FIRST
  - [x] Test 1: Empty entries returns empty analytics
  - [x] Test 2: Entries with no strategies return empty
  - [x] Test 3: Counts strategy occurrences correctly
  - [x] Test 4: Calculates diversity score correctly
  - [x] Test 5: Sorts strategies by count descending
  - [x] Test 6: Respects limit parameter
  - [x] Test 7: Handles unknown strategy IDs
  - [x] Test 8: Populates strategy text from catalog
  - [x] Test 9: Calculates percentage correctly

- [x] **Step 2**: Extend protocol
  - [x] Add `calculateSelfCare()` to `LocalAnalyticsCalculatorProtocol`

- [x] **Step 3**: Add infrastructure
  - [x] Add `StrategyInfo` struct
  - [x] Add `strategyLookup` property
  - [x] Build lookup in `init()`

- [x] **Step 4**: Implement algorithm
  - [x] Filter entries with non-nil strategyID
  - [x] Handle empty case
  - [x] Count strategy occurrences
  - [x] Calculate diversity score
  - [x] Build TopStrategyItem list
  - [x] Sort by count descending
  - [x] Apply limit
  - [x] Return SelfCareAnalytics

---

## Phase 2: Testing (NEXT ⏳)

- [ ] **Step 5**: Run tests
  ```bash
  frontend/WavelengthWatch/run-tests-individually.sh LocalAnalyticsCalculatorTests
  ```
  - [ ] All 10 new tests pass
  - [ ] All existing tests still pass
  - [ ] No test failures

- [ ] **Step 6**: Format code
  ```bash
  swiftformat frontend/
  ```
  - [ ] No formatting changes needed (expected)
  - [ ] SwiftFormat exits clean

- [ ] **Step 7**: Pre-commit hooks
  ```bash
  pre-commit run --all-files
  ```
  - [ ] All hooks pass
  - [ ] No linting errors
  - [ ] No formatting errors

---

## Phase 3: Version Control (AFTER TESTS PASS ⏳)

- [ ] **Step 8**: Create branch
  ```bash
  git checkout -b feature/issue-250-self-care-calculator
  ```

- [ ] **Step 9**: Stage changes
  ```bash
  git add frontend/WavelengthWatch/WavelengthWatch\ Watch\ App/Services/LocalAnalyticsCalculator.swift
  git add frontend/WavelengthWatch/WavelengthWatch\ Watch\ AppTests/LocalAnalyticsCalculatorTests.swift
  ```

- [ ] **Step 10**: Commit with message
  ```bash
  git commit -m "feat: Add self-care analytics to LocalAnalyticsCalculator (#250)

  Implement calculateSelfCare() method following TDD workflow:
  - Port algorithm from backend analytics.py:596-704
  - Add StrategyInfo struct and strategyLookup table
  - Extend LocalAnalyticsCalculatorProtocol
  - Add 10 comprehensive test cases

  Tests verify:
  - Empty data handling
  - Strategy counting and diversity calculation
  - Sorting by count descending
  - Limit parameter behavior
  - Unknown strategy ID handling
  - Strategy text population from catalog

  Closes #250"
  ```

- [ ] **Step 11**: Push to remote
  ```bash
  git push origin feature/issue-250-self-care-calculator
  ```

---

## Phase 4: Pull Request (AFTER PUSH ⏳)

- [ ] **Step 12**: Create PR on GitHub
  - [ ] Title: "feat: Add self-care analytics to LocalAnalyticsCalculator (#250)"
  - [ ] Description references #250
  - [ ] Label: `enhancement`
  - [ ] Assignee: Self

- [ ] **Step 13**: Wait for CI
  - [ ] Backend checks pass
  - [ ] SwiftFormat check passes
  - [ ] Xcode build passes
  - [ ] All tests pass in CI

---

## Phase 5: Review & Merge (AFTER CI PASSES ⏳)

- [ ] **Step 14**: Request Claude review
  - [ ] Tag Claude in PR comment
  - [ ] Wait for review

- [ ] **Step 15**: Address review comments
  - [ ] Make requested changes (if any)
  - [ ] Push updates
  - [ ] Wait for re-review

- [ ] **Step 16**: Get LGTM
  - [ ] Unequivocal approval from Claude
  - [ ] No outstanding comments
  - [ ] CI still green

- [ ] **Step 17**: Merge PR
  - [ ] Squash and merge
  - [ ] Delete branch after merge
  - [ ] Verify issue #250 auto-closed

---

## Quick Reference

### Files Modified
```
frontend/WavelengthWatch/WavelengthWatch Watch App/Services/LocalAnalyticsCalculator.swift
frontend/WavelengthWatch/WavelengthWatch Watch AppTests/LocalAnalyticsCalculatorTests.swift
```

### Test Command
```bash
frontend/WavelengthWatch/run-tests-individually.sh LocalAnalyticsCalculatorTests
```

### Format Command
```bash
swiftformat frontend/
```

### Pre-commit Command
```bash
pre-commit run --all-files
```

### Branch Name
```
feature/issue-250-self-care-calculator
```

---

## Troubleshooting

### If Tests Fail
1. Read error message carefully
2. Check test expectations vs implementation
3. Verify algorithm logic matches backend
4. Re-run individual failing test for clarity
5. Fix implementation (not tests, unless test is wrong)
6. Re-run all tests

### If SwiftFormat Fails
1. Review formatting errors
2. Run `swiftformat frontend/` to auto-fix
3. Verify changes look correct
4. Re-run SwiftFormat to verify clean

### If Pre-commit Fails
1. Read hook error messages
2. Fix issues (usually formatting or linting)
3. Re-run pre-commit
4. If persistent, check `.pre-commit-config.yaml`

### If CI Fails
1. Check CI logs for specific failure
2. Run same checks locally (test, format, lint)
3. Fix issue
4. Push update
5. Wait for CI to re-run

---

## Success Criteria

- ✅ All 10 new tests pass
- ✅ All existing tests still pass
- ✅ SwiftFormat clean
- ✅ Pre-commit hooks pass
- ✅ CI passes
- ✅ Unequivocal LGTM from Claude
- ✅ PR merged
- ✅ Issue #250 closed

---

**Last Updated**: 2026-01-16
**Status**: Implementation complete, ready for testing
