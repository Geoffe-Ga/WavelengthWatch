# Root Cause Analysis: Strategy Card Sizing Bug

**Issue**: Strategy phase cards render tiny/shrunken when user scrolls between primary and secondary emotion selection, and persists after flow completion.

**Date**: 2025-12-16
**Related Issues**: #158, #165, #180

---

## Executive Summary

The bug occurs because **multiple SwiftUI bindings use the raw `layerSelection` value instead of a clamped version**. When `layerSelection` is out of bounds for the current `filteredLayers`, these bindings cause undefined behavior in the scroll view and card transform calculations.

---

## The Problem

### Symptoms
1. Strategy cards render at ~85% scale (tiny) instead of 100%
2. Cards appear squished to the left
3. Issue occurs after scrolling vertically during emotion selection
4. Issue persists even after flow completion

### Root Cause

**Three places use raw `layerSelection` without clamping:**

| Location | Code | Problem |
|----------|------|---------|
| Line 390 | `.scrollPosition(id: .init(get: { layerSelection }, ...))` | Scroll tries to position at non-existent ID |
| Line 399 | `get: { Double(layerSelection) }` | Digital crown getter returns out-of-range value |
| Line 378 | `selectedLayerIndex: clampedSelection` | ✅ Already fixed - but doesn't help if other bindings are broken |

### Why This Causes Tiny Cards

The `transformEffect` calculation (lines 543-555):
```swift
private var transformEffect: ... {
    let distance = layerIndex - selectedLayerIndex
    switch distance {
    case 0: return (scale: 1.0, ...)      // Full size
    case 1, -1: return (scale: 0.95, ...) // Slightly smaller
    default: return (scale: 0.85, ...)    // TINY - this is hit!
    }
}
```

When `layerSelection = 5` (from previous scroll position) and filter mode changes to `.strategiesOnly`:
- `filteredLayers.count = 1` (only layer 0)
- `clampedSelection = min(5, 0) = 0` ✅ Correct
- BUT the scroll position binding still returns `layerSelection = 5`

The scroll view receives conflicting information:
1. ForEach generates 1 card with `layerIndex = 0`
2. Scroll position says "position at ID 5" (doesn't exist)
3. This causes SwiftUI to render the view in an undefined state

---

## Detailed Flow Analysis

### Scenario: User scrolls during emotion logging flow

```
Step 1: User in .emotionsOnly mode, scrolls to layer 5 (Orange)
  - layerSelection = 5
  - filteredLayers.count = 10
  - All bindings consistent ✓

Step 2: User selects secondary emotion, taps "Add Strategy"
  - FlowCoordinator.promptForStrategy() sets layerFilterMode = .strategiesOnly
  - filteredLayers recalculated: count = 1 (only layer 0)

Step 3: View re-renders with INCONSISTENT state:
  - layerSelection = 5 (NOT UPDATED YET - onChange hasn't fired)
  - filteredLayers.count = 1

  Bindings evaluate:
  - scrollPosition.get() returns 5 → no card with ID 5 exists!
  - digitalCrownRotation.get() returns 5.0 → configured range is 0...0!
  - clampedSelection = min(5, 0) = 0 → passed to LayerCardView

Step 4: SwiftUI tries to render:
  - ForEach produces 1 card (index 0)
  - Scroll view is confused about position
  - Card may render in wrong location or with wrong transform

Step 5: onChange handlers fire (TOO LATE):
  - layerSelection eventually gets clamped
  - But initial render damage is done
  - Animation may interpolate from bad state
```

---

## The Fix

### Current State (Partial Fixes)
- Line 372: `clampedSelection` for `selectedLayerIndex` ✅
- Line 164-182: `onChange(of: viewModel.layerFilterMode)` handler ✅

### Missing Fixes

**1. Scroll Position Binding (Line 389-396)**
```swift
// BEFORE (broken):
.scrollPosition(id: .init(
    get: { layerSelection },  // Returns 5 when only 1 layer exists
    set: { ... }
))

// AFTER (fixed):
.scrollPosition(id: .init(
    get: {
        let maxIndex = max(0, viewModel.filteredLayers.count - 1)
        return min(layerSelection, maxIndex)
    },
    set: { ... }
))
```

**2. Digital Crown Rotation (Line 397-414)**
```swift
// BEFORE (broken):
.digitalCrownRotation(
    .init(
        get: { Double(layerSelection) },  // Returns 5.0 when range is 0...0
        set: { ... }
    ),
    from: 0,
    through: Double(max(viewModel.filteredLayers.count - 1, 0)),
    ...
)

// AFTER (fixed):
.digitalCrownRotation(
    .init(
        get: {
            let maxIndex = max(0, viewModel.filteredLayers.count - 1)
            return Double(min(layerSelection, maxIndex))
        },
        set: { ... }
    ),
    from: 0,
    through: Double(max(viewModel.filteredLayers.count - 1, 0)),
    ...
)
```

**3. ScrollViewReader proxy.scrollTo (Line 415-420)**
```swift
// BEFORE:
.onChange(of: layerSelection) { _, newValue in
    guard viewModel.filteredLayers.count > 0, newValue < viewModel.filteredLayers.count else { return }
    // This guard prevents scrollTo but doesn't fix the initial render
    ...
}

// Note: The guard is good but doesn't help with initial render.
// The scroll position binding fix above addresses this.
```

---

## Implementation Plan

### Phase 1: Create Computed Property
Add a `clampedLayerSelection` computed property to centralize the clamping logic:

```swift
private var clampedLayerSelection: Int {
    guard viewModel.filteredLayers.count > 0 else { return 0 }
    return min(layerSelection, viewModel.filteredLayers.count - 1)
}
```

### Phase 2: Update All Bindings
Replace `layerSelection` with `clampedLayerSelection` in:
1. `.scrollPosition(id:)` getter
2. `.digitalCrownRotation` getter
3. Keep `clampedSelection` calculation in ForEach (redundant but defensive)

### Phase 3: Test Cases
1. Start flow, scroll to layer 5, add strategy → cards should be full size
2. Complete flow with strategy selected → cards should stay full size
3. Cancel flow mid-way → cards should stay full size
4. All existing tests should continue to pass

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Clamping causes scroll jump | Low | Medium | Test scroll behavior thoroughly |
| Digital crown feels wrong | Low | Low | Clamping happens in getter, setter already clamps |
| Other bindings affected | Low | Medium | Search for other uses of `layerSelection` |

---

## Files Modified

- `frontend/WavelengthWatch/WavelengthWatch Watch App/ContentView.swift`
  - Add `clampedLayerSelection` computed property
  - Update `.scrollPosition(id:)` getter
  - Update `.digitalCrownRotation` getter

---

## Verification

After fix, verify:
- [ ] Strategy cards display at full size when scrolling between selections
- [ ] Cards stay full size after flow completion
- [ ] No regression in normal browsing scroll behavior
- [ ] Digital crown works correctly in all filter modes
- [ ] All existing tests pass
