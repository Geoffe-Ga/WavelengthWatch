# Bug Report: [Brief Title - State Issue]

**Date:** YYYY-MM-DD
**Reporter:** [Your Name]
**Category:** State Management
**Status:** 🔴 New

---

## Bug Summary

[One sentence description of the state issue]

---

## Severity & Priority

**Severity:** [Choose one]
- 🔴 Critical - State corruption, data loss, app crashes
- 🟠 High - Incorrect state causes wrong behavior
- 🟡 Medium - State inconsistency, UI out of sync
- 🟢 Low - Minor state issue

**Priority:** [Choose one]
- P0 - Fix immediately before any release
- P1 - Fix before next release
- P2 - Fix in upcoming release
- P3 - Nice to have

---

## Environment

**Device/Simulator:**
- [ ] 41mm Apple Watch Series 9
- [ ] 45mm Apple Watch Series 9
- [ ] 49mm Apple Watch Ultra 2

**Software:**
- watchOS Version: [e.g., 10.0]
- Xcode Version: [e.g., 16.4]
- Build/Commit: [SHA or branch name]

---

## State Type

**What kind of state is affected?**

- [ ] View state (@State)
- [ ] ViewModel state (@StateObject, @ObservableObject)
- [ ] Environment state (@EnvironmentObject, @Environment)
- [ ] App state (@AppStorage, UserDefaults)
- [ ] Navigation state (NavigationStack, sheet presentation)
- [ ] Binding state (@Binding)
- [ ] Global state (singletons, static)
- [ ] Other: _________________

---

## Steps to Reproduce

1. [First step - describe initial state]
2. [Second step - describe state change]
3. [Third step]
4. [Continue until state issue appears]

**Example:**
1. Launch app - selectedLayerIndex = 0
2. Navigate to Purple layer (index 2) using Digital Crown
3. ViewModel.selectedLayerIndex updates to 2
4. Navigate to detail view
5. Return to main view
6. Observe selectedLayerIndex value

---

## Expected State

[Describe what the state should be]

**Expected State Values:**

```swift
// Expected state after reproduction steps
selectedLayerIndex: 2
selectedPhaseIndex: 1
showingMenu: false
isShowingDetailView: false
```

---

## Actual State

[Describe what the state actually is]

**Actual State Values:**

```swift
// Actual state after reproduction steps
selectedLayerIndex: 0  // ❌ WRONG - Should be 2
selectedPhaseIndex: 1  // ✅ Correct
showingMenu: false     // ✅ Correct
isShowingDetailView: false  // ✅ Correct
```

---

## Visual Evidence

### Screenshots

**Location:** `prompts/claude-comm/bugs/screenshots/[issue-name]/`

- [ ] Screenshot showing UI reflecting wrong state
- [ ] Screenshot of Xcode debugger showing state values
- [ ] Screenshot of console logs showing state changes

### Video

- [ ] Screen recording showing state issue: `[filename].mov`
- [ ] Duration: [X seconds]

---

## State Lifecycle

**Trace state changes:**

| Step | Action | Expected State | Actual State | Notes |
|------|--------|---------------|--------------|-------|
| 1 | Launch app | index: 0 | index: 0 | ✅ Correct |
| 2 | Navigate to Purple | index: 2 | index: 2 | ✅ Correct |
| 3 | Enter detail view | index: 2 | index: 2 | ✅ Correct |
| 4 | Exit detail view | index: 2 | index: 0 | ❌ Reset! |

**When does state become incorrect?**

- [ ] Immediately after specific action
- [ ] After time delay: _______ seconds
- [ ] After view transition
- [ ] After app backgrounding
- [ ] After force quit
- [ ] After specific sequence of actions

---

## State Persistence

**Should state persist?**

- [ ] Yes - across app launches (@AppStorage, UserDefaults)
- [ ] Yes - across view transitions (@StateObject, @EnvironmentObject)
- [ ] No - local to view (@State)

**Does it persist correctly?**

- [ ] Yes - Persists as expected
- [ ] No - Lost when it shouldn't be
- [ ] No - Persists when it shouldn't
- [ ] Partially - Some state persists, some doesn't

**UserDefaults check:**

```bash
# Check stored values
defaults read guru.aptitude.WavelengthWatch
```

**UserDefaults values:**

```
selectedLayerIndex = [value]
selectedPhaseIndex = [value]
[other relevant keys]
```

---

## State Synchronization

**Are multiple state sources out of sync?**

**ViewModel State:**
```swift
viewModel.selectedLayerIndex: [value]
viewModel.selectedPhaseIndex: [value]
```

**View State:**
```swift
layerSelection: [value]
phaseSelection: [value]
```

**UserDefaults:**
```
selectedLayerIndex: [value]
selectedPhaseIndex: [value]
```

**Which is correct?**

