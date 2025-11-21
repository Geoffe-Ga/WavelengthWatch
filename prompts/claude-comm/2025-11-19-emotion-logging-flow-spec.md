# Enhanced Emotion Logging Flow - Feature Specification

**Date**: 2025-11-19
**Status**: Draft - Pending Review
**Epic**: Multi-Step Journal Entry Flow

## Executive Summary

This specification describes a multi-phasic emotion logging flow that guides users through recording their primary emotional state, optional secondary emotion, and self-care strategy application. The feature builds upon the existing journal infrastructure while introducing a new guided UX pattern that will become the primary method for creating journal entries.

## Background & Context

### Current State

The app currently supports basic journal logging via:
- **Single-tap logging**: Users tap the mystical journal icon (+) on curriculum or strategy cards
- **Immediate submission**: A confirmation dialog appears, and upon "Yes", the entry is submitted
- **Limited data capture**: Only captures one curriculum entry OR one curriculum + one strategy
- **Backend support**: The `/api/v1/journal` endpoint already supports:
  - `curriculum_id` (required)
  - `secondary_curriculum_id` (optional)
  - `strategy_id` (optional)
  - `initiated_by` enum (self/scheduled)

**Key Files**:
- `ContentView.swift:813-827` - Strategy logging with confirmation alert
- `ContentView.swift:913-972` - Curriculum card logging with confirmation alert
- `ContentView.swift:1007-1065` - Strategy card logging within curriculum detail view
- `ContentViewModel.swift:66-88` - Journal submission method
- `backend/routers/journal.py:124-137` - POST endpoint for journal creation
- `backend/models.py:120-163` - Journal table with all relationships

### Gap Analysis

**Missing Capabilities**:
1. **No guided multi-step flow** - Users cannot easily log primary + secondary emotions in one session
2. **Strategy logging is disconnected** - Strategies are logged separately, not as a natural follow-up to emotional check-ins
3. **No intermediate state management** - No way to build up a journal entry across multiple screens
4. **No "flow completion" concept** - Each tap is atomic; no session-based journaling experience

## User Story

**As a** person with Bipolar disorder who wants to track my emotional patterns,

**I want to** be guided through a natural reflection flow where I:
1. Identify my primary emotional state (layer/phase/dosage)
2. Optionally identify a secondary emotion if I'm experiencing multiple states
3. Review recommended self-care strategies and optionally log one I'm applying

**So that** I can:
- Create richer, more complete journal entries without confusion
- Build self-awareness through a structured reflection process
- Associate my self-care actions with the emotions that prompted them
- Establish a consistent journaling habit with lower cognitive load

## Feature Requirements

### FR-0: Layer Filtering Architecture (Foundation)

**Description**: The core navigation system must support dynamic layer filtering to enable three distinct view modes: Browse (all layers), Emotion Selection (layers 1-10 only), and Strategy Selection (layer 0 only).

**Requirements**:

1. **Filterable Layer Data Source**:
   - Create a computed property or method that filters `CatalogResponseModel.layers` based on a filter criterion
   - Filter types:
     - `.all`: Show all layers 0-10 (Browse mode)
     - `.emotionsOnly`: Show only layers where `id >= 1` (Emotion Selection mode)
     - `.strategiesOnly`: Show only layers where `id == 0` (Strategy Selection mode)

2. **Navigation Component Reusability**:
   - The existing dual-axis layer/phase navigation must work with filtered layer sets
   - When layer filtering is applied:
     - Vertical scroll range adapts to filtered layer count
     - Digital crown range adapts accordingly
     - Layer indicator shows only filtered layers
     - Navigation state (selected indices) references filtered array

3. **State Management**:
   - `JournalFlowViewModel` holds the current filter mode
   - Filter mode determines which layers are visible
   - Changing filter mode resets navigation indices appropriately

