# Schedule Notification & Multi-Emotion Logging Feature - Implementation Plan

## Executive Summary

After analyzing the WavelengthWatch codebase, I recommend implementing the multi-emotion logging flow using **SwiftUI environment-based state management** combined with a dedicated **JournalFlowCoordinator** object. This approach leverages existing patterns in the codebase while maintaining clean separation of concerns.

The app is a **watchOS-native SwiftUI application** (not React Native as initially assumed in the requirements). It uses `@StateObject`, `@Published`, and `@EnvironmentObject` for state management, native SwiftUI `NavigationStack` for navigation, and protocols for dependency injection. The implementation will introduce a flow coordinator that temporarily overrides navigation constraints during scheduler-initiated journaling sessions.

**Key Architecture Decision**: Rather than building a separate modal stack, we'll enhance the existing navigation system with **environment-based flow state** that controls layer visibility and tracks multi-step journal entries. This maintains consistency with the app's current architecture while enabling the constrained navigation required for the feature.

## Architecture Decision: Flow Coordinator Pattern

### Rationale

The codebase already demonstrates excellent SwiftUI patterns:
- **ObservableObject ViewModels**: `ContentViewModel` and `ScheduleViewModel` manage domain logic
- **Environment-based state**: Custom `EnvironmentKey` for `isShowingDetailView` (ContentView.swift:10-18)
- **Protocol-based architecture**: `JournalClientProtocol`, `NotificationSchedulerProtocol` enable testability
- **State persistence**: `@AppStorage` for layer/phase selection (ContentView.swift:46-47)

The proposed solution fits naturally into this architecture by introducing:

1. **`JournalFlowState` ObservableObject**: Manages multi-emotion logging session state
2. **Environment injection**: Similar to existing `isShowingDetailView` pattern
3. **View modifiers**: Conditionally filter visible layers based on flow state
4. **Existing navigation**: No new navigation paradigm required

### Why Not Alternative Approaches?

| Approach | Why Not |
|----------|---------|
| **Separate Modal Stack** | Introduces navigation complexity; harder to reuse existing layer/phase rendering logic |
| **Global State Enum** | Lacks encapsulation; harder to test and maintain side effects |
| **Navigation Wrapper Views** | Breaks existing gesture/scroll behavior; requires extensive refactoring |
| **State Machine Library** | Overkill for this flow; adds external dependency |

### SwiftUI Best Practices Alignment

This approach follows Apple's documented patterns:
- **Data flow**: Single source of truth (`@StateObject`) with derived state
- **Environment**: Cross-cutting concerns (flow constraints) injected via `@EnvironmentObject`
- **View composition**: Modifier-based behavior augmentation
- **Lifecycle**: Clear entry/exit points with proper state cleanup

## Codebase Analysis Findings

### 1. Navigation Architecture

**Implementation**: Dual-axis TabView system (ContentView.swift:45-721)

**Vertical Navigation (Layers)**:
- `ScrollView(.vertical)` with `LazyVStack` containing `LayerCardView` instances (ContentView.swift:200-227)
- Digital Crown rotation support (ContentView.swift:227-244)
- `@AppStorage("selectedLayerIndex")` persists current layer (ContentView.swift:46)
- Layer indicator overlay shows current position (ContentView.swift:325-387)

**Horizontal Navigation (Phases)**:
- Each `LayerView` wraps a `TabView(.page)` (ContentView.swift:456-491)
- `PhaseNavigator` utility provides wraparound behavior (PhaseNavigator.swift:1-36)
- Renders `phaseCount + 2` pages to enable circular scrolling (ContentView.swift:457)
- Page indicator overlay (ContentView.swift:493-515)

**Key Files**:
- `ContentView.swift`: Main navigation container
- `PhaseNavigator.swift`: Phase index math utilities
- `ContentViewModel.swift`: Layer/phase selection state

### 2. Schedule/Notification System

**Implementation**: UNUserNotificationCenter-based (WavelengthWatchApp.swift:8-99, NotificationScheduler.swift:1-103)

**Notification Flow**:
1. **Schedule Creation**: User creates `JournalSchedule` with time/days (ScheduleSettingsView.swift:147-258)
2. **Notification Scheduling**: `NotificationScheduler` creates `UNCalendarNotificationTrigger` for each day (NotificationScheduler.swift:63-101)
3. **Notification Delivery**: System delivers notification with `userInfo` payload including `scheduleId` and `"initiatedBy": "scheduled"` (NotificationScheduler.swift:70-78)
4. **Response Handling**: `NotificationDelegateShim` forwards to `NotificationDelegate` (WavelengthWatchApp.swift:76-90)
5. **State Update**: `NotificationDelegate.scheduledNotificationReceived` published (WavelengthWatchApp.swift:54-73)
6. **ContentView Integration**: `onChange(of: notificationDelegate.scheduledNotificationReceived)` sets `initiatedBy` in ContentViewModel (ContentView.swift:151-156)

**Current State**:
- Notifications deliver successfully
- `currentInitiatedBy` correctly set to `.scheduled` in `ContentViewModel` (ContentViewModel.swift:88-90)
- Journal submissions use this value (ContentViewModel.swift:71)
- **Missing**: UI constraints and multi-step flow

**Key Files**:
- `WavelengthWatchApp.swift`: App initialization, notification category setup
- `NotificationScheduler.swift`: Notification scheduling logic
- `ScheduleViewModel.swift`: Schedule CRUD operations
- `ScheduleSettingsView.swift`: Schedule management UI

