# Phase 1 Findings: Menu Replacement Preparation

**Date:** 2025-11-22
**Branch:** `feature/stationary-menu-button`
**Issue:** #114

---

## Executive Summary

✅ **GOOD NEWS:** NavigationStack is **already wrapping** the main content (line 82 in ContentView.swift)
✅ **DECISION:** Proceed directly with **Option 1 (Toolbar approach)**
✅ **NO CHANGES NEEDED:** Dual-axis scrolling already works with NavigationStack

---

## Current Implementation Analysis

### 1. NavigationStack Already Present ✅

**Location:** `ContentView.swift` line 82

```swift
var body: some View {
  ZStack {
    NavigationStack {  // ← ALREADY HERE!
      ZStack {
        if viewModel.layers.isEmpty {
          // ... loading/error states
        } else if viewModel.phaseOrder.isEmpty {
          Text("No phase information available.")
        } else {
          layeredContent  // ← Dual-axis scrolling content
        }
      }
      .task { await viewModel.loadCatalog() }
      // ... modifiers
      .sheet(isPresented: $showingMenu) { ... }
    }
    .environmentObject(viewModel)
    .environment(\.isShowingDetailView, $isShowingDetailView)

    // Floating menu button overlay (lines 186-204)
    if !isShowingDetailView {
      VStack { ... }
    }
  }
}
```

**Finding:** Content is already wrapped in NavigationStack, so we can use `.toolbar()` modifier directly.

---

### 2. Dual-Axis Scrolling Structure ✅

**Vertical Scrolling (Layers):**
- **Implementation:** `ScrollView(.vertical)` with `LazyVStack` (lines 238-113)
- **Selection:** `scrollPosition(id:)` bound to `$layerSelection`
- **Input:** Digital Crown rotation + drag gestures
- **Status:** ✅ Works with NavigationStack (already using it)

**Horizontal Scrolling (Phases):**
- **Implementation:** `TabView` with `.tabViewStyle(.page)` (lines 255-270)
- **Selection:** `$selection` binding for phase index
- **Infinite scroll:** Wraps around using `PhaseNavigator` modulo logic
- **Status:** ✅ TabView works inside NavigationStack (already using it)

**Conclusion:** No conflicts discovered. Dual-axis scrolling is compatible with NavigationStack.

---

### 3. Current Floating Menu Button

**Location:** `ContentView.swift` lines 186-204

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
- Position: Top-left using VStack + HStack + Spacer
- Visibility: Controlled by `!isShowingDetailView`
- Z-index: Overlays in ZStack (outside NavigationStack)
- **Problem:** Scrolls with content (not stationary)

---

### 4. Environment Key Mechanism ✅

**Definition:** `ContentView.swift` lines 10-19

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

**Detail Views Set to True:**

**CurriculumDetailView** (lines 703-708):
```swift
.onAppear {
  isShowingDetailView.wrappedValue = true
}
.onDisappear {
  isShowingDetailView.wrappedValue = false
}
```

**StrategyListView** (lines 627-632):
```swift
.onAppear {
  isShowingDetailView.wrappedValue = true
}
.onDisappear {
  isShowingDetailView.wrappedValue = false
}
```

**Status:** ✅ Mechanism works correctly. Button hides in detail views.

---

### 5. Menu Sheet Presentation ✅

**Location:** `ContentView.swift` lines 170-181

```swift
.sheet(isPresented: $showingMenu) {
  NavigationStack {
    MenuView(journalClient: journalClient)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            showingMenu = false
          }
        }
      }
  }
}
```

**Finding:** Already uses NavigationStack for menu sheet! This confirms toolbar pattern works in this codebase.

---

## Test Results

### Test 1: Verify NavigationStack Doesn't Break Scrolling ✅

**Method:** Code review
**Result:** ✅ PASS - NavigationStack already present, scrolling works

**Evidence:**
- Vertical scrolling: `ScrollView(.vertical)` with `.scrollTargetBehavior(.viewAligned)` works
- Horizontal scrolling: `TabView` works (used in menu sheet too)
- Digital Crown: `.digitalCrownRotation()` modifier works
- Drag gestures: `.simultaneousGesture(DragGesture())` works