4. **Initial Phase/Layer Selection**:
   - Support pre-setting the initial layer and phase when entering a filtered view
   - Example: When entering Strategy Selection mode, pre-select layer 0 and phase matching primary emotion's phase

**Implementation Approach**:

Create an enum for filter modes:
```swift
enum LayerFilterMode {
    case all              // Show layers 0-10
    case emotionsOnly     // Show layers 1-10
    case strategiesOnly   // Show layer 0 only
}
```

Add computed property to filter layers:
```swift
// In ContentViewModel or JournalFlowViewModel
@Published var layerFilterMode: LayerFilterMode = .all

var filteredLayers: [CatalogLayerModel] {
    switch layerFilterMode {
    case .all:
        return layers
    case .emotionsOnly:
        return layers.filter { $0.id >= 1 }
    case .strategiesOnly:
        return layers.filter { $0.id == 0 }
    }
}
```

Modify navigation to use `filteredLayers`:
- Replace direct references to `viewModel.layers` with `viewModel.filteredLayers`
- Update layer selection indices to work within filtered array bounds
- Ensure layer indicator renders correctly for filtered set

**Acceptance Criteria**:
- [ ] `LayerFilterMode` enum exists with three modes
- [ ] Computed property `filteredLayers` returns correct subset based on mode
- [ ] Navigation components (TabView, ScrollView, Digital Crown) work with filtered layers
- [ ] Layer indicator displays only filtered layers
- [ ] Changing filter mode does not crash or show invalid layers
- [ ] Initial layer/phase can be pre-set when entering a filtered view
- [ ] Tests verify filtering logic for all three modes

**Dependencies**:
- This is a prerequisite for FR-2, FR-3, and FR-4
- Must be implemented before any flow step can use filtered navigation

### FR-1: Initiate Emotion Logging Flow

**Description**: Users must be able to enter the emotion logging flow from multiple entry points.

**Entry Points**:
1. **From Main View (new)**: A "Log Emotion" button in the menu or a dedicated floating action button
2. **From Notification (existing)**: Tapping a scheduled notification sets `initiatedBy = .scheduled`
3. **From Quick Action (future)**: Complication or Siri shortcut (out of scope for MVP)

**Acceptance Criteria**:
- [ ] User can tap "Log Emotion" from the menu
- [ ] Flow correctly sets `initiatedBy` based on entry point
- [ ] Entry point is tracked for analytics

### FR-2: Primary Emotion Selection

**Description**: The first step guides users to select their primary emotional state from emotion layers only.

**Screen Design**:
- **Title**: "What are you feeling?"
- **Subtitle**: "Scroll to find your layer and phase"
- **Layer Filtering**: Show ONLY layers 1-10 (emotion layers: Beige, Purple, Red, etc.)
  - Layer 0 (Strategies) is completely hidden/filtered out
  - User navigates only through emotion-bearing layers
- **Interaction**: Reuses existing dual-axis navigation (layers vertical, phases horizontal)
  - Vertical scrolling through layers 1-10
  - Horizontal scrolling through phases
  - Digital crown rotates through layers
- **Visual Design**: Simplified version of the main curriculum view
  - No menu button
  - No journal icons (to avoid confusion)
  - Larger "Select" button at bottom of each phase card
- **Selection Mechanism**:
  - User scrolls to desired layer/phase
  - Taps phase card or "Select" button
  - A dosage picker appears (Medicine/Toxic)
  - User selects dosage and confirms

**State Management**:
- Store `selectedPrimaryCurriculumID: Int?` in a new `JournalFlowViewModel`
- Track which layer/phase/dosage was selected for display in summary
- Filter catalog to show only `layer.id >= 1`

**Acceptance Criteria**:
- [ ] Only layers 1-10 (emotion layers) are visible
- [ ] Layer 0 (Strategies) is not visible
- [ ] User can scroll through all emotion layers and phases
- [ ] Tapping a phase card shows dosage picker (Medicine/Toxic)
- [ ] Selecting a dosage advances to next step
- [ ] Selection is stored in flow state
- [ ] User can go "Back" to change their selection