### 3. Journal/Logging System

**Backend Schema** (models.py:120-162):
```python
class Journal(SQLModel, table=True):
    id: int | None
    created_at: datetime
    user_id: int
    curriculum_id: int                    # Required: primary emotion
    secondary_curriculum_id: int | None   # Optional: second emotion
    strategy_id: int | None               # Optional: self-care strategy
    initiated_by: InitiatedBy             # SELF or SCHEDULED
```

**Frontend Flow**:
1. User taps journal icon on `CurriculumCard` or `StrategyCard`
2. Alert confirmation shown (ContentView.swift:813-827, 1049-1064)
3. `ContentViewModel.journal()` called (ContentViewModel.swift:64-86)
4. `JournalClient.submit()` sends POST to `/api/v1/journal` (JournalClient.swift:80-95)
5. Success/failure feedback via alert (ContentView.swift:135-150)
6. `currentInitiatedBy` reset to `.self_initiated` after submission (ContentViewModel.swift:80, 84)

**Current Capabilities**:
- ✅ Single emotion logging with optional strategy
- ✅ `InitiatedBy` tracking
- ✅ Database schema supports `secondary_curriculum_id`
- ❌ No UI for multi-emotion selection
- ❌ No guided flow structure

**Key Files**:
- `JournalClient.swift`: HTTP client for journal API
- `ContentViewModel.swift`: Journal submission orchestration
- `ContentView.swift`: Journal UI (alerts, icon buttons)

### 4. State Management Patterns

The app uses **standard SwiftUI state management** without external frameworks:

**ObservableObject ViewModels**:
- `ContentViewModel` (ContentViewModel.swift:3-103)
  - `@Published` properties for layers, phases, loading state, journal feedback
  - Injected as `@EnvironmentObject` in ContentView (ContentView.swift:170)
  - Protocol-based dependencies (`CatalogRepositoryProtocol`, `JournalClientProtocol`)

- `ScheduleViewModel` (ScheduleViewModel.swift:4-77)
  - `@Published var schedules: [JournalSchedule]`
  - Manages persistence to `UserDefaults`
  - Coordinates with `NotificationSchedulerProtocol`

- `NotificationDelegate` (WavelengthWatchApp.swift:54-74)
  - `@Published var scheduledNotificationReceived: ScheduledNotification?`
  - Single-purpose: bridge notification system to app state

**Local View State**:
- `@State` for transient UI (menu visibility, alerts, loading indicators)
- `@AppStorage` for persistence (`selectedLayerIndex`, `selectedPhaseIndex`)

**Environment Propagation**:
- Custom `EnvironmentKey` for `isShowingDetailView` (ContentView.swift:10-18)
- Used to control menu button visibility (ContentView.swift:174)

**Pattern for This Feature**:
- New `JournalFlowCoordinator` as `@StateObject` in ContentView
- Injected via `@EnvironmentObject` to child views
- Tracks multi-step flow state and logged emotion IDs

### 5. Database Schema & Relationships

**Relevant Tables** (models.py:1-173):

**Curriculum** (lines 61-86):
- `id`, `layer_id`, `phase_id`, `dosage` (Medicinal/Toxic), `expression`
- Relationships: `layer`, `phase`, `journal_entries`, `secondary_journal_entries`

**Strategy** (lines 88-118):
- `id`, `strategy`, `layer_id`, `color_layer_id`, `phase_id`
- Relationships: `layer`, `color_layer`, `phase`, `journal_entries`

**Journal** (lines 120-162):
- Primary key: `id`
- Foreign keys: `curriculum_id` (required), `secondary_curriculum_id` (optional), `strategy_id` (optional)
- Relationships loaded eagerly in API responses (backend/routers/journal.py)

**Phase Linkage**:
- Each `Curriculum` entry has a `phase_id` (models.py:66)
- Frontend can navigate to the corresponding phase by:
  1. Looking up `curriculum.phase_id` from first logged emotion
  2. Mapping to `phaseOrder` index in `ContentViewModel.phaseOrder` (ContentViewModel.swift:6)
  3. Setting `selectedPhaseIndex` and `layerSelection = 0` to show Layer 0 (Self-Care)

### 6. UI/UX Patterns & Components

**Alert Pattern**: Standard SwiftUI `.alert()` modifiers (ContentView.swift:813-827)
```swift
.alert("Log Strategy", isPresented: $showingConfirmation) {
  Button("Yes") { /* action */ }
  Button("Cancel", role: .cancel) {}
} message: {
  Text("Would you like to log...?")
}
```

**Sheet Pattern**: `.sheet(isPresented:)` for modal presentation (ContentView.swift:157-168)
```swift
.sheet(isPresented: $showingMenu) {
  NavigationStack { MenuView() }
}
```

**NavigationLink**: For push navigation to detail views (ContentView.swift:695-719)
```swift
NavigationLink(destination: destinationView) {
  Image(systemName: "chevron.right.circle.fill")
}
```

**Overlays**: Non-interactive indicators (layer indicator, page indicator)
- Layer indicator: Trailing capsule with position (ContentView.swift:325-387)
- Page indicator: Bottom dot pagination (ContentView.swift:493-515)

**Reusable Components**:
- `MysticalJournalIcon`: Animated "+" icon (ContentView.swift:975-1005)
- `CurriculumCard`: Medicinal/Toxic feeling cards (ContentView.swift:913-973)
- `StrategyCard`: Self-care strategy rows (ContentView.swift:1007-1066)

