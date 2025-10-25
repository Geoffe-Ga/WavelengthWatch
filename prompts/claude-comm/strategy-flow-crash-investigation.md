# Strategy Flow Crash Investigation

**Date**: 2025-10-24
**Status**: Critical Bug - Strategy flow completely broken

## Problem Description

When a user completes the journal flow and accepts the self-care prompt (to log a strategy), the following incorrect behavior occurs:

1. **Premature Success Alert**: Immediately shows "Thanks for logging a strategy" even though no strategy has been selected yet
2. **Auto-logging Strategy**: A strategy (ID 48) is automatically logged without user selection
3. **Black Screen/Unresponsive**: After showing the success alert, attempting to navigate back causes the screen to go black and become unresponsive
4. **Layer Visibility Issue**: Other layers appear to be "dark" rather than properly inaccessible during strategy selection mode

## Expected Behavior

When user presses "Yes I want to log a strategy":
1. Navigate to strategies layer (layer 0)
2. Show ONLY the strategies layer (other layers should not be accessible)
3. Display green banner: "Tap a self-care strategy" with Cancel button
4. Wait for user to select a strategy
5. Only AFTER user selects and confirms a strategy, show success alert
6. Return to normal navigation mode

## Console Logs Analysis

### Full Log Trace
```
🟡 showingJournalConfirmation changed from false to true, userConfirmed=false
🟡 CurriculumCard alert 'Yes' tapped
🟡 showingJournalConfirmation changed from true to false, userConfirmed=true
🟡 Alert dismissed with confirmation, calling journal after delay
🟡 Delay complete, calling journal now
🔵 journal() called: curriculumID=1, secondary=nil, strategy=nil
🟡 CurriculumCard journal() completed
🟣 showSecondaryFeelingPrompt changed from false to true, response=nil

[ERROR] Presenting view controller from detached view controller
[ERROR] Attempt to present while presentation is in progress

🔵 Secondary prompt: Yes tapped
🟣 showSecondaryFeelingPrompt changed from true to false, response=Optional(true)
🟣 Secondary alert dismissed, processing response after delay
🟣 Delay complete, processing response: Optional(true)

[Crown Sequencer warnings - indicates navigation issues]

🟡 showingJournalConfirmation changed from false to true, userConfirmed=false
🟡 CurriculumCard alert 'Yes' tapped
🟡 showingJournalConfirmation changed from true to false, userConfirmed=true
🟡 Alert dismissed with confirmation, calling journal after delay
🟡 Delay complete, calling journal now
🔵 journal() called: curriculumID=1, secondary=Optional(37), strategy=nil
🟡 CurriculumCard journal() completed
🟤 showSelfCarePrompt changed from false to true, response=nil

[ERROR] Presenting view controller from detached view controller
[ERROR] Multiple "Publishing changes from within view updates" warnings

🟢 Self-care prompt: Yes tapped
🟤 showSelfCarePrompt changed from true to false, response=Optional(true)
🟤 Self-care alert dismissed, processing response after delay
🟤 Delay complete, processing response: Optional(true)

[ERROR] Presenting view controller from detached view controller

⚠️  🔵 journal() called: curriculumID=1, secondary=nil, strategy=Optional(48)

[ERROR] Presenting view controller from detached view controller
```

### Key Observations

#### 1. **Premature Strategy Logging** (Line marked with ⚠️)
```
🟤 Delay complete, processing response: Optional(true)
🔵 journal() called: curriculumID=1, secondary=nil, strategy=Optional(48)
```
**Problem**: Strategy ID 48 is being logged immediately after `handleSelfCareResponse(wantsSelfCare: true)` is called, without user interaction to select a strategy.

**Expected**: After `handleSelfCareResponse(true)`, should:
- Navigate to strategies layer
- Show strategy selection UI
- Wait for user tap on a strategy
- Only THEN call `journal()` with the selected strategy ID

#### 2. **Missing Navigation Logs**
No logs show:
- Layer navigation completing
- Banner appearing
- `isLoggingStrategy` being set to true

**This suggests** `handleSelfCareResponse` is triggering side effects we don't expect.

#### 3. **Persistent "Detached View Controller" Errors**
Despite the `.onChange` fixes, alerts still present from detached view controllers. This indicates the 100ms delay is insufficient, or there's a deeper architectural issue with how SwiftUI is managing the view hierarchy.

#### 4. **"Publishing Changes" Warnings**
The flood of these warnings after self-care prompt suggests multiple state changes happening synchronously during view updates.

## Root Causes (Hypotheses)

### Bug #1: Success Alert Shown Too Early
**Location**: `ContentViewModel.swift:178`
```swift
func handleSelfCareResponse(wantsSelfCare: Bool) {
  showSelfCarePrompt = false
  if wantsSelfCare {
    selectedLayerIndex = layers.count - 1
    isLoggingStrategy = true
    journalFeedback = JournalFeedback(kind: .success)  // ❌ WRONG!
  }
}
```

**Issue**: Setting `journalFeedback` here shows "Thanks for logging a strategy" before the strategy is selected.

**Fix**: Remove this line. Only show success feedback after strategy is actually logged.

### Bug #2: Phantom Strategy Auto-Logging
**Mystery**: Where does `journal(curriculumID: 1, strategy: 48)` get called?

**Possibilities**:
1. StrategyListView might have auto-tap behavior
2. Layer visibility change triggers an unwanted view update
3. Success alert triggering causes a callback somewhere
4. `journalFeedback` being set triggers something in the view

**Need to investigate**: StrategyListView and StrategyCard implementations.