- [ ] ViewModel has correct state
- [ ] View has correct state
- [ ] UserDefaults has correct state
- [ ] None have correct state

---

## Bindings & Data Flow

**Is this a binding issue?**

- [ ] Yes - @Binding not updating
- [ ] Yes - Two-way binding broken
- [ ] No - Not related to bindings

**Data flow:**

```
Source → [Steps] → Destination

Example:
layerSelection → onChange → viewModel.selectedLayerId → ViewModel updates → storedLayerIndex
```

**Where does data flow break?**

[Identify which step in the flow fails]

---

## Race Conditions

**Could this be a race condition?**

- [ ] Yes - Multiple async updates
- [ ] Yes - Timing-dependent behavior
- [ ] No - Deterministic issue

**If yes, describe timing:**

[Describe the timing of competing state updates]

**Example:**
```
Time: 0ms  - User swipes to new phase
Time: 5ms  - phaseSelection updates
Time: 10ms - onChange fires
Time: 15ms - ViewModel updates
Time: 20ms - View returns from detail view, resets state ❌
```

---

## Console Logs

**Relevant console output:**

```
[Paste console output showing state changes]
```

**State-related warnings:**

```
[Paste any warnings about state, bindings, or publishers]
```

---

## Code Locations

**Suspected files:**

- [ ] File: _____________ - Lines: _______ - State: _____________
- [ ] File: _____________ - Lines: _______ - State: _____________

**State management code:**

```swift
// Paste relevant state management code
@State private var layerSelection: Int
@StateObject private var viewModel: ContentViewModel

.onChange(of: layerSelection) { _, newValue in
  // ...
}
```

**Suspected causes:**

- [ ] Missing state update
- [ ] Race condition
- [ ] Incorrect binding
- [ ] State reset in wrong place
- [ ] Lifecycle issue (onAppear/onDisappear)
- [ ] Publisher cancellation
- [ ] Environment object lost
- [ ] UserDefaults not saving
- [ ] Other: _________________

---

## Related Issues

**GitHub Issues:**
- Related to: #______
- Duplicate of: #______
- Blocks: #______
- Blocked by: #______

**Pull Requests:**
- Introduced in: PR #______
- Fixed in: PR #______ (if applicable)

---

## User Impact

**How does this affect users?**

[Describe the impact on user experience]

**Consequences:**

- [ ] User loses navigation position
- [ ] User input lost
- [ ] UI displays wrong data
- [ ] User has to redo actions
- [ ] App appears broken
- [ ] Other: _________________

---

## Data Integrity

**Is user data at risk?**

- [ ] Yes - Data could be lost
- [ ] Yes - Data could be corrupted
- [ ] No - UI issue only
- [ ] Unknown

**If yes, describe risk:**

[What data could be affected?]

---

## Workaround

**Is there a temporary workaround?**

[Describe any way to work around this issue]

**Example:**
Force quit and relaunch the app. State will be restored from UserDefaults to the last saved position.

---

## Regression

- [ ] This worked correctly before
- [ ] This is a new feature
- [ ] Unknown

**If regression, when did it break?**

- Commit/PR: [SHA or PR number]
- What changed: [Brief description]

---

## Suggested Fix

**Proposed solution:**

[If you have ideas for how to fix this, describe them here]

**Example:**
1. Add state restoration in onAppear that checks UserDefaults
2. Remove state reset in onDisappear (causing the bug)
3. Add @MainActor annotation to ensure state updates on main thread
4. Add synchronization between layerSelection and viewModel
5. Add state validation/consistency checks

**Files to modify:**

- [ ] File: _____________ - Change: _____________
- [ ] File: _____________ - Change: _____________

---

## Test Coverage

**Are there tests for this state management?**

- [ ] Yes, tests exist
- [ ] No, tests needed
- [ ] Unknown

**Tests to add/fix:**

**Example:**
```swift
@Test func testStatePersiststhroughDetailViewNavigation() async {
  // Given selectedLayerIndex = 2
  // When user navigates to detail view
  // And returns to main view
  // Then selectedLayerIndex should still be 2
}

@Test func testStateRestoration() async {
  // Given app with saved state
  // When app relaunches
  // Then state should restore correctly
}
```

---

## Reproduction Rate

**How often does this occur?**

- [ ] Always (100%)
- [ ] Frequently (>75%)
- [ ] Sometimes (25-75%)
- [ ] Rarely (<25%)
- [ ] Timing-dependent

---

## Checklist

- [ ] Bug reproduced at least twice
- [ ] State values captured (before/after)
- [ ] Console logs captured
- [ ] UserDefaults checked
- [ ] Data flow traced
- [ ] All relevant information filled out
- [ ] GitHub issue created: #______
- [ ] Related issues linked

---

## Notes

[Any additional notes, observations, or context about the state issue]
