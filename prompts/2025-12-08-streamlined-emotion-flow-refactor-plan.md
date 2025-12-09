# Streamlined Emotion Flow Refactor Plan

**Epic Name:** "Streamlined Emotion Flow" (Epic #131)
**Created:** 2025-12-08
**Status:** Planning
**Priority:** P0 - Critical architectural refactor

---

## Executive Summary

**Problem:** The current multi-step emotion logging flow violates DRY principles by duplicating the entire ContentView navigation system in sheet presentations, resulting in:
- 5,000+ lines of duplicate code
- UI crowding on 42mm watches (#128, #129, #130)
- Maintenance burden (every ContentView improvement must be duplicated)
- Poor UX (cramped sheets vs. full-screen navigation)

**Solution:** Delete duplicate UI, reuse existing ContentView with `LayerFilterMode` enum to control visibility. FlowCoordinator manages STATE only, not UI.

**Impact:**
- ✅ 95% code reduction (5,000 lines → 250 lines)
- ✅ Zero duplicate navigation code
- ✅ No UI crowding (reuses perfect full-screen navigation)
- ✅ Single source of truth for navigation
- ✅ Future-proof: ContentView improvements automatically apply to flow

---

## Architecture Comparison

### Current (Broken) Architecture

```
ContentView
  └─ Perfect full-screen navigation ✅

FlowCoordinatorView (DUPLICATE)
  ├─ PrimaryEmotionSelectionView (DUPLICATE navigation in sheet)
  │   └─ FilteredLayerNavigationView (DUPLICATE of ContentView logic)
  ├─ SecondaryEmotionSelectionView (DUPLICATE)
  │   └─ FilteredLayerNavigationView (DUPLICATE again)
  └─ StrategySelectionView (DUPLICATE)
      └─ Custom phase navigator (MORE duplication)

Problems:
❌ 5,000+ lines of duplicate code
❌ UI crowding in sheets
❌ Bugs in 3+ places
❌ Maintenance nightmare
```

### New (Streamlined) Architecture

```
ContentView
  └─ Full-screen navigation (REUSED for everything) ✅
  └─ Aware of FlowCoordinator state
  └─ Shows confirmation sheets at right times

FlowCoordinator (NEW - STATE ONLY)
  ├─ Manages flow steps (enum)
  ├─ Controls ContentViewModel.layerFilterMode ✅ (already exists!)
  ├─ Captures selections
  └─ NO UI LOGIC

LayerFilterMode enum ✅ (already exists!)
  ├─ .all → Show all layers (normal browsing)
  ├─ .emotionsOnly → Show layers 1-10 (primary/secondary)
  └─ .strategiesOnly → Show layer 0 (strategy selection)

Benefits:
✅ ~250 lines total
✅ Zero duplication
✅ No UI crowding
✅ Single source of truth
```

---

## Detailed Refactor Steps

### Phase 1: Cleanup (Delete Duplicate Code)

**Files to DELETE:**
```
frontend/WavelengthWatch/WavelengthWatch Watch App/
├── Views/PrimaryEmotionSelectionView.swift           [DELETE]
├── Views/SecondaryEmotionSelectionView.swift         [DELETE]
├── Views/SecondaryEmotionPromptView.swift            [DELETE]
├── Views/StrategySelectionView.swift                 [DELETE]
├── Views/FlowCoordinatorView.swift                   [DELETE]
└── Views/Components/FilteredLayerNavigationView.swift [DELETE]

frontend/WavelengthWatch/WavelengthWatch Watch AppTests/
├── PrimaryEmotionSelectionViewTests.swift            [DELETE]
├── SecondaryEmotionSelectionViewTests.swift          [DELETE]
├── SecondaryEmotionPromptViewTests.swift             [DELETE]
├── StrategySelectionViewTests.swift                  [DELETE]
├── FlowCoordinatorViewTests.swift                    [DELETE]
└── FilteredLayerNavigationViewTests.swift            [DELETE]
```

**Files to KEEP (already perfect):**
```
✅ Models/LayerFilterMode.swift           (already implements filter enum)
✅ ViewModels/ContentViewModel.swift      (already supports layerFilterMode)
✅ ContentView.swift                      (just needs flow awareness)
```

**Files to REFACTOR:**
```
🔄 ViewModels/JournalFlowViewModel.swift  → Simplify to pure state management
🔄 Views/JournalReviewView.swift          → Simplify (no navigation needed)
```

---

### Phase 2: Git Strategy

#### Option A: Clean Revert with Cherry-Pick (RECOMMENDED)

**Step 1: Revert to clean slate**
```bash
# Create backup branch
git branch backup/emotion-flow-attempt-2025-12-08

# Checkout main
git checkout main

# Revert to before emotion flow work began
git reset --hard 28f4195
# Commit: "Merge pull request #118 from Geoffe-Ga/feature/stationary-menu-button"
# Date: Mon Nov 24 17:44:55 2025 -0800
```

**Step 2: Cherry-pick the good parts**
```bash
# Cherry-pick LayerFilterMode and infrastructure (if not already present)
git cherry-pick 3c8f091  # feat(models): Add LayerFilterMode enum
git cherry-pick b1b9983  # feat(components): Add EmotionSummaryCard (keep for review)

# Cherry-pick critical bug fixes from main
git cherry-pick 0106556  # fix: Resolve emotion logging flow critical bugs
# This includes:
# - Layer order fix (JournalFlowViewModel)
# - Black screen fix (phase index)
# - Scrolling fix (simplified transforms)
# - Command execution guidelines (CLAUDE.md)

# Skip the UI crowding fixes (4f5fbdb) - those views will be deleted
```

**Step 3: Create new feature branch**
```bash
git checkout -b feat/streamlined-emotion-flow
```

#### Option B: Delete and Rebuild (ALTERNATIVE)

If cherry-picking is too complex, stay on current branch and delete:
```bash
# Stay on current branch
git checkout main

# Create new feature branch
git checkout -b feat/streamlined-emotion-flow

# Delete duplicate view files
git rm frontend/WavelengthWatch/WavelengthWatch\ Watch\ App/Views/PrimaryEmotionSelectionView.swift
git rm frontend/WavelengthWatch/WavelengthWatch\ Watch\ App/Views/SecondaryEmotionSelectionView.swift
git rm frontend/WavelengthWatch/WavelengthWatch\ Watch\ App/Views/SecondaryEmotionPromptView.swift
git rm frontend/WavelengthWatch/WavelengthWatch\ Watch\ App/Views/StrategySelectionView.swift
git rm frontend/WavelengthWatch/WavelengthWatch\ Watch\ App/Views/FlowCoordinatorView.swift
git rm frontend/WavelengthWatch/WavelengthWatch\ Watch\ App/Views/Components/FilteredLayerNavigationView.swift

# Commit deletion
git commit -m "refactor: Delete duplicate navigation views for streamlined flow"
```

**Recommendation:** Use Option A for cleanest history.

---

### Phase 3: GitHub Issues Management

#### Issues to CLOSE (won't fix - views being deleted)

- **#128** [BUG] Dosage picker sheet has overlapping text on 42mm watch
  - **Close reason:** "Won't fix - dosage picker being removed in favor of reusing ContentView"
  - **Comment:** "Closing in favor of Streamlined Emotion Flow refactor (Epic #131). The dosage picker sheet is being removed entirely - we'll reuse ContentView's existing full-screen navigation instead."

- **#129** [BUG] Strategy selection sheet has overlapping text on 42mm watch
  - **Close reason:** "Won't fix - strategy selection sheet being removed"
  - **Comment:** "Closing in favor of Streamlined Emotion Flow refactor (Epic #131). The strategy selection sheet is being removed entirely - we'll reuse ContentView's existing navigation with LayerFilterMode.strategiesOnly."

- **#130** [BUG] Primary emotion selection view has overlapping navigation on 42mm watch
  - **Close reason:** "Won't fix - primary emotion selection view being removed"
  - **Comment:** "Closing in favor of Streamlined Emotion Flow refactor (Epic #131). The primary emotion selection view is being removed entirely - we'll reuse ContentView's existing full-screen navigation with LayerFilterMode.emotionsOnly."

#### Issues to KEEP (bug fixes still valid)

- **#123** [BUG] Black screen crash when tapping phase card - KEEP ✅
  - Status: FIXED (phase index initialization)
  - Relevant to ContentView when we reuse it

- **#124** [BUG] Black screen crash on vertical scroll - KEEP ✅
  - Status: FIXED (simplified transforms for 42mm)
  - Relevant to ContentView

- **#127** [BUG] Layer order inversion - KEEP ✅
  - Status: FIXED (JournalFlowViewModel layer ordering)
  - Will refactor JournalFlowViewModel but keep the fix

#### Issues to UPDATE (change scope)

- **#120** Manual Testing - Core Flow & Happy Paths
  - **Update:** Add comment: "Testing plan needs revision for Streamlined Emotion Flow architecture (Epic #131). Will create new testing plan once refactor is complete."
  - **Status:** Blocked until refactor complete

- **#121** Manual Testing - State Management & Integration
  - **Update:** Same as #120

- **#122** Manual Testing - Edge Cases & Stress Testing
  - **Update:** Same as #120

- **#92** [EPIC] Multi-Step Emotion Logging Flow
  - **Update:** Add comment: "Architecture changed to Streamlined Emotion Flow (Epic #131). Original implementation violated DRY by duplicating ContentView navigation. New approach reuses existing navigation with LayerFilterMode."
  - **Link:** Link to Epic #131
  - **Status:** Keep open, track progress in Epic #131

---

## New Epic: Streamlined Emotion Flow

### Epic #131: Streamlined Emotion Flow

**Title:** [EPIC] Streamlined Emotion Flow - DRY Architecture Refactor

**Description:**
```markdown
## Overview

Refactor the emotion logging flow to follow DRY principles by reusing ContentView's existing navigation instead of duplicating it in sheet presentations.

## Problem Statement

The current multi-step emotion logging flow (Epic #92) duplicates ContentView's layer/phase navigation system in multiple sheet views, resulting in:
- 5,000+ lines of duplicate code
- UI crowding on 42mm watches (#128, #129, #130)
- Maintenance burden (changes must be duplicated)
- Poor UX (cramped sheets vs. full-screen navigation)

## Solution

Delete duplicate views and implement flow coordinator pattern:
1. **Reuse ContentView** for all navigation (full-screen, no crowding)
2. **FlowCoordinator** manages state only (no UI logic)
3. **LayerFilterMode** controls visibility (.all, .emotionsOnly, .strategiesOnly)
4. **Confirmation sheets** for capturing selections between steps

## Architecture

```
User Flow:
1. Tap "Log Emotion" → Show alert "Select your primary emotion"
2. Navigate ContentView (filtered to emotions only via LayerFilterMode)
3. Tap "Log Medicinal" → FlowCoordinator captures selection
4. Show sheet: "Primary: Commitment. Add secondary?"
5. If yes → Navigate ContentView again (still emotions only)
6. If no → Move to strategy selection (ContentView filtered to strategies)
7. Review sheet → Submit to backend
```

## Benefits

- ✅ 95% code reduction (5,000 lines → 250 lines)
- ✅ Zero UI crowding (full-screen navigation)
- ✅ Single source of truth for navigation
- ✅ Future-proof: ContentView improvements automatically apply

## Dependencies

- Requires: LayerFilterMode enum ✅ (already exists)
- Requires: ContentViewModel.layerFilterMode support ✅ (already exists)
- Blocks: Manual testing (#120, #121, #122)
- Supersedes: Issues #128, #129, #130 (views being deleted)

## Acceptance Criteria

- [ ] All duplicate navigation views deleted
- [ ] FlowCoordinator manages state only (no UI)
- [ ] ContentView reused for all navigation steps
- [ ] LayerFilterMode controls layer visibility
- [ ] No UI crowding on any watch size
- [ ] Flow completes successfully: primary → secondary → strategy → review → submit
- [ ] All existing ContentView features work during flow
- [ ] Tests pass for state management
- [ ] Manual testing plan updated and executed
```

**Labels:**
- `epic`
- `epic:streamlined-emotion-flow`
- `priority:P0`
- `phase:6-integration`
- `refactor`

**Estimated Effort:** 2-3 days
**Estimated Story Points:** 21

---

## GitHub Issue Templates

### Issue #132: [Refactor] Delete duplicate navigation views

```markdown
## Summary

Delete all duplicate navigation view files that reimplemented ContentView's layer/phase navigation in sheet presentations.

---

## Context

Part of Streamlined Emotion Flow refactor (Epic #131). These views violate DRY by duplicating ContentView's navigation logic, causing UI crowding and maintenance burden.

**Files being deleted:**
- PrimaryEmotionSelectionView.swift
- SecondaryEmotionSelectionView.swift
- SecondaryEmotionPromptView.swift
- StrategySelectionView.swift
- FlowCoordinatorView.swift
- FilteredLayerNavigationView.swift
- Related test files

---

## Acceptance Criteria

- [ ] All 6 view files deleted from Views/ directory
- [ ] All related test files deleted
- [ ] No compilation errors after deletion
- [ ] Git history shows clean deletion commit
- [ ] Follow-up issues ready to implement replacement

---

## Implementation Notes

After deletion, navigation will temporarily break. This is expected - subsequent issues will restore functionality by reusing ContentView.

**Branch:** `feat/streamlined-emotion-flow`

**Commit message format:**
```
refactor: Delete duplicate navigation views for streamlined flow (#131)

Removes duplicate implementations of layer/phase navigation that were
causing UI crowding and maintenance issues.

Deleted files:
- PrimaryEmotionSelectionView.swift
- SecondaryEmotionSelectionView.swift
- SecondaryEmotionPromptView.swift
- StrategySelectionView.swift
- FlowCoordinatorView.swift
- FilteredLayerNavigationView.swift

Part of Epic #131: Streamlined Emotion Flow
Supersedes: #128, #129, #130
```

---

## Related Issues

- Epic #131: Streamlined Emotion Flow
- Closes: #128, #129, #130 (views being deleted)
```

**Labels:** `refactor`, `epic:streamlined-emotion-flow`, `priority:P0`

---

### Issue #133: [Feat] Create FlowCoordinator for state management

```markdown
## Summary

Create a lightweight FlowCoordinator class that manages emotion logging flow STATE without any UI logic. Controls ContentViewModel.layerFilterMode to filter layers.

---

## Context

Part of Streamlined Emotion Flow refactor (Epic #131). FlowCoordinator is responsible for:
- Tracking current flow step
- Capturing user selections (primary, secondary, strategy)
- Controlling ContentViewModel.layerFilterMode
- **NOT responsible for UI** (ContentView handles that)

---

## Requirements

### FlowCoordinator Properties

```swift
class FlowCoordinator: ObservableObject {
  // Dependencies
  let contentViewModel: ContentViewModel

  // Published state
  @Published var currentStep: FlowStep = .idle
  @Published var selections: Selections = .init()

  // Flow steps enum
  enum FlowStep {
    case idle                      // Not in flow
    case selectingPrimary         // User navigating ContentView for primary
    case confirmingPrimary        // Show confirmation sheet
    case selectingSecondary       // User navigating ContentView for secondary
    case confirmingSecondary      // Show confirmation sheet
    case selectingStrategy        // User navigating ContentView for strategy
    case confirmingStrategy       // Show confirmation sheet
    case review                    // Show review sheet
  }

  // Selections struct
  struct Selections {
    var primary: CatalogCurriculumEntryModel?
    var secondary: CatalogCurriculumEntryModel?
    var strategy: CatalogStrategyModel?
  }
}
```

### Methods

```swift
// Start flow
func startPrimarySelection()

// Capture selections
func capturePrimary(_ emotion: CatalogCurriculumEntryModel)
func captureSecondary(_ emotion: CatalogCurriculumEntryModel?)
func captureStrategy(_ strategy: CatalogStrategyModel?)

// Navigation
func promptForSecondary()
func promptForStrategy()
func showReview()

// Completion
func submit() async throws

// Cancellation
func cancel()
func reset()
```

### Key Implementation Details

1. **Control ContentViewModel filter:**
   ```swift
   func startPrimarySelection() {
     contentViewModel.layerFilterMode = .emotionsOnly
     currentStep = .selectingPrimary
   }

   func promptForStrategy() {
     contentViewModel.layerFilterMode = .strategiesOnly
     currentStep = .selectingStrategy
   }
   ```

2. **No UI logic** - just state transitions

3. **Inject into ContentViewModel** as optional dependency

---

## Acceptance Criteria

- [ ] FlowCoordinator class created with all required properties
- [ ] FlowStep enum defined with all steps
- [ ] Selections struct defined
- [ ] All methods implemented
- [ ] Controls ContentViewModel.layerFilterMode correctly
- [ ] No UI logic (no views, no SwiftUI imports beyond @Published)
- [ ] Unit tests pass (state transitions)
- [ ] Can be injected into ContentViewModel as optional

---

## Testing

```swift
@Test func startPrimarySelection_setsEmotionsOnlyFilter() {
  let contentVM = ContentViewModel(...)
  let coordinator = FlowCoordinator(contentViewModel: contentVM)

  coordinator.startPrimarySelection()

  #expect(contentVM.layerFilterMode == .emotionsOnly)
  #expect(coordinator.currentStep == .selectingPrimary)
}

@Test func capturePrimary_storesSelectionAndAdvances() {
  let coordinator = FlowCoordinator(...)
  let emotion = CatalogCurriculumEntryModel(id: 1, ...)

  coordinator.capturePrimary(emotion)

  #expect(coordinator.selections.primary == emotion)
  #expect(coordinator.currentStep == .confirmingPrimary)
}
```

---

## Implementation Notes

**File location:** `ViewModels/FlowCoordinator.swift`

**Design principle:** This class is PURE STATE MANAGEMENT. It knows nothing about SwiftUI views, sheets, alerts, or navigation. It only manages the flow state machine and controls which layers are visible.

---

## Related Issues

- Epic #131: Streamlined Emotion Flow
- Blocks: #134 (Update ContentView for flow awareness)
- Requires: #132 (Delete duplicate views) completed first
```

**Labels:** `feature`, `epic:streamlined-emotion-flow`, `priority:P0`

---

### Issue #134: [Feat] Update ContentView for flow awareness

```markdown
## Summary

Update ContentView to be aware of FlowCoordinator state and show confirmation sheets at appropriate times during emotion logging flow.

---

## Context

Part of Streamlined Emotion Flow refactor (Epic #131). ContentView already has perfect navigation - we just need to make it aware of when it's being used for flow vs. normal browsing.

---

## Requirements

### 1. Add FlowCoordinator dependency

```swift
struct ContentView: View {
  @StateObject var viewModel: ContentViewModel
  @StateObject var flowCoordinator: FlowCoordinator? // Optional - nil for normal browsing

  // ... existing code
}
```

### 2. Show prompt when flow starts

```swift
.alert("Select your primary emotion", isPresented: $showPrimaryPrompt) {
  Button("Continue") {
    // User acknowledged, can now navigate
  }
  Button("Cancel") {
    flowCoordinator?.cancel()
  }
}
```

### 3. Intercept "Log Medicinal/Toxic" button taps

```swift
Button("Log Medicinal") {
  if let flow = flowCoordinator, flow.currentStep != .idle {
    // In flow mode - capture selection
    flow.capturePrimary(entry)
  } else {
    // Normal mode - immediate logging
    Task { await viewModel.journal(curriculumID: entry.id) }
  }
}
```

### 4. Show confirmation sheets between steps

```swift
// After capturing primary
.sheet(isPresented: $showPrimaryConfirmation) {
  VStack {
    Text("Primary emotion selected")
    Text(flowCoordinator.selections.primary?.expression ?? "")

    Button("Add Secondary Emotion") {
      flowCoordinator.promptForSecondary()
    }
    Button("Skip to Strategy") {
      flowCoordinator.promptForStrategy()
    }
    Button("Skip to Review") {
      flowCoordinator.showReview()
    }
  }
}

// Similar sheets for secondary and strategy confirmations
```

### 5. Show review sheet

```swift
.sheet(isPresented: $showReview) {
  JournalReviewView(
    selections: flowCoordinator.selections,
    onSubmit: {
      Task {
        try await flowCoordinator.submit()
      }
    },
    onCancel: { flowCoordinator.cancel() }
  )
}
```

---

## Acceptance Criteria

- [ ] FlowCoordinator injected as optional dependency
- [ ] Initial prompt shows when flow starts
- [ ] Log buttons check flow state before acting
- [ ] Confirmation sheets show after each selection
- [ ] Review sheet shows final summary
- [ ] Normal browsing still works (flowCoordinator = nil)
- [ ] No UI crowding on any watch size
- [ ] User can cancel at any point
- [ ] LayerFilterMode changes are reflected in UI (layers filter correctly)

---

## UI/UX Requirements

**Full-screen navigation (existing):**
- ✅ No changes to navigation logic
- ✅ No changes to layer/phase cards
- ✅ No changes to scrolling behavior

**New confirmation sheets (simple alerts/sheets):**
- Small, focused sheets
- Clear "Primary: [emotion]" context
- Simple button choices
- No navigation within sheets
- Quick dismissal

---

## Testing

**Manual testing:**
1. Launch app
2. Tap "Log Emotion"
3. See prompt "Select your primary emotion"
4. Navigate to any layer/phase (full screen, perfect navigation)
5. Tap "Log Medicinal"
6. See confirmation: "Primary: Commitment. Add secondary?"
7. Choose "Add Secondary"
8. Navigate again (same perfect navigation)
9. Tap another emotion
10. Continue through flow
11. Review and submit

**Unit testing:**
```swift
@Test func logButton_inFlowMode_capturesSelection() {
  let flow = FlowCoordinator(...)
  let contentView = ContentView(viewModel: vm, flowCoordinator: flow)

  flow.startPrimarySelection()
  // Simulate tapping "Log Medicinal"
  // Assert flow.selections.primary is set
}
```

---

## Implementation Notes

**Key principle:** ContentView navigation stays EXACTLY the same. We're only adding:
1. Awareness of flow state
2. Conditional button behavior
3. Confirmation sheets

Total new code: ~100 lines
Total deleted code: 5,000+ lines (from deleted views)

---

## Related Issues

- Epic #131: Streamlined Emotion Flow
- Requires: #133 (FlowCoordinator) completed
- Requires: #132 (Delete duplicate views) completed
```

**Labels:** `feature`, `epic:streamlined-emotion-flow`, `priority:P0`

---

### Issue #135: [Feat] Implement confirmation sheets for flow steps

```markdown
## Summary

Create simple, focused confirmation sheets that appear between flow steps to capture user intent and provide context.

---

## Context

Part of Streamlined Emotion Flow refactor (Epic #131). After user selects an emotion/strategy in ContentView, show a confirmation sheet before moving to next step.

---

## Requirements

### 1. Primary Emotion Confirmation Sheet

**Trigger:** After user taps "Log Medicinal/Toxic" in primary selection step

**Content:**
```swift
PrimaryConfirmationSheet {
  VStack(spacing: 16) {
    // Context
    VStack(spacing: 4) {
      Text("Primary Emotion")
        .font(.caption)
        .foregroundColor(.secondary)

      Text(emotion.expression)
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(emotion.dosage == .medicinal ? .green : .red)
    }

    // Options
    Button("Add Secondary Emotion") {
      flowCoordinator.promptForSecondary()
    }
    .buttonStyle(.borderedProminent)

    Button("Skip to Strategy") {
      flowCoordinator.promptForStrategy()
    }

    Button("Skip to Review") {
      flowCoordinator.showReview()
    }

    Button("Cancel", role: .cancel) {
      flowCoordinator.cancel()
    }
  }
  .padding()
}
```

### 2. Secondary Emotion Confirmation Sheet

**Trigger:** After user taps "Log Medicinal/Toxic" in secondary selection step

**Content:**
```swift
SecondaryConfirmationSheet {
  VStack(spacing: 16) {
    // Context (show both emotions)
    VStack(spacing: 8) {
      HStack {
        Text("Primary:")
        Text(primary.expression)
          .foregroundColor(primary.dosage == .medicinal ? .green : .red)
      }
      .font(.caption)

      HStack {
        Text("Secondary:")
        Text(secondary.expression)
          .foregroundColor(secondary.dosage == .medicinal ? .green : .red)
      }
      .font(.caption)
    }

    // Options
    Button("Select Strategy") {
      flowCoordinator.promptForStrategy()
    }
    .buttonStyle(.borderedProminent)

    Button("Skip to Review") {
      flowCoordinator.showReview()
    }

    Button("Cancel", role: .cancel) {
      flowCoordinator.cancel()
    }
  }
  .padding()
}
```

### 3. Strategy Confirmation Sheet

**Trigger:** After user taps strategy in strategy selection step

**Content:**
```swift
StrategyConfirmationSheet {
  VStack(spacing: 16) {
    // Context
    VStack(spacing: 4) {
      Text("Strategy Selected")
        .font(.caption)
        .foregroundColor(.secondary)

      Text(strategy.strategy)
        .font(.title3)
        .fontWeight(.semibold)
    }

    // Emotion context
    HStack(spacing: 12) {
      Text("Primary: \(primary.expression)")
      if let secondary = secondary {
        Text("Secondary: \(secondary.expression)")
      }
    }
    .font(.caption2)
    .foregroundColor(.secondary)

    // Options
    Button("Review & Submit") {
      flowCoordinator.showReview()
    }
    .buttonStyle(.borderedProminent)

    Button("Cancel", role: .cancel) {
      flowCoordinator.cancel()
    }
  }
  .padding()
}
```

---

## Acceptance Criteria

- [ ] Primary confirmation sheet implemented
- [ ] Secondary confirmation sheet implemented
- [ ] Strategy confirmation sheet implemented
- [ ] All sheets show clear context (what was selected)
- [ ] All sheets provide logical next steps
- [ ] All sheets allow cancellation
- [ ] Sheets are small and focused (no navigation)
- [ ] No UI crowding on any watch size
- [ ] Text is readable on 42mm watches
- [ ] Buttons are easily tappable

---

## Design Requirements

**Keep sheets simple:**
- Use native SwiftUI components
- No custom navigation
- No GeometryReader needed (sheets are small by nature)
- Present with `.sheet(isPresented:)` or `.alert()`
- Dismiss automatically after button tap

**Responsive design:**
- Use system fonts (automatically scale)
- Use standard padding
- Limit content to essentials
- No complex layouts

---

## Testing

**Manual testing on 42mm watch:**
1. Go through flow
2. Verify each confirmation sheet appears
3. Verify text is readable
4. Verify buttons are tappable
5. Verify context is clear
6. Verify cancellation works

**Unit testing:**
```swift
@Test func primaryConfirmation_showsEmotionContext() {
  // Test that sheet displays correct emotion
}

@Test func secondaryConfirmation_showsBothEmotions() {
  // Test that sheet shows primary + secondary
}
```

---

## Related Issues

- Epic #131: Streamlined Emotion Flow
- Requires: #134 (ContentView flow awareness)
```

**Labels:** `feature`, `epic:streamlined-emotion-flow`, `priority:P0`

---

### Issue #136: [Feat] Implement journal review and submission

```markdown
## Summary

Create a simple review sheet that displays all selected emotions and strategy, with a submit button to send to backend.

---

## Context

Part of Streamlined Emotion Flow refactor (Epic #131). Final step in flow shows user their selections before submitting to backend.

---

## Requirements

### Review Sheet UI

```swift
struct JournalReviewView: View {
  let selections: FlowCoordinator.Selections
  let onSubmit: () -> Void
  let onCancel: () -> Void

  @State private var isSubmitting = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          // Primary emotion
          SelectionCard(
            title: "Primary Emotion",
            text: selections.primary?.expression ?? "",
            color: selections.primary?.dosage == .medicinal ? .green : .red
          )

          // Secondary emotion (if present)
          if let secondary = selections.secondary {
            SelectionCard(
              title: "Secondary Emotion",
              text: secondary.expression,
              color: secondary.dosage == .medicinal ? .green : .red
            )
          }

          // Strategy (if present)
          if let strategy = selections.strategy {
            SelectionCard(
              title: "Strategy",
              text: strategy.strategy,
              color: .blue
            )
          }

          // Submit button
          Button("Submit Journal Entry") {
            isSubmitting = true
            onSubmit()
          }
          .buttonStyle(.borderedProminent)
          .disabled(isSubmitting)

          if isSubmitting {
            ProgressView("Submitting...")
          }
        }
        .padding()
      }
      .navigationTitle("Review")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: onCancel)
        }
      }
    }
  }
}

