# Emotion Logging Flow - Implementation Plan

**Date**: 2025-11-19
**Epic**: Multi-Step Journal Entry Flow
**Spec Reference**: `prompts/claude-comm/2025-11-19-emotion-logging-flow-spec.md`

## Overview

This plan breaks down the emotion logging flow feature into atomized, test-driven tasks. Tasks are organized by phase, with clear dependencies and parallelization opportunities marked.

## Principles

- **Test-Driven Development**: Write tests before implementation
- **Atomic PRs**: Each task should produce a small, focused PR (<300 lines diff)
- **Tracer Bullet Approach**: Connect systems end-to-end first, then flesh out
- **Parallel Execution**: Tasks marked with 🟢 can run in parallel within their phase
- **Sequential Execution**: Tasks marked with 🔴 must wait for dependencies

## Phase 0: Foundation (Layer Filtering Architecture)

**Goal**: Implement FR-0 - the core layer filtering system that all other features depend on.

### Task 0.1: Create LayerFilterMode Enum 🟢

**Description**: Define the enum and filtering logic for layer visibility modes.

**Files to Create**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Models/LayerFilterMode.swift`

**Implementation**:
```swift
enum LayerFilterMode: Equatable {
    case all              // Browse mode: layers 0-10
    case emotionsOnly     // Emotion selection: layers 1-10
    case strategiesOnly   // Strategy selection: layer 0 only

    func filter(_ layers: [CatalogLayerModel]) -> [CatalogLayerModel] {
        switch self {
        case .all:
            return layers
        case .emotionsOnly:
            return layers.filter { $0.id >= 1 }
        case .strategiesOnly:
            return layers.filter { $0.id == 0 }
        }
    }
}
```

**Tests to Write** (`LayerFilterModeTests.swift`):
- `test_filterAll_returnsAllLayers`
- `test_filterEmotionsOnly_excludesLayerZero`
- `test_filterEmotionsOnly_includesLayersOneToTen`
- `test_filterStrategiesOnly_includesOnlyLayerZero`
- `test_filterStrategiesOnly_excludesOtherLayers`
- `test_filterEmotionsOnly_withEmptyArray_returnsEmpty`
- `test_equatable_sameModesAreEqual`

**Acceptance Criteria**:
- [ ] Enum exists with three cases
- [ ] `filter()` method correctly filters layers for each mode
- [ ] All tests pass
- [ ] Code is formatted with SwiftFormat

**Estimated Effort**: 1-2 hours
**Dependencies**: None
**PR Size**: ~50 lines

---

### Task 0.2: Add Layer Filtering to ContentViewModel 🔴

**Description**: Add filtering support to ContentViewModel so the main view can optionally filter layers.

**Dependencies**: Task 0.1

**Files to Modify**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/ViewModels/ContentViewModel.swift`

**Implementation**:
```swift
@Published var layerFilterMode: LayerFilterMode = .all

var filteredLayers: [CatalogLayerModel] {
    layerFilterMode.filter(layers)
}
```

**Tests to Add** (`ContentViewModelTests.swift`):
- `test_filteredLayers_defaultsToAll`
- `test_filteredLayers_withEmotionsOnly_excludesLayerZero`
- `test_filteredLayers_withStrategiesOnly_includesOnlyLayerZero`
- `test_filteredLayers_reactsToModeChange`
- `test_filteredLayers_whenLayersEmpty_returnsEmpty`

**Acceptance Criteria**:
- [ ] `layerFilterMode` property added (defaults to `.all`)
- [ ] `filteredLayers` computed property added
- [ ] Existing tests still pass
- [ ] New filtering tests pass
- [ ] No breaking changes to existing functionality

**Estimated Effort**: 2-3 hours
**PR Size**: ~30 lines code + ~100 lines tests

---

### Task 0.3: Update ContentView to Support Filtered Navigation 🔴

**Description**: Modify ContentView to use `filteredLayers` instead of `layers` in navigation, while maintaining backward compatibility.

**Dependencies**: Task 0.2

**Files to Modify**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/ContentView.swift`

**Implementation Changes**:
- Replace `viewModel.layers` with `viewModel.filteredLayers` in:
  - `layeredContent` ForEach loop
  - Digital crown range calculation
  - Layer selection bounds checking
  - Layer indicator rendering
- Ensure layer/phase indices are clamped to `filteredLayers` bounds
- Update layer indicator to show only filtered layers

**Tests to Add** (UI/Integration tests):
- `test_navigation_withAllFilter_showsAllLayers`
- `test_navigation_withEmotionsFilter_showsOnlyEmotionLayers`
- `test_navigation_withStrategiesFilter_showsOnlyLayerZero`
- `test_digitalCrown_rangeAdaptsToFilteredLayers`
- `test_layerIndicator_showsOnlyFilteredLayers`

**Manual Testing Checklist**:
- [ ] Default browse mode shows all layers (0-10)
- [ ] Changing filter to `.emotionsOnly` hides layer 0
- [ ] Changing filter to `.strategiesOnly` shows only layer 0
- [ ] Navigation doesn't crash when switching filters
- [ ] Digital crown scrolls through correct range
- [ ] Layer indicator renders correctly for each mode

**Acceptance Criteria**:
- [ ] ContentView uses `filteredLayers` for navigation
- [ ] Layer selection bounds are correct for filtered arrays
- [ ] Digital crown range adapts to filtered layer count
- [ ] Layer indicator shows only filtered layers
- [ ] All existing tests pass
- [ ] New tests pass
- [ ] No visual regressions in browse mode

**Estimated Effort**: 4-6 hours
**PR Size**: ~150 lines modifications + ~150 lines tests

---

## Phase 1: Flow Foundation & State Management

**Goal**: Create the flow coordinator, view model, and basic navigation structure (implements FR-1, FR-6).

### Task 1.1: Create JournalFlowViewModel 🟢

**Description**: Create the view model that manages state across all flow steps.

**Dependencies**: Task 0.2 (needs LayerFilterMode)

**Files to Create**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/ViewModels/JournalFlowViewModel.swift`