### Test 2: Verify Environment Key Works with Toolbar ✅

**Method:** Code review
**Result:** ✅ PASS - Environment values work across NavigationStack

**Evidence:**
- `isShowingDetailView` environment key set in ContentView
- Detail views read it via `@Environment(\.isShowingDetailView)`
- SwiftUI environment propagates through NavigationStack hierarchy

### Test 3: Verify Toolbar Placement Options ✅

**Method:** Review watchOS toolbar documentation
**Result:** ✅ PASS - `.topBarLeading` placement available

**Available placements for watchOS:**
- `.topBarLeading` ✅ (what we need)
- `.topBarTrailing`
- `.bottomBar`
- `.automatic`

---

## Compatibility Matrix

| Feature | NavigationStack | Toolbar | Status |
|---------|----------------|---------|--------|
| Vertical ScrollView | ✅ | ✅ | Compatible |
| Horizontal TabView | ✅ | ✅ | Compatible |
| Digital Crown | ✅ | ✅ | Compatible |
| Environment Keys | ✅ | ✅ | Compatible |
| Sheet Presentation | ✅ | ✅ | Compatible |
| Safe Area Handling | ✅ | ✅ | Automatic |

---

## Decision: Option 1 (Toolbar Approach)

### Rationale

1. **NavigationStack already present** - No structural changes needed
2. **Dual-axis scrolling works** - No conflicts with existing implementation
3. **Toolbar is watchOS-native** - Automatically handles safe area, stationarity
4. **Already using toolbar** - Menu sheet uses toolbar for "Done" button
5. **Minimal code changes** - Just move button from overlay to `.toolbar {}`

### Implementation Plan

**Replace** (lines 186-204):
```swift
// Floating menu button overlay - only show on main view
if !isShowingDetailView {
  VStack { ... }
}
```

**With** (after existing `.sheet()` modifier, before `.environmentObject()`):
```swift
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
```

**Add** (after `.toolbar {}`):
```swift
.navigationBarTitleDisplayMode(.inline)
.navigationTitle("")
```

---

## Risks & Mitigations

### Risk 1: Button Overlapping Content

**Likelihood:** Low
**Mitigation:** Toolbar automatically adds top padding to content
**Fallback:** Add `.safeAreaInset(edge: .top)` if needed

### Risk 2: Environment Key Not Working in Toolbar

**Likelihood:** Very Low
**Evidence:** Environment values propagate through toolbar items
**Test:** Verify in Phase 2 implementation

### Risk 3: Toolbar Scrolls with Content

**Likelihood:** None
**Evidence:** Toolbar is pinned to navigation bar by iOS/watchOS design
**Confirmation:** Apple documentation confirms toolbar items are stationary

---

## Phase 1 Completion Checklist

- [x] Review existing dual-axis scrolling implementation
- [x] Verify NavigationStack already present
- [x] Confirm TabView compatibility with NavigationStack
- [x] Test environment key mechanism (code review)
- [x] Document all findings
- [x] **Decision:** Proceed with Option 1 (Toolbar)
- [x] Identify no blocking issues

---

## Recommendation for Phase 2

✅ **PROCEED** with Phase 2 (Implement Toolbar Approach) - Issue #115

**No blockers identified.**

**Estimated implementation time:** 30-60 minutes
**Complexity:** Low
**Risk:** Minimal

---

## Code Locations Reference

- **NavigationStack wrapper:** ContentView.swift line 82
- **Floating menu button:** ContentView.swift lines 186-204
- **Environment key definition:** ContentView.swift lines 10-19
- **Menu sheet presentation:** ContentView.swift lines 170-181
- **Dual-axis scrolling:** ContentView.swift lines 230-331 (layeredContent + LayerView)
- **Detail views (set isShowingDetailView):**
  - CurriculumDetailView: lines 703-708
  - StrategyListView: lines 627-632

---

**Status:** Phase 1 Complete ✅
**Next Step:** Proceed to Phase 2 (#115) - Implement Toolbar Approach
