# Plan: Replace Floating Menu with Top Navigation Button

**Date:** 2025-11-22
**Context:** Phase 6.1 (Notification Routing) complete - PR #112
**Objective:** Replace the current floating three-dot menu button with a stationary top navigation button

---

## Current Implementation Analysis

### Location
**File:** `WavelengthWatch Watch App/ContentView.swift` (lines 206-226)

### Current Behavior
```swift
// Floating menu button overlay - only show on main view
if !isShowingDetailView {
  VStack {
    HStack {
      Button {
        showingMenu = true
      } label: {
        Image(systemName: "ellipsis.circle")
          .font(.system(size: UIConstants.menuButtonSize))
          .foregroundColor(.white.opacity(0.7))
      }
      .buttonStyle(.plain)
      .frame(minWidth: 44, minHeight: 44)
      .contentShape(Rectangle())
      .padding(.leading, 8)
      .padding(.top, 4)
      Spacer()
    }
    Spacer()
  }
}
```

**Properties:**
- **Position:** Top-left corner using VStack + HStack + Spacer pattern
- **Visibility:** Hidden when `isShowingDetailView == true`
- **Z-index behavior:** Overlays on top of scrollable content
- **Scrolling:** Floats/moves with scroll (not pinned to safe area)
- **Size:** 20pt icon in 44x44 touch target
- **Presentation:** Shows sheet with `MenuView` (defined at line 1063)

### What MenuView Contains
- **Log Emotion** button (opens emotion flow)
- **Schedules** (NavigationLink → ScheduleSettingsView)
- **Analytics** (NavigationLink → AnalyticsView)
- **About Archetypal Wavelength** (NavigationLink → ConceptExplainerView)

### Environment Key Mechanism
```swift
private struct IsShowingDetailViewKey: EnvironmentKey {
  static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
  var isShowingDetailView: Binding<Bool> {
    get { self[IsShowingDetailViewKey.self] }
    set { self[IsShowingDetailViewKey.self] = newValue }
  }
}
```

**Usage in ContentView:**
```swift
.environment(\.isShowingDetailView, $isShowingDetailView)
```

Detail views (e.g., `CurriculumDetailView`, `StrategyListView`) set this to `true` in their `onAppear` to hide the menu.

---

## Desired Implementation

### Goal
Replace the floating overlay button with a **stationary top navigation button** that:
1. ✅ Stays at the **very top** of the screen (safe area top edge)
2. ✅ Remains **stationary** (does not scroll vertically or horizontally)
3. ✅ Only visible on **appropriate screens** (main layer/phase navigation, NOT detail views)
4. ✅ Positioned in the **top-left corner**
5. ✅ Uses proper watchOS navigation patterns

### watchOS Navigation Pattern Recommendations

**Option 1: Toolbar with NavigationStack (Recommended)**
- Use `.toolbar(content:)` modifier with `.topBarLeading` placement
- Requires wrapping main content in `NavigationStack`
- Automatically handles safe area, stationarity, and watchOS conventions
- Best for native look & feel

**Option 2: Custom Safe Area Overlay**
- Use `.safeAreaInset(edge: .top)` modifier
- Manually position button at top edge
- More control over appearance but requires careful safe area handling

**Option 3: ZStack with Frame + Alignment**
- Use `ZStack(alignment: .topLeading)` with `.ignoresSafeArea(edges: .bottom)`
- Pin button to top safe area with `.frame(maxHeight: .infinity, alignment: .top)`
- Most similar to current floating pattern but stationary

---

## Recommended Approach: Option 1 (Toolbar)

### Implementation Plan

#### 1. Wrap Content in NavigationStack

**Current structure:**
```swift
var body: some View {
  ZStack(alignment: .topLeading) {
    layeredContent
    // Floating menu button overlay
    if !isShowingDetailView { ... }
  }
}
```

**New structure:**
```swift
var body: some View {
  NavigationStack {
    ZStack(alignment: .topLeading) {
      layeredContent
    }
    .toolbar {
      if !isShowingDetailView {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            showingMenu = true
          } label: {
            Image(systemName: "ellipsis.circle")
              .font(.system(size: UIConstants.menuButtonSize))
              .foregroundColor(.white.opacity(0.7))
          }
          .buttonStyle(.plain)
        }
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .navigationTitle("") // Empty title to maximize space
  }
}
```

#### 2. Update Menu Presentation

**Current:**
```swift
.sheet(isPresented: $showingMenu) {
  NavigationStack {
    MenuView(journalClient: journalClient)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") { showingMenu = false }
        }
      }
  }
}
```

**Keep as-is** - Sheet presentation already correct

#### 3. Verify Detail View Behavior

**Ensure detail views still hide menu:**
- `CurriculumDetailView` sets `isShowingDetailView.wrappedValue = true` on appear
- `StrategyListView` sets `isShowingDetailView.wrappedValue = true` on appear
- Environment key already in place (lines 9-19)

**No changes needed** - existing mechanism works with toolbar

---

## Alternative: Option 3 (Safe Area Overlay)