struct SelectionCard: View {
  let title: String
  let text: String
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)
        .textCase(.uppercase)

      Text(text)
        .font(.body)
        .fontWeight(.semibold)
        .foregroundColor(color)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.secondary.opacity(0.1))
    )
  }
}
```

---

## Backend Submission

```swift
// In FlowCoordinator
func submit() async throws {
  guard let primary = selections.primary else {
    throw FlowError.missingPrimaryEmotion
  }

  // Use existing journal submission
  try await contentViewModel.journal(
    curriculumID: primary.id,
    secondaryCurriculumID: selections.secondary?.id,
    strategyID: selections.strategy?.id,
    initiatedBy: .self_initiated
  )

  // Reset flow on success
  reset()
}
```

---

## Acceptance Criteria

- [ ] Review sheet displays all selections
- [ ] Primary emotion always shown
- [ ] Secondary emotion shown if present
- [ ] Strategy shown if present
- [ ] Submit button calls backend
- [ ] Loading indicator shown during submission
- [ ] Success dismisses sheet and resets flow
- [ ] Error shows alert with retry option
- [ ] Cancel returns to previous step (or exits flow)
- [ ] Responsive layout on all watch sizes

---

## Error Handling

```swift
// In ContentView
.alert("Submission Failed", isPresented: $showSubmissionError) {
  Button("Retry") {
    Task {
      try await flowCoordinator.submit()
    }
  }
  Button("Cancel") {
    flowCoordinator.cancel()
  }
} message: {
  Text(errorMessage)
}
```

---

## Success Feedback

After successful submission:
1. Dismiss review sheet
2. Show brief confirmation (toast or alert)
3. Return ContentView to normal browsing mode
4. Reset FlowCoordinator state

```swift
// Success feedback
.alert("Journal Entry Saved", isPresented: $showSuccess) {
  Button("OK") {
    flowCoordinator.reset()
  }
} message: {
  Text("Your emotions have been logged.")
}
```

---

## Testing

**Manual testing:**
1. Complete full flow (primary, secondary, strategy)
2. Review sheet shows all selections
3. Tap Submit
4. Verify backend receives data correctly
5. Verify success feedback shows
6. Verify flow resets

**Edge cases:**
- Test with only primary emotion
- Test with primary + secondary
- Test with all selections
- Test network error handling
- Test cancellation from review

**Unit testing:**
```swift
@Test func submit_withPrimary_callsBackend() async throws {
  let flow = FlowCoordinator(...)
  flow.selections.primary = emotion

  try await flow.submit()

  // Verify backend was called with correct data
}