## Implementation Roadmap

### Phase 1: Foundation (JournalFlowCoordinator & State Models)

**Complexity**: Low (~100 LOC)
**Depends On**: None
**Testing**: Unit tests for state transitions

#### 1.1 Create `Models/JournalFlowModels.swift`

**Purpose**: Define flow state and session data structures

```swift
import Foundation

/// Represents the current step in the scheduler-initiated journal flow
enum JournalFlowStep: Equatable {
  case inactive                    // Normal app usage
  case selectingFirstEmotion      // Scheduler-initiated: choose from Layers 1-10
  case promptForSecondEmotion     // Alert: "Log another emotion?"
  case selectingSecondEmotion     // Choosing second emotion from Layers 1-10
  case promptForSelfCare          // Alert: "Log self-care?"
  case selectingSelfCare          // Choosing strategy from Layer 0
}

/// Container for emotions/strategies logged during a session
struct JournalFlowSession: Equatable {
  var firstEmotionCurriculumID: Int?
  var firstEmotionPhaseID: Int?
  var secondEmotionCurriculumID: Int?
  var selectedStrategyID: Int?
  var initiatedBy: InitiatedBy = .self_initiated

  var hasFirstEmotion: Bool { firstEmotionCurriculumID != nil }
  var hasSecondEmotion: Bool { secondEmotionCurriculumID != nil }
  var hasSelfCare: Bool { selectedStrategyID != nil }
}

/// Alert prompt configuration for flow transitions
struct JournalFlowAlert: Identifiable, Equatable {
  let id = UUID()
  let title: String
  let message: String
  let primaryAction: JournalFlowAction
  let secondaryAction: JournalFlowAction

  enum JournalFlowAction: Equatable {
    case continueToSecondEmotion
    case skipToSelfCarePrompt
    case continueToSelfCare
    case finishFlow
    case cancelFlow
  }
}
```

**File Location**: `/frontend/WavelengthWatch/WavelengthWatch Watch App/Models/JournalFlowModels.swift`

**Tests to Add** (`tests/frontend/JournalFlowModelsTests.swift`):
- ✅ Session property computed values (`hasFirstEmotion`, etc.)
- ✅ `JournalFlowStep` equality
- ✅ Alert action handling

#### 1.2 Create `ViewModels/JournalFlowCoordinator.swift`

**Purpose**: Orchestrate multi-step flow logic and layer filtering

```swift
import Foundation
import SwiftUI

@MainActor
final class JournalFlowCoordinator: ObservableObject {
  @Published private(set) var currentStep: JournalFlowStep = .inactive
  @Published private(set) var session: JournalFlowSession = JournalFlowSession()
  @Published var alertConfig: JournalFlowAlert?
  @Published var showExitConfirmation: Bool = false

  /// Returns the range of layers visible for the current step
  var visibleLayerRange: ClosedRange<Int>? {
    switch currentStep {
    case .inactive:
      return nil  // No filtering, all layers visible
    case .selectingFirstEmotion, .selectingSecondEmotion:
      return 1...10  // Hide Layer 0 (Self-Care)
    case .selectingSelfCare:
      return 0...0  // Only Layer 0 visible
    case .promptForSecondEmotion, .promptForSelfCare:
      return nil  // Alerts don't navigate
    }
  }

  /// Start flow from scheduler notification
  func beginScheduledFlow(initiatedBy: InitiatedBy) {
    session = JournalFlowSession(initiatedBy: initiatedBy)
    currentStep = .selectingFirstEmotion
  }

  /// User selected first emotion
  func logFirstEmotion(curriculumID: Int, phaseID: Int) {
    session.firstEmotionCurriculumID = curriculumID
    session.firstEmotionPhaseID = phaseID
    currentStep = .promptForSecondEmotion

    alertConfig = JournalFlowAlert(
      title: "Log Another Emotion?",
      message: "Would you like to log a second emotion?",
      primaryAction: .continueToSecondEmotion,
      secondaryAction: .skipToSelfCarePrompt
    )
  }

  /// User selected second emotion
  func logSecondEmotion(curriculumID: Int) {
    session.secondEmotionCurriculumID = curriculumID
    currentStep = .promptForSelfCare

    alertConfig = JournalFlowAlert(
      title: "Log Self-Care?",
      message: "Would you like to log self-care for these feelings?",
      primaryAction: .continueToSelfCare,
      secondaryAction: .finishFlow
    )
  }

  /// User selected self-care strategy
  func logSelfCare(strategyID: Int) {
    session.selectedStrategyID = strategyID
    // Flow completes after self-care selection
  }

  /// Handle alert button actions
  func handleAlertAction(_ action: JournalFlowAlert.JournalFlowAction) {
    alertConfig = nil

    switch action {
    case .continueToSecondEmotion:
      currentStep = .selectingSecondEmotion
    case .skipToSelfCarePrompt:
      promptForSelfCare()
    case .continueToSelfCare:
      currentStep = .selectingSelfCare
    case .finishFlow:
      completeFlow()
    case .cancelFlow:
      cancelFlow()
    }
  }

  /// User tapped X button during flow
  func requestExit() {
    if currentStep != .inactive {
      showExitConfirmation = true
    }
  }

  /// Confirmed exit
  func confirmExit(saveEntries: Bool) {
    if saveEntries {
      completeFlow()
    } else {
      cancelFlow()
    }
  }

  // MARK: - Private

  private func promptForSelfCare() {
    currentStep = .promptForSelfCare

    alertConfig = JournalFlowAlert(
      title: "Log Self-Care?",
      message: "Would you like to log self-care for these feelings?",
      primaryAction: .continueToSelfCare,
      secondaryAction: .finishFlow
    )
  }

  private func completeFlow() {
    currentStep = .inactive
    session = JournalFlowSession()
    showExitConfirmation = false
  }

  private func cancelFlow() {
    currentStep = .inactive
    session = JournalFlowSession()
    showExitConfirmation = false
  }
}
```

