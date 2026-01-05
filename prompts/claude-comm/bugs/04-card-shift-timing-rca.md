# Root Cause Analysis: Card Shift After 1 Second (#182)

**Issue**: [#182](https://github.com/Geoffe-Ga/WavelengthWatch/issues/182)
**Status**: Investigating
**Date**: 2026-01-05

## Summary

When scrolling vertically through layers, cards appear to shift left ~2 pixels approximately 1 second after becoming visible. This creates a jarring UX where the card "settles" into position after the initial render.

## Symptoms

- **Trigger**: Scroll upward (towards earlier layers)
- **Timing**: ~1 second after card loads
- **Visual**: Subtle leftward shift (~2 pixels)
- **Frequency**: Consistent, reproducible

## Root Cause Hypothesis

### Primary Hypothesis: Layer Indicator Overlay Layout Impact

The layer indicator overlay (ContentView.swift lines 437-531):

1. **Shows on scroll**: `showLayerIndicator = true` triggers display
2. **Hides after 1 second**: `scheduleLayerIndicatorHide()` at line 533-544
3. **Uses `.overlay(alignment: .trailing)`** at line 437
4. **Has `.padding(.trailing, 6)`** at line 526

**The Problem:**
Even though `.overlay` should be layout-neutral, the padding within the overlay may cause subtle layout recalculation when the overlay's opacity changes from 1 → 0.

### Timing Correlation

```swift
// Line 536: 1-second delay matches observed shift timing
try? await Task.sleep(nanoseconds: 1_000_000_000)
```

The 1-second delay in `scheduleLayerIndicatorHide()` directly correlates with when users observe the shift.

### Layout Impact Analysis

The indicator has variable width:
- **Selected layer**: `width: 8` (line 506)
- **Unselected layers**: `width: 4` (line 506)

When the indicator fades out via `.opacity` transition:
1. The overlay's content still exists (opacity 0, not removed from hierarchy)
2. SwiftUI may recalculate the parent container's frame
3. The `.padding(.trailing, 6)` could cause the parent to adjust its content position

## Alternative Hypotheses

### Hypothesis 2: Animation Timing
The `LayerCardView.transformEffect` uses `.interactiveSpring(response: 0.4, dampingFraction: 0.8)` (line 597). If `selectedLayerIndex` updates after render, the spring animation could cause delayed position adjustment.

**Why less likely**: The shift timing (1 second) doesn't match the spring animation duration (~0.4s response time).

### Hypothesis 3: GeometryReader Frame Update
The parent uses `GeometryReader` to measure available space. If the geometry changes when the indicator disappears, cards could shift.

**Why less likely**: GeometryReader should only measure, not affect layout.

## Investigation Plan

1. ✅ Confirm timing correlation (1 second = indicator hide delay)
2. ⏳ Test if removing `.padding(.trailing, 6)` eliminates shift
3. ⏳ Test if using `.offset` instead of `.padding` fixes issue
4. ⏳ Verify fix doesn't break indicator positioning
5. ⏳ Check if shift occurs in both directions (up and down scroll)

## Proposed Fix

**Replace `.padding(.trailing, 6)` with `.offset(x: -6)`**

This ensures the overlay is truly layout-neutral:
- `.padding` may affect parent layout calculations
- `.offset` repositions without affecting layout
- Maintains same visual positioning

### Code Change Location

**File**: `frontend/WavelengthWatch/WavelengthWatch Watch App/ContentView.swift`
**Line**: 526

**Before:**
```swift
}
.padding(.trailing, 6)
Spacer()
```

**After:**
```swift
}
.offset(x: -6)  // Use offset instead of padding to avoid layout impact
Spacer()
```

### Additional Safeguard

Consider adding `.fixedSize()` to the overlay to prevent it from affecting parent layout:

```swift
.overlay(alignment: .trailing) {
  enhancedLayerIndicator(in: geometry.size)
    .fixedSize()  // Prevent overlay from affecting parent layout
}
```

## Testing Strategy

### Manual Testing
1. Scroll upward through layers
2. Watch for 1-second delayed shift
3. Verify fix eliminates shift
4. Verify indicator still displays correctly
5. Test on both 42mm and 46mm watch sizes

### Automated Testing
This is primarily a UI timing issue. Automated testing would require:
- UI testing framework to observe frame changes
- Timing assertions (check layout 0.5s vs 1.5s after scroll)
- Frame comparison snapshots

**Decision**: Manual testing is more practical for this polish bug.

## Success Criteria

- [ ] Cards render in final position immediately
- [ ] No delayed horizontal shift after 1 second
- [ ] Layer indicator still animates smoothly
- [ ] Indicator positioning unchanged visually
- [ ] Fix verified on 42mm and 46mm simulators
- [ ] All existing tests pass

## References

- Issue #182: Card shifts left ~2 pixels after 1 second
- Related code: ContentView.swift lines 437-544 (layer indicator)
- Similar timing issues: None found in issue history

---

**Next Steps:**
1. Implement proposed fix
2. Manual verification
3. Submit PR
4. Monitor for regressions