@Test func submit_withoutPrimary_throwsError() async {
  let flow = FlowCoordinator(...)

  await #expect(throws: FlowError.self) {
    try await flow.submit()
  }
}
```

---

## Related Issues

- Epic #131: Streamlined Emotion Flow
- Requires: #135 (Confirmation sheets)
```

**Labels:** `feature`, `epic:streamlined-emotion-flow`, `priority:P0`

---

### Issue #137: [Test] Create integration tests for streamlined flow

```markdown
## Summary

Create comprehensive integration tests for the streamlined emotion logging flow, verifying state transitions and ContentView integration.

---

## Context

Part of Streamlined Emotion Flow refactor (Epic #131). Ensure the new architecture works correctly end-to-end.

---

## Test Coverage Requirements

### 1. FlowCoordinator State Machine Tests

```swift
@Test func flowProgression_primaryOnly() async throws {
  let coordinator = FlowCoordinator(...)

  // Start flow
  coordinator.startPrimarySelection()
  #expect(coordinator.currentStep == .selectingPrimary)
  #expect(coordinator.contentViewModel.layerFilterMode == .emotionsOnly)

  // Capture primary
  coordinator.capturePrimary(emotion)
  #expect(coordinator.selections.primary == emotion)
  #expect(coordinator.currentStep == .confirmingPrimary)

  // Skip to review
  coordinator.showReview()
  #expect(coordinator.currentStep == .review)

  // Submit
  try await coordinator.submit()
  #expect(coordinator.currentStep == .idle)
  #expect(coordinator.selections.primary == nil) // Reset
}

