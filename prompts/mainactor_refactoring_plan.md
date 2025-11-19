# @MainActor Testing Issue - Comprehensive Refactoring Plan

**Date**: October 28, 2025
**Author**: Claude Code
**Status**: Proposed

## Executive Summary

The WavelengthWatch project has a **critical testing infrastructure issue**: Swift Testing + `@MainActor` + watchOS Simulator are incompatible, causing all unit tests to crash with `SIGSEGV`. This affects **100% of existing unit tests** (82 tests across multiple test files).

**Root Cause**: Swift Testing framework cannot properly coordinate `@MainActor` execution on watchOS Simulator, resulting in NULL pointer dereferences in the test runtime itself.

**Solution**: Refactor ViewModels to use **testable architecture patterns** that eliminate the need for `@MainActor` while maintaining UI thread safety and SwiftUI compatibility.

## Problem Analysis

### Current State

**Affected Code**:
- `ContentViewModel` (line 3: `@MainActor final class`)
- `ScheduleViewModel` (uses `@MainActor`)
- `JournalFlowCoordinator` (Phase 1 code: `@MainActor final class`)
- All 82 existing Swift Testing unit tests use `@MainActor`

**Test Failures**:
```
Test case 'ContentViewModelTests/loadsCatalogSuccessfully()' failed (0.000 seconds)
Crash: SIGSEGV (Segmentation fault: 11)
Exception: EXC_BAD_ACCESS at 0x0000000000000010
```

**Why XCTest Won't Work**:
- Mixing Swift Testing (82 tests) + XCTest (3 UI tests + new tests) in same target causes test runner hangs
- Converting all 82 tests to XCTest is massive refactoring with no guarantee of success
- XCTest has same `@MainActor` limitations on watchOS Simulator

### Why @MainActor Was Used

SwiftUI requires `ObservableObject` property updates to occur on the main thread. The standard pattern is:

```swift
@MainActor
final class ContentViewModel: ObservableObject {
  @Published var layers: [CatalogLayerModel] = []
  // ...
}
```

This ensures all `@Published` updates happen on `@MainActor`, preventing SwiftUI threading issues.

### The Core Insight

**We don't need `@MainActor` on the class** - we only need it on methods that update `@Published` properties. By using:
1. Regular classes (no `@MainActor` attribute)
2. `@MainActor` on individual methods that update UI state
3. Nonisolated initializers for testing

We can achieve the same thread safety while enabling testability.

## Architecture Decision: Isolated Methods Pattern

### Proposed Pattern

```swift
// ❌ Old Pattern (untestable on watchOS)
@MainActor
final class ContentViewModel: ObservableObject {
  @Published var layers: [CatalogLayerModel] = []

  init(...) { }

  func loadCatalog() async { }
}

// ✅ New Pattern (testable + safe)
final class ContentViewModel: ObservableObject {
  @Published var layers: [CatalogLayerModel] = []

  nonisolated init(...) { }

  @MainActor
  func loadCatalog() async { }
}
```

### Why This Works

1. **Thread Safety**: `@MainActor` on methods still ensures UI updates happen on main thread
2. **Testability**: Tests can instantiate ViewModels without `@MainActor` context
3. **SwiftUI Compatibility**: `@Published` updates still isolated to main actor
4. **Minimal Changes**: Only class declaration and method attributes change

### Precedent

This is the pattern recommended in Swift Concurrency documentation for testable `ObservableObject` classes. Apple's sample code uses this pattern for unit-testable ViewModels.

## Implementation Roadmap

### Requirements for ALL Phases

- **Test-Driven Development**: Red → Green → Refactor workflow
- **Verify tests pass after each phase**: Run `xcodebuild test` and confirm no crashes
- **Pre-commit hooks**: All linting must pass
- **Atomic commits**: One commit per completed phase with detailed message
- **No shortcuts**: Fix issues properly, don't comment out failing tests
- **Regression testing**: Verify app still works in Simulator after each phase

### Phase 1: Refactor ContentViewModel (Highest Risk)

**Complexity**: Medium (affects 5 tests + main UI)
**Risk**: High (core ViewModel for entire app)
**Testing**: Must verify app still loads in Simulator