### Bug #3: Layer Visibility Filtering Causes Issues
**Location**: `ContentView.swift:260-273`
```swift
private var visibleLayers: [CatalogLayerModel] {
  let strategiesIndex = viewModel.layers.count - 1

  if viewModel.isLoggingStrategy {
    return viewModel.layers.enumerated().filter { $0.offset == strategiesIndex }.map(\.element)
  }
  // ...
}
```

**Issue**: When `isLoggingStrategy` becomes true, `visibleLayers` array changes from [all layers] to [strategies layer only]. This causes:
- ForEach to re-render with completely different data
- `layerSelection` index might now be invalid
- Digital Crown bindings might point to wrong layer
- View hierarchy gets confused

**Better Approach**: Don't filter the layers array. Instead:
- Keep all layers visible in the array
- Add `.disabled()` modifier to non-strategy layers
- Add visual dimming overlay to non-strategy layers
- This maintains stable indices and view hierarchy

## Immediate Action Items

1. ✅ Document the issue in this file
2. ✅ Remove premature success alert in `handleSelfCareResponse` (line 184 - removed journalFeedback assignment)
3. ⚠️ Investigate where strategy auto-logging happens (awaiting user test with new logs)
4. ✅ Replace layer filtering with layer disabling + visual dimming (ContentView.swift:336-349 - replaced visibleLayers filtering with isLayerEnabled() helper)
5. ✅ Add more logging around strategy selection flow (StrategyCard and isLoggingStrategy changes)
6. ⚠️ Test fix with same flow: log emotion → yes → log secondary → yes → log strategy

## Files Involved

- `ContentViewModel.swift:170-184` - handleSelfCareResponse
- `ContentViewModel.swift:80-151` - journal() method
- `ContentView.swift:260-273` - visibleLayers computed property
- `ContentView.swift:275-322` - layeredContent view using visibleLayers
- Need to review: StrategyListView and StrategyCard

## Testing Notes

The user reported the issue occurs during this flow:
1. Tap an emotion card
2. Confirm logging (Yes)
3. Secondary feeling prompt appears (Yes)
4. Select a secondary emotion card
5. Confirm logging (Yes)
6. Self-care prompt appears (Yes)
7. **❌ BUG OCCURS HERE** - Success alert shows immediately, screen goes black

The success alert appearing at step 7 is incorrect - should only appear after step 8 (user selects and confirms a strategy).

## Fixes Applied

### Fix #1: Removed Premature Success Alert (COMPLETED)
**File**: `ContentViewModel.swift:175-191`
**Change**: Removed `journalFeedback = JournalFeedback(kind: .success)` from the `wantsSelfCare == true` branch in `handleSelfCareResponse()`.

**Before**:
```swift
func handleSelfCareResponse(wantsSelfCare: Bool) {
  showSelfCarePrompt = false
  if wantsSelfCare {
    selectedLayerIndex = layers.count - 1
    isLoggingStrategy = true
    journalFeedback = JournalFeedback(kind: .success)  // ❌ WRONG - shows success too early
  }
}
```

**After**:
```swift
func handleSelfCareResponse(wantsSelfCare: Bool) {
  showSelfCarePrompt = false
  if wantsSelfCare {
    selectedLayerIndex = layers.count - 1
    isLoggingStrategy = true
    print("🟢 Entered strategy logging mode, navigating to strategies layer")
    // DON'T show success alert yet - wait until strategy is actually logged
  } else {
    journalFeedback = JournalFeedback(kind: .success)
    pendingJournalEntry = nil
  }
}
```

### Fix #2: Replaced Layer Filtering with Layer Disabling (COMPLETED)
**File**: `ContentView.swift:336-349`
**Problem**: The `visibleLayers` computed property was filtering the array, causing ForEach to re-render with different data and breaking the view hierarchy when `isLoggingStrategy` changed.

**Before**:
```swift
private var visibleLayers: [CatalogLayerModel] {
  let strategiesIndex = viewModel.layers.count - 1

  if viewModel.isLoggingStrategy {
    return viewModel.layers.enumerated().filter { $0.offset == strategiesIndex }.map(\.element)
  } else if viewModel.isSelectingSecondary || viewModel.showSecondaryFeelingPrompt {
    return viewModel.layers.enumerated().filter { $0.offset != strategiesIndex }.map(\.element)
  } else {
    return viewModel.layers
  }
}
```

**After**:
```swift
private func isLayerEnabled(_ layerIndex: Int) -> Bool {
  let strategiesIndex = viewModel.layers.count - 1

  if viewModel.isLoggingStrategy {
    return layerIndex == strategiesIndex
  } else if viewModel.isSelectingSecondary || viewModel.showSecondaryFeelingPrompt {
    return layerIndex != strategiesIndex
  } else {
    return true
  }
}
```

**Changes**:
1. Replaced filtering with a helper function that determines if a layer should be enabled
2. Updated `layeredContent` to use `viewModel.layers` directly (stable indices)
3. Added `isEnabled` parameter to `LayerCardView`, `LayerView`, and `PhasePageView`
4. Applied `.disabled(!isEnabled)` and dark overlay to disabled layers
5. Conditionally hide NavigationLink on disabled layers

This maintains stable layer indices and view hierarchy while still providing visual feedback about which layers are accessible.

### Additional Logging Added (COMPLETED)
**Files Modified**:
- `ContentViewModel.swift`: Added print statements in `journal()` method and `handleSelfCareResponse()`
- `ContentView.swift`: Added `.onChange(of: viewModel.isLoggingStrategy)` logging
- `ContentView.swift`: Added extensive logging to `StrategyCard` including `.onAppear`, tap gestures, alert buttons, and `.onChange`

These logs will help identify where the phantom strategy auto-logging originates.
