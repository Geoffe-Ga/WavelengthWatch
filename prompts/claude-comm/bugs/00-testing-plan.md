# WavelengthWatch Comprehensive Testing Plan

**Date:** 2025-11-24
**Context:** Post-PR #118 manual testing
**Tester:** Manual testing via Xcode simulator

---

## Testing Environment Setup

### Prerequisites
- [ ] Backend running: `uvicorn backend.app:app --reload` on `http://127.0.0.1:8000`
- [ ] Local config created: `APIConfiguration-Local.plist` with localhost URL
- [ ] Xcode 16.4+ installed
- [ ] Simulators available for all watch sizes

### Simulator Configuration

Test on **all three watch sizes**:
- [ ] 41mm (Apple Watch Series 9 - smallest, most likely to show clipping)
- [ ] 45mm (Apple Watch Series 9 - medium)
- [ ] 49mm (Apple Watch Ultra 2 - largest)

---

## Test Categories

### 1. UI Layout & Sizing Tests
### 2. Navigation Tests
### 3. Menu & Toolbar Tests
### 4. Detail View Tests
### 5. Journal Flow Tests
### 6. Notification Tests
### 7. Data Loading Tests
### 8. Performance Tests
### 9. Edge Case Tests

---

## 1. UI Layout & Sizing Tests

**Objective:** Verify UI elements render correctly on all watch sizes without clipping

### Test 1.1: Phase Label Sizing
**Template:** `bug-template-layout.md`

- [ ] **41mm Watch**
  - [ ] Navigate through all phases horizontally
  - [ ] Verify phase labels are fully visible
  - [ ] Check font sizes are consistent across phases
  - [ ] Verify "BOTTOMING OUT" (longest label) fits without clipping
  - [ ] Screenshot each phase

- [ ] **45mm Watch**
  - [ ] Navigate through all phases horizontally
  - [ ] Verify phase labels are fully visible
  - [ ] Check font sizes are consistent across phases
  - [ ] Screenshot each phase

- [ ] **49mm Watch**
  - [ ] Navigate through all phases horizontally
  - [ ] Verify phase labels are fully visible
  - [ ] Check font sizes are consistent across phases
  - [ ] Screenshot each phase

**Known Issue:** #119 - Phase labels use inconsistent sizing

### Test 1.2: Content Box Visibility
**Template:** `bug-template-layout.md`

- [ ] **41mm Watch (Critical)**
  - [ ] Navigate to each layer vertically
  - [ ] Verify content boxes are fully visible (not clipped top/bottom)
  - [ ] Check "View Details" buttons are fully visible
  - [ ] Verify glow effects are visible at bottom
  - [ ] Screenshot any clipped content

- [ ] **45mm Watch**
  - [ ] Navigate to each layer vertically
  - [ ] Verify content boxes are fully visible
  - [ ] Check "View Details" buttons are fully visible
  - [ ] Verify glow effects are visible

- [ ] **49mm Watch**
  - [ ] Navigate to each layer vertically
  - [ ] Verify content boxes are fully visible
  - [ ] Check "View Details" buttons are fully visible
  - [ ] Verify glow effects are visible

**Known Issue:** #119 - Content clipping on smaller watches

### Test 1.3: Toolbar & Menu Button
**Template:** `bug-template-ui.md`

