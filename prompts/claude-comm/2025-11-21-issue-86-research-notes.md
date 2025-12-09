# Issue #86 Research Notes - StrategyCard vs StrategySummaryCard

**Date**: 2025-11-21
**Issue**: #86 - [Phase 5.2] Create StrategySummaryCard Component
**Status**: Clarified, ready to implement

## Problem Statement

During implementation attempt, discovered a naming conflict:
- Issue #86 asks to create `StrategyCard` component
- A `StrategyCard` already exists in `ContentView.swift:978`
- The two components serve **completely different purposes**

## Analysis

### Existing Component: StrategyCard (ContentView.swift:978)

**Purpose**: Interactive catalog browsing card with journal logging capability

**Context**: Used in the main browsing/catalog view where users explore strategies

**Features**:
- Interactive (tap to log journal entry)
- Shows MysticalJournalIcon overlay for quick logging
- Displays confirmation alert before submitting
- Integrates with ContentViewModel via @EnvironmentObject
- Requires `color`, `phase`, and `viewModel` dependencies

**Signature**:
```swift
struct StrategyCard: View {
  let strategy: CatalogStrategyModel
  let color: Color
  let phase: CatalogPhaseModel
  @EnvironmentObject private var viewModel: ContentViewModel
  @State private var showingJournalConfirmation = false

  var body: some View {
    ZStack(alignment: .topTrailing) {
      HStack {
        Circle().fill(Color(stage: strategy.color))
        Text(strategy.strategy)
        // ... interactive elements
      }
      MysticalJournalIcon(color: color) // Logging action
    }
    .alert("Log Strategy", isPresented: $showingJournalConfirmation) {
      // Journal submission logic
    }
  }
}
```

**Location**: Lives in ContentView.swift as part of catalog browsing implementation

**Used by**: Catalog browsing views, strategy lists

---

### Intended Component: StrategySummaryCard (Task 5.2)

**Purpose**: Display-only summary card for the journal review screen

**Context**: Used in Phase 5 (Review & Submit) to show selected strategy before submission

**Features**:
- Display-only (no interactivity)
- Compact mode for different contexts
- Simple presentation of strategy selection
- Follows `EmotionSummaryCard` pattern

**Signature** (from implementation plan):
```swift
struct StrategySummaryCard: View {
  let strategy: CatalogStrategyModel
  var compact: Bool = false

  var body: some View {
    HStack {
      Circle()
        .fill(Color(stage: strategy.color))
        .frame(width: 6, height: 6)
      Text(strategy.strategy)
        .font(compact ? .body : .title3)
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.secondary.opacity(0.2))
    )
  }
}
```

**Location**: Should live in `Views/Components/` directory

**Used by**: Journal Review View (Task 5.1), flow summary displays

---

## Component Naming Pattern

Looking at existing Components directory:
- ✅ `EmotionSummaryCard.swift` - Display card for selected emotions in flow
- ✅ `FilteredLayerNavigationView.swift` - Reusable navigation component

**Pattern**: Components in the `/Components/` directory are reusable, display-oriented building blocks for the flow.

**Naming Convention**:
- `[Type]SummaryCard` for display-only cards showing selections
- `[Purpose][Type]` for functional components

## Resolution

### Recommended Solution: Option A ✅

**Rename new component to `StrategySummaryCard`**

**Rationale**:
1. ✅ Follows established pattern (`EmotionSummaryCard`)
2. ✅ Clear semantic meaning (summary of selected strategy)
3. ✅ No refactoring of existing code needed
4. ✅ Lives in Components/ directory with other flow components
5. ✅ Differentiates from interactive catalog card

**Files to Create**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Views/Components/StrategySummaryCard.swift`
- `frontend/WavelengthWatch/WavelengthWatch Watch AppTests/StrategySummaryCardTests.swift`

### Alternative: Option B ❌ (Not Recommended)

**Rename existing component to `CatalogStrategyCard` or `InteractiveStrategyCard`**

**Why rejected**:
- ⚠️ Requires refactoring ContentView.swift
- ⚠️ More invasive change
- ⚠️ Could affect other parts of codebase
- ⚠️ Existing component works fine with current name in its context

## Implementation Guide

### Step 1: Create StrategySummaryCard Component

Follow the pattern of `EmotionSummaryCard.swift`:

```swift
import SwiftUI