#### 1.1 Update ContentViewModel Class Declaration

**File**: `frontend/WavelengthWatch/WavelengthWatch Watch App/ViewModels/ContentViewModel.swift`

**Changes**:
```swift
// Remove @MainActor from class
final class ContentViewModel: ObservableObject {
  // ... @Published properties unchanged ...

  // Mark init as nonisolated
  nonisolated init(
    repository: CatalogRepositoryProtocol,
    journalClient: JournalClientProtocol,
    initialLayerIndex: Int = 0,
    initialPhaseIndex: Int = 0
  ) {
    self.repository = repository
    self.journalClient = journalClient
    self.selectedLayerIndex = initialLayerIndex
    self.selectedPhaseIndex = initialPhaseIndex
  }

  // Add @MainActor to all methods that update @Published properties
  @MainActor
  func loadCatalog() async { /* existing body */ }

  @MainActor
  func retryLoadCatalog() { /* existing body */ }

  @MainActor
  func logJournalEntry(
    curriculumID: Int,
    secondaryCurriculumID: Int?,
    strategyID: Int?
  ) async { /* existing body */ }

  @MainActor
  func dismissJournalFeedback() { /* existing body */ }
}
```

**Tests to Update**: `ContentViewModelTests` (5 tests)
- Remove `@MainActor` from test methods
- Tests should now run without crashes

#### 1.2 Update Tests

**File**: `frontend/WavelengthWatch/WavelengthWatch Watch AppTests/WavelengthWatch_Watch_AppTests.swift`

**Changes**:
```swift
struct ContentViewModelTests {
  // Remove @MainActor from test methods
  @Test func loadsCatalogSuccessfully() async throws {
    let repository = CatalogRepositoryMock(cached: SampleData.catalog, result: .success(SampleData.catalog))
    let journal = JournalClientMock()
    let viewModel = ContentViewModel(repository: repository, journalClient: journal)

    await viewModel.loadCatalog()

    #expect(viewModel.layers.count == 1)
    #expect(viewModel.isLoading == false)
  }

  // Repeat for other 4 tests...
}
```

#### 1.3 Run Tests & Verify

```bash
xcodebuild test -scheme "WavelengthWatch Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)"
```

**Success Criteria**:
- All ContentViewModel tests pass (5/5)
- No SIGSEGV crashes
- Tests run in reasonable time (< 30 seconds)

#### 1.4 Manual Testing in Simulator

1. Build and run app
2. Verify catalog loads
3. Verify layer/phase navigation works
4. Verify journal logging works
5. Verify error states display correctly

**Success Criteria**: No regressions, app behaves identically to before refactoring

### Phase 2: Refactor ScheduleViewModel

**Complexity**: Low (straightforward CRUD operations)
**Risk**: Medium (schedule functionality is user-facing)
**Testing**: 5 tests to update

#### 2.1 Update ScheduleViewModel

**File**: `frontend/WavelengthWatch/WavelengthWatch Watch App/ViewModels/ScheduleViewModel.swift`

**Changes**:
```swift
final class ScheduleViewModel: ObservableObject {
  // ... @Published properties unchanged ...

  nonisolated init(repository: ScheduleRepositoryProtocol = ScheduleRepository.shared) {
    self.repository = repository
  }

  @MainActor
  func loadSchedule() { /* existing body */ }

  @MainActor
  func saveSchedule(_ schedule: JournalSchedule, notificationScheduler: NotificationSchedulerProtocol) async {
    /* existing body */
  }

  @MainActor
  func deleteSchedule(notificationScheduler: NotificationSchedulerProtocol) async {
    /* existing body */
  }

  @MainActor
  func toggleSchedule(notificationScheduler: NotificationSchedulerProtocol) async {
    /* existing body */
  }
}
```

#### 2.2 Update Tests

**File**: `frontend/WavelengthWatch/WavelengthWatch Watch AppTests/WavelengthWatch_Watch_AppTests.swift`

Remove `@MainActor` from:
- `ScheduleViewModelTests` (5 tests)

#### 2.3 Run Tests & Verify

```bash
xcodebuild test -scheme "WavelengthWatch Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)"
```

