# Issue #282: Testing Checklist

## Manual Testing Commands

### 1. Run Affected Test Suites
```bash
cd /Users/geoffgallinger/Projects/WavelengthWatchRoot
frontend/WavelengthWatch/run-tests-individually.sh StreakDisplayViewTests
frontend/WavelengthWatch/run-tests-individually.sh GrowthIndicatorsViewTests
```

### 2. Run All Tests (Optional - Full Validation)
```bash
frontend/WavelengthWatch/run-tests-individually.sh
```

### 3. Run Pre-commit Hooks
```bash
pre-commit run --all-files
```

This will run:
- SwiftFormat linting on all Swift files
- Backend checks (if applicable)

### 4. Verify SwiftFormat Manually (Optional)
```bash
swiftformat --lint frontend
```

## Expected Results

### Test Results
All tests should PASS with the following new behaviors:
- `StreakDisplayView` uses `.resting` instead of `.declining`
- `GrowthIndicatorsView` uses `.varying` instead of `.negative`
- No red/orange colors used for non-positive trends
- `.secondary` color used for neutral/resting/varying states

### Visual Changes (Preview)
When viewing in Xcode:
1. Open `StreakDisplayView.swift` in Xcode
2. Enable Canvas/Preview
3. Check "Active Streak" preview (5 current, 12 longest):
   - Should show down arrow (↓)
   - Arrow should be gray/secondary color (NOT orange)
4. Check "At Record" preview (15 current, 15 longest):
   - Should show right arrow (→)
   - Arrow should be green

## Code Review Checklist

### Enum Changes
- [ ] `TrendIndicator.declining` → `TrendIndicator.resting` ✓
- [ ] `TrendDirection.negative` → `TrendDirection.varying` ✓

### Color Changes
- [ ] `StreakDisplayView.trendColor` for resting: `.orange` → `.secondary` ✓
- [ ] `GrowthIndicatorsView.trendColor` for varying: `.red` → `.secondary` ✓
- [ ] `GrowthIndicatorsView.trendColor` for neutral: `.orange` → `.secondary` ✓

### Test Changes
- [ ] All "declining" test names updated to "resting" ✓
- [ ] All "negative" test names updated to "varying" or "decreasing" ✓
- [ ] New test added: `trendIndicators_useNeutralSupportiveLanguage()` ✓
- [ ] Color assertions updated to verify NO red/orange ✓

### Documentation
- [ ] Comments updated to reflect supportive language ✓
- [ ] Enum documentation added explaining neutral approach ✓
- [ ] Implementation summary created ✓

## Known Issues/Limitations

None expected. This is a pure presentation layer change with no data model impacts.

## Git Workflow

### 1. Create Feature Branch
```bash
git checkout -b feature/issue-282-reframe-declining-language
```

### 2. Stage Changes
```bash
git add frontend/WavelengthWatch/WavelengthWatch\ Watch\ App/Views/Components/StreakDisplayView.swift
git add frontend/WavelengthWatch/WavelengthWatch\ Watch\ App/Views/Analytics/GrowthIndicatorsView.swift
git add frontend/WavelengthWatch/WavelengthWatch\ Watch\ AppTests/StreakDisplayViewTests.swift
git add frontend/WavelengthWatch/WavelengthWatch\ Watch\ AppTests/GrowthIndicatorsViewTests.swift
git add prompts/claude-comm/issue-282-*.md
```

### 3. Commit
```bash
git commit -m "feat: Replace 'declining' language with neutral 'resting' terminology (#282)

- Rename TrendIndicator.declining → .resting
- Rename TrendDirection.negative → .varying
- Replace red/orange colors with neutral .secondary
- Update all tests to verify supportive language
- Add test to verify no evaluative colors used

Restores APTITUDE value: 'This is not a failure. This is your
body's wisdom asking you to rest and integrate.'

Phase 1 Quick Win from Analytics Mission Alignment initiative."
```

### 4. Push and Create PR
```bash
git push -u origin feature/issue-282-reframe-declining-language
```

Then create PR on GitHub targeting `main` branch.

## PR Description Template

```markdown
## Issue
Closes #282

## Summary
Removes harmful "declining" and "negative" terminology from trend indicators, replacing with neutral, supportive language that honors natural rhythms.

## Changes
- **StreakDisplayView**: `.declining` → `.resting`, orange → secondary
- **GrowthIndicatorsView**: `.negative` → `.varying`, red/orange → secondary
- **Tests**: Updated all assertions and added neutral language verification

## APTITUDE Alignment
Restores core value: "This is not a failure. This is your body's wisdom asking you to rest and integrate."

## Testing
- [x] Updated tests pass locally
- [x] Pre-commit hooks pass
- [x] SwiftFormat linting clean
- [ ] CI checks pass (verify after PR creation)

## Screenshots
Preview of "Active Streak" showing gray down arrow instead of orange.
```

## Success Metrics

- [ ] All tests pass
- [ ] Pre-commit hooks pass
- [ ] CI passes
- [ ] Code review approved
- [ ] Merged to main
- [ ] No instances of "declining" in user-facing code
- [ ] No red/orange "bad" colors in trend indicators