**Implementation**:
```swift
enum FlowStep: Equatable {
    case primaryEmotion
    case secondaryPrompt
    case secondaryEmotion
    case strategySelection
    case review
}

@MainActor
final class JournalFlowViewModel: ObservableObject {
    @Published var currentStep: FlowStep = .primaryEmotion
    @Published var selectedPrimaryCurriculumID: Int?
    @Published var selectedSecondaryCurriculumID: Int?
    @Published var selectedStrategyID: Int?
    @Published var initiatedBy: InitiatedBy = .self_initiated
    @Published var layerFilterMode: LayerFilterMode = .emotionsOnly

    private let catalog: CatalogResponseModel
    private let contentViewModel: ContentViewModel

    init(catalog: CatalogResponseModel, contentViewModel: ContentViewModel) {
        self.catalog = catalog
        self.contentViewModel = contentViewModel
    }

    var filteredLayers: [CatalogLayerModel] {
        layerFilterMode.filter(catalog.layers.reversed())
    }

    func canProceed(from step: FlowStep) -> Bool { ... }
    func reset() { ... }
    func advance(to step: FlowStep) { ... }
    func getPrimaryCurriculum() -> CatalogCurriculumEntryModel? { ... }
    func getSecondaryCurriculum() -> CatalogCurriculumEntryModel? { ... }
    func getStrategy() -> CatalogStrategyModel? { ... }
}
```

**Tests to Write** (`JournalFlowViewModelTests.swift`):
- `test_init_startsAtPrimaryEmotion`
- `test_init_defaultsToSelfInitiated`
- `test_init_defaultsToEmotionsOnlyFilter`
- `test_filteredLayers_returnsEmotionsOnly_initially`
- `test_filteredLayers_returnsStrategiesOnly_whenInStrategyStep`
- `test_canProceed_fromPrimary_requiresSelection`
- `test_canProceed_fromSecondaryPrompt_alwaysTrue`
- `test_canProceed_fromStrategySelection_alwaysTrue`
- `test_reset_clearsAllSelections`
- `test_reset_resetsToInitialStep`
- `test_advance_updatesCurrentStep`
- `test_advance_toStrategySelection_setsStrategiesFilter`
- `test_getPrimaryCurriculum_returnsNil_whenNotSelected`
- `test_getPrimaryCurriculum_returnsCurriculum_whenSelected`

**Acceptance Criteria**:
- [ ] ViewModel initializes with correct defaults
- [ ] State management properties exist
- [ ] Filter mode changes based on flow step
- [ ] Validation logic works correctly
- [ ] Reset clears all state
- [ ] All tests pass

**Estimated Effort**: 4-5 hours
**PR Size**: ~150 lines code + ~200 lines tests

---

### Task 1.2: Create Flow Coordinator View 🔴

**Description**: Create the coordinator that owns the NavigationStack and presents the flow as a sheet.

**Dependencies**: Task 1.1

**Files to Create**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Views/JournalFlowCoordinatorView.swift`

**Implementation**:
```swift
struct JournalFlowCoordinatorView: View {
    @StateObject private var flowViewModel: JournalFlowViewModel
    @EnvironmentObject private var contentViewModel: ContentViewModel
    @Environment(\.dismiss) private var dismiss

    init(catalog: CatalogResponseModel, contentViewModel: ContentViewModel, initiatedBy: InitiatedBy) {
        _flowViewModel = StateObject(wrappedValue: JournalFlowViewModel(
            catalog: catalog,
            contentViewModel: contentViewModel
        ))
    }