@Test func flowProgression_fullFlow() async throws {
  // Test: primary → secondary → strategy → review → submit
}

@Test func flowCancellation_resetsState() {
  // Test: cancel at each step resets correctly
}
```

### 2. ContentView Integration Tests

```swift
@Test func contentView_inFlowMode_filtersLayers() {
  let vm = ContentViewModel(...)
  let flow = FlowCoordinator(contentViewModel: vm)
  let contentView = ContentView(viewModel: vm, flowCoordinator: flow)

  flow.startPrimarySelection()

  // ContentView should only show emotion layers
  #expect(vm.filteredLayers.count == 10) // Layers 1-10 only
  #expect(vm.filteredLayers.allSatisfy { $0.id >= 1 })
}

@Test func contentView_normalMode_showsAllLayers() {
  let vm = ContentViewModel(...)
  let contentView = ContentView(viewModel: vm, flowCoordinator: nil)

  // ContentView should show all layers
  #expect(vm.filteredLayers.count == 11) // Layers 0-10
}

@Test func logButton_inFlowMode_capturesInsteadOfSubmitting() {
  // Test: Tapping log button in flow mode captures selection
  // Instead of immediately submitting to backend
}
```

### 3. LayerFilterMode Integration Tests

```swift
@Test func layerFilterMode_emotionsOnly_excludesStrategies() {
  let vm = ContentViewModel(...)
  vm.layerFilterMode = .emotionsOnly

  #expect(vm.filteredLayers.allSatisfy { $0.id >= 1 })
}