**File Location**: `/frontend/WavelengthWatch/WavelengthWatch Watch App/ViewModels/JournalFlowCoordinator.swift`

**Tests to Add** (`tests/frontend/JournalFlowCoordinatorTests.swift`):
- ✅ `beginScheduledFlow()` sets correct step and session
- ✅ `logFirstEmotion()` transitions to prompt
- ✅ `visibleLayerRange` returns correct ranges for each step
- ✅ `handleAlertAction()` transitions correctly
- ✅ Exit confirmation flow

**Integration Points**:
- Injected into ContentView as `@StateObject`
- Accessed by journal buttons via `@EnvironmentObject`

---

### Phase 2: Navigation Constraints & Flow Triggering

**Complexity**: Medium (~150 LOC)
**Depends On**: Phase 1
**Testing**: Integration tests for navigation filtering

#### 2.1 Modify `ContentView.swift`: Inject FlowCoordinator

**Changes**:
1. Add `@StateObject` for `JournalFlowCoordinator` (after line 48)
2. Inject as `@EnvironmentObject` (near line 170)
3. Respond to notification state changes to trigger flow
4. Filter layers based on `visibleLayerRange`

**Specific Edits**:

**Edit 1**: Add flow coordinator property
```swift
// After line 48 (@StateObject private var viewModel: ContentViewModel)
@StateObject private var flowCoordinator = JournalFlowCoordinator()
```

**Edit 2**: Observe notification and start flow
```swift
// Replace lines 151-156 (existing onChange for scheduledNotificationReceived)
.onChange(of: notificationDelegate.scheduledNotificationReceived) { _, newValue in
  if let notification = newValue {
    viewModel.setInitiatedBy(notification.initiatedBy)
    flowCoordinator.beginScheduledFlow(initiatedBy: notification.initiatedBy)
    notificationDelegate.clearNotificationState()
  }
}
```

**Edit 3**: Filter visible layers
```swift
// Inside layeredContent, replace line 202 (ForEach(viewModel.layers.indices...))
ForEach(filteredLayerIndices, id: \.self) { index in
  // ... existing LayerCardView rendering
}

// Add computed property before body
private var filteredLayerIndices: [Int] {
  guard let range = flowCoordinator.visibleLayerRange else {
    return Array(viewModel.layers.indices)
  }
  return viewModel.layers.indices.filter { index in
    let layerID = viewModel.layers[index].id
    return range.contains(layerID)
  }
}
```

**Edit 4**: Inject environment object
```swift
// Replace line 170 (.environmentObject(viewModel))
.environmentObject(viewModel)
.environmentObject(flowCoordinator)
```

**Edit 5**: Handle exit button during flow
```swift
// Replace floating menu button logic (lines 174-193)
if !isShowingDetailView {
  VStack {
    HStack {
      // Exit button during flow
      if flowCoordinator.currentStep != .inactive {
        Button {
          flowCoordinator.requestExit()
        } label: {
          Image(systemName: "xmark.circle")
            .font(.system(size: UIConstants.menuButtonSize))
            .foregroundColor(.red.opacity(0.7))
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .padding(.leading, 8)
        .padding(.top, 4)
      } else {
        // Normal menu button
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
      }
      Spacer()
    }
    Spacer()
  }
}
```

**Edit 6**: Add exit confirmation alert
```swift
// After the journal feedback alert (after line 150)
.alert("Exit Flow?", isPresented: $flowCoordinator.showExitConfirmation) {
  Button("Save & Exit") {
    flowCoordinator.confirmExit(saveEntries: true)
  }
  Button("Discard") {
    flowCoordinator.confirmExit(saveEntries: false)
  }
  Button("Cancel", role: .cancel) {}
} message: {
  Text("Would you like to save your entries or discard them?")
}
```

**File**: `ContentView.swift`
**Lines Modified**: ~15 lines added, ~30 lines modified
**Risk**: Medium (touches core navigation loop)

**Tests to Add**:
- ✅ Layer filtering works correctly for each step
- ✅ Exit button appears/disappears based on flow state
- ✅ Navigation to scheduled flow triggers correct state

#### 2.2 Create `Views/JournalFlowAlertView.swift`

**Purpose**: Reusable alert view for flow prompts

```swift
import SwiftUI

extension View {
  func journalFlowAlert(
    config: Binding<JournalFlowAlert?>,
    onAction: @escaping (JournalFlowAlert.JournalFlowAction) -> Void
  ) -> some View {
    self.alert(
      config.wrappedValue?.title ?? "",
      isPresented: Binding(
        get: { config.wrappedValue != nil },
        set: { if !$0 { config.wrappedValue = nil } }
      )
    ) {
      Button(primaryButtonTitle(for: config.wrappedValue?.primaryAction)) {
        if let action = config.wrappedValue?.primaryAction {
          onAction(action)
        }
      }
      Button(secondaryButtonTitle(for: config.wrappedValue?.secondaryAction), role: .cancel) {
        if let action = config.wrappedValue?.secondaryAction {
          onAction(action)
        }
      }
    } message: {
      Text(config.wrappedValue?.message ?? "")
    }
  }

  private func primaryButtonTitle(for action: JournalFlowAlert.JournalFlowAction?) -> String {
    switch action {
    case .continueToSecondEmotion: return "Yes"
    case .continueToSelfCare: return "Yes"
    case .finishFlow: return "Done"
    default: return "OK"
    }
  }

  private func secondaryButtonTitle(for action: JournalFlowAlert.JournalFlowAction?) -> String {
    switch action {
    case .skipToSelfCarePrompt, .finishFlow: return "No"
    case .cancelFlow: return "Cancel"
    default: return "Dismiss"
    }
  }
}
```

