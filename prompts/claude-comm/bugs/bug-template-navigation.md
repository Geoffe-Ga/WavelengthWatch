# Bug Report: [Brief Title - Navigation Issue]

**Date:** YYYY-MM-DD
**Reporter:** [Your Name]
**Category:** Navigation
**Status:** 🔴 New

---

## Bug Summary

[One sentence description of the navigation issue]

---

## Severity & Priority

**Severity:** [Choose one]
- 🔴 Critical - Cannot navigate, feature blocked
- 🟠 High - Navigation broken or incorrect
- 🟡 Medium - Navigation works but is unintuitive
- 🟢 Low - Minor navigation polish

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

## Navigation Type

**What kind of navigation is affected?**

- [ ] Vertical scrolling (layers)
- [ ] Horizontal scrolling (phases)
- [ ] Detail view navigation (push/pop)
- [ ] Sheet presentation (menu, modals)
- [ ] Tab navigation
- [ ] Back button
- [ ] Gesture navigation (swipe)
- [ ] Digital Crown
- [ ] Other: _________________

---

## Steps to Reproduce

1. [First step - be specific]
2. [Second step - include navigation action]
3. [Third step]
4. [Continue until issue appears]

**Example:**
1. Launch app
2. Swipe left to navigate through phases
3. Reach the last phase ("Clearing")
4. Swipe left one more time
5. Observe navigation behavior

---

## Expected Behavior

[What should happen when navigating]

**Example:**
After swiping left from the last phase, the app should wrap around to the first phase ("Rising") with a smooth transition.

---

## Actual Behavior

[What actually happens during navigation]

**Example:**
After swiping left from the last phase, the view freezes for 2 seconds, then jumps abruptly to the first phase. No transition animation plays.

---

## Visual Evidence

### Screenshots

**Location:** `prompts/claude-comm/bugs/screenshots/[issue-name]/`

- [ ] Screenshot of starting state
- [ ] Screenshot of ending state (incorrect)
- [ ] Screenshot showing navigation UI elements

### Video

- [ ] Screen recording showing the navigation issue: `[filename].mov`
- [ ] Duration: [X seconds]
- [ ] Shows the full navigation flow

---

## Navigation State

**Current navigation state when bug occurs:**

**Layer:**
- Starting layer: [e.g., Purple]
- Expected ending layer: [e.g., Purple]
- Actual ending layer: [e.g., Red]

**Phase:**
- Starting phase: [e.g., Rising]
- Expected ending phase: [e.g., Peaking]
- Actual ending phase: [e.g., Rising]

**View Stack:**
- Expected stack depth: [e.g., 2 views]
- Actual stack depth: [e.g., 3 views]

---

## Input Method

**How is navigation triggered?**

- [ ] Digital Crown rotation
  - Direction: [Clockwise/Counter-clockwise]
  - Speed: [Slow/Normal/Fast]

- [ ] Swipe gesture
  - Direction: [Up/Down/Left/Right]
  - Speed: [Slow/Normal/Fast]

- [ ] Button tap
  - Button: [e.g., "View Details", "Back"]

- [ ] Navigation bar button
- [ ] Other: _________________

---

## Frequency & Timing

**When does this occur?**

- [ ] Always (100%)
- [ ] After specific sequence
- [ ] After X seconds: _______
- [ ] Only on first launch
- [ ] Only after returning from detail view
- [ ] Intermittently
- [ ] Other: _________________

**Timing:**
- Delay before navigation: [X seconds]
- Duration of animation: [X seconds]
- Total time affected: [X seconds]

---

## Affected Areas

**Which navigation paths are affected?**

- [ ] Layer scrolling (vertical)
- [ ] Phase scrolling (horizontal)
- [ ] Main view → Detail view
- [ ] Detail view → Main view
- [ ] Main view → Menu
- [ ] Menu → Menu items
- [ ] Menu → Journal flow
- [ ] Journal flow steps
- [ ] Other: _________________

---

## State Consistency

**Navigation state issues:**

- [ ] Visual state doesn't match data state
- [ ] Selection indicator incorrect
- [ ] Back button appears when it shouldn't
- [ ] Navigation bar title wrong
- [ ] App state out of sync
- [ ] UserDefaults not updated
- [ ] ViewModel state incorrect

---

## Code Locations

**Suspected files:**

- [ ] `ContentView.swift` - Lines: _______
- [ ] `PhaseNavigator.swift` - Lines: _______
- [ ] `ContentViewModel.swift` - Lines: _______
- [ ] Navigation handlers: _______
- [ ] Other: _________________

**Suspected causes:**

- [ ] Race condition in state updates
- [ ] Missing state synchronization
- [ ] Incorrect index calculation
- [ ] onChange handler issue
- [ ] Gesture conflict
- [ ] Animation issue
- [ ] Other: _________________

---

## Related Issues

**GitHub Issues:**
- Related to: #______
- Blocks: #______
- Blocked by: #______

**Pull Requests:**
- Introduced in: PR #______
- Fixed in: PR #______ (if applicable)

---

## Workaround

**Is there a temporary workaround?**

[Describe any way to work around this issue]

**Example:**
Navigate using Digital Crown instead of swipe gestures. Crown rotation still works correctly.

---

## User Impact

**How does this affect users?**

[Describe the impact on user experience]

**Can users still navigate?**
- [ ] Yes, with workaround
- [ ] Yes, but experience is poor
- [ ] No, completely blocked

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
1. Add debouncing to swipe gesture handler
2. Ensure phase index updates synchronously
3. Add transition animation with consistent duration
4. Verify wrapping logic in PhaseNavigator

**Files to modify:**

- [ ] `ContentView.swift`
- [ ] `PhaseNavigator.swift`
- [ ] Other: _________________

---

## Test Coverage

**Are there tests for this navigation path?**

- [ ] Yes, tests exist but may be incorrect
- [ ] No, tests don't cover this path
- [ ] Unknown

**Tests to add:**

[List test cases that should be added]

---

## Reproduction Rate

**How often does this occur?**

- [ ] Always (100%)
- [ ] Frequently (>75%)
- [ ] Sometimes (25-75%)
- [ ] Rarely (<25%)
- [ ] Once

---

## Checklist

- [ ] Bug reproduced at least twice
- [ ] Video recording captured
- [ ] Navigation state documented
- [ ] All relevant information filled out
- [ ] GitHub issue created: #______
- [ ] Related issues linked

---

## Notes

[Any additional notes, observations, or context about the navigation issue]
