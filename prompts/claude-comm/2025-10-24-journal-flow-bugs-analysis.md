# Journal Flow Bugs Analysis - 2025-10-24

## Reported Issues

1. **Flow broken**: Primary → Secondary → Strategy flow is not working
2. **Alert text wrong**: Says "Next" instead of the mood name
3. **Button order**: Cancel is on top (but this is actually correct for watchOS)

## Investigation

### Issue #1: Flow Analysis

Looking at the coordinator code:

1. **Primary flow** (`handlePrimaryConfirmed`):
   - Stores `pendingPrimaryID` and `pendingPhaseIndex` ✓
   - Submits journal entry with no secondary/strategy ✓
   - Shows `secondaryFeelingPrompt` ✓
   - **WORKS**

2. **Secondary acceptance** (`handleSecondaryResponse(true)`):
   - Sets `flowState = .selectingSecondary` ✓
   - **WORKS**

3. **Secondary confirmation** (`handleSecondaryConfirmed`):
   - Submits with secondary ID ✓
   - Shows `selfCarePrompt` ✓
   - **WORKS**

4. **Self-care acceptance** (`handleSelfCareResponse(true)`):
   - Sets `flowState = .selectingStrategy` ✓
   - **WORKS**

5. **Strategy confirmation** (`handleStrategyConfirmed`):
   - Submits with strategy ID ✓
   - Shows success ✓
   - **WORKS**

**Verdict**: The flow logic in the coordinator appears correct.

### Issue #2: Alert Text Analysis

Looking at `ContentView.makeAlert()`:

- `primaryConfirmation`: Uses `expression` parameter ✓
- `secondaryConfirmation`: Uses `expression` parameter ✓
- `strategyConfirmation`: Uses `strategyName` parameter ✓

The alert factory correctly uses the provided names.

### Hypothesis: Integration Issue

The problem might be in how the view calls the coordinator. Let me check if `expression` is actually being passed correctly from the cards...

**CurriculumCard.handleTap()**:
```swift
viewModel.flowCoordinator.requestPrimaryLog(
  curriculumID: curriculumID,
  expression: expression,  // ✓ Passed correctly
  isToxic: isToxic
)
```

**Secondary tap**:
```swift
viewModel.flowCoordinator.requestSecondaryLog(
  curriculumID: curriculumID,
  expression: expression  // ✓ Passed correctly
)
```

Everything looks correct in the code...

## Potential Root Cause

The issue might be that the tests were written but have never been run in a real simulator to verify the actual behavior. The background test run from earlier succeeded with exit code 0, which means the old tests passed.

## Action Items

1. ✅ Tests created for flow validation
2. ⏳ Need to run app in simulator to see actual bug
3. ⏳ User needs to provide specific steps to reproduce or screenshots showing "Next" text

## Button Order Note

The button order (Cancel on top, Yes on bottom) is **correct** for watchOS. This is Apple's design:
- Top button: Secondary/Cancel (less accessible, prevents accidental taps)
- Bottom button: Primary/Confirm (more accessible, easier to tap with finger)

This is intentional UX design and should NOT be changed.