**File Location**: `/frontend/WavelengthWatch/WavelengthWatch Watch App/Views/JournalFlowAlertView.swift`

**Usage in ContentView**:
```swift
// Add after other alerts
.journalFlowAlert(config: $flowCoordinator.alertConfig) { action in
  flowCoordinator.handleAlertAction(action)
}
```

---

### Phase 3: Multi-Emotion Journal Submission

**Complexity**: Medium (~100 LOC)
**Depends On**: Phase 1, Phase 2
**Testing**: Integration tests with mock API client

#### 3.1 Extend `ContentViewModel.swift`: Add Multi-Entry Submission

**Current Method** (ContentViewModel.swift:64-86):
```swift
func journal(
  curriculumID: Int,
  secondaryCurriculumID: Int? = nil,
  strategyID: Int? = nil,
  initiatedBy: InitiatedBy? = nil
) async
```

**Change**: Repurpose existing method (already supports `secondaryCurriculumID`)

**New Method**: Add batch completion for flow coordinator
```swift
// Add to ContentViewModel
func completeJournalFlow(session: JournalFlowSession) async {
  guard let primaryID = session.firstEmotionCurriculumID else { return }

  await journal(
    curriculumID: primaryID,
    secondaryCurriculumID: session.secondEmotionCurriculumID,
    strategyID: session.selectedStrategyID,
    initiatedBy: session.initiatedBy
  )
}
```

**File**: `ContentViewModel.swift`
**Lines Added**: ~10 lines
**Risk**: Low (leverages existing API)

**Tests to Add**:
- ✅ `completeJournalFlow()` calls `journal()` with correct params
- ✅ Session data maps to API payload correctly

#### 3.2 Modify `JournalFlowCoordinator.swift`: Trigger Submission

**Change**: Wire completion to ContentViewModel

```swift
// Update completeFlow() method
private func completeFlow() {
  // Trigger submission via callback
  onComplete?(session)

  currentStep = .inactive
  session = JournalFlowSession()
  showExitConfirmation = false
}

// Add property
var onComplete: ((JournalFlowSession) async -> Void)?
```

**Wire in ContentView** (during initialization):
```swift
flowCoordinator.onComplete = { session in
  await viewModel.completeJournalFlow(session: session)
}
```

**File**: `JournalFlowCoordinator.swift`, `ContentView.swift`
**Lines Modified**: ~10 lines
**Risk**: Low

#### 3.3 Update Journal Button Behavior

**Change**: Integrate with flow coordinator when active

**Edit `CurriculumCard`** (ContentView.swift:913-973):
```swift
// Replace onTapGesture (line 953)
.onTapGesture {
  if flowCoordinator.currentStep == .selectingFirstEmotion {
    flowCoordinator.logFirstEmotion(curriculumID: /* extract ID */, phaseID: /* extract ID */)
  } else if flowCoordinator.currentStep == .selectingSecondEmotion {
    flowCoordinator.logSecondEmotion(curriculumID: /* extract ID */)
  } else {
    // Normal behavior: show confirmation
    showingJournalConfirmation = true
  }
}
```

**Similar changes** for:
- `StrategyCard` (ContentView.swift:1007-1066)
- `StrategyListView` tappable items (ContentView.swift:783-788)

**Challenge**: Extracting `phase_id` from curriculum entry
- **Solution**: Pass `phase` object to `CurriculumCard` (already available in context)

**File**: `ContentView.swift`
**Lines Modified**: ~30 lines across multiple card components
**Risk**: Medium (changes tap behavior logic)

**Tests to Add**:
- ✅ Tapping during flow updates coordinator state
- ✅ Normal taps still show confirmation alerts
- ✅ Correct curriculum/phase IDs passed to coordinator

---

### Phase 4: Self-Care Navigation

**Complexity**: Medium (~80 LOC)
**Depends On**: Phase 3
**Testing**: UI tests for navigation behavior

#### 4.1 Automatic Phase Navigation

**Requirement**: When entering `.selectingSelfCare` step, navigate to Layer 0 at the phase of the first logged emotion.

**Implementation in `JournalFlowCoordinator`**:
```swift
// Expose navigation target
var targetPhaseIndex: Int? {
  guard currentStep == .selectingSelfCare,
        let phaseID = session.firstEmotionPhaseID else {
    return nil
  }
  return phaseID  // Assume phase ID maps to index (validate with phase order)
}

var targetLayerIndex: Int? {
  guard currentStep == .selectingSelfCare else { return nil }
  return 0  // Layer 0 = Self-Care
}
```