    var body: some View {
        NavigationStack {
            currentStepView
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            flowViewModel.reset()
                            dismiss()
                        }
                    }
                }
        }
        .environmentObject(flowViewModel)
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch flowViewModel.currentStep {
        case .primaryEmotion:
            PrimaryEmotionSelectionView()
        case .secondaryPrompt:
            SecondaryEmotionPromptView()
        case .secondaryEmotion:
            SecondaryEmotionSelectionView()
        case .strategySelection:
            StrategySelectionView()
        case .review:
            JournalReviewView()
        }
    }
}
```

**Tests to Write** (`JournalFlowCoordinatorTests.swift`):
- `test_init_createsFlowViewModel`
- `test_init_setsInitiatedBy`
- `test_cancel_resetsFlow`
- `test_cancel_dismissesSheet`
- `test_currentStepView_showsPrimaryInitially`
- `test_navigation_preservesFlowViewModel`

**Acceptance Criteria**:
- [ ] Coordinator initializes with catalog and initiatedBy
- [ ] NavigationStack is set up
- [ ] Cancel button exists and works
- [ ] Current step view is rendered based on flowViewModel.currentStep
- [ ] FlowViewModel is available via environment
- [ ] All tests pass

**Estimated Effort**: 3-4 hours
**PR Size**: ~80 lines code + ~100 lines tests

---

### Task 1.3: Add "Log Emotion" Entry Point to Menu 🔴

**Description**: Add navigation link in MenuView to open the flow (implements FR-1).

**Dependencies**: Task 1.2

**Files to Modify**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/ContentView.swift` (MenuView)

**Implementation**:
```swift
struct MenuView: View {
    @EnvironmentObject private var viewModel: ContentViewModel
    @State private var showingJournalFlow = false

    var body: some View {
        List {
            Button {
                showingJournalFlow = true
            } label: {
                Label("Log Emotion", systemImage: "heart.text.square")
            }

            NavigationLink(destination: ScheduleSettingsView()) {
                Label("Schedules", systemImage: "clock")
            }
            // ... existing menu items
        }
        .navigationTitle("Menu")
        .sheet(isPresented: $showingJournalFlow) {
            if let catalog = viewModel.cachedOrLoadedCatalog() {
                JournalFlowCoordinatorView(
                    catalog: catalog,
                    contentViewModel: viewModel,
                    initiatedBy: .self_initiated
                )
            }
        }
    }
}
```

**Tests to Write** (UI tests):
- `test_menu_hasLogEmotionButton`
- `test_logEmotionButton_opensFlow`
- `test_logEmotionButton_setsInitiatedByToSelf`
- `test_flowDismiss_returnsToMenu`

**Acceptance Criteria**:
- [ ] "Log Emotion" button appears in menu
- [ ] Tapping button opens flow sheet
- [ ] Flow is initialized with `.self_initiated`
- [ ] Flow uses current catalog data
- [ ] Tests pass

**Estimated Effort**: 2-3 hours
**PR Size**: ~40 lines code + ~80 lines tests

---

## Phase 2: Primary Emotion Selection (FR-2)

**Goal**: Implement the first step of the flow where users select their primary emotion.

### Task 2.1: Create Primary Emotion Selection View 🟢

**Description**: Create the view for selecting primary emotion using filtered layer navigation.

**Dependencies**: Phase 1 complete

**Files to Create**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Views/Flow/PrimaryEmotionSelectionView.swift`

**Implementation**:
```swift
struct PrimaryEmotionSelectionView: View {
    @EnvironmentObject private var flowViewModel: JournalFlowViewModel
    @State private var selectedLayerIndex = 0
    @State private var selectedPhaseIndex = 0
    @State private var showingDosagePicker = false
    @State private var selectedDosage: CatalogDosage?