### FR-3: Secondary Emotion Selection (Optional)

**Description**: After selecting a primary emotion, users are offered the option to log a secondary emotion.

**Screen Design**:
- **Title**: "Anything else?"
- **Subtitle**: "Many people experience multiple states at once"
- **Primary Display**: Shows selected primary emotion as a card at top (non-interactive)
- **Action Buttons**:
  - "Add Secondary Emotion" (primary action)
  - "Skip" (secondary action)
- **If "Add Secondary Emotion"**:
  - Return to layer/phase/dosage picker (same as FR-2)
  - **Layer Filtering**: Show ONLY layers 1-10 (emotion layers)
    - Layer 0 (Strategies) remains hidden
  - Primary emotion visible at top as context
  - Prevent selecting the same curriculum entry twice

**State Management**:
- Store `selectedSecondaryCurriculumID: Int?` in `JournalFlowViewModel`
- Validate that secondary ≠ primary
- Filter catalog to show only `layer.id >= 1`

**Acceptance Criteria**:
- [ ] Primary emotion is displayed clearly at top
- [ ] User can tap "Add Secondary Emotion" to open picker
- [ ] Only layers 1-10 (emotion layers) are visible in picker
- [ ] Layer 0 (Strategies) is not visible in picker
- [ ] Secondary picker prevents selecting the same entry as primary
- [ ] User can tap "Skip" to proceed without secondary
- [ ] User can go "Back" to change primary selection
- [ ] Selection is stored in flow state

### FR-4: Strategy Selection (Optional)

**Description**: After emotion selection(s), users navigate the Strategies layer (layer 0) to optionally select a self-care strategy.

**Screen Design**:
- **Layer Filtering**: Show ONLY layer 0 (Strategies layer)
  - Layers 1-10 (emotion layers) are completely hidden/filtered out
  - User cannot accidentally navigate to emotion layers
- **Initial Phase Position**:
  - Horizontally scroll to the phase that matches the primary emotion's phase
  - Example: If primary emotion was "Red - Rising", start at the "Rising" phase of the Strategies layer
- **Interaction**: Same dual-axis navigation as main view
  - Vertical scrolling is disabled (only 1 layer visible)
  - Horizontal scrolling through phases works normally
  - Digital crown rotates through phases
- **Visual Overlay**:
  - Semi-transparent card at top showing primary (and secondary if present) emotion context
  - Can be dismissed/minimized to see strategies clearly
- **Selection Mechanism**:
  - User scrolls horizontally through strategy phases
  - Taps a specific strategy card to select it
  - Confirmation: "Log with [Strategy Name]?" alert appears
  - Options: "Select Strategy" / "Skip Strategies" / "Cancel"
- **Action Buttons** (floating or bottom sheet):
  - "Continue without Strategy" (always available)
  - "Select Strategy" (appears after tapping a strategy card)