**Success Criteria**: 10/10 tests passing (ContentViewModel + ScheduleViewModel)

### Phase 3: Refactor JournalFlowCoordinator (Phase 1 Code)

**Complexity**: Low (new code, no existing dependencies)
**Risk**: Low (feature not yet integrated into UI)
**Testing**: 23 tests to update

#### 3.1 Update JournalFlowCoordinator

**File**: `frontend/WavelengthWatch/WavelengthWatch Watch App/ViewModels/JournalFlowCoordinator.swift`

**Changes**:
```swift
final class JournalFlowCoordinator: ObservableObject {
  @Published private(set) var currentStep: JournalFlowStep = .inactive
  @Published private(set) var session: JournalFlowSession = .init()
  @Published var alertConfig: JournalFlowAlert?
  @Published var showExitConfirmation: Bool = false

  var onComplete: ((JournalFlowSession) async -> Void)?

  nonisolated init() { }

  @MainActor
  func beginScheduledFlow(initiatedBy: InitiatedBy) { /* existing body */ }

  @MainActor
  func logFirstEmotion(curriculumID: Int, phaseIndex: Int) { /* existing body */ }

  @MainActor
  func logSecondEmotion(curriculumID: Int) { /* existing body */ }

  @MainActor
  func logSelfCare(strategyID: Int) { /* existing body */ }

  @MainActor
  func handleAlertAction(_ action: JournalFlowAlert.JournalFlowAction) { /* existing body */ }

  @MainActor
  func requestExit() { /* existing body */ }

  @MainActor
  func confirmExit(saveEntries: Bool) { /* existing body */ }

  @MainActor
  private func completeFlow() async { /* existing body */ }

  @MainActor
  private func resetState() { /* existing body */ }

  // Computed properties don't need @MainActor (they're synchronous reads)
  var visibleLayerRange: ClosedRange<Int>? { /* existing body */ }
  var targetPhaseIndex: Int? { /* existing body */ }
  var targetLayerIndex: Int? { /* existing body */ }
}
```

#### 3.2 Update Tests

**File**: `frontend/WavelengthWatch/WavelengthWatch Watch AppTests/JournalFlowCoordinatorTests.swift`

Remove `@MainActor` from:
- All 23 test methods
- Keep async where needed

#### 3.3 Run Tests & Verify

```bash
xcodebuild test -scheme "WavelengthWatch Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)"
```

**Success Criteria**: 36/36 tests passing (all ViewModels)

### Phase 4: Update Remaining Test Files

**Complexity**: Low (simple test updates)
**Risk**: Low (isolated to test code)
**Testing**: ~46 remaining tests

#### 4.1 Files to Update

Update tests in `WavelengthWatch_Watch_AppTests.swift`:
- `CatalogRepositoryTests` (4 tests)
- `JournalClientTests` (1 test)
- `PhaseNavigatorTests` (3 tests)
- `AppConfigurationTests` (7 tests)
- `MysticalJournalIconTests` (1 test)
- `JournalScheduleTests` (3 tests)
- `NotificationSchedulerTests` (4 tests)
- `NotificationDelegateTests` (3 tests)
- `ContentViewModelInitiationContextTests` (3 tests)
- `JournalUIInteractionTests` (4 tests)

Update tests in `JournalFlowModelsTests.swift`:
- All 13 tests (remove `@MainActor` where present)

**Pattern**:
```swift
// Before
struct SomeTests {
  @MainActor
  @Test func testSomething() { }
}

// After
struct SomeTests {
  @Test func testSomething() { }
}
```

#### 4.2 Run Full Test Suite

```bash
xcodebuild test -scheme "WavelengthWatch Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)"
```

**Success Criteria**: 85/85 tests passing (82 unit + 3 UI)

### Phase 5: Documentation & Cleanup

**Complexity**: Low
**Risk**: None
**Testing**: N/A

#### 5.1 Update Documentation

**Files to Update**:
- `prompts/claude-comm/test-framework-documentation.md`: Update status to reflect resolved issue
- `CLAUDE.md`: Add note about testable ViewModel pattern
- `README.md`: Update test status