If NavigationStack conflicts with existing dual-axis scrolling:

```swift
var body: some View {
  ZStack(alignment: .topLeading) {
    layeredContent

    // Stationary top button using safe area
    if !isShowingDetailView {
      VStack(spacing: 0) {
        HStack {
          Button {
            showingMenu = true
          } label: {
            Image(systemName: "ellipsis.circle")
              .font(.system(size: UIConstants.menuButtonSize))
              .foregroundColor(.white.opacity(0.7))
          }
          .buttonStyle(.plain)
          .frame(minWidth: 44, minHeight: 44)
          .contentShape(Rectangle())
          .padding(.leading, 8)
          .padding(.top, 4)
          Spacer()
        }
        .background(.ultraThinMaterial) // Optional: add background
        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .allowsHitTesting(true) // Ensure button receives taps
    }
  }
  .ignoresSafeArea(.all, edges: .bottom) // Keep safe area at top
}
```

**Why this works:**
- `frame(maxHeight: .infinity, alignment: .top)` pins VStack to top
- Doesn't scroll because it's in ZStack overlay, not inside ScrollView
- Safe area respected at top edge
- Hit testing allows button interaction while passing through elsewhere

---

## Files to Modify

### Primary File
- **`WavelengthWatch Watch App/ContentView.swift`**
  - Lines 206-226: Replace floating button implementation
  - Lines 5-7: May need to update UIConstants if changing size
  - Lines 172-183: Verify sheet presentation still works
  - Lines 9-19: Environment key (no changes needed)

### Files to Test (Verify menu hides correctly)
- **`WavelengthWatch Watch App/Views/Components/CurriculumDetailView.swift`**
  - Verify `isShowingDetailView.wrappedValue = true` still hides menu
- **`WavelengthWatch Watch App/Views/Components/StrategyListView.swift`**
  - Verify `isShowingDetailView.wrappedValue = true` still hides menu

### Files That Should NOT Change
- **`MenuView` struct** (lines 1063-1109): No changes needed
- **Detail views**: Environment key mechanism already works
- **Sheet presentation**: Already correct

---

## Implementation Steps

### Phase 1: Preparation
1. ✅ Create this plan document
2. ⬜ Review existing dual-axis scrolling behavior
3. ⬜ Verify NavigationStack compatibility with current TabView structure
4. ⬜ Test current menu visibility in detail views

### Phase 2: Implementation (Option 1 - Toolbar)
1. ⬜ Wrap main content in `NavigationStack`
2. ⬜ Replace floating button (lines 206-226) with `.toolbar` modifier
3. ⬜ Add `ToolbarItem(placement: .topBarLeading)` with menu button
4. ⬜ Ensure `if !isShowingDetailView` condition still works
5. ⬜ Set `.navigationBarTitleDisplayMode(.inline)`
6. ⬜ Test horizontal/vertical scrolling (button should stay at top)

### Phase 3: Testing
1. ⬜ Test menu button appears on main layer/phase view
2. ⬜ Test menu button is **stationary** during vertical scrolling
3. ⬜ Test menu button is **stationary** during horizontal scrolling (phase changes)
4. ⬜ Test menu button **hides** when navigating to emotion detail view
5. ⬜ Test menu button **hides** when navigating to strategy list view
6. ⬜ Test menu sheet opens correctly
7. ⬜ Test "Log Emotion" flow from menu
8. ⬜ Test navigation links (Schedules, Analytics, About)
9. ⬜ Test notification-triggered flow still works (unrelated but verify)

### Phase 4: Fallback (If NavigationStack Breaks Scrolling)
1. ⬜ Revert NavigationStack wrapper
2. ⬜ Implement Option 3 (Safe Area Overlay) instead
3. ⬜ Repeat Phase 3 testing

---

## Edge Cases to Consider

### 1. **Dual-Axis Scrolling Conflict**
**Issue:** NavigationStack might interfere with nested TabView (vertical layers + horizontal phases)

**Mitigation:**
- Test thoroughly in Phase 3, step 2-3
- Use Option 3 if NavigationStack breaks scrolling
- Verify both vertical (layer change) and horizontal (phase change) scrolling

### 2. **Safe Area Insets on Different Watch Sizes**
**Issue:** Watch sizes vary (38mm, 40mm, 41mm, 42mm, 44mm, 45mm, 46mm, 49mm)

**Mitigation:**
- Use `.padding(.top, 4)` relative to safe area (not fixed offset)
- Test on Apple Watch Series 10 (46mm) and Series 8 (41mm) simulators
- Toolbar automatically handles safe area (if using Option 1)

### 3. **Button Overlapping Curriculum Cards**
**Issue:** Top content might be partially obscured by stationary button

**Mitigation:**
- Add `.background(.ultraThinMaterial)` behind button for visibility
- Adjust top padding of `layeredContent` if needed
- Toolbar automatically handles this (if using Option 1)

### 4. **Sheet Presentation from Menu**
**Issue:** Menu already presented as sheet - "Log Emotion" opens another sheet