- [ ] **All Watch Sizes**
  - [ ] Verify three-dot menu button appears at top-left
  - [ ] Button is stationary (doesn't scroll with content)
  - [ ] Button has proper spacing from screen edge
  - [ ] Button is tappable (44pt min touch target)
  - [ ] Button color/opacity correct (white 0.7 opacity)

**Related PR:** #118

### Test 1.4: Bottom Safe Area
**Template:** `bug-template-layout.md`

- [ ] **All Watch Sizes**
  - [ ] Verify no black padding at bottom
  - [ ] Content box glow extends to bottom edge
  - [ ] No content cut off at bottom

**Fixed in:** PR #118 commit `e4945f5`

---

## 2. Navigation Tests

**Objective:** Verify navigation works correctly in all directions

### Test 2.1: Vertical Layer Scrolling
**Template:** `bug-template-navigation.md`

- [ ] **Digital Crown**
  - [ ] Rotate crown up → moves to next layer
  - [ ] Rotate crown down → moves to previous layer
  - [ ] Scrolling is smooth (no stuttering)
  - [ ] Layer selection updates correctly

- [ ] **Swipe Gesture**
  - [ ] Swipe up → moves to next layer
  - [ ] Swipe down → moves to previous layer
  - [ ] Gesture is responsive

- [ ] **Layer Indicator**
  - [ ] Layer name shows briefly on change
  - [ ] Indicator fades after ~1 second
  - [ ] Indicator text is readable

### Test 2.2: Horizontal Phase Scrolling
**Template:** `bug-template-navigation.md`

- [ ] **Swipe Gesture**
  - [ ] Swipe left → moves to next phase
  - [ ] Swipe right → moves to previous phase
  - [ ] Phase wraps around (infinite scroll)
  - [ ] Smooth transition between phases

- [ ] **Phase Wrapping**
  - [ ] From last phase, swipe left → wraps to first phase
  - [ ] From first phase, swipe right → wraps to last phase

### Test 2.3: Navigation State Persistence
**Template:** `bug-template-state.md`

- [ ] Navigate to specific layer and phase
- [ ] Force quit app (CMD+Shift+H, swipe up)
- [ ] Relaunch app
- [ ] Verify app returns to same layer and phase

---

## 3. Menu & Toolbar Tests

**Objective:** Verify menu button and menu sheet work correctly

### Test 3.1: Menu Button Visibility
**Template:** `bug-template-ui.md`

- [ ] **Main View**
  - [ ] Button visible on main phase/layer view
  - [ ] Button visible after scrolling vertically
  - [ ] Button visible after scrolling horizontally
  - [ ] Button remains stationary during scrolling

- [ ] **Detail Views**
  - [ ] Navigate to CurriculumDetailView
  - [ ] Verify button is HIDDEN
  - [ ] Return to main view
  - [ ] Verify button REAPPEARS
  - [ ] Navigate to StrategyListView
  - [ ] Verify button is HIDDEN
  - [ ] Return to main view
  - [ ] Verify button REAPPEARS

### Test 3.2: Menu Sheet Functionality
**Template:** `bug-template-functional.md`

- [ ] Tap three-dot menu button
- [ ] Menu sheet opens from bottom
- [ ] "Done" button visible in top-left
- [ ] Menu options visible:
  - [ ] Log Emotion
  - [ ] Schedules
  - [ ] Analytics
  - [ ] About
- [ ] Tap "Done" → sheet dismisses
- [ ] Tap outside sheet → sheet dismisses

### Test 3.3: Menu Navigation
**Template:** `bug-template-navigation.md`

- [ ] From menu, tap "Log Emotion"
  - [ ] Journal flow opens
  - [ ] Primary emotion selection appears
  - [ ] Can complete flow or cancel

- [ ] From menu, tap "Schedules"
  - [ ] Schedule settings view opens
  - [ ] Can toggle schedule on/off
  - [ ] Can set time
  - [ ] Can navigate back

- [ ] From menu, tap "Analytics"
  - [ ] Analytics view opens
  - [ ] Placeholder content visible
  - [ ] Can navigate back

- [ ] From menu, tap "About"
  - [ ] About view opens
  - [ ] App info visible
  - [ ] Can navigate back

---

## 4. Detail View Tests

**Objective:** Verify detail views display correctly and navigation works

### Test 4.1: Curriculum Detail View
**Template:** `bug-template-functional.md`

- [ ] From main view, tap "View Details" on any emotion
- [ ] CurriculumDetailView opens
- [ ] Verify displayed content:
  - [ ] Emotion name (e.g., "Affection")
  - [ ] Layer name (e.g., "Purple - Power")
  - [ ] Phase name (e.g., "Rising")
  - [ ] Medicine description
  - [ ] Toxic description
- [ ] Verify navigation:
  - [ ] Back button works (returns to main view)
  - [ ] Swipe right works (returns to main view)
- [ ] Verify menu button is HIDDEN

### Test 4.2: Strategy List View
**Template:** `bug-template-functional.md`

- [ ] From main view, tap emotion box (not "View Details")
- [ ] StrategyListView opens
- [ ] Verify displayed content:
  - [ ] Emotion name in title
  - [ ] List of strategies
  - [ ] Strategy descriptions
- [ ] Tap a strategy
  - [ ] Strategy detail opens
  - [ ] Strategy description visible
  - [ ] Can navigate back
- [ ] Verify navigation:
  - [ ] Back button works
  - [ ] Swipe right works
- [ ] Verify menu button is HIDDEN

---

## 5. Journal Flow Tests

**Objective:** Verify emotion logging flow works end-to-end

### Test 5.1: Primary Emotion Selection
**Template:** `bug-template-functional.md`

- [ ] Open menu → tap "Log Emotion"
- [ ] Primary emotion selection view appears
- [ ] Verify UI:
  - [ ] Title: "How are you feeling?"
  - [ ] Layer tabs visible (Beige, Purple, Red, etc.)
  - [ ] Emotions listed for selected layer
  - [ ] Emotions are tappable
- [ ] Tap different layer tabs
  - [ ] Emotion list updates
  - [ ] Correct emotions for each layer
- [ ] Select an emotion
  - [ ] Moves to secondary emotion prompt

### Test 5.2: Secondary Emotion Flow
**Template:** `bug-template-functional.md`

- [ ] After selecting primary emotion
- [ ] Secondary emotion prompt appears
- [ ] Options:
  - [ ] "Just [emotion name]" button
  - [ ] "Add another feeling" button
- [ ] Tap "Just [emotion name]"
  - [ ] Skips secondary selection
  - [ ] Moves to strategy selection
- [ ] OR tap "Add another feeling"
  - [ ] Secondary emotion selection appears
  - [ ] Can select second emotion
  - [ ] Primary emotion is excluded from list
  - [ ] Selection moves to strategy selection

### Test 5.3: Strategy Selection
**Template:** `bug-template-functional.md`

- [ ] After emotion selection(s)
- [ ] Strategy selection view appears
- [ ] Verify UI:
  - [ ] Strategies filtered by phase
  - [ ] Strategy descriptions visible
  - [ ] "Skip" button available
- [ ] Tap a strategy
  - [ ] Strategy selected
  - [ ] Moves to review view
- [ ] OR tap "Skip"
  - [ ] No strategy selected
  - [ ] Moves to review view

### Test 5.4: Journal Review & Submission
**Template:** `bug-template-functional.md`

- [ ] After strategy selection/skip
- [ ] Review view appears
- [ ] Verify displayed data:
  - [ ] Primary emotion with layer/phase
  - [ ] Secondary emotion (if selected)
  - [ ] Strategy (if selected)
  - [ ] Timestamp
- [ ] Tap "Log Entry" button
  - [ ] Submission shows loading state
  - [ ] Success alert appears: "Entry Logged"
  - [ ] Alert message: "Thanks for checking in."
  - [ ] Flow dismisses
  - [ ] Returns to main view
- [ ] Verify backend:
  - [ ] Check backend logs for POST to `/api/v1/journal`
  - [ ] Verify entry saved in database

### Test 5.5: Journal Flow Cancellation
**Template:** `bug-template-functional.md`

- [ ] Start journal flow
- [ ] At each step, tap "Cancel" button (if available) or back button
- [ ] Verify:
  - [ ] Flow cancels immediately
  - [ ] Returns to main view
  - [ ] No partial entry saved

---

## 6. Notification Tests

**Objective:** Verify scheduled notifications trigger journal flow

**Note:** Requires notification permissions granted

### Test 6.1: Schedule Setup
**Template:** `bug-template-functional.md`

- [ ] Open menu → tap "Schedules"
- [ ] Verify notification permission requested
- [ ] Grant permission (if prompted)
- [ ] Create a schedule:
  - [ ] Toggle schedule ON
  - [ ] Set time to 1-2 minutes in future
  - [ ] Navigate back
- [ ] Wait for notification to fire

### Test 6.2: Notification Delivery
**Template:** `bug-template-functional.md`

- [ ] While app is in background
- [ ] Notification fires at scheduled time
- [ ] Verify notification:
  - [ ] Title: "Journal Check-In"
  - [ ] Body shows prompt
  - [ ] Action button available

### Test 6.3: Notification Tap Routing
**Template:** `bug-template-functional.md`

- [ ] Tap notification
- [ ] App opens
- [ ] Journal flow opens automatically
- [ ] Primary emotion selection appears
- [ ] Can complete flow normally
- [ ] Entry logs with `initiated_by: "scheduled"`

**Related PR:** #112

---

## 7. Data Loading Tests

**Objective:** Verify catalog loads correctly from backend

### Test 7.1: Initial Load (No Cache)
**Template:** `bug-template-data.md`

- [ ] Delete app from simulator (long press → delete)
- [ ] Reinstall app
- [ ] Launch app
- [ ] Verify loading:
  - [ ] "Loading curriculum…" message appears
  - [ ] Backend receives GET to `/api/v1/catalog`
  - [ ] Catalog loads successfully
  - [ ] UI populates with layers and phases

### Test 7.2: Cached Load
**Template:** `bug-template-data.md`

- [ ] Force quit app
- [ ] Relaunch app
- [ ] Verify:
  - [ ] Catalog loads immediately from cache
  - [ ] No "Loading…" delay
  - [ ] Backend request still made (refresh in background)

### Test 7.3: Offline Mode
**Template:** `bug-template-data.md`

- [ ] Ensure app has cached data (launch once)
- [ ] Stop backend server
- [ ] Force quit app
- [ ] Relaunch app
- [ ] Verify:
  - [ ] App loads from cache
  - [ ] UI fully functional with cached data
  - [ ] No error messages for catalog
  - [ ] Journal submission fails gracefully

### Test 7.4: Network Error Handling
**Template:** `bug-template-data.md`

- [ ] Delete app (clear cache)
- [ ] Stop backend server
- [ ] Launch app
- [ ] Verify:
  - [ ] Error message appears
  - [ ] "Retry" button available
- [ ] Start backend server
- [ ] Tap "Retry"
- [ ] Verify catalog loads successfully

---

## 8. Performance Tests

**Objective:** Verify app performs smoothly without lag

### Test 8.1: Scrolling Performance
**Template:** `bug-template-performance.md`

- [ ] Rapid vertical scrolling (crown)
  - [ ] No dropped frames
  - [ ] Smooth transitions
  - [ ] Layer indicator updates correctly

- [ ] Rapid horizontal scrolling (swipes)
  - [ ] No dropped frames
  - [ ] Smooth transitions
  - [ ] Phase changes immediately

### Test 8.2: View Transition Performance
**Template:** `bug-template-performance.md`

- [ ] Navigate to detail view
  - [ ] Transition is smooth
  - [ ] Content appears immediately
- [ ] Navigate back
  - [ ] Transition is smooth
  - [ ] Main view resumes correctly

### Test 8.3: Journal Flow Performance
**Template:** `bug-template-performance.md`

- [ ] Complete full journal flow
- [ ] Verify each step:
  - [ ] No lag between steps
  - [ ] Smooth transitions
  - [ ] No UI freezing during submission

---

## 9. Edge Case Tests

**Objective:** Test unusual scenarios and boundary conditions

### Test 9.1: Rapid Interactions
**Template:** `bug-template-functional.md`

- [ ] Rapidly tap menu button multiple times
  - [ ] Menu opens only once
  - [ ] No duplicate sheets

- [ ] Rapidly scroll through phases
  - [ ] Selection updates correctly
  - [ ] No race conditions

- [ ] Rapidly tap emotions in journal flow
  - [ ] Only one selection registers
  - [ ] No double-submission

### Test 9.2: State Recovery
**Template:** `bug-template-state.md`

- [ ] Start journal flow
- [ ] Force quit app mid-flow
- [ ] Relaunch app
- [ ] Verify:
  - [ ] Returns to main view (flow not persisted)
  - [ ] No corrupted state

### Test 9.3: Long Text Handling
**Template:** `bug-template-layout.md`

- [ ] Navigate to emotions/strategies with long descriptions
- [ ] Verify:
  - [ ] Text wraps correctly
  - [ ] No text clipping
  - [ ] Scrolling works if needed

### Test 9.4: Empty/Missing Data
**Template:** `bug-template-data.md`

- [ ] Test with incomplete catalog data (if possible)
- [ ] Verify graceful degradation
- [ ] No crashes

---

## Bug Report Workflow

### When You Find a Bug

1. **Stop testing that area** - Note where you were
2. **Reproduce the bug** - Try to trigger it 2-3 times
3. **Choose appropriate template:**
   - Layout issues → `bug-template-layout.md`
   - Navigation issues → `bug-template-navigation.md`
   - Functional issues → `bug-template-functional.md`
   - Data issues → `bug-template-data.md`
   - Performance issues → `bug-template-performance.md`
   - State issues → `bug-template-state.md`
   - UI issues → `bug-template-ui.md`

4. **Fill out template** in `prompts/claude-comm/bugs/reports/`
5. **Take screenshots/video** - Store in `prompts/claude-comm/bugs/screenshots/`
6. **Create GitHub issue** (or batch multiple bugs into one issue)
7. **Continue testing** - Move to next test case

### Bug Severity Guidelines

- **🔴 Critical:** App crashes, data loss, unusable features
- **🟠 High:** Major functionality broken, significant UX issues
- **🟡 Medium:** Minor functionality issues, cosmetic problems
- **🟢 Low:** Polish items, minor inconsistencies

---

## Test Completion Checklist

- [ ] All test categories completed
- [ ] Tested on all watch sizes (41mm, 45mm, 49mm)
- [ ] Bug reports filed for all issues
- [ ] Screenshots/videos captured
- [ ] GitHub issues created
- [ ] Testing summary document created

---

## Testing Summary Template

After completing all tests, create a summary: `prompts/claude-comm/bugs/testing-summary-YYYY-MM-DD.md`

**Template:**

```markdown
# Testing Summary - YYYY-MM-DD

**Tester:** [Name]
**Duration:** [Hours]
**Build:** [Commit SHA or branch]

## Environment
- Xcode Version:
- Simulators Tested: 41mm, 45mm, 49mm
- Backend Status: Running/Offline

## Tests Completed
- [ ] Category 1: UI Layout & Sizing
- [ ] Category 2: Navigation
- [ ] Category 3: Menu & Toolbar
- [ ] Category 4: Detail Views
- [ ] Category 5: Journal Flow
- [ ] Category 6: Notifications
- [ ] Category 7: Data Loading
- [ ] Category 8: Performance
- [ ] Category 9: Edge Cases

## Bugs Found
- Total bugs: X
- Critical: X
- High: X
- Medium: X
- Low: X

## GitHub Issues Created
- #XXX - [Brief title]
- #XXX - [Brief title]

## Overall Assessment
[Pass/Fail - summary of major findings]

## Next Steps
[What needs to be fixed before shipping]
```

---

**Good luck with testing! 🧪**