/// A reusable card component for displaying selected strategies in the journal flow.
///
/// This card shows a strategy with its color indicator.
/// It supports both standard and compact display modes for different UI contexts.
///
/// ## Usage
/// ```swift
/// // Standard display
/// StrategySummaryCard(strategy: selectedStrategy)
///
/// // Compact mode for flow step headers
/// StrategySummaryCard(strategy: selectedStrategy, compact: true)
/// ```
struct StrategySummaryCard: View {
  let strategy: CatalogStrategyModel
  var compact: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: compact ? 2 : 4) {
      // Strategy text (main content)
      Text(strategy.strategy)
        .font(compact ? .body : .title3)
        .fontWeight(.bold)
        .lineLimit(compact ? 2 : nil)

      // Color indicator
      HStack(spacing: 4) {
        Circle()
          .fill(strategyColor)
          .frame(width: 6, height: 6)

        Text(strategy.color)
          .font(.caption2)
          .foregroundColor(.secondary)
          .textCase(.uppercase)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(compact ? 8 : 12)
    .background(
      RoundedRectangle(cornerRadius: compact ? 6 : 8)
        .fill(Color.secondary.opacity(0.15))
    )
  }

  private var strategyColor: Color {
    // Map strategy color strings to SwiftUI colors
    switch strategy.color.lowercased() {
    case "beige": .gray
    case "purple": .purple
    case "red": .red
    case "blue": .blue
    case "orange": .orange
    case "green": .green
    case "yellow": .yellow
    case "turquoise": .cyan
    case "coral": .pink
    case "teal": .teal
    default: .gray
    }
  }
}
```

### Step 2: Create Tests

```swift
import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

struct StrategySummaryCardTests {
  private func makeSampleStrategy() -> CatalogStrategyModel {
    CatalogStrategyModel(id: 1, strategy: "Cold Shower", color: "Blue")
  }

  @Test func card_displaysStrategy() {
    let strategy = makeSampleStrategy()
    let card = StrategySummaryCard(strategy: strategy)
    #expect(strategy.strategy == "Cold Shower")
  }

  @Test func card_displaysColorIndicator() {
    let blueStrategy = CatalogStrategyModel(id: 1, strategy: "Cold Shower", color: "Blue")
    let redStrategy = CatalogStrategyModel(id: 2, strategy: "Exercise", color: "Red")
    #expect(blueStrategy.color == "Blue")
    #expect(redStrategy.color == "Red")
  }

  @Test func compactMode_usesSmallerFont() {
    let strategy = makeSampleStrategy()
    let standardCard = StrategySummaryCard(strategy: strategy)
    let compactCard = StrategySummaryCard(strategy: strategy, compact: true)
    #expect(standardCard.strategy.id == strategy.id)
    #expect(compactCard.strategy.id == strategy.id)
  }
}
```

### Step 3: Integration

Use in Journal Review View (Task 5.1):

```swift
// Display selected strategy in review
if let strategy = flowViewModel.getStrategy() {
  VStack(alignment: .leading, spacing: 4) {
    Text("Self-Care Strategy")
      .font(.caption)
      .foregroundColor(.secondary)

    StrategySummaryCard(strategy: strategy)
  }
}
```

## Updated Issue Details

**Title**: [Phase 5.2] Create StrategySummaryCard Component (was: StrategyCard)

**Acceptance Criteria** (updated):
- [ ] Component named `StrategySummaryCard` (not `StrategyCard`)
- [ ] Located in `Views/Components/` directory
- [ ] Displays strategy text with color indicator
- [ ] Compact mode works (smaller fonts for inline display)
- [ ] All tests pass

**Tests to Write** (updated):
- test_card_displaysStrategy
- test_card_displaysColorIndicator
- test_compactMode_usesSmallerFont

**Effort**: 1-2 hours | **PR Size**: ~100 lines (including tests)

## Summary

The confusion arose from overlapping naming. The resolution is simple:
- **Existing `StrategyCard`** stays in ContentView.swift for catalog browsing
- **New `StrategySummaryCard`** goes in Components/ for flow display

This follows the established pattern and keeps both components serving their distinct purposes without conflicts.

---

**Status**: Research complete, implementation path clear
**Next Step**: Implement StrategySummaryCard following the guide above
**Related**: Issue #85 (Journal Review View) will consume this component