**State Management**:
- Store `selectedStrategyID: Int?` in `JournalFlowViewModel`
- Store `selectedPhaseForStrategies: Int` (derived from primary emotion's phase)
- Filter catalog to show only `layer.id == 0`
- Pre-set phase selection to match primary emotion's phase

**Acceptance Criteria**:
- [ ] Only layer 0 (Strategies) is visible in the navigation
- [ ] Phase initially matches primary emotion's phase
- [ ] User can horizontally scroll through all strategy phases
- [ ] User cannot vertically scroll to other layers
- [ ] Tapping a strategy card shows confirmation
- [ ] Primary (and secondary) emotions shown as context overlay
- [ ] "Continue without Strategy" always works
- [ ] User can go "Back" to change secondary selection
- [ ] Selection is stored in flow state

### FR-5: Confirmation & Submission

**Description**: The final step shows a summary and submits the journal entry.

**Screen Design**:
- **Title**: "Review Your Entry"
- **Summary Display**:
  - Primary emotion: [Layer] - [Phase] - [Dosage] - [Expression]
  - Secondary emotion: [Layer] - [Phase] - [Dosage] - [Expression] (if selected)
  - Strategy: [Strategy text] (if selected)
  - Timestamp: [formatted local time]
- **Action Buttons**:
  - "Log Entry" (primary) - submits to backend
  - "Edit" (secondary) - goes back to primary selection

**Submission**:
- Call `ContentViewModel.journal()` with:
  - `curriculumID: selectedPrimaryCurriculumID`
  - `secondaryCurriculumID: selectedSecondaryCurriculumID`
  - `strategyID: selectedStrategyID`
  - `initiatedBy: currentInitiatedBy`
- Show loading state during submission
- On success: Show success alert and dismiss flow
- On error: Show error alert and allow retry

**Acceptance Criteria**:
- [ ] All selected data is displayed in summary
- [ ] Timestamp is shown in local time
- [ ] "Log Entry" submits correctly
- [ ] Loading state is shown during submission
- [ ] Success dismisses flow and shows confirmation
- [ ] Error allows retry without losing data
- [ ] "Edit" button allows changing selections

### FR-6: Flow State Management

**Description**: The flow must maintain state across all steps and support navigation in both directions.

**Implementation**:
- Create `JournalFlowViewModel: ObservableObject`
  - `@Published var selectedPrimaryCurriculumID: Int?`
  - `@Published var selectedSecondaryCurriculumID: Int?`
  - `@Published var selectedStrategyID: Int?`
  - `@Published var initiatedBy: InitiatedBy`
  - `@Published var currentStep: FlowStep` (enum: primary, secondary, strategy, review)
  - `func reset()` - clears all state
  - `func canProceed(from step: FlowStep) -> Bool` - validates step completion
- Use `NavigationStack` with `navigationPath` for step management
- Ensure "Back" button works at each step
- Ensure data persists when going backward

**Acceptance Criteria**:
- [ ] State is maintained across all steps
- [ ] Going back preserves selections
- [ ] Validation prevents advancing without required data
- [ ] Flow can be cancelled at any step
- [ ] Cancelling resets all state

### FR-7: Entry Point Integration

**Description**: The new flow must be accessible from appropriate places in the app.

**Integration Points**:
1. **Menu**: Add "Log Emotion" option
2. **Notification Handling**: Route notification taps to flow with `initiatedBy = .scheduled`
3. **Preserve Existing Quick-Log**: Keep the existing (+) icon workflow for power users

**Acceptance Criteria**:
- [ ] "Log Emotion" appears in menu
- [ ] Tapping it opens the flow with `initiatedBy = .self_initiated`
- [ ] Notification tap opens flow with `initiatedBy = .scheduled`
- [ ] Existing (+) icon still works for quick logging
- [ ] Both flows coexist without conflicts

## Non-Functional Requirements

### NFR-1: Performance
- Flow screens must render within 100ms on Apple Watch Series 6+
- Navigation transitions should feel instant (<50ms perceived delay)
- No janky scrolling when browsing layers/phases

### NFR-2: Accessibility
- All steps must support VoiceOver with clear labels
- Buttons must meet minimum touch target sizes (44x44pt)
- Text must be readable at all Dynamic Type sizes

### NFR-3: Offline Support
- Flow should work offline using cached curriculum/strategies
- Queue submission if offline (future enhancement - out of MVP scope)
- Show clear error if submission fails

### NFR-4: Data Integrity
- No duplicate submissions (idempotency)
- Validate all IDs before submission
- Handle backend validation errors gracefully

## User Experience Flow Diagram

```
[Entry Point] ──> [Primary Selection] ──> [Secondary Selection] ──> [Strategy Selection] ──> [Review & Submit] ──> [Success]
      │                 │                         │                          │                      │               │
      │                 │                         │                          │                      │               └─> Dismiss Flow
      │                 │                         │                          │                      │
      │                 │                         │                          │                      └─> On Error: Show Alert, Allow Retry
      │                 │                         │                          │
      │                 │                         │                          └─> Back to Secondary
      │                 │                         │
      │                 │                         └─> Skip ──> [Review & Submit]
      │                 │                         └─> Back to Primary
      │                 │
      │                 └─> Back (Cancel Flow)
      │
      └─> Menu: initiatedBy = .self_initiated
      └─> Notification: initiatedBy = .scheduled
```

## Technical Architecture

### New Components

1. **LayerFilterMode.swift** (Foundation - implements FR-0)
   - Enum defining three filter modes: `.all`, `.emotionsOnly`, `.strategiesOnly`
   - Provides filtering logic for catalog layers
   - **Must be implemented first** - all other components depend on this

2. **JournalFlowViewModel.swift**
   - Manages flow state across all steps
   - Holds current `LayerFilterMode`
   - Provides `filteredLayers` computed property
   - Validates steps and coordinates with ContentViewModel for submission
   - Manages initial layer/phase selection when entering each step

3. **JournalFlowCoordinator.swift** (or integrate into existing view)
   - Owns NavigationStack
   - Presents flow as a sheet
   - Handles dismissal

4. **Flow Step Views**:
   - `PrimaryEmotionSelectionView.swift` - Uses layer/phase navigation with `.emotionsOnly` filter
   - `SecondaryEmotionPromptView.swift` - Skip prompt or navigates to picker with `.emotionsOnly` filter
   - `StrategySelectionView.swift` - Uses layer/phase navigation with `.strategiesOnly` filter (layer 0 only)
   - `JournalReviewView.swift` - Summary and submit

5. **Shared Components**:
   - `EmotionSummaryCard.swift` - Reusable card for displaying selected emotions
   - `JournalFlowButton.swift` - Consistent button styling for flow
   - `FilteredLayerNavigationView.swift` (optional) - Reusable wrapper for layer/phase navigation with filtering

### Modified Components

1. **ContentViewModel.swift** - Add layer filtering support (FR-0)
   - Add `layerFilterMode: LayerFilterMode` property (defaults to `.all`)
   - Add `filteredLayers` computed property
   - Refactor `journal()` to be called by JournalFlowViewModel or remain as-is

2. **ContentView.swift** - Update to use `filteredLayers` where appropriate
   - Layer/phase navigation components reference `filteredLayers`
   - Layer indicator adapts to filtered layer count
   - Digital crown range adapts to filtered layer count

3. **MenuView.swift** - Add "Log Emotion" navigation link

4. **NotificationDelegate.swift** - Route to flow instead of just setting initiatedBy

### Backend (No Changes Required)

The existing `/api/v1/journal` endpoint supports all required fields:
- `curriculum_id` (required) ✓
- `secondary_curriculum_id` (optional) ✓
- `strategy_id` (optional) ✓
- `initiated_by` (enum) ✓

## Testing Strategy

### Unit Tests

1. **JournalFlowViewModelTests**
   - Test state transitions
   - Test validation logic
   - Test reset behavior
   - Test initiatedBy tracking

2. **Flow Integration Tests**
   - Test complete flow from start to submit
   - Test back navigation preserves state
   - Test cancellation clears state
   - Test error handling

### UI Tests

1. **Flow Navigation Tests**
   - Can complete full flow
   - Can skip optional steps
   - Can go back at each step
   - Can cancel at any point

2. **Data Validation Tests**
   - Cannot select same curriculum twice
   - Cannot advance without required selections
   - Backend errors are displayed

### Manual Testing Scenarios

1. Happy path: Primary → Secondary → Strategy → Submit
2. Minimal path: Primary → Skip → Skip → Submit
3. Strategy only: Primary → Skip → Strategy → Submit
4. Error handling: Primary → Submit → Network Error → Retry
5. Back navigation: Primary → Secondary → Back → Change Primary
6. Cancellation: Primary → Secondary → Cancel

## Success Metrics

### Quantitative
- **Adoption Rate**: % of journal entries created via flow vs. quick-log
- **Completion Rate**: % of flows started that result in submission
- **Secondary Emotion Usage**: % of entries with secondary_curriculum_id
- **Strategy Logging**: % of entries with strategy_id
- **Error Rate**: % of submissions that fail
- **Time to Complete**: Average duration from flow start to submission

### Qualitative
- User feedback: Does the flow feel natural?
- Cognitive load: Is it easier to log emotions this way?
- Discoverability: Do users find the entry points?

## Out of Scope (Future Enhancements)

1. **Offline Queue**: Submissions are queued when offline and synced later
2. **Multiple Secondary Emotions**: Support >1 secondary emotion
3. **Free-Text Notes**: Add a notes field to journal entries
4. **Quick Edit**: Edit recent entries within 5 minutes
5. **Flow Templates**: Save common patterns (e.g., "Morning Anxiety Check")
6. **Emotional Journey View**: Visualize the flow selections before submitting
7. **Strategy Effectiveness Tracking**: Rate how well a strategy worked

## Open Questions

1. **Should we deprecate the quick-log (+) icon?**
   - *Proposal*: Keep it for power users, but make flow the primary path

2. **How do we handle extremely long strategy lists?**
   - *Proposal*: Show top 5-7 most relevant, with "Show All" expansion

3. **Should secondary selection be filtered by relevance to primary?**
   - *Proposal*: No filtering in MVP; show all layers/phases

4. **What happens if catalog is empty (offline, no cache)?**
   - *Proposal*: Show error state: "Cannot log emotion - curriculum not available"

5. **Should we show a "done logging for today" state if they've hit their schedule goals?**
   - *Proposal*: Out of scope for MVP; just show success

## Dependencies

1. **Existing Infrastructure**:
   - `ContentViewModel` for submission
   - `CatalogRepository` for curriculum/strategies
   - `JournalClient` for API calls
   - Layer/phase navigation components

2. **Design Assets**:
   - Button styles for flow
   - Card designs for emotion summaries
   - Success/error alert designs

3. **Documentation**:
   - User-facing: How to use the emotion logging flow
   - Developer-facing: How to extend the flow with new steps

## Risks & Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Flow is too long/tedious | High | Medium | Make all steps after primary optional; allow skip |
| Users prefer quick-log | Medium | Low | Keep both methods; track usage metrics |
| Navigation feels janky | High | Low | Test on real hardware; optimize animations |
| Backend submission fails | High | Low | Robust error handling; allow retry without data loss |
| State management bugs | Medium | Medium | Comprehensive unit tests; thorough manual testing |

## Acceptance Criteria (Epic Level)

This feature is complete when:

- [ ] All FR (Functional Requirements) acceptance criteria are met
- [ ] All NFR (Non-Functional Requirements) are validated
- [ ] Unit tests achieve >90% coverage for new code
- [ ] UI tests cover all critical paths
- [ ] Manual testing scenarios pass on real hardware
- [ ] Code review completed and approved
- [ ] Documentation updated (CLAUDE.md, README.md)
- [ ] Metrics tracking is in place

## Next Steps

**After approval of this spec**:

1. **Break down into implementation plan** - Task-level planning with parallelization
2. **Create GitHub issues** - One issue per atomic task
3. **Begin TDD implementation** - Tests first, then implementation
4. **Iterative PRs** - Small, focused PRs with all tests passing

---

**Document Status**: Draft
**Review Requested From**: User
**Pending Decisions**: Open Questions section
**Estimated Implementation**: 8-12 atomized PRs over 2-3 weeks