**Wire into ContentView**:
```swift
// Add after flowCoordinator state changes
.onChange(of: flowCoordinator.currentStep) { _, newStep in
  if newStep == .selectingSelfCare {
    if let layerIndex = flowCoordinator.targetLayerIndex {
      layerSelection = layerIndex
    }
    if let phaseIndex = flowCoordinator.targetPhaseIndex {
      phaseSelection = phaseIndex + 1  // Account for TabView offset
    }
  }
}
```

**Challenge**: Mapping `phase_id` to `phaseOrder` index
- **Solution**: ContentViewModel already has `phaseOrder: [String]` (ContentViewModel.swift:6)
- Need to map phase ID → phase name → index in phaseOrder
- **Workaround**: Store phase index (not ID) in session during `logFirstEmotion()`

**Updated `JournalFlowSession`**:
```swift
struct JournalFlowSession: Equatable {
  var firstEmotionCurriculumID: Int?
  var firstEmotionPhaseIndex: Int?  // Store index directly
  // ...
}
```

**File**: `JournalFlowCoordinator.swift`, `ContentView.swift`, `JournalFlowModels.swift`
**Lines Modified**: ~20 lines
**Risk**: Medium (navigation state coordination)

**Tests to Add**:
- ✅ Navigation jumps to correct layer/phase
- ✅ Phase index calculation matches expected phase

---

### Phase 5: Testing & Edge Cases

**Complexity**: Medium (~300 LOC tests)
**Depends On**: All previous phases
**Testing**: Comprehensive integration and UI tests

#### 5.1 Unit Tests

**New Test Files**:

1. **`JournalFlowModelsTests.swift`**
   - Session property calculations
   - Equatable conformance

2. **`JournalFlowCoordinatorTests.swift`**
   - State transition logic
   - Visible layer range calculation
   - Alert action handling
   - Exit confirmation flow

3. **`ContentViewModelJournalFlowTests.swift`**
   - `completeJournalFlow()` integration
   - Session data mapping

**Test Strategy**: Use existing protocol-based architecture for mocking
- Mock `JournalClientProtocol` to verify payloads
- Mock `NotificationDelegate` to trigger flows

#### 5.2 Integration Tests

**Scenarios**:
1. ✅ Full flow: Notification → First emotion → Second emotion → Self-care → Submission
2. ✅ Partial flow: Notification → First emotion → Skip second → Self-care → Submission
3. ✅ Minimal flow: Notification → First emotion → Skip all → Submission
4. ✅ Exit without save: Notification → First emotion → X → Discard
5. ✅ Exit with save: Notification → First emotion → Second emotion → X → Save

**Testing Challenges**:
- **Challenge**: SwiftUI view testing on watchOS
- **Solution**: Extract logic into testable ViewModels; use XCTest with view model state assertions

#### 5.3 Edge Cases

**Identified Edge Cases**:

| Edge Case | Handling Strategy |
|-----------|------------------|
| **App backgrounded mid-flow** | Preserve state in `@StateObject` (automatic); consider persisting to `UserDefaults` if flow should survive app termination |
| **Second notification while in flow** | Ignore via `currentStep != .inactive` guard in `beginScheduledFlow()` |
| **User force-quits app** | Accept data loss; prompt on next open if persisted |
| **API failure during submission** | Show error alert; keep flow active; allow retry |
| **Network unavailable** | Existing error handling in `ContentViewModel.journal()` (line 82) |
| **Empty curriculum data** | Validate during catalog load; prevent flow start if data missing |
| **Phase ID mismatch** | Defensive phase index bounds checking |

**Recommended Additions**:

1. **Guard in `beginScheduledFlow()`**:
```swift
func beginScheduledFlow(initiatedBy: InitiatedBy) {
  guard currentStep == .inactive else {
    // Already in a flow; ignore
    return
  }
  // ...
}
```

2. **API Error Recovery**:
```swift
// In ContentViewModel.journal()
catch {
  journalFeedback = JournalFeedback(kind: .failure("..."))
  // DO NOT reset currentInitiatedBy if in a flow
  if flowCoordinator?.currentStep == .inactive {
    currentInitiatedBy = .self_initiated
  }
}
```

3. **Persistence Option** (Optional Enhancement):
```swift
// In JournalFlowCoordinator
private let persistenceKey = "com.wavelengthwatch.activeJournalFlow"

func persistState() {
  let encoder = JSONEncoder()
  if let data = try? encoder.encode(session) {
    UserDefaults.standard.set(data, forKey: persistenceKey)
  }
}

func restoreState() {
  guard let data = UserDefaults.standard.data(forKey: persistenceKey) else { return }
  let decoder = JSONDecoder()
  if let restored = try? decoder.decode(JournalFlowSession.self, from: data) {
    session = restored
    // Restore step based on session state
  }
}
```

---

### Phase 6: UI Polish & Accessibility

**Complexity**: Low (~50 LOC)
**Depends On**: Phase 4
**Testing**: Manual accessibility audit

#### 6.1 Visual Indicators

**Flow Active Indicator**: Show subtle UI hint that a scheduled flow is in progress

**Implementation**:
```swift
// In ContentView, overlay indicator
if flowCoordinator.currentStep != .inactive {
  VStack {
    HStack {
      Spacer()
      Text("Scheduled Check-In")
        .font(.caption2)
        .foregroundColor(.blue.opacity(0.7))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
          Capsule()
            .fill(Color.blue.opacity(0.2))
        )
        .padding(.top, 4)
        .padding(.trailing, 8)
    }
    Spacer()
  }
}
```

**File**: `ContentView.swift`
**Lines Added**: ~15 lines

#### 6.2 Accessibility

