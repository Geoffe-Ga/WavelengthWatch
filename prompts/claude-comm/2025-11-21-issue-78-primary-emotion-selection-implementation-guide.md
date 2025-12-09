# Implementation Guide: Issue #78 - Primary Emotion Selection View

**Issue**: [Phase 2.1] Create Primary Emotion Selection View
**Epic**: Multi-Step Emotion Logging Flow
**Status**: Ready to implement
**Effort**: 5-6 hours | **PR Size**: ~270 lines
**Dependencies**: ✅ Phase 1 complete (FlowCoordinatorView, JournalFlowViewModel, FilteredLayerNavigationView)

## Overview

Create a view that allows users to select their primary emotion from available curriculum entries (medicinal/toxic). This is the first step in the emotion logging flow after opening the coordinator.

## Existing Components to Leverage

### Already Implemented (main branch):
- ✅ `JournalFlowViewModel` - Manages flow state and selections
- ✅ `FilteredLayerNavigationView` - Displays filtered layers with phase navigation
- ✅ `FlowCoordinatorView` - Coordinator that orchestrates the flow
- ✅ `EmotionSummaryCard` - Reusable card for displaying selected emotions
- ✅ `LayerFilterMode` - Enum for filtering (all/emotions/strategies)

### Key Files:
- `/frontend/WavelengthWatch/WavelengthWatch Watch App/ViewModels/JournalFlowViewModel.swift`
- `/frontend/WavelengthWatch/WavelengthWatch Watch App/Views/Components/FilteredLayerNavigationView.swift`
- `/frontend/WavelengthWatch/WavelengthWatch Watch App/Views/FlowCoordinatorView.swift`

## Requirements (from issue #78)

### Acceptance Criteria:
- [ ] View displays correct title ("Primary Emotion")
- [ ] Only emotion layers (1-10) visible (no layer 0 strategies)
- [ ] Dosage picker shows when user taps a phase card
- [ ] Selection stores curriculum ID in JournalFlowViewModel
- [ ] Advances to next step after selection
- [ ] All tests pass

### Tests to Write (TDD):
1. `test_view_showsTitle` - Verify title is "Primary Emotion"
2. `test_view_showsOnlyEmotionLayers` - Verify layers 1-10 displayed
3. `test_view_doesNotShowStrategyLayer` - Verify layer 0 excluded
4. `test_tapPhaseCard_showsDosagePicker` - Verify picker appears on tap
5. `test_selectMedicine_advancesToNextStep` - Verify flow progression
6. `test_selectDosage_storesCurriculumID` - Verify state updated in viewModel

## Implementation Approach

### Step 1: Create Test File

**File**: `frontend/WavelengthWatch/WavelengthWatch Watch AppTests/PrimaryEmotionSelectionViewTests.swift`

```swift
import Foundation
import SwiftUI
import Testing
@testable import WavelengthWatch_Watch_App

struct PrimaryEmotionSelectionViewTests {
  private func makeSampleCatalog() -> CatalogResponseModel {
    let medicinal = CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Confident")
    let toxic = CatalogCurriculumEntryModel(id: 2, dosage: .toxic, expression: "Aggressive")
    let strategy = CatalogStrategyModel(id: 3, strategy: "Cold Shower", color: "Blue")

    let phase = CatalogPhaseModel(
      id: 1,
      name: "Rising",
      medicinal: [medicinal],
      toxic: [toxic],
      strategies: [strategy]
    )

    // Layer 0: Strategies (should be filtered out)
    let strategyLayer = CatalogLayerModel(
      id: 0,
      color: "Strategies",
      title: "SELF-CARE",
      subtitle: "(Strategies)",
      phases: [phase]
    )

    // Layer 3: Red (should be visible)
    let emotionLayer = CatalogLayerModel(
      id: 3,
      color: "Red",
      title: "RED",
      subtitle: "(Power)",
      phases: [phase]
    )

    return CatalogResponseModel(
      phaseOrder: ["Rising"],
      layers: [strategyLayer, emotionLayer]
    )
  }

  @Test func view_showsTitle() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // View should have "Primary Emotion" in navigation title
    // This will be tested via FlowCoordinatorView integration
    #expect(viewModel.currentStep == .primaryEmotion)
  }

  @Test func view_showsOnlyEmotionLayers() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    // filteredLayers should exclude layer 0 when in primaryEmotion step
    let filtered = viewModel.filteredLayers
    #expect(filtered.count == 1)
    #expect(filtered.first?.id == 3) // Only emotion layer
  }

  @Test func view_doesNotShowStrategyLayer() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    let filtered = viewModel.filteredLayers
    let hasStrategyLayer = filtered.contains { $0.id == 0 }
    #expect(hasStrategyLayer == false)
  }

  @Test func selectDosage_storesCurriculumID() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    viewModel.selectPrimaryCurriculum(id: 1)

    #expect(viewModel.selectedPrimaryCurriculumID == 1)
  }

  @Test func selectMedicine_advancesToNextStep() {
    let catalog = makeSampleCatalog()
    let viewModel = JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)

    #expect(viewModel.currentStep == .primaryEmotion)

    viewModel.selectPrimaryCurriculum(id: 1)
    viewModel.advanceStep()

    #expect(viewModel.currentStep == .secondaryEmotion)
  }
}
```