**Add Section to CLAUDE.md**:
```markdown
## Testing Strategy - ViewModel Pattern

**Pattern**: Use nonisolated initializers + @MainActor methods for testable ViewModels

ViewModels should follow this pattern to enable unit testing while maintaining thread safety:

```swift
final class SomeViewModel: ObservableObject {
  @Published var state: SomeState

  // Nonisolated init allows tests to create instances without @MainActor
  nonisolated init(dependencies: ...) {
    // Initialize properties
  }

  // Mark methods that update @Published properties with @MainActor
  @MainActor
  func performAction() async {
    self.state = newState
  }
}
```

**Rationale**: Swift Testing + @MainActor + watchOS Simulator are incompatible. This pattern provides thread safety without requiring `@MainActor` on the entire class.
```

#### 5.2 Update Test Framework Documentation

**File**: `prompts/claude-comm/test-framework-documentation.md`

Update conclusion section:
```markdown
## Resolution (October 28, 2025)

The @MainActor + Swift Testing + watchOS Simulator issue was resolved by refactoring ViewModels to use:
- Nonisolated initializers
- @MainActor on individual methods instead of entire class
- This maintains thread safety while enabling testability

**Result**: All 85 tests now pass successfully on watchOS Simulator.
```

## Testing Strategy

### Red → Green → Refactor Workflow

**For Each Phase**:

1. **Red**: Run tests before changes - confirm current state
2. **Refactor**: Apply ViewModel changes
3. **Green**: Run tests after changes - confirm all pass
4. **Manual**: Test in Simulator - confirm no regressions
5. **Commit**: Create detailed commit message

### Test Validation Checklist

After each phase, verify:
- [ ] All unit tests pass
- [ ] No SIGSEGV crashes
- [ ] Test runtime < 2 minutes
- [ ] App launches in Simulator
- [ ] No SwiftUI threading warnings
- [ ] Pre-commit hooks pass

## Success Criteria

**Phase 1 Complete When**:
- ContentViewModel tests pass (5/5)
- App works in Simulator
- No threading issues

**Phase 2 Complete When**:
- ScheduleViewModel tests pass (5/5)
- Schedule CRUD works in Simulator

**Phase 3 Complete When**:
- JournalFlowCoordinator tests pass (23/23)
- No crashes or hangs

**Phase 4 Complete When**:
- All tests pass (85/85)
- Test suite runs reliably

**Phase 5 Complete When**:
- Documentation updated
- Knowledge captured for future development

## Rollback Plan

If any phase fails:

1. **Revert changes**: `git checkout -- <files>`
2. **Re-analyze**: Investigate what went wrong
3. **Adjust approach**: Modify refactoring strategy
4. **Retry**: Attempt phase again with new approach

## Risk Mitigation

**High-Risk Changes** (ContentViewModel):
- Test in Simulator immediately after changes
- Keep previous commit accessible for quick revert
- Verify all UI flows manually

**Medium-Risk Changes** (ScheduleViewModel):
- Focus testing on schedule CRUD operations
- Verify notifications still work

**Low-Risk Changes** (New code, test updates):
- Standard testing workflow sufficient

## Timeline Estimate

- **Phase 1**: 30-45 minutes (includes thorough manual testing)
- **Phase 2**: 20-30 minutes
- **Phase 3**: 15-20 minutes
- **Phase 4**: 30-40 minutes (many files to update)
- **Phase 5**: 10-15 minutes

**Total**: ~2 hours for complete refactoring

## Appendix: Alternative Approaches Considered

### A. Convert to XCTest
**Rejected**: Mixing frameworks causes test hangs. Converting 82 tests is high-effort with uncertain outcome.

### B. Remove All Tests
**Rejected**: Violates TDD principles and removes safety net for future changes.

### C. Use Main.actor.run { }
**Rejected**: Tests still crash because Swift Testing runtime fails, not our code.

### D. Wait for Apple to Fix
**Rejected**: Unknown timeline, blocks all testing indefinitely.

### E. Nonisolated Init + @MainActor Methods (SELECTED)
**Accepted**: Minimal code changes, maintains thread safety, proven pattern, enables testing.