**VoiceOver Support**:
- Add `.accessibilityLabel()` to flow-specific buttons
- Announce flow state changes with `.accessibilityAnnouncement()`

**Example**:
```swift
// Exit button
.accessibilityLabel("Exit scheduled check-in")
.accessibilityHint("Double-tap to exit the current flow")

// Flow indicator
.accessibilityElement(children: .combine)
.accessibilityLabel("Scheduled check-in in progress")
```

**Haptic Feedback**:
```swift
// On flow transitions
WKInterfaceDevice.current().play(.notification)
```

**File**: `ContentView.swift`
**Lines Added**: ~10 lines

---

## File-by-File Change Summary

| File | Type | Lines Modified | Complexity | Description |
|------|------|---------------|-----------|-------------|
| `Models/JournalFlowModels.swift` | New | ~100 | Low | Flow state enums, session model, alert config |
| `ViewModels/JournalFlowCoordinator.swift` | New | ~150 | Medium | Flow orchestration logic |
| `Views/JournalFlowAlertView.swift` | New | ~50 | Low | Reusable alert view modifier |
| `ContentView.swift` | Modify | ~80 | High | Layer filtering, flow integration, exit button |
| `ContentViewModel.swift` | Modify | ~15 | Low | Batch journal submission method |
| `CurriculumCard` (in ContentView) | Modify | ~15 | Medium | Flow-aware tap handling |
| `StrategyCard` (in ContentView) | Modify | ~15 | Medium | Flow-aware tap handling |
| `StrategyListView` (in ContentView) | Modify | ~10 | Medium | Flow-aware tap handling |
| **Total New Code** | | ~300 LOC | | |
| **Total Modified Code** | | ~135 LOC | | |

---

## Testing Strategy

### Unit Test Coverage

**New Test Files** (watchOS target test scheme):
1. `JournalFlowModelsTests.swift` (~50 LOC)
2. `JournalFlowCoordinatorTests.swift` (~150 LOC)
3. `ContentViewModelFlowTests.swift` (~50 LOC)

**Mocking Strategy**:
- Leverage existing `JournalClientProtocol` for API mocking
- Mock `CatalogRepositoryProtocol` for layer/phase data
- No new dependencies required

### Integration Test Scenarios

**Critical Paths**:
1. ✅ **Happy Path**: Notification → First → Second → Self-Care → Submit → Success
2. ✅ **Skip Second**: Notification → First → No → Self-Care → Submit
3. ✅ **Skip All**: Notification → First → No → No → Submit
4. ✅ **Exit & Save**: Notification → First → X → Save → Submit
5. ✅ **Exit & Discard**: Notification → First → Second → X → Discard → Cleanup

**Validation Points**:
- Layer filtering matches step
- Navigation jumps to correct phase
- API payload includes all logged IDs
- State cleanup on completion

### Manual Testing Checklist

**Functional**:
- [ ] Notification triggers flow correctly
- [ ] Layer 0 hidden during emotion selection
- [ ] Layers 1-10 hidden during self-care selection
- [ ] Phase navigation jumps to correct phase
- [ ] Exit button appears/disappears correctly
- [ ] Alerts show correct messages
- [ ] Journal submission includes all data

**Edge Cases**:
- [ ] Rapid notification taps (ignore duplicates)
- [ ] Backgrounding during flow (state preserved)
- [ ] API failure (error shown, flow remains active)
- [ ] Empty curriculum data (flow disabled)

**UI/UX**:
- [ ] Animations smooth during layer filtering
- [ ] No visual glitches when layers hide/show
- [ ] Alerts readable on small watch screen
- [ ] VoiceOver announces flow state

---

## Potential Risks & Mitigations

### Risk 1: Layer Filtering Performance

**Issue**: Filtering layers during ScrollView iteration could impact scroll performance

**Mitigation**:
- Use `LazyVStack` (already implemented)
- Compute `filteredLayerIndices` once per step change (not per render)
- Profile with Instruments to validate

**Rollback**: If performance degrades, use conditional rendering with `if` statements instead of filtering

### Risk 2: Navigation State Conflicts

**Issue**: Programmatic navigation (jumping to Layer 0) may conflict with user gestures

**Mitigation**:
- Disable Digital Crown during `.selectingSelfCare` step
- Add `.disabled()` modifier to layer ScrollView
- Show visual indicator that navigation is locked

**Code**:
```swift
.scrollDisabled(flowCoordinator.currentStep == .selectingSelfCare)
.digitalCrownRotation(..., isEnabled: flowCoordinator.currentStep == .inactive)
```

### Risk 3: Data Loss on App Termination

**Issue**: Force-quit during flow loses in-progress session

**Mitigation** (Optional):
- Implement `persistState()` in `JournalFlowCoordinator`
- Call on `scenePhase` changes (`.onChange(of: scenePhase)`)
- Prompt user to resume on next launch

**Decision**: Start without persistence; add if user feedback indicates need

### Risk 4: Phase ID → Index Mapping

**Issue**: Backend phase IDs may not map directly to frontend `phaseOrder` indices

**Mitigation**:
- Store `phaseIndex` (not `phaseID`) in session
- Pass index from `LayerView` context (already knows current phase)
- Validate mapping in tests

**Defensive Code**:
```swift
let safeIndex = min(max(phaseIndex, 0), viewModel.phaseOrder.count - 1)
```

### Risk 5: Concurrent Notifications

**Issue**: Multiple notifications firing simultaneously