@Test func layerFilterMode_strategiesOnly_onlyShowsLayer0() {
  let vm = ContentViewModel(...)
  vm.layerFilterMode = .strategiesOnly

  #expect(vm.filteredLayers.count == 1)
  #expect(vm.filteredLayers[0].id == 0)
}

@Test func layerFilterMode_all_showsEverything() {
  let vm = ContentViewModel(...)
  vm.layerFilterMode = .all

  #expect(vm.filteredLayers.count == 11)
}
```

### 4. Backend Submission Tests

```swift
@Test func submit_withAllSelections_callsBackendCorrectly() async throws {
  let mockClient = MockJournalClient()
  let vm = ContentViewModel(..., journalClient: mockClient)
  let flow = FlowCoordinator(contentViewModel: vm)

  flow.selections.primary = primaryEmotion
  flow.selections.secondary = secondaryEmotion
  flow.selections.strategy = strategy

  try await flow.submit()

  #expect(mockClient.lastSubmission?.curriculumID == primaryEmotion.id)
  #expect(mockClient.lastSubmission?.secondaryCurriculumID == secondaryEmotion.id)
  #expect(mockClient.lastSubmission?.strategyID == strategy.id)
}

@Test func submit_networkError_throwsError() async {
  let mockClient = MockJournalClient(shouldFail: true)
  let flow = FlowCoordinator(...)

  await #expect(throws: NetworkError.self) {
    try await flow.submit()
  }

  // State should NOT reset on error
  #expect(flow.selections.primary != nil)
}
```

### 5. Edge Case Tests

```swift
@Test func flowCoordinator_withNilSecondary_skipsToStrategy() {
  // Test: User can skip secondary emotion
}