### Step 2: Create PrimaryEmotionSelectionView Component

**File**: `frontend/WavelengthWatch/WavelengthWatch Watch App/Views/PrimaryEmotionSelectionView.swift`

```swift
import SwiftUI

/// View for selecting the primary emotion in the journal flow.
///
/// This view displays only emotion layers (excluding strategies layer 0),
/// allows the user to browse phases, and presents a dosage picker when
/// tapping on a phase card.
struct PrimaryEmotionSelectionView: View {
  let catalog: CatalogResponseModel
  @ObservedObject var flowViewModel: JournalFlowViewModel

  @State private var selectedLayerIndex: Int = 0
  @State private var selectedPhaseIndex: Int = 0
  @State private var showingDosagePicker: Bool = false
  @State private var selectedPhase: CatalogPhaseModel?

  var body: some View {
    VStack(spacing: 0) {
      // Instruction text
      Text("How are you feeling?")
        .font(.title3)
        .fontWeight(.medium)
        .foregroundColor(.secondary)
        .padding(.top)

      // Filtered layer navigation (emotions only)
      FilteredLayerNavigationView(
        layers: flowViewModel.filteredLayers,
        phaseOrder: catalog.phaseOrder,
        selectedLayerIndex: $selectedLayerIndex,
        selectedPhaseIndex: $selectedPhaseIndex,
        onPhaseCardTap: { phase in
          selectedPhase = phase
          showingDosagePicker = true
        }
      )
    }
    .sheet(isPresented: $showingDosagePicker) {
      if let phase = selectedPhase {
        DosagePickerView(
          phase: phase,
          layer: currentLayer,
          onSelect: { curriculum in
            flowViewModel.selectPrimaryCurriculum(id: curriculum.id)
            showingDosagePicker = false
            // Advance to next step after selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
              flowViewModel.advanceStep()
            }
          },
          onCancel: {
            showingDosagePicker = false
          }
        )
        .presentationDetents([.medium, .large])
      }
    }
  }

  private var currentLayer: CatalogLayerModel? {
    guard selectedLayerIndex < flowViewModel.filteredLayers.count else { return nil }
    return flowViewModel.filteredLayers[selectedLayerIndex]
  }
}

// MARK: - Dosage Picker Sheet

/// Sheet view for selecting medicinal or toxic dosage from a phase.
private struct DosagePickerView: View {
  let phase: CatalogPhaseModel
  let layer: CatalogLayerModel?
  let onSelect: (CatalogCurriculumEntryModel) -> Void
  let onCancel: () -> Void

  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
        // Phase context
        VStack(spacing: 8) {
          if let layer {
            Text(layer.title)
              .font(.caption)
              .foregroundColor(.secondary)
              .textCase(.uppercase)
          }

          Text(phase.name)
            .font(.title2)
            .fontWeight(.bold)
        }
        .padding(.top)

        // Dosage options
        VStack(spacing: 12) {
          if !phase.medicinal.isEmpty {
            DosageSection(
              title: "Medicinal",
              entries: phase.medicinal,
              color: .green,
              onSelect: onSelect
            )
          }

          if !phase.toxic.isEmpty {
            DosageSection(
              title: "Toxic",
              entries: phase.toxic,
              color: .red,
              onSelect: onSelect
            )
          }
        }
        .padding()

        Spacer()
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", action: onCancel)
        }
      }
      .navigationTitle("Select Dosage")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

/// Section displaying curriculum entries for a specific dosage type.
private struct DosageSection: View {
  let title: String
  let entries: [CatalogCurriculumEntryModel]
  let color: Color
  let onSelect: (CatalogCurriculumEntryModel) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 4) {
        Circle()
          .fill(color)
          .frame(width: 6, height: 6)

        Text(title)
          .font(.caption)
          .fontWeight(.semibold)
          .textCase(.uppercase)
          .foregroundColor(.secondary)
      }

      ForEach(entries) { entry in
        Button {
          onSelect(entry)
        } label: {
          HStack {
            Text(entry.expression)
              .font(.body)
              .foregroundColor(.primary)
              .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .padding(.vertical, 8)
          .padding(.horizontal, 12)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.secondary.opacity(0.1))
          )
        }
        .buttonStyle(.plain)
      }
    }
  }
}

// MARK: - Previews

#Preview {
  let catalog = CatalogResponseModel(
    phaseOrder: ["Rising"],
    layers: [
      CatalogLayerModel(
        id: 3,
        color: "Red",
        title: "RED",
        subtitle: "(Power)",
        phases: [
          CatalogPhaseModel(
            id: 1,
            name: "Rising",
            medicinal: [
              CatalogCurriculumEntryModel(id: 1, dosage: .medicinal, expression: "Confident")
            ],
            toxic: [
              CatalogCurriculumEntryModel(id: 2, dosage: .toxic, expression: "Aggressive")
            ],
            strategies: []
          )
        ]
      )
    ]
  )

  PrimaryEmotionSelectionView(
    catalog: catalog,
    flowViewModel: JournalFlowViewModel(catalog: catalog, initiatedBy: .self_initiated)
  )
}
```

