# Bug Report: [Brief Title - Functional Issue]

**Date:** YYYY-MM-DD
**Reporter:** [Your Name]
**Category:** Functionality
**Status:** 🔴 New

---

## Bug Summary

[One sentence description of what's not working]

---

## Severity & Priority

**Severity:** [Choose one]
- 🔴 Critical - Feature completely broken, app crashes
- 🟠 High - Core feature broken or produces incorrect results
- 🟡 Medium - Feature works but with issues
- 🟢 Low - Minor functional issue

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

**Backend Status:**
- [ ] Backend running (localhost:8000)
- [ ] Backend offline
- [ ] Backend URL: _______________

---

## Feature Affected

**Which feature is broken?**

- [ ] Menu & Toolbar
- [ ] Journal flow (emotion logging)
- [ ] Detail views (curriculum/strategy)
- [ ] Notifications
- [ ] Data loading/syncing
- [ ] Settings/Schedules
- [ ] Analytics
- [ ] Other: _________________

---

## Steps to Reproduce

1. [First step - be very specific]
2. [Second step]
3. [Third step]
4. [Continue until issue appears]

**Example:**
1. Launch app
2. Tap three-dot menu button
3. Tap "Log Emotion"
4. Select "Purple" layer tab
5. Tap "Affection" emotion
6. Tap "Add another feeling"
7. Select "Joy" as secondary emotion
8. Observe behavior

---

## Expected Behavior

[What should happen - describe the correct functionality]

**Example:**
After selecting "Joy" as secondary emotion, the app should move to the strategy selection screen showing strategies filtered for the Purple layer's current phase.

---

## Actual Behavior

[What actually happens - describe the incorrect functionality]

**Example:**
After selecting "Joy", the app hangs for 5 seconds with a blank white screen, then crashes back to the main view. No error message is shown. The journal entry is not saved.

---

## Visual Evidence

### Screenshots

**Location:** `prompts/claude-comm/bugs/screenshots/[issue-name]/`

- [ ] Screenshot before the issue
- [ ] Screenshot when issue occurs
- [ ] Screenshot of error message (if any)
- [ ] Screenshot of incorrect state/data

### Video

- [ ] Screen recording showing the full flow: `[filename].mov`
- [ ] Duration: [X seconds]
- [ ] Shows complete reproduction steps

---

## Error Messages

**Console Logs:**

```
[Paste any relevant console output from Xcode]
```

**Error Alerts:**

[If app shows error alert, copy exact text]

**Backend Logs:**

```
[If backend is involved, paste relevant logs]
```

---

## Data State

**What data is involved?**

**Input Data:**
- Primary emotion: [e.g., Affection]
- Secondary emotion: [e.g., Joy]
- Selected strategy: [e.g., None]
- Phase: [e.g., Rising]
- Layer: [e.g., Purple]

**Expected Output:**
[What data should result from this action]

**Actual Output:**
[What data actually results, if any]

---

## Network Requests

**If feature involves backend communication:**

**Expected Request:**
- Endpoint: [e.g., POST /api/v1/journal]
- Method: [GET/POST/PUT/DELETE]
- Payload: [JSON or description]

**Actual Request:**
- Status: [e.g., Not sent, 200 OK, 500 Error]
- Response: [JSON or error message]

**Backend Logs:**
```
[Paste backend logs if available]
```

---

## User Actions

**What was the user trying to accomplish?**

[Describe the user's goal]

**Can the user complete their task?**
- [ ] Yes, with workaround
- [ ] No, completely blocked
- [ ] Partially - some data saved/lost

---

## Code Locations

**Suspected files:**

- [ ] `ContentView.swift` - Lines: _______
- [ ] `JournalFlowViewModel.swift` - Lines: _______
- [ ] `FlowCoordinatorView.swift` - Lines: _______
- [ ] `MenuView.swift` - Lines: _______
- [ ] API Client: _______ - Lines: _______
- [ ] Other: _________________

**Suspected causes:**

- [ ] State management issue
- [ ] Missing error handling
- [ ] Race condition
- [ ] API call failure
- [ ] Data validation issue
- [ ] Business logic error
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

## Workaround

**Is there a temporary workaround?**

[Describe any way users can accomplish their goal]

**Example:**
Users can log a single emotion (primary only) by tapping "Just [emotion name]" instead of adding a secondary feeling. This successfully submits the journal entry.

---

## User Impact

**Who is affected?**

- [ ] All users
- [ ] Users on specific watch sizes
- [ ] Users with specific data/state
- [ ] Users performing specific action
- [ ] Other: _________________

**Frequency of use:**

- [ ] High - Core feature used regularly
- [ ] Medium - Feature used occasionally
- [ ] Low - Rarely used feature

---

## Data Integrity

**Is data at risk?**

- [ ] Yes - Data loss possible
- [ ] Yes - Data corruption possible
- [ ] No - No data impact
- [ ] Unknown

**If yes, describe:**

[What data could be lost or corrupted?]

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
1. Add nil check for secondary emotion selection
2. Add error handling for empty strategy list
3. Add loading state during transition
4. Add timeout for hanging operations
5. Add user-facing error message

**Files to modify:**

- [ ] File: _____________ - Change: _____________
- [ ] File: _____________ - Change: _____________

---

## Test Coverage

**Are there tests for this functionality?**

- [ ] Yes, tests exist and passing (test may be incorrect)
- [ ] Yes, tests exist and failing
- [ ] No, tests don't cover this
- [ ] Unknown

**Tests to add/fix:**

[List test cases that should be added or fixed]

**Example:**
```swift
@Test func testSecondaryEmotionSelection() async {
  // Given primary emotion selected
  // When user selects secondary emotion
  // Then should transition to strategy selection
  // And should not hang or crash
}
```

---

## Reproduction Rate

**How often does this occur?**

- [ ] Always (100%)
- [ ] Frequently (>75%)
- [ ] Sometimes (25-75%)
- [ ] Rarely (<25%)
- [ ] Once

**Conditions that affect reproduction:**

[Are there specific conditions that make it more/less likely?]

---

## Checklist

- [ ] Bug reproduced at least twice
- [ ] Video recording captured
- [ ] Console logs captured
- [ ] Backend logs captured (if applicable)
- [ ] All relevant information filled out
- [ ] GitHub issue created: #______
- [ ] Related issues linked
- [ ] Developer notified (if critical)

---

## Notes

[Any additional notes, observations, or context about the functionality issue]