**Mitigation**:
- Guard in `beginScheduledFlow()` (ignore if `currentStep != .inactive`)
- UNUserNotificationCenter naturally serializes delivery
- Notification actions require foreground (`.foreground` option)

---

## Open Questions for Developer

### Architecture Decisions

**Q1**: Should partial flows persist across app restarts?
- **Options**: (A) Yes, save to `UserDefaults` (B) No, accept data loss
- **Recommendation**: Start with (B); add (A) if user testing shows frustration

**Q2**: Should users be able to cancel the flow mid-step and return to normal navigation without saving?
- **Current**: Yes, via X button with discard option
- **Alternative**: Force completion once started
- **Recommendation**: Keep current flexible approach

**Q3**: Should the "scheduled check-in" indicator be persistent or auto-hide?
- **Options**: (A) Always visible (B) Auto-hide after 3s (C) Only show on layer scroll
- **Recommendation**: (A) for clarity during flow

### UI/UX Refinements

**Q4**: What should happen if the user swipes to a hidden layer during flow?
- **Current**: Layer filtered out, not scrollable
- **Alternative**: Show disabled state with overlay message
- **Recommendation**: Current (cleaner UX)

**Q5**: Should there be a "Resume Flow" prompt if the user backgrounds the app?
- **Options**: (A) Yes, on foreground (B) No, assume context preserved
- **Recommendation**: (B) initially; (A) if user feedback indicates confusion

**Q6**: Should the self-care phase navigation be animated or instant?
- **Options**: (A) Instant jump (B) Animated scroll
- **Recommendation**: (B) with `.easeInOut` for better orientation

### Data & API

**Q7**: How should the system handle missing phase data (e.g., curriculum entry without phase)?
- **Current**: Defensive `guard let` checks
- **Alternative**: Crash with assertion in debug builds
- **Recommendation**: Current (graceful degradation)

**Q8**: Should the journal API response trigger any additional UI (beyond success alert)?
- **Options**: (A) No, current alert is sufficient (B) Show submitted data summary
- **Recommendation**: (A); summary could be future analytics feature

---

## Appendix: Code Structure Recommendations

### Project Organization

```
WavelengthWatch Watch App/
├── Models/
│   ├── CatalogModels.swift (existing)
│   ├── JournalSchedule.swift (existing)
│   └── JournalFlowModels.swift (NEW)
├── ViewModels/
│   ├── ContentViewModel.swift (modify)
│   ├── ScheduleViewModel.swift (existing)
│   └── JournalFlowCoordinator.swift (NEW)
├── Views/
│   ├── ContentView.swift (modify)
│   ├── ScheduleSettingsView.swift (existing)
│   └── JournalFlowAlertView.swift (NEW)
├── Services/
│   ├── JournalClient.swift (existing)
│   ├── NotificationScheduler.swift (existing)
│   └── ... (existing)
└── WavelengthWatchApp.swift (existing)
```

### Naming Conventions

**Consistency with Existing Code**:
- View models: `*ViewModel` suffix
- Coordinators: `*Coordinator` suffix
- Models: Plain nouns (`JournalFlowSession`, not `JournalFlowSessionModel`)
- Protocols: `*Protocol` suffix (existing pattern)

### Protocol Extraction (Future)

**Optional Refactor** for testability:
```swift
protocol JournalFlowCoordinating: ObservableObject {
  var currentStep: JournalFlowStep { get }
  var session: JournalFlowSession { get }
  func beginScheduledFlow(initiatedBy: InitiatedBy)
  func logFirstEmotion(curriculumID: Int, phaseID: Int)
  // ...
}

extension JournalFlowCoordinator: JournalFlowCoordinating {}
```

**Benefit**: Easier to mock in ContentView tests
**Cost**: Adds complexity for marginal gain
**Recommendation**: Wait until testing reveals need

---

## Implementation Timeline Estimate

| Phase | Description | Estimated Time | Dependencies |
|-------|-------------|----------------|--------------|
| 1 | Foundation models & coordinator | 2-3 hours | None |
| 2 | Navigation constraints & flow triggering | 3-4 hours | Phase 1 |
| 3 | Multi-emotion journal submission | 2-3 hours | Phase 1, 2 |
| 4 | Self-care phase navigation | 2 hours | Phase 3 |
| 5 | Testing & edge cases | 4-5 hours | All phases |
| 6 | UI polish & accessibility | 1-2 hours | Phase 4 |
| **Total** | | **14-19 hours** | |

**Recommended Approach**: Implement phases sequentially with testing between each phase. Validate navigation behavior manually after Phase 2 before proceeding.

---

## Conclusion

This implementation plan provides a **SwiftUI-idiomatic solution** that:
- ✅ Leverages existing architecture patterns (`@StateObject`, `@EnvironmentObject`, protocols)
- ✅ Requires minimal refactoring (~430 total LOC, mostly new code)
- ✅ Maintains separation of concerns (flow logic in coordinator, UI in views)
- ✅ Supports all required features (multi-emotion, self-care, exit handling)
- ✅ Handles edge cases gracefully (concurrent notifications, data errors)
- ✅ Provides clear testing strategy with protocol-based mocking

The **key architectural insight** is using environment-based state propagation rather than separate navigation stacks, which keeps the implementation aligned with existing code patterns and reduces integration risk.

**Next Steps**:
1. Review open questions with stakeholders
2. Begin Phase 1 implementation
3. Test navigation filtering behavior early (Phase 2)
4. Validate phase ID → index mapping with real data
5. Conduct accessibility audit after Phase 6