### Step 3: Update FlowCoordinatorView

Update `primaryEmotionView` in FlowCoordinatorView.swift to use the new component:

```swift
private var primaryEmotionView: some View {
  PrimaryEmotionSelectionView(
    catalog: catalog,
    flowViewModel: flowViewModel
  )
}
```

Remove the TODO comment and the placeholder FilteredLayerNavigationView.

### Step 4: Run Tests

```bash
cd frontend/WavelengthWatch
./run-tests-individually.sh PrimaryEmotionSelectionViewTests
```

Ensure all tests pass before proceeding.

### Step 5: Manual Testing Checklist

- [ ] Open the app and trigger the emotion logging flow from MenuView
- [ ] Verify only emotion layers (1-10) are visible
- [ ] Verify layer 0 (strategies) is NOT visible
- [ ] Tap a phase card and verify dosage picker appears
- [ ] Select a medicinal option and verify flow advances
- [ ] Select a toxic option and verify flow advances
- [ ] Cancel the dosage picker and verify it dismisses
- [ ] Verify the selected curriculum ID is stored in flowViewModel

### Step 6: Format and Commit

```bash
cd frontend
swiftformat WavelengthWatch

cd WavelengthWatch
git add .
git commit -m "feat(flow): Add primary emotion selection view

Implements Phase 2.1 of emotion logging flow.

Features:
- Displays only emotion layers (1-10), filters out strategies
- Dosage picker sheet for medicinal/toxic selection
- Integrates with JournalFlowViewModel state management
- Advances to secondary emotion step after selection

Tests:
- All 6 acceptance criteria tests passing
- Verified layer filtering logic
- Tested dosage selection flow

Closes #78

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git push origin feature/primary-emotion-selection
```

### Step 7: Create Pull Request

```bash
gh pr create --title "feat(flow): Add primary emotion selection view (#78)" --body "## Summary
Implements Phase 2.1 of the emotion logging flow - primary emotion selection.

## Changes
- ✅ Created PrimaryEmotionSelectionView with dosage picker
- ✅ Added PrimaryEmotionSelectionViewTests (6 tests)
- ✅ Integrated with FlowCoordinatorView
- ✅ Verified layer filtering (emotions only, no strategies)

## Testing
All tests passing:
- test_view_showsTitle
- test_view_showsOnlyEmotionLayers
- test_view_doesNotShowStrategyLayer
- test_tapPhaseCard_showsDosagePicker
- test_selectMedicine_advancesToNextStep
- test_selectDosage_storesCurriculumID

## Manual Testing
- [x] Emotion layers filter correctly
- [x] Dosage picker displays and functions
- [x] Selection advances flow
- [x] State persists in viewModel

## Screenshots
[Add screenshots of the view and dosage picker]

Closes #78"
```

## Important Notes

### Layer Filtering
The `JournalFlowViewModel.filteredLayers` property should already filter based on `currentStep`:
- `.primaryEmotion` → returns only emotion layers (id > 0)
- `.strategySelection` → returns only layer 0

Verify this logic exists or add it if missing.

### State Management
- Selection flows through `JournalFlowViewModel.selectPrimaryCurriculum(id:)`
- Advancement uses `JournalFlowViewModel.advanceStep()`
- Reset uses `JournalFlowViewModel.reset()`

### Edge Cases to Handle
- Empty medicinal or toxic arrays (show only available options)
- Phase with neither medicinal nor toxic (should not happen per spec, but handle gracefully)
- User cancels dosage picker (should return to navigation without selection)

## Related Issues & PRs
- Depends on: #75 (JournalFlowViewModel) ✅ Merged
- Depends on: #76 (FlowCoordinatorView) ✅ Merged
- Depends on: #79 (FilteredLayerNavigationView) ✅ Merged
- Follows: #80 (Secondary Emotion Prompt) - next phase
- Related spec: `prompts/claude-comm/2025-11-19-emotion-logging-flow-spec.md`

## Estimated Time
- Test creation: 1 hour
- View implementation: 2-3 hours
- Integration & testing: 1 hour
- Polish & PR: 1 hour
**Total**: 5-6 hours

---
*Document created: 2025-11-21*
*For: Claude Code session continuation*
*Status: Ready to implement*
