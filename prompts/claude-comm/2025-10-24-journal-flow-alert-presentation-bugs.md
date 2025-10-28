# Journal Flow Alert Presentation Architecture - 2025-10-24

## Executive Summary

The journal entry logging flow suffers from **fundamental architecture flaws** that cause runtime warnings and undefined behavior. The current implementation fights against SwiftUI's declarative model by using imperative control flow to coordinate alerts across multiple view layers.

**Status**: Code compiles and tests pass, but produces 26+ runtime warnings during normal operation. These warnings indicate undefined behavior that Apple will convert to hard crashes in future watchOS releases.

**Priority**: CRITICAL - Must be fixed before App Store submission.

---

## Root Cause Analysis

### The Real Problem

The architecture attempts to coordinate a multi-step wizard flow (primary feeling → secondary prompt → self-care prompt → strategy selection) using:

1. **Multiple independent alert modifiers** across 4+ views (ContentView, CurriculumCard, StrategyListView, StrategyCard)
2. **Imperative state mutations** inside SwiftUI's render cycle
3. **No coordination layer** between alert presentation and navigation state changes

This creates race conditions where:
- Multiple alerts try to present simultaneously
- State changes happen during view updates
- Navigation hierarchy is torn down while alerts are presenting

### Current Architecture (Anti-Pattern)

```
ContentView
├─ .alert(journalFeedback)           ← Alert #1
├─ .alert(showSecondaryFeelingPrompt) ← Alert #2
├─ .alert(showSelfCarePrompt)         ← Alert #3
└─ NavigationStack
   └─ CurriculumDetailView
      └─ CurriculumCard
         └─ .alert(showingJournalConfirmation) ← Alert #4 (CONFLICT!)
```

**Problem**: When user taps a curriculum card:
1. Child view presents alert #4
2. Alert dismisses, triggers API call
3. ViewModel immediately sets `showSecondaryFeelingPrompt = true`
4. Parent view tries to present alert #2
5. **COLLISION**: Two alerts fighting for same view hierarchy

---

## Comprehensive Refactoring Plan

### Phase 1: Centralized Alert Orchestration (Core Fix)

**Goal**: Single source of truth for all alert state, ensuring only one alert presents at a time.

#### 1.1 Create Journal Flow State Machine

**Location**: `ViewModels/JournalFlowCoordinator.swift` (NEW FILE)

```swift
@MainActor
final class JournalFlowCoordinator: ObservableObject {
    // MARK: - Alert State

    enum AlertType: Identifiable, Equatable {
        case primaryConfirmation(CurriculumEntry)
        case secondaryFeelingPrompt
        case selfCarePrompt
        case strategyConfirmation(CatalogStrategyModel)
        case success(message: String)
        case error(message: String)

        var id: String {
            switch self {
            case .primaryConfirmation: return "primary"
            case .secondaryFeelingPrompt: return "secondary"
            case .selfCarePrompt: return "selfCare"
            case .strategyConfirmation: return "strategy"
            case .success: return "success"
            case .error: return "error"
            }
        }
    }

    @Published private(set) var activeAlert: AlertType?
    @Published private(set) var flowState: FlowState = .idle

    enum FlowState {
        case idle
        case selectingSecondary
        case selectingStrategy
    }

    // MARK: - Actions (NOT State Mutations)

    func requestPrimaryLog(_ entry: CurriculumEntry) {
        activeAlert = .primaryConfirmation(entry)
    }

    func handlePrimaryConfirmed(_ entry: CurriculumEntry) async {
        activeAlert = nil // Dismiss current alert

        // Wait for alert dismissal animation
        try? await Task.sleep(for: .milliseconds(300))

        // Perform API call
        await performJournalSubmission(entry)

        // Wait for API completion
        try? await Task.sleep(for: .milliseconds(200))

        // Present next prompt AFTER previous state settled
        activeAlert = .secondaryFeelingPrompt
    }

    func handleSecondaryResponse(wantsSecondary: Bool) {
        activeAlert = nil

        if wantsSecondary {
            flowState = .selectingSecondary
        } else {
            // Skip to self-care after brief delay
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                activeAlert = .selfCarePrompt
            }
        }
    }

    // ... similar pattern for all flow steps
}
```