@Test func flowCoordinator_withNilStrategy_skipsToReview() {
  // Test: User can skip strategy
}

@Test func flowCoordinator_cancel_midFlow_resetsEverything() {
  // Test: Cancellation at any step resets all state
}

@Test func contentView_switchingFilterModes_preservesLayerSelection() {
  // Test: Changing filter doesn't break navigation state
}
```

---

## Acceptance Criteria

- [ ] All FlowCoordinator state machine tests pass
- [ ] All ContentView integration tests pass
- [ ] All LayerFilterMode tests pass
- [ ] All backend submission tests pass
- [ ] All edge case tests pass
- [ ] Test coverage > 90% for new code
- [ ] No flaky tests
- [ ] Tests run successfully on CI

---

## Testing Strategy

**Unit tests:** State logic, state transitions
**Integration tests:** ContentView + FlowCoordinator interaction
**End-to-end tests:** Full flow simulation
**Manual tests:** Real device testing (covered in separate issues)

---

## Related Issues

- Epic #131: Streamlined Emotion Flow
- Blocks: Manual testing (#120 update)
```

**Labels:** `testing`, `epic:streamlined-emotion-flow`, `priority:P0`

---

### Issue #138: [Docs] Update manual testing plan for streamlined flow

```markdown
## Summary

Revise the manual testing plan (issue #120) to reflect the streamlined emotion flow architecture.

---

## Context

Part of Streamlined Emotion Flow refactor (Epic #131). The original testing plan in #120 referenced duplicate views that no longer exist. Need to create new testing plan based on ContentView reuse.

---

## Requirements

Create new testing plan markdown file:
`prompts/claude-comm/bugs/02-streamlined-emotion-flow-testing-plan.md`

**Structure:**
1. Architecture Overview (how it works now)
2. Test Categories (same as before)
3. Updated Test Cases (referencing ContentView)
4. Device Matrix (41mm, 42mm, 45mm, 49mm)
5. Success Criteria

**Key differences from old plan:**
- All navigation happens in ContentView (full screen)
- Confirmation sheets are simple and focused
- No FilteredLayerNavigationView to test
- LayerFilterMode controls what's visible

---

## Updated Test Categories

### Category 1: Flow Entry Points
- Test 1.1: Menu "Log Emotion" button
- Test 1.2: Notification tap (if implemented)

### Category 2: Primary Emotion Selection
- Test 2.1: Initial prompt shows
- Test 2.2: ContentView filtered to emotions only
- Test 2.3: Full-screen navigation works
- Test 2.4: Tapping "Log Medicinal" captures selection
- Test 2.5: Confirmation sheet shows

### Category 3: Secondary Emotion Selection
- Test 3.1: Option to add secondary presented
- Test 3.2: ContentView still filtered to emotions only
- Test 3.3: Can select different emotion
- Test 3.4: Can skip secondary

### Category 4: Strategy Selection
- Test 4.1: Prompted for strategy after emotions
- Test 4.2: ContentView filtered to strategies only (layer 0)
- Test 4.3: Can select strategy
- Test 4.4: Can skip strategy

### Category 5: Review and Submission
- Test 5.1: Review sheet shows all selections
- Test 5.2: Submit sends to backend
- Test 5.3: Success feedback shows
- Test 5.4: Flow resets after submission

### Category 6: Cancellation and Errors
- Test 6.1: Can cancel from any step
- Test 6.2: Cancellation resets flow
- Test 6.3: Network errors show retry option
- Test 6.4: Retry works correctly

### Category 7: Device Compatibility
- Test 7.1: 42mm watch - no UI crowding
- Test 7.2: 41mm watch - no UI crowding
- Test 7.3: 45mm watch - proper layout
- Test 7.4: 49mm watch - proper layout

---

## Acceptance Criteria

- [ ] New testing plan created
- [ ] All test cases updated for new architecture
- [ ] References to deleted views removed
- [ ] Device matrix included
- [ ] Success criteria defined
- [ ] Testing plan reviewed and approved
- [ ] Linked to Epic #131

---

## Related Issues

- Epic #131: Streamlined Emotion Flow
- Updates: #120 (original testing plan)
- Requires: #134, #135, #136 (implementation) completed
```