    var body: some View {
        VStack {
            Text("What are you feeling?")
                .font(.title3)
                .padding()

            // Reuse layer/phase navigation (filtered to emotions only)
            FilteredLayerNavigationView(
                layers: flowViewModel.filteredLayers,
                phaseOrder: flowViewModel.catalog.phaseOrder,
                selectedLayerIndex: $selectedLayerIndex,
                selectedPhaseIndex: $selectedPhaseIndex,
                onPhaseCardTap: {
                    showingDosagePicker = true
                }
            )
        }
        .alert("Select Dosage", isPresented: $showingDosagePicker) {
            Button("Medicine") {
                selectDosage(.medicinal)
            }
            Button("Toxic") {
                selectDosage(.toxic)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func selectDosage(_ dosage: CatalogDosage) {
        // Find curriculum ID for selected layer/phase/dosage
        // Set flowViewModel.selectedPrimaryCurriculumID
        // Advance to next step
    }
}
```

**Tests to Write** (`PrimaryEmotionSelectionViewTests.swift`):
- `test_view_showsTitle`
- `test_view_showsOnlyEmotionLayers`
- `test_view_doesNotShowStrategyLayer`
- `test_tapPhaseCard_showsDosagePicker`
- `test_selectMedicine_advancesToNextStep`
- `test_selectToxic_advancesToNextStep`
- `test_selectDosage_storesCurriculumID`
- `test_cancel_dismissesPicker`

**Acceptance Criteria**:
- [ ] View displays correct title
- [ ] Only emotion layers (1-10) are visible
- [ ] User can navigate through layers/phases
- [ ] Tapping phase card shows dosage picker
- [ ] Selecting dosage stores curriculum ID
- [ ] Selecting dosage advances to next step
- [ ] Tests pass

**Estimated Effort**: 5-6 hours
**PR Size**: ~120 lines code + ~150 lines tests

---

### Task 2.2: Create Reusable FilteredLayerNavigationView Component 🟢

**Description**: Extract the layer/phase navigation into a reusable component that works with filtered layers.

**Dependencies**: None (can be done in parallel with 2.1)

**Files to Create**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Views/Components/FilteredLayerNavigationView.swift`

**Implementation**:
```swift
struct FilteredLayerNavigationView: View {
    let layers: [CatalogLayerModel]
    let phaseOrder: [String]
    @Binding var selectedLayerIndex: Int
    @Binding var selectedPhaseIndex: Int
    let onPhaseCardTap: () -> Void

    var body: some View {
        // Similar to existing ContentView layer navigation
        // But works with any filtered array of layers
        // Includes vertical layer scrolling, horizontal phase scrolling
        // Digital crown support
    }
}
```

**Tests to Write** (`FilteredLayerNavigationViewTests.swift`):
- `test_navigation_displaysAllProvidedLayers`
- `test_navigation_displaysAllPhases`
- `test_layerSelection_updatesBinding`
- `test_phaseSelection_updatesBinding`
- `test_tapPhaseCard_callsCallback`
- `test_digitalCrown_changesLayerSelection`
- `test_swipe_changesPhaseSelection`

**Acceptance Criteria**:
- [ ] Component works with any array of layers
- [ ] Bindings work correctly
- [ ] Tap callback fires
- [ ] Digital crown works
- [ ] Tests pass

**Estimated Effort**: 6-8 hours
**PR Size**: ~200 lines code + ~200 lines tests

---

## Phase 3: Secondary Emotion Selection (FR-3)

**Goal**: Implement optional secondary emotion selection.

### Task 3.1: Create Secondary Emotion Prompt View 🟢

**Description**: Create the prompt screen that offers to add a secondary emotion or skip.

**Dependencies**: Phase 2 complete

**Files to Create**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Views/Flow/SecondaryEmotionPromptView.swift`

**Implementation**:
```swift
struct SecondaryEmotionPromptView: View {
    @EnvironmentObject private var flowViewModel: JournalFlowViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Anything else?")
                .font(.title3)

            Text("Many people experience multiple states at once")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let primary = flowViewModel.getPrimaryCurriculum() {
                EmotionSummaryCard(curriculum: primary)
            }

            Spacer()

            Button("Add Secondary Emotion") {
                flowViewModel.advance(to: .secondaryEmotion)
            }
            .buttonStyle(.borderedProminent)

            Button("Skip") {
                flowViewModel.advance(to: .strategySelection)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
```

**Tests to Write** (`SecondaryEmotionPromptViewTests.swift`):
- `test_view_showsTitle`
- `test_view_showsPrimaryEmotion`
- `test_addSecondaryButton_advancesToSecondarySelection`
- `test_skipButton_advancesToStrategySelection`
- `test_primaryEmotion_displaysCorrectly`

**Acceptance Criteria**:
- [ ] View displays title and subtitle
- [ ] Primary emotion is shown
- [ ] "Add Secondary Emotion" button works
- [ ] "Skip" button advances to strategy selection
- [ ] Tests pass

**Estimated Effort**: 3-4 hours
**PR Size**: ~60 lines code + ~100 lines tests

---

### Task 3.2: Create Secondary Emotion Selection View 🔴

**Description**: Create the secondary emotion picker (reuses primary selection logic but prevents duplicates).

**Dependencies**: Task 3.1

**Files to Create**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Views/Flow/SecondaryEmotionSelectionView.swift`

**Implementation**:
```swift
struct SecondaryEmotionSelectionView: View {
    @EnvironmentObject private var flowViewModel: JournalFlowViewModel
    @State private var selectedLayerIndex = 0
    @State private var selectedPhaseIndex = 0
    @State private var showingDosagePicker = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            // Show primary emotion context at top
            if let primary = flowViewModel.getPrimaryCurriculum() {
                EmotionSummaryCard(curriculum: primary, compact: true)
                    .padding(.horizontal)
            }

            Text("Select Secondary Emotion")
                .font(.title3)

            FilteredLayerNavigationView(
                layers: flowViewModel.filteredLayers,
                phaseOrder: flowViewModel.catalog.phaseOrder,
                selectedLayerIndex: $selectedLayerIndex,
                selectedPhaseIndex: $selectedPhaseIndex,
                onPhaseCardTap: {
                    showingDosagePicker = true
                }
            )
        }
        .alert("Select Dosage", isPresented: $showingDosagePicker) {
            // Similar to primary, but validate != primary
        }
        .alert("Invalid Selection", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func selectDosage(_ dosage: CatalogDosage) {
        // Validate not same as primary
        // Set flowViewModel.selectedSecondaryCurriculumID
        // Advance to strategy selection
    }
}
```

**Tests to Write** (`SecondaryEmotionSelectionViewTests.swift`):
- `test_view_showsPrimaryEmotionContext`
- `test_view_showsOnlyEmotionLayers`
- `test_selectSameAsPrimary_showsError`
- `test_selectDifferentFromPrimary_advances`
- `test_selectDosage_storesCurriculumID`

**Acceptance Criteria**:
- [ ] Primary emotion shown as context
- [ ] Only emotion layers visible
- [ ] Selecting same as primary shows error
- [ ] Selecting different emotion works
- [ ] Advances to strategy selection after selection
- [ ] Tests pass

**Estimated Effort**: 4-5 hours
**PR Size**: ~100 lines code + ~120 lines tests

---

### Task 3.3: Create EmotionSummaryCard Component 🟢

**Description**: Create reusable card component for displaying selected emotions.

**Dependencies**: None (can be done in parallel)

**Files to Create**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Views/Components/EmotionSummaryCard.swift`

**Implementation**:
```swift
struct EmotionSummaryCard: View {
    let curriculum: CatalogCurriculumEntryModel
    let layer: CatalogLayerModel?
    let phase: CatalogPhaseModel?
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let layer = layer {
                Text(layer.title)
                    .font(compact ? .caption2 : .caption)
                    .foregroundColor(.secondary)
            }
            if let phase = phase {
                Text(phase.name)
                    .font(compact ? .caption : .body)
                    .fontWeight(.medium)
            }
            Text(curriculum.expression)
                .font(compact ? .body : .title3)
                .fontWeight(.bold)
            HStack {
                Circle()
                    .fill(curriculum.dosage == .medicinal ? .green : .red)
                    .frame(width: 6, height: 6)
                Text(curriculum.dosage.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.2))
        )
    }
}
```

**Tests to Write** (`EmotionSummaryCardTests.swift`):
- `test_card_displaysLayerTitle`
- `test_card_displaysPhaseName`
- `test_card_displaysExpression`
- `test_card_displaysDosage`
- `test_compactMode_usesSmaller Fonts`
- `test_medicinal_showsGreenIndicator`
- `test_toxic_showsRedIndicator`

**Acceptance Criteria**:
- [ ] Card displays all curriculum info
- [ ] Compact mode works
- [ ] Dosage indicator shows correct color
- [ ] Tests pass

**Estimated Effort**: 2-3 hours
**PR Size**: ~60 lines code + ~100 lines tests

---

## Phase 4: Strategy Selection (FR-4)

**Goal**: Implement strategy selection using filtered navigation (layer 0 only).

### Task 4.1: Create Strategy Selection View 🟢

**Description**: Create the strategy selection screen that shows only layer 0, pre-scrolled to the relevant phase.

**Dependencies**: Phase 3 complete

**Files to Create**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Views/Flow/StrategySelectionView.swift`

**Implementation**:
```swift
struct StrategySelectionView: View {
    @EnvironmentObject private var flowViewModel: JournalFlowViewModel
    @State private var selectedPhaseIndex: Int
    @State private var selectedStrategyID: Int?
    @State private var showingConfirmation = false

    init() {
        // Initialize selectedPhaseIndex to match primary emotion's phase
        _selectedPhaseIndex = State(initialValue: 0) // Will be set in onAppear
    }

    var body: some View {
        VStack {
            // Show primary (and secondary) emotion context
            emotionContextView

            Text("Self-Care Strategies")
                .font(.title3)

            // Filtered to show ONLY layer 0 (strategies)
            // Vertical scrolling disabled (only 1 layer)
            // Horizontal scrolling through phases
            FilteredLayerNavigationView(
                layers: flowViewModel.filteredLayers, // Only layer 0
                phaseOrder: flowViewModel.catalog.phaseOrder,
                selectedLayerIndex: .constant(0), // Always 0
                selectedPhaseIndex: $selectedPhaseIndex,
                onStrategyCardTap: { strategyID in
                    selectedStrategyID = strategyID
                    showingConfirmation = true
                }
            )

            Button("Continue without Strategy") {
                flowViewModel.selectedStrategyID = nil
                flowViewModel.advance(to: .review)
            }
            .buttonStyle(.bordered)
        }
        .onAppear {
            // Set filter to strategies only
            flowViewModel.layerFilterMode = .strategiesOnly

            // Set initial phase to match primary emotion's phase
            if let primary = flowViewModel.getPrimaryCurriculum() {
                selectedPhaseIndex = getPhaseIndex(for: primary)
            }
        }
        .alert("Select Strategy?", isPresented: $showingConfirmation) {
            Button("Select") {
                flowViewModel.selectedStrategyID = selectedStrategyID
                flowViewModel.advance(to: .review)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var emotionContextView: some View {
        VStack(spacing: 4) {
            if let primary = flowViewModel.getPrimaryCurriculum() {
                EmotionSummaryCard(curriculum: primary, compact: true)
            }
            if let secondary = flowViewModel.getSecondaryCurriculum() {
                EmotionSummaryCard(curriculum: secondary, compact: true)
            }
        }
        .padding(.horizontal)
    }
}
```

**Tests to Write** (`StrategySelectionViewTests.swift`):
- `test_view_showsOnlyLayerZero`
- `test_view_doesNotShowEmotionLayers`
- `test_view_initialPhaseMatchesPrimaryEmotion`
- `test_view_showsPrimaryEmotionContext`
- `test_view_showsSecondaryEmotion_ifSelected`
- `test_tapStrategy_showsConfirmation`
- `test_selectStrategy_storesStrategyID`
- `test_selectStrategy_advancesToReview`
- `test_continueWithoutStrategy_advancesToReview`
- `test_continueWithoutStrategy_leavesStrategyIDNil`

**Acceptance Criteria**:
- [ ] Only layer 0 (Strategies) is visible
- [ ] Layers 1-10 are not visible
- [ ] Phase initially matches primary emotion's phase
- [ ] Horizontal scrolling through phases works
- [ ] Vertical scrolling is disabled (or shows only 1 layer)
- [ ] Emotion context is displayed
- [ ] Tapping strategy shows confirmation
- [ ] "Continue without Strategy" works
- [ ] Tests pass

**Estimated Effort**: 6-7 hours
**PR Size**: ~150 lines code + ~180 lines tests

---

### Task 4.2: Enhance FilteredLayerNavigationView for Strategy Tapping 🔴

**Description**: Add strategy card tap support to FilteredLayerNavigationView.

**Dependencies**: Task 4.1

**Files to Modify**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Views/Components/FilteredLayerNavigationView.swift`

**Implementation**:
Add optional callback for strategy taps:
```swift
let onStrategyCardTap: ((Int) -> Void)? = nil

// In strategy card rendering:
.onTapGesture {
    onStrategyCardTap?(strategy.id)
}
```

**Tests to Add**:
- `test_strategyTap_callsCallback`
- `test_strategyTap_whenCallbackNil_doesNotCrash`

**Acceptance Criteria**:
- [ ] Strategy tap callback added
- [ ] Callback is optional (nil-safe)
- [ ] Tapping strategy calls callback with ID
- [ ] Tests pass

**Estimated Effort**: 2-3 hours
**PR Size**: ~30 lines code + ~40 lines tests

---

## Phase 5: Review & Submission (FR-5)

**Goal**: Implement the final review and submission step.

### Task 5.1: Create Journal Review View 🟢

**Description**: Create the review screen that shows all selections and submits to backend.

**Dependencies**: Phase 4 complete

**Files to Create**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Views/Flow/JournalReviewView.swift`

**Implementation**:
```swift
struct JournalReviewView: View {
    @EnvironmentObject private var flowViewModel: JournalFlowViewModel
    @EnvironmentObject private var contentViewModel: ContentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSubmitting = false
    @State private var submissionError: String?
    @State private var showingSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Review Your Entry")
                    .font(.title3)

                // Primary emotion
                if let primary = flowViewModel.getPrimaryCurriculum() {
                    VStack(alignment: .leading) {
                        Text("Primary Emotion")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        EmotionSummaryCard(curriculum: primary)
                    }
                }

                // Secondary emotion (if selected)
                if let secondary = flowViewModel.getSecondaryCurriculum() {
                    VStack(alignment: .leading) {
                        Text("Secondary Emotion")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        EmotionSummaryCard(curriculum: secondary)
                    }
                }

                // Strategy (if selected)
                if let strategy = flowViewModel.getStrategy() {
                    VStack(alignment: .leading) {
                        Text("Self-Care Strategy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        StrategyCard(strategy: strategy)
                    }
                }

                // Timestamp
                Text("Logged at: \(formattedTimestamp)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Actions
                Button("Log Entry") {
                    Task { await submitEntry() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSubmitting)

                if !isSubmitting {
                    Button("Edit") {
                        flowViewModel.advance(to: .primaryEmotion)
                    }
                    .buttonStyle(.bordered)
                }

                if isSubmitting {
                    ProgressView()
                }
            }
            .padding()
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK") {
                flowViewModel.reset()
                dismiss()
            }
        } message: {
            Text("Entry logged successfully!")
        }
        .alert("Error", isPresented: .constant(submissionError != nil)) {
            Button("Retry") {
                submissionError = nil
                Task { await submitEntry() }
            }
            Button("Cancel", role: .cancel) {
                submissionError = nil
            }
        } message: {
            Text(submissionError ?? "")
        }
    }

    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    private func submitEntry() async {
        guard let primaryID = flowViewModel.selectedPrimaryCurriculumID else {
            submissionError = "No primary emotion selected"
            return
        }

        isSubmitting = true

        do {
            await contentViewModel.journal(
                curriculumID: primaryID,
                secondaryCurriculumID: flowViewModel.selectedSecondaryCurriculumID,
                strategyID: flowViewModel.selectedStrategyID,
                initiatedBy: flowViewModel.initiatedBy
            )

            // Check if submission succeeded
            if let feedback = contentViewModel.journalFeedback {
                switch feedback.kind {
                case .success:
                    showingSuccess = true
                case .failure(let message):
                    submissionError = message
                }
            }
        }

        isSubmitting = false
    }
}
```

**Tests to Write** (`JournalReviewViewTests.swift`):
- `test_view_showsTitle`
- `test_view_showsPrimaryEmotion`
- `test_view_showsSecondaryEmotion_ifSelected`
- `test_view_hidesSecondaryEmotion_ifNotSelected`
- `test_view_showsStrategy_ifSelected`
- `test_view_hidesStrategy_ifNotSelected`
- `test_view_showsTimestamp`
- `test_logEntry_submitsToBackend`
- `test_logEntry_showsLoadingState`
- `test_logEntry_onSuccess_showsAlert`
- `test_logEntry_onSuccess_dismissesFlow`
- `test_logEntry_onError_showsAlert`
- `test_logEntry_onError_allowsRetry`
- `test_editButton_returnsToFirstStep`

**Acceptance Criteria**:
- [ ] All selections are displayed
- [ ] Timestamp is shown
- [ ] "Log Entry" submits to backend
- [ ] Loading state is shown during submission
- [ ] Success shows alert and dismisses flow
- [ ] Error shows alert and allows retry
- [ ] "Edit" returns to first step
- [ ] Tests pass

**Estimated Effort**: 5-6 hours
**PR Size**: ~150 lines code + ~200 lines tests

---

### Task 5.2: Create StrategyCard Component 🟢

**Description**: Create reusable card component for displaying strategies.

**Dependencies**: None (can be done in parallel)

**Files to Create**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Views/Components/StrategyCard.swift`

**Implementation**:
```swift
struct StrategyCard: View {
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

**Tests to Write** (`StrategyCardTests.swift`):
- `test_card_displaysStrategy`
- `test_card_displaysColorIndicator`
- `test_compactMode_usesSmallerFont`

**Acceptance Criteria**:
- [ ] Card displays strategy text
- [ ] Color indicator shows correct color
- [ ] Compact mode works
- [ ] Tests pass

**Estimated Effort**: 1-2 hours
**PR Size**: ~30 lines code + ~50 lines tests

---

## Phase 6: Integration & Polish

**Goal**: Connect all pieces, handle notification routing, and polish the UX.

### Task 6.1: Update NotificationDelegate to Route to Flow 🔴

**Description**: Modify notification handling to open the flow with `.scheduled` initiatedBy.

**Dependencies**: Phase 5 complete

**Files to Modify**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Services/NotificationDelegate.swift` (if exists)
- `frontend/WavelengthWatch/WavelengthWatch Watch App/WavelengthWatchApp.swift`

**Implementation**:
Update notification tap handling to:
1. Extract `initiatedBy` from notification
2. Open JournalFlowCoordinatorView as a sheet
3. Pass `.scheduled` as initiatedBy

**Tests to Write**:
- `test_notificationTap_opensFlow`
- `test_notificationTap_setsInitiatedByScheduled`
- `test_notificationPayload_parsedCorrectly`

**Acceptance Criteria**:
- [ ] Tapping notification opens flow
- [ ] Flow is initialized with `.scheduled`
- [ ] Notification state is cleared after handling
- [ ] Tests pass

**Estimated Effort**: 3-4 hours
**PR Size**: ~60 lines code + ~80 lines tests

---

### Task 6.2: Add Flow Entry Point from Existing Detail Views (Optional) 🟢

**Description**: Optionally add a way to enter the flow from existing curriculum/strategy detail views.

**Dependencies**: Phase 5 complete

**Files to Modify**:
- `frontend/WavelengthWatch/WavelengthWatch Watch App/ContentView.swift` (CurriculumDetailView)
- `frontend/WavelengthWatch/WavelengthWatch Watch App/ContentView.swift` (StrategyListView)

**Implementation**:
Add "Log via Flow" button that:
- Opens JournalFlowCoordinatorView
- Pre-fills primary emotion based on current curriculum
- User can then add secondary/strategy

**Tests to Write**:
- `test_curriculumDetail_hasFlowButton`
- `test_strategyList_hasFlowButton`
- `test_flowButton_opensPrefilled Flow`

**Acceptance Criteria**:
- [ ] Button exists in detail views
- [ ] Opening flow pre-fills current selection
- [ ] User can continue flow from there
- [ ] Tests pass

**Estimated Effort**: 4-5 hours
**PR Size**: ~80 lines code + ~100 lines tests

---

### Task 6.3: End-to-End Integration Tests 🔴

**Description**: Write comprehensive integration tests for the entire flow.

**Dependencies**: All previous tasks complete

**Files to Create**:
- `frontend/WavelengthWatch/WavelengthWatch Watch AppTests/JournalFlowIntegrationTests.swift`

**Tests to Write**:
- `test_fullFlow_primaryOnly`
- `test_fullFlow_primaryAndSecondary`
- `test_fullFlow_primaryAndStrategy`
- `test_fullFlow_primarySecondaryAndStrategy`
- `test_fullFlow_skipSecondary`
- `test_fullFlow_skipStrategy`
- `test_fullFlow_cancelAtEachStep`
- `test_fullFlow_backNavigation`
- `test_fullFlow_validationPreventsInvalidAdvance`
- `test_fullFlow_submissionSuccess`
- `test_fullFlow_submissionError_retry`
- `test_notificationEntry_setsInitiatedByScheduled`
- `test_menuEntry_setsInitiatedBySelf`

**Acceptance Criteria**:
- [ ] All flow paths tested
- [ ] Edge cases covered
- [ ] Error handling verified
- [ ] Back navigation tested
- [ ] All tests pass

**Estimated Effort**: 6-8 hours
**PR Size**: ~400 lines tests

---

### Task 6.4: Accessibility & VoiceOver Support 🟢

**Description**: Add accessibility labels and VoiceOver support to all flow views.

**Dependencies**: Phase 5 complete

**Files to Modify**:
- All flow view files

**Implementation**:
- Add `.accessibilityLabel()` to all interactive elements
- Add `.accessibilityHint()` for complex actions
- Add `.accessibilityValue()` for current selections
- Test with VoiceOver enabled

**Acceptance Criteria**:
- [ ] All buttons have labels
- [ ] Current selections are announced
- [ ] Navigation is clear with VoiceOver
- [ ] Manual VoiceOver testing passes

**Estimated Effort**: 3-4 hours
**PR Size**: ~100 lines modifications

---

### Task 6.5: Documentation Updates 🟢

**Description**: Update project documentation to reflect new feature.

**Dependencies**: All implementation complete

**Files to Modify**:
- `CLAUDE.md`
- `README.md`

**Implementation**:
Add sections describing:
- How to use the emotion logging flow
- Architecture of layer filtering
- How to extend the flow with new steps

**Acceptance Criteria**:
- [ ] CLAUDE.md updated
- [ ] README.md updated
- [ ] Architecture documented
- [ ] Usage examples added

**Estimated Effort**: 2-3 hours
**PR Size**: ~150 lines documentation

---

## Summary & Parallelization Strategy

### Task Dependency Graph

```
Phase 0 (Foundation):
  0.1 (LayerFilterMode) 🟢
    ↓
  0.2 (ContentViewModel filtering) 🔴
    ↓
  0.3 (ContentView filtering support) 🔴

Phase 1 (Flow Foundation):
  1.1 (JournalFlowViewModel) 🟢 [depends on 0.2]
    ↓
  1.2 (Flow Coordinator) 🔴
    ↓
  1.3 (Menu entry point) 🔴

Phase 2 (Primary Selection):
  2.1 (Primary view) 🟢 [depends on Phase 1]
  2.2 (FilteredNavigation component) 🟢 [parallel to 2.1]

Phase 3 (Secondary Selection):
  3.1 (Secondary prompt) 🟢 [depends on Phase 2]
  3.2 (Secondary view) 🔴
  3.3 (EmotionSummaryCard) 🟢 [parallel to 3.1, 3.2]

Phase 4 (Strategy Selection):
  4.1 (Strategy view) 🟢 [depends on Phase 3]
  4.2 (FilteredNavigation enhancement) 🔴

Phase 5 (Review & Submit):
  5.1 (Review view) 🟢 [depends on Phase 4]
  5.2 (StrategyCard component) 🟢 [parallel to 5.1]

Phase 6 (Integration):
  6.1 (Notification routing) 🔴 [depends on Phase 5]
  6.2 (Detail view entry points) 🟢 [parallel to 6.1]
  6.3 (Integration tests) 🔴 [depends on all]
  6.4 (Accessibility) 🟢 [depends on Phase 5]
  6.5 (Documentation) 🟢 [depends on all implementation]
```

### Recommended Work Streams

**Stream 1 (Critical Path)**:
- 0.1 → 0.2 → 0.3 → 1.1 → 1.2 → 1.3 → 2.1 → 3.1 → 3.2 → 4.1 → 4.2 → 5.1 → 6.1 → 6.3

**Stream 2 (Components)**:
- 2.2 → 3.3 → 5.2 → 6.4

**Stream 3 (Polish)**:
- 6.2 → 6.5

### Estimated Timeline

- **Phase 0**: 1-2 days (8-15 hours)
- **Phase 1**: 1-2 days (9-12 hours)
- **Phase 2**: 1-2 days (11-14 hours)
- **Phase 3**: 1-2 days (9-12 hours)
- **Phase 4**: 1-2 days (8-10 hours)
- **Phase 5**: 1 day (6-8 hours)
- **Phase 6**: 2-3 days (15-20 hours)

**Total**: 8-12 days (66-91 hours) with serial execution
**Total with Parallelization**: 6-8 days (with 2-3 developers working in parallel)

### Total PR Count: 28 atomic PRs

### Success Criteria

Epic is complete when:
- [ ] All 28 tasks complete
- [ ] All unit tests pass (>90% coverage)
- [ ] All integration tests pass
- [ ] Manual testing scenarios pass
- [ ] Accessibility testing passes
- [ ] Documentation updated
- [ ] All CI checks pass
- [ ] Code reviewed and approved

---

**Plan Status**: Ready for Implementation
**Next Action**: Create GitHub issues for Phase 0 tasks