**Key Principles**:
- ✅ Alert state is immutable from outside (private(set))
- ✅ All transitions go through async action methods
- ✅ Explicit delays for animation coordination
- ✅ No direct state mutation from views

#### 1.2 Update ContentViewModel

**Changes**: Delegate alert logic to coordinator

```swift
@MainActor
final class ContentViewModel: ObservableObject {
    @Published var layers: [CatalogLayerModel] = []
    // ... existing properties

    let flowCoordinator = JournalFlowCoordinator() // NEW

    // REMOVE: journalFeedback, showSecondaryFeelingPrompt, showSelfCarePrompt
    // REMOVE: All alert-related methods

    // Keep only data management logic
    func loadCatalog() async { ... }
    func journal(...) async { ... } // Simplified to just API call
}
```

#### 1.3 Refactor ContentView

**Before** (4 alert modifiers):
```swift
.alert(item: $viewModel.journalFeedback) { ... }
.alert("Secondary?", isPresented: $viewModel.showSecondaryFeelingPrompt) { ... }
.alert("Self-care?", isPresented: $viewModel.showSelfCarePrompt) { ... }
```

**After** (1 coordinated alert):
```swift
.alert(item: $viewModel.flowCoordinator.activeAlert) { alertType in
    makeAlert(for: alertType, coordinator: viewModel.flowCoordinator)
}

private func makeAlert(for type: JournalFlowCoordinator.AlertType,
                       coordinator: JournalFlowCoordinator) -> Alert {
    switch type {
    case .primaryConfirmation(let entry):
        return Alert(
            title: Text("Log Feeling"),
            message: Text("Log \"\(entry.expression)\"?"),
            primaryButton: .default(Text("Yes")) {
                Task { await coordinator.handlePrimaryConfirmed(entry) }
            },
            secondaryButton: .cancel()
        )
    case .secondaryFeelingPrompt:
        return Alert(
            title: Text("Add Secondary Feeling?"),
            message: Text("Would you like to log a second feeling?"),
            primaryButton: .default(Text("Yes")) {
                coordinator.handleSecondaryResponse(wantsSecondary: true)
            },
            secondaryButton: .default(Text("No")) {
                coordinator.handleSecondaryResponse(wantsSecondary: false)
            }
        )
    // ... handle all alert types
    }
}
```

---

### Phase 2: Remove Child View Alerts (Eliminate Conflicts)

#### 2.1 Convert CurriculumCard to Action-Based

**Before** (manages own alert):
```swift
struct CurriculumCard: View {
    @State private var showingJournalConfirmation = false // ❌

    var body: some View {
        // ...
        .alert("Log?", isPresented: $showingJournalConfirmation) { ... } // ❌
    }
}
```

**After** (emits action):
```swift
struct CurriculumCard: View {
    let entry: CurriculumEntry
    let onLogRequest: (CurriculumEntry) -> Void // ✅ Callback pattern

    var body: some View {
        // ...
        .onTapGesture {
            onLogRequest(entry) // ✅ Delegate to parent
        }
    }
}
```

#### 2.2 Update CurriculumDetailView

```swift
struct CurriculumDetailView: View {
    @EnvironmentObject var viewModel: ContentViewModel

    var body: some View {
        ScrollView {
            ForEach(phase.medicinal) { entry in
                CurriculumCard(entry: entry) { selectedEntry in
                    viewModel.flowCoordinator.requestPrimaryLog(selectedEntry)
                }
            }
        }
    }
}
```

#### 2.3 Apply Same Pattern to StrategyListView & StrategyCard

---

### Phase 3: Navigation Coordination (Prevent Detached Controller Warnings)

#### 3.1 Separate Navigation from Alert Logic

**Problem**: Current code clears `navigationPath` while alerts are active

**Solution**: Navigation becomes a side effect of flow state changes

```swift
// In ContentView
.onChange(of: viewModel.flowCoordinator.flowState) { _, newState in
    switch newState {
    case .idle:
        break
    case .selectingSecondary:
        // Alert already dismissed, safe to navigate
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            navigationPath = NavigationPath() // Clear to root
        }
    case .selectingStrategy:
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            navigationPath = NavigationPath()
            viewModel.selectedLayerIndex = 0 // Navigate to strategies
        }
    }
}
```