**Labels:** `documentation`, `testing`, `epic:streamlined-emotion-flow`, `priority:P1`

---

## Summary of New Issues

| Issue # | Title | Type | Priority | Blockers |
|---------|-------|------|----------|----------|
| #131 | [EPIC] Streamlined Emotion Flow | Epic | P0 | - |
| #132 | Delete duplicate navigation views | Refactor | P0 | - |
| #133 | Create FlowCoordinator for state management | Feature | P0 | #132 |
| #134 | Update ContentView for flow awareness | Feature | P0 | #132, #133 |
| #135 | Implement confirmation sheets | Feature | P0 | #134 |
| #136 | Implement journal review and submission | Feature | P0 | #135 |
| #137 | Create integration tests | Test | P0 | #133-#136 |
| #138 | Update manual testing plan | Docs | P1 | #133-#136 |

---

## Implementation Timeline

**Week 1:**
- Day 1: #132 (Delete duplicate views)
- Day 2: #133 (FlowCoordinator)
- Day 3: #134 (ContentView updates)

**Week 2:**
- Day 1: #135 (Confirmation sheets)
- Day 2: #136 (Review & submission)
- Day 3: #137 (Integration tests)
- Day 4: #138 (Testing plan) + Manual testing

**Total: ~1.5 weeks**

---

## Success Metrics

- ✅ 95% code reduction (5,000 lines → 250 lines)
- ✅ Zero UI crowding on any watch size
- ✅ 100% test coverage for state management
- ✅ Manual testing passes on all watch sizes
- ✅ No duplicate navigation code
- ✅ Single source of truth (ContentView)

---

## Notes

This refactor is a **complete architectural improvement** that will:
1. Make the codebase dramatically simpler
2. Eliminate entire classes of bugs (UI crowding)
3. Make future changes easier (one navigation to maintain)
4. Improve UX (full-screen navigation vs. cramped sheets)

**Key insight:** We already built the infrastructure (LayerFilterMode), we just need to USE it properly instead of rebuilding the UI.

---

**Document Version:** 1.0
**Last Updated:** 2025-12-08
**Author:** Chief Architect (Claude)
**Status:** Ready for implementation
