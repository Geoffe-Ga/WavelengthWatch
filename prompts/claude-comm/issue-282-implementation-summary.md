# Issue #282: Reframe "declining" trend language - Implementation Summary

**Date**: 2026-01-23
**Issue**: #282 - Reframe "declining" trend language in growth indicators
**Priority**: Phase 1 Quick Win (Analytics Mission Alignment)
**Status**: Implementation Complete - Ready for Testing

## Changes Made

### 1. StreakDisplayView.swift
**File**: `/frontend/WavelengthWatch/WavelengthWatch Watch App/Views/Components/StreakDisplayView.swift`

- **Renamed enum case**: `.declining` → `.resting`
- **Updated color**: `.orange` → `.secondary` (neutral)
- **Updated comments**: "Working back toward record" → "Honoring natural rhythm"
- **Added documentation**: Explicit note about neutral, supportive language

### 2. GrowthIndicatorsView.swift
**File**: `/frontend/WavelengthWatch/WavelengthWatch Watch App/Views/Analytics/GrowthIndicatorsView.swift`

- **Renamed enum case**: `TrendDirection.negative` → `TrendDirection.varying`
- **Updated colors**:
  - `.varying`: `.red` → `.secondary` (neutral)
  - `.neutral`: `.orange` → `.secondary` (neutral)
- **Added documentation**: Explicit note about avoiding evaluative terminology

### 3. Test Files Updated

#### StreakDisplayViewTests.swift
- Renamed test: `showsDecliningTrend` → `showsRestingTrend`
- Renamed test: `returnsDownArrowForDecliningTrend` → `returnsDownArrowForRestingTrend`
- Updated comment: ".declining" → ".resting"
- Updated assertions: `.declining` → `.resting`
- **Added new test**: `trendIndicators_useNeutralSupportiveLanguage()` to verify no red/orange colors

#### GrowthIndicatorsViewTests.swift
- Renamed test: `returnsNegativeForTrendBelowThreshold` → `returnsVaryingForTrendBelowThreshold`
- Renamed test: `returnsDownArrowForNegativeTrend` → `returnsDownArrowForVaryingTrend`
- Renamed test: `returnsRedForNegativeTrend` → `returnsNeutralColorForVaryingTrend`
- Renamed test: `returnsOrangeForNeutralTrend` → `returnsNeutralColorForNeutralTrend`
- Renamed test: `integrationTest_withRealisticNegativeGrowthData` → `integrationTest_withRealisticVaryingGrowthData`
- Renamed test: `isEmpty_returnsFalseWhenHasNegativeTrend` → `isEmpty_returnsFalseWhenHasVaryingTrend`
- Renamed test: `formattedTrend_includesPercentageAndSignForNegativeTrend` → `formattedTrend_includesPercentageAndSignForDecreasingTrend`
- **Updated assertions**: Changed color checks to verify NO red/orange colors used

## Language Changes Summary

### Before (Evaluative/Judgmental)
- "declining" → implies failure
- "negative" → implies bad
- Red color → danger/failure
- Orange color → warning/problem

### After (Neutral/Supportive)
- "resting" → honoring natural rhythm
- "varying" → natural fluctuation
- Secondary color → neutral, non-judgmental
- Green → still celebrates achievements (kept)

## APTITUDE Alignment

This change restores the core APTITUDE value:
> "This is not a failure. This is your body's wisdom asking you to rest and integrate."

By removing evaluative language and colors, we support users in honoring their natural rhythms without judgment.

## Files Modified
1. `/frontend/WavelengthWatch/WavelengthWatch Watch App/Views/Components/StreakDisplayView.swift`
2. `/frontend/WavelengthWatch/WavelengthWatch Watch App/Views/Analytics/GrowthIndicatorsView.swift`
3. `/frontend/WavelengthWatch/WavelengthWatch Watch AppTests/StreakDisplayViewTests.swift`
4. `/frontend/WavelengthWatch/WavelengthWatch Watch AppTests/GrowthIndicatorsViewTests.swift`

## Next Steps
1. Run tests: `frontend/WavelengthWatch/run-tests-individually.sh StreakDisplayViewTests GrowthIndicatorsViewTests`
2. Run pre-commit hooks: `pre-commit run --all-files`
3. Create feature branch and PR
4. Verify CI passes

## Success Criteria
- [x] No instances of "declining" in user-facing strings
- [x] No red/orange colors used to indicate "bad" engagement
- [x] Neutral language: "resting", "varying"
- [x] Tests updated to verify neutral language and colors
- [ ] All tests passing
- [ ] Pre-commit hooks passing
- [ ] CI passing