**Key**: Navigation happens AFTER alert state transitions, never during.

---

### Phase 4: Testing & Validation

#### 4.1 Unit Tests for Flow Coordinator

```swift
@Test func testPrimaryToSecondaryFlow() async throws {
    let coordinator = JournalFlowCoordinator()
    let entry = CurriculumEntry(id: 1, expression: "Test")

    // Request primary log
    coordinator.requestPrimaryLog(entry)
    #expect(coordinator.activeAlert == .primaryConfirmation(entry))

    // Confirm primary
    await coordinator.handlePrimaryConfirmed(entry)

    // Should show secondary prompt after delay
    try await Task.sleep(for: .milliseconds(600))
    #expect(coordinator.activeAlert == .secondaryFeelingPrompt)
}
```

#### 4.2 Integration Test for Full Flow

Run through complete user journey in simulator with console monitoring:
1. Log primary feeling
2. Accept secondary prompt
3. Select secondary feeling
4. Accept self-care prompt
5. Select strategy
6. Verify success

**Success Criteria**: Zero warnings in console output.

---

## Implementation Timeline

### Week 1: Foundation
- [ ] Create `JournalFlowCoordinator.swift`
- [ ] Implement alert state machine
- [ ] Write unit tests for coordinator
- [ ] Update ContentViewModel to use coordinator

### Week 2: View Layer
- [ ] Refactor ContentView alert system
- [ ] Convert CurriculumCard to action-based
- [ ] Convert StrategyListView to action-based
- [ ] Remove all child view alert modifiers

### Week 3: Navigation & Polish
- [ ] Implement navigation coordination
- [ ] Add integration tests
- [ ] Full flow testing in simulator
- [ ] Console validation (zero warnings)

### Week 4: Review & Documentation
- [ ] Code review for SwiftUI best practices
- [ ] Update architecture documentation
- [ ] Performance testing
- [ ] Final QA pass

---

## Design Principles for Future Development

### 1. **Unidirectional Data Flow**
Views receive state, emit actions. Never mutate @Published properties from views.

```swift
// ❌ BAD: View mutates ViewModel
Button("Tap") { viewModel.showAlert = true }

// ✅ GOOD: View calls action method
Button("Tap") { viewModel.requestAlert() }
```

### 2. **Coordinator Pattern for Complex Flows**
Multi-step wizards get dedicated coordinator objects that manage state transitions.

### 3. **Single Alert per View Hierarchy**
Never have multiple `.alert()` modifiers in parent-child relationship. Always use enum-based alert state.

### 4. **Async Coordination for Timing**
Use explicit `Task.sleep()` delays for animation coordination, not implicit timers.

### 5. **Testable by Default**
All flow logic lives in pure Swift objects (@MainActor classes), not in views. Views are thin presentation layer.

---

## Appendix: Current Alert Locations

### Before Refactoring
1. `ContentView.swift:202` - `.alert(item: $viewModel.journalFeedback)`
2. `ContentView.swift:224` - `.alert("Pick a secondary feeling?")`
3. `ContentView.swift:243` - `.alert("Log what self-care?")`
4. `ContentView.swift:1185` - `CurriculumCard.alert("Log Medicine/Toxic")`
5. `ContentView.swift:1007` - `StrategyListView.alert("Log Strategy")`
6. `ContentView.swift:1300` - `StrategyCard.alert("Log Strategy")`

### After Refactoring
1. `ContentView.swift` - Single `.alert(item: $viewModel.flowCoordinator.activeAlert)`

**Result**: 6 → 1 alert modifier, zero conflicts, predictable behavior.

---

## References

- [SwiftUI Alert Best Practices](https://developer.apple.com/documentation/swiftui/alert)
- [Coordinator Pattern in SwiftUI](https://www.swiftbysundell.com/articles/navigation-in-swiftui/)
- [Managing State in SwiftUI](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)
- Apple's "Publishing changes from within view updates" warning documentation

---

**Document Status**: Comprehensive refactoring plan approved and ready for implementation.
**Last Updated**: 2025-10-24
**Author**: Claude Code
**Reviewer**: Geoff Gallinger