**Mitigation:**
- Current implementation already handles this correctly (nested sheets)
- Verify in Phase 3, step 7 that nested sheets work

### 5. **Notification Flow Interaction**
**Issue:** Notification-triggered flow opens sheet while menu might be visible

**Mitigation:**
- Menu and notification flow both use separate sheet bindings (`$showingMenu` vs `$showingFlowFromNotification`)
- Verify in Phase 3, step 9 that both can coexist

---

## Success Criteria

### Visual
- ✅ Menu button appears in **top-left corner** at safe area edge
- ✅ Button remains **completely stationary** during scrolling (horizontal & vertical)
- ✅ Button **only visible** on main layer/phase navigation screens
- ✅ Button **hidden** when viewing emotion details or strategy lists
- ✅ Clean visual separation from scrolling content

### Functional
- ✅ Tapping button opens menu sheet
- ✅ Menu sheet presents correctly with all 4 options
- ✅ "Log Emotion" flow works from menu
- ✅ Navigation links work (Schedules, Analytics, About)
- ✅ "Done" button dismisses menu
- ✅ Notification-triggered flow unaffected
- ✅ All existing tests pass (24/24 suites)

### Performance
- ✅ No scroll lag or jank
- ✅ No z-index flickering or rendering issues
- ✅ Smooth sheet animations

---

## Rollback Plan

**If implementation fails or breaks existing functionality:**

1. **Git revert** to commit before changes
2. **Restore floating button** implementation (lines 206-226)
3. **File issue** documenting problems encountered
4. **Consider alternative approaches:**
   - Custom toolbar using `.overlay()` instead of `.toolbar()`
   - Split-screen approach with persistent top bar
   - Gesture-based menu (long press on screen edge)

---

## Technical Notes

### Why Current Floating Approach Scrolls
- Button is inside `ZStack` which contains `layeredContent` (ScrollView)
- Even though button is in overlay layer, the **entire ZStack** can scroll
- SwiftUI treats overlays as children of the scrollable content

### Why Toolbar Approach Is Stationary
- `.toolbar()` modifier operates **outside** the scrollable content hierarchy
- Toolbar items are part of the **navigation bar**, not the content
- Navigation bar is pinned to safe area and doesn't scroll

### Why Safe Area Overlay Approach Works
- Using `.frame(maxHeight: .infinity, alignment: .top)` pins VStack to top edge
- VStack is **outside** the ScrollView content tree
- SwiftUI renders overlay **after** scrollable content but **before** safe area handling

---

## References

### Code Locations
- **Main Content View:** `ContentView.swift` lines 230-306
- **Floating Menu Button:** `ContentView.swift` lines 206-226
- **Menu View:** `ContentView.swift` lines 1063-1109
- **Environment Key:** `ContentView.swift` lines 9-19
- **Detail View Examples:**
  - `CurriculumDetailView.swift` (sets `isShowingDetailView = true`)
  - `StrategyListView.swift` (sets `isShowingDetailView = true`)

### SwiftUI Documentation
- [Toolbar Modifier](https://developer.apple.com/documentation/swiftui/view/toolbar(content:)-5w0tj)
- [ToolbarItemPlacement](https://developer.apple.com/documentation/swiftui/toolbaritemplacement)
- [Safe Area Insets](https://developer.apple.com/documentation/swiftui/view/safearinset(edge:alignment:spacing:content:))
- [NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack)

### Related PRs
- **PR #112:** Phase 6.1 - Notification Routing to Flow (just completed)
- **PR #111:** Phase 5.1 - Journal Review View

---

## Open Questions

1. **Should the menu button have a background?**
   - Current: Transparent with white opacity 0.7
   - Option: Add `.background(.ultraThinMaterial)` for better visibility
   - Decision: Test both and choose based on visual clarity

2. **Should menu button size change?**
   - Current: 20pt icon (`UIConstants.menuButtonSize`)
   - watchOS standard: 17-22pt for toolbar icons
   - Decision: Keep at 20pt (already within range)

3. **Should we use SF Symbols 2.0+ menu icon?**
   - Current: `ellipsis.circle`
   - Alternative: `line.3.horizontal` (hamburger menu, more standard)
   - Decision: Keep `ellipsis.circle` for consistency with watchOS patterns

4. **Navigation bar title - show or hide?**
   - Option A: `.navigationTitle("")` (empty, maximizes space)
   - Option B: `.navigationTitle("WavelengthWatch")` (brand presence)
   - Decision: Empty title to avoid clutter on small watch screen

---

## Notes for Future Implementation

- Start with **Option 1 (Toolbar)** as it's most idiomatic for watchOS
- Have **Option 3 (Safe Area Overlay)** ready as fallback
- Test on **multiple watch sizes** (41mm and 46mm minimum)
- Verify **accessibility** (VoiceOver reads button correctly)
- Consider **haptic feedback** on button press (optional enhancement)
- Document any changes in **CLAUDE.md** under Architecture Overview

---

**Status:** Plan complete, ready for implementation
**Next Step:** Review dual-axis scrolling compatibility before implementing
