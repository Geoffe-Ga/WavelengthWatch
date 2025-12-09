# Streamlined Emotion Flow - Manual Testing Plan

**Epic:** #131 - Streamlined Emotion Flow - DRY Architecture Refactor
**Date:** 2025-12-09
**Context:** Post-refactor testing plan for ContentView-based flow
**Focus:** Verify streamlined architecture eliminates UI crowding and maintains functionality

---

## Architecture Overview

The streamlined emotion flow refactor (Epic #131) eliminates 5,000+ lines of duplicate code by reusing ContentView's existing navigation instead of duplicating it in sheet presentations.

### Key Architectural Changes

**Before (Epic #92):**
- Duplicate navigation views (FilteredLayerNavigationView, PrimaryEmotionSelectionView, etc.)
- Complex sheet presentations with embedded navigation
- UI crowding on 42mm watches (#128, #129, #130)
- 5,000+ lines of duplicate code

**After (Epic #131):**
- **Single source of truth:** ContentView handles all navigation (full-screen)
- **FlowCoordinator:** Pure state management (no UI logic)
- **LayerFilterMode:** Controls layer visibility (.all, .emotionsOnly, .strategiesOnly)
- **Simple confirmation alerts:** Between each step
- **FlowReviewSheet:** Final review before submission
- **Zero UI crowding:** Full-screen navigation eliminates cramped sheets
- **95% code reduction:** 5,000 lines → 250 lines

### Flow Architecture

```
User Flow:
1. Menu → Tap "Log Emotion" → Alert: "Select your primary emotion"
2. ContentView (filtered to .emotionsOnly via LayerFilterMode)
3. Navigate freely → Tap "Log Medicinal/Toxic" → FlowCoordinator captures selection
4. Alert: "Primary: Grounded. Add secondary?" → [Yes/Skip to Review]
5. If yes → ContentView (still .emotionsOnly) → Select second emotion
6. Alert: "Add strategy?" → [Yes/Skip to Review]
7. If yes → ContentView (filtered to .strategiesOnly) → Select strategy
8. FlowReviewSheet → Shows all selections → Submit to backend
```

**Key Difference:** All navigation uses the existing ContentView with full-screen interaction. No duplicate navigation views. Simple alerts for confirmation between steps.

---

## Testing Environment Setup

### Prerequisites

- [ ] Backend running: `uvicorn backend.app:app --reload`
- [ ] Backend accessible at: `http://127.0.0.1:8000`
- [ ] APIConfiguration-Local.plist created with localhost URL
- [ ] Database has current catalog data
- [ ] Xcode 16.4+ with watchOS 10.0+ simulator

### Test Devices

**Primary focus:** 42mm watch (previously showed UI crowding - should be resolved)

Device Matrix:
- [ ] **42mm Apple Watch Series 7** (critical - previously had issues)
- [ ] **41mm Apple Watch Series 9** (smallest screen)
- [ ] **45mm Apple Watch Series 9** (mid-size)
- [ ] **49mm Apple Watch Ultra 2** (largest screen)

### Backend Verification

```bash
# Test catalog endpoint
curl http://127.0.0.1:8000/api/v1/catalog | jq '.layers | length'
# Should return 11 (layers 0-10)

# Test journal endpoint
curl http://127.0.0.1:8000/api/v1/journal | jq 'length'
# Should return existing journal entries
```

---

## Test Categories

1. **Flow Entry Points** - How users start the flow
2. **Primary Emotion Selection** - ContentView filtering, full-screen navigation, capture
3. **Secondary Emotion Selection** - Optional second emotion selection
4. **Strategy Selection** - ContentView filtered to strategies, optional
5. **Review and Submission** - FlowReviewSheet, backend submission
6. **Cancellation and Errors** - Cancel flow, network errors, retry
7. **Device Compatibility** - No UI crowding on any watch size
8. **Normal Browsing** - Flow doesn't interfere with normal ContentView usage

---

## Category 1: Flow Entry Points

**Objective:** Verify menu entry point launches flow with initial prompt

### Test 1.1: Menu "Log Emotion" Button
**Test on all watch sizes:**

**Steps:**
1. Open menu (tap ellipsis button in top-left)
2. Tap "Log Emotion"
3. Verify alert appears: "Select your primary emotion"
4. Read alert message: "Navigate to any emotion and tap to log it."
5. Tap "Continue"
6. Verify ContentView is now active (no sheet presentation)
7. Tap "Cancel" on alert
8. Verify menu sheet dismisses, flow doesn't start

**Expected Results:**
- ✅ Alert shows clear instructions
- ✅ "Continue" starts flow (ContentView visible)
- ✅ "Cancel" dismisses alert, returns to normal browsing
- ✅ No UI crowding on any device size

**Known Issues:** None

---

## Category 2: Primary Emotion Selection

**Objective:** Verify ContentView filters to emotions only, full-screen navigation works, selection captured correctly

### Test 2.1: Initial Prompt Shows
**Test on 42mm and 41mm watches:**

**Steps:**
1. Start flow via menu
2. Tap "Continue" on initial alert
3. Verify ContentView is visible (full screen)
4. Verify no sheet presentation overlays

**Expected Results:**
- ✅ ContentView visible at full screen
- ✅ No cramped sheet presentations
- ✅ No UI crowding on 42mm watch

### Test 2.2: ContentView Filtered to Emotions Only
**Test on all watch sizes:**

**Steps:**
1. Start flow, tap "Continue"
2. Scroll vertically through layers
3. Verify only emotion layers visible (1-10: Beige, Purple, Red, Blue, Orange, Green, Yellow, Teal, Ultraviolet, Clear Light)
4. Verify layer 0 (Strategies) is **not** visible

**Expected Results:**
- ✅ Only layers 1-10 visible (emotions)
- ✅ Layer 0 (Strategies) filtered out
- ✅ Layer indicator shows correct filtered layers
- ✅ Digital crown scrolls through emotion layers only

### Test 2.3: Full-Screen Navigation Works
**Test on 42mm watch (critical):**

**Steps:**
1. Start flow
2. Navigate vertically through layers (scroll/digital crown)
3. Navigate horizontally through phases (swipe/tap)
4. Tap chevron to open detail view
5. Verify detail view opens at full screen

**Expected Results:**
- ✅ Full-screen navigation (no sheet)
- ✅ All ContentView features work normally
- ✅ Layer/phase navigation smooth
- ✅ Detail view opens at full size
- ✅ **No UI crowding** on 42mm watch

### Test 2.4: Tapping "Log Medicinal" Captures Selection
**Test on all watch sizes:**

**Steps:**
1. Start flow
2. Navigate to Beige layer, Rising phase
3. Tap chevron to open detail view
4. Tap card body or journal icon on "Grounded" (medicinal)
5. Verify alert: "Log Medicine"
6. Verify message: "Would you like to log 'Grounded'?"
7. Tap "Yes"
8. Verify alert disappears

**Expected Results:**
- ✅ Log alert appears
- ✅ "Yes" captures selection (no immediate backend submission)
- ✅ "Cancel" dismisses alert, returns to detail view
- ✅ Detail view still accessible after alert

### Test 2.5: Confirmation Alert Shows
**Test on 42mm and 41mm watches:**

**Steps:**
1. Complete Test 2.4 (select "Grounded")
2. After tapping "Yes" on log alert
3. Verify confirmation alert appears
4. Verify title: "Primary emotion selected"
5. Read message: Shows selected emotion name
6. Verify buttons: "Add Secondary Emotion", "Skip to Review", "Cancel"

**Expected Results:**
- ✅ Confirmation alert appears immediately
- ✅ Selected emotion name visible in message
- ✅ Three clear action buttons
- ✅ Text readable on 42mm watch
- ✅ Buttons easily tappable

---

## Category 3: Secondary Emotion Selection

**Objective:** Verify optional secondary emotion selection flow

### Test 3.1: Option to Add Secondary Presented
**Test on all watch sizes:**

**Steps:**
1. Complete primary selection (Test 2.4-2.5)
2. On confirmation alert, tap "Add Secondary Emotion"
3. Verify alert dismisses
4. Verify ContentView still visible (full screen)
5. Verify still filtered to emotions only

**Expected Results:**
- ✅ Alert dismisses
- ✅ ContentView stays visible (no new sheet)
- ✅ Still showing only emotion layers
- ✅ User can navigate freely

### Test 3.2: ContentView Still Filtered to Emotions Only
**Test on 41mm watch:**

**Steps:**
1. After choosing "Add Secondary Emotion"
2. Scroll through layers vertically
3. Verify only emotion layers 1-10 visible
4. Verify Strategies layer not visible

**Expected Results:**
- ✅ Filter mode unchanged (still .emotionsOnly)
- ✅ Can select any emotion layer
- ✅ Same navigation as primary selection

### Test 3.3: Can Select Different Emotion
**Test on all watch sizes:**

**Steps:**
1. After choosing "Add Secondary Emotion"
2. Navigate to Purple layer, Rising phase
3. Open detail view
4. Tap "Log Medicinal" on "Connected"
5. Tap "Yes" on log alert
6. Verify confirmation alert appears
7. Verify shows both primary and secondary selections

**Expected Results:**
- ✅ Can select different emotion than primary
- ✅ Log alert appears correctly
- ✅ Confirmation alert shows both emotions
- ✅ Message format: "You selected 'Connected'. Add a strategy or skip to review?"

### Test 3.4: Can Skip Secondary
**Test on all watch sizes:**

**Steps:**
1. Complete primary selection
2. On confirmation alert, tap "Skip to Review"
3. Verify FlowReviewSheet appears
4. Verify only primary emotion shown (no secondary)

**Expected Results:**
- ✅ Can skip directly to review
- ✅ Review sheet shows only primary
- ✅ No error or blank fields

---

## Category 4: Strategy Selection

**Objective:** Verify ContentView filters to strategies, optional selection works

### Test 4.1: Prompted for Strategy After Emotions
**Test on 42mm watch:**

**Steps:**
1. Complete primary and secondary selection
2. On secondary confirmation alert, tap "Add Strategy"
3. Verify alert dismisses
4. Verify ContentView visible

**Expected Results:**
- ✅ Prompt to add strategy appears
- ✅ ContentView remains visible (full screen)
- ✅ No UI crowding

### Test 4.2: ContentView Filtered to Strategies Only (Layer 0)
**Test on all watch sizes:**

**Steps:**
1. After choosing "Add Strategy"
2. Scroll vertically through layers
3. Verify only Strategies layer (layer 0) visible
4. Verify all emotion layers hidden
5. Verify layer indicator shows "SELF-CARE (Strategies)"

**Expected Results:**
- ✅ Only layer 0 (Strategies) visible
- ✅ Emotion layers 1-10 filtered out
- ✅ Layer indicator correct
- ✅ Can navigate through phases horizontally

### Test 4.3: Can Select Strategy
**Test on all watch sizes:**

**Steps:**
1. After filter changes to strategies
2. Navigate to Strategies layer, Rising phase
3. Tap chevron to open StrategyListView
4. Tap a strategy (e.g., "Deep Breathing")
5. Verify alert: "Log Strategy"
6. Tap "Yes"
7. Verify confirmation alert appears
8. Verify shows selected strategy name

**Expected Results:**
- ✅ Strategy log alert appears
- ✅ Confirmation alert shows strategy
- ✅ Message format: "You selected 'Deep Breathing'. Continue to review?"

### Test 4.4: Can Skip Strategy
**Test on all watch sizes:**

**Steps:**
1. Complete primary selection
2. Tap "Skip to Review" (or skip secondary, then skip strategy)
3. Verify FlowReviewSheet appears
4. Verify no strategy shown

**Expected Results:**
- ✅ Can skip strategy selection
- ✅ Review sheet shows only emotions
- ✅ No strategy field in review

---

## Category 5: Review and Submission

**Objective:** Verify FlowReviewSheet displays selections correctly, submission works

### Test 5.1: Review Sheet Shows All Selections
**Test on 42mm and 41mm watches:**

**Steps:**
1. Complete full flow (primary + secondary + strategy)
2. Tap "Continue to Review" on strategy confirmation
3. Verify FlowReviewSheet appears
4. Verify title: "Review"
5. Verify primary emotion card shows:
   - Label: "PRIMARY EMOTION"
   - Emotion name
   - Dosage indicator (medicinal/toxic)
6. Verify secondary emotion card shows (if selected)
7. Verify strategy card shows (if selected)
8. Verify "Submit Entry" button visible
9. Verify "Cancel" button in navigation bar

**Expected Results:**
- ✅ Review sheet appears as modal
- ✅ All selections displayed clearly
- ✅ Text readable on 42mm watch
- ✅ Cards use appropriate colors
- ✅ Submit button prominent
- ✅ No UI crowding on small screens

### Test 5.2: Submit Sends to Backend
**Test on all watch sizes:**

**Steps:**
1. On review sheet, tap "Submit Entry"
2. Verify progress indicator appears
3. Wait for submission to complete
4. Verify success alert appears
5. Tap "OK" on success alert
6. Verify review sheet dismisses
7. Verify ContentView returns to normal mode (all layers visible)

**Backend Verification:**
```bash
# Check journal entry was created
curl http://127.0.0.1:8000/api/v1/journal | jq '.[-1]'
# Should show new entry with correct curriculum_id, secondary_curriculum_id, strategy_id
```

**Expected Results:**
- ✅ Submit button shows progress indicator
- ✅ Success alert appears
- ✅ Review sheet dismisses
- ✅ Flow resets (returns to idle state)
- ✅ ContentView filter resets to .all
- ✅ Backend receives correct data

### Test 5.3: Success Feedback Shows
**Test on all watch sizes:**

**Steps:**
1. Complete submission
2. Verify success alert appears
3. Read alert title and message
4. Tap "OK"
5. Verify alert dismisses

**Expected Results:**
- ✅ Success alert clear and concise
- ✅ "OK" button dismisses
- ✅ User returned to browsing mode

### Test 5.4: Flow Resets After Submission
**Test on all watch sizes:**

**Steps:**
1. Complete submission, dismiss success alert
2. Scroll through layers vertically
3. Verify all layers visible (0-10)
4. Verify filter mode reset to .all
5. Open menu, start new flow
6. Verify previous selections cleared

**Expected Results:**
- ✅ All layers visible after submission
- ✅ Filter mode = .all
- ✅ Starting new flow shows clean state
- ✅ No residual data from previous flow

---

## Category 6: Cancellation and Errors

**Objective:** Verify user can cancel at any step, errors handled gracefully

### Test 6.1: Can Cancel from Any Step
**Test on all watch sizes:**

**Test A - Cancel from primary confirmation:**
1. Start flow, select primary emotion
2. On confirmation alert, tap "Cancel"
3. Verify flow exits
4. Verify ContentView filter resets to .all

**Test B - Cancel from secondary selection:**
1. Start flow, select primary, choose "Add Secondary"
2. Navigate to select secondary
3. On secondary confirmation, tap "Cancel"
4. Verify flow exits
5. Verify filter resets

**Test C - Cancel from review sheet:**
1. Complete full flow to review
2. On review sheet, tap "Cancel" in navigation bar
3. Verify review sheet dismisses
4. Verify flow exits
5. Verify filter resets

**Expected Results:**
- ✅ Cancel available at every step
- ✅ Cancel exits flow immediately
- ✅ Filter resets to .all
- ✅ No data persisted
- ✅ Return to normal browsing

### Test 6.2: Cancellation Resets Flow
**Test on all watch sizes:**

**Steps:**
1. Start flow, select primary, cancel
2. Start new flow
3. Verify no previous selections shown
4. Verify clean flow state

**Expected Results:**
- ✅ Flow state fully reset
- ✅ No residual selections
- ✅ Fresh flow instance

### Test 6.3: Network Errors Show Retry Option
**Test on all watch sizes:**

**Steps:**
1. Stop backend: Kill uvicorn process
2. Complete flow to review sheet
3. Tap "Submit Entry"
4. Wait for network timeout
5. Verify error alert appears
6. Read error message
7. Restart backend: `uvicorn backend.app:app --reload`
8. On error alert, tap "Retry" (if available) or "OK"
9. If "OK", tap "Submit Entry" again
10. Verify submission succeeds

**Expected Results:**
- ✅ Error alert appears on network failure
- ✅ Error message clear and helpful
- ✅ Retry option available (or can manually retry)
- ✅ Review sheet stays open (state preserved)
- ✅ Selections preserved for retry
- ✅ Retry succeeds after backend restored

### Test 6.4: Retry Works Correctly
**Test on all watch sizes:**

**Steps:**
1. Trigger network error (Test 6.3)
2. Verify review sheet still shows selections
3. Verify currentStep preserved (still .review)
4. Restart backend
5. Tap "Submit Entry" again
6. Verify submission succeeds
7. Verify success alert appears

**Expected Results:**
- ✅ State preserved on error
- ✅ Can retry without re-entering data
- ✅ Retry submits same data
- ✅ Success after retry

---

## Category 7: Device Compatibility

**Objective:** Verify no UI crowding on any watch size (critical for Epic #131)

### Test 7.1: 42mm Watch - No UI Crowding
**Test on 42mm Apple Watch Series 7:**

**Steps:**
1. Complete full flow (all steps)
2. At each step, verify:
   - ContentView navigation: Layers/phases visible, tap targets adequate
   - Detail views: Cards readable, journal icons tappable
   - Confirmation alerts: Text readable, buttons tappable
   - Review sheet: All cards readable, submit button accessible
3. Take screenshots at each step

**Expected Results:**
- ✅ **No UI crowding** at any step
- ✅ All text readable without scrolling alerts
- ✅ All buttons easily tappable (not cramped)
- ✅ ContentView uses full screen (no sheet constraints)
- ✅ Review sheet properly sized

**Critical Success Criterion:** This test MUST pass for Epic #131 to be considered successful. UI crowding on 42mm was the primary driver for this refactor.

### Test 7.2: 41mm Watch - No UI Crowding
**Test on 41mm Apple Watch Series 9:**

**Steps:**
1. Same as Test 7.1 on smallest screen
2. Verify all UI elements accessible

**Expected Results:**
- ✅ No UI crowding on smallest screen
- ✅ All functionality accessible
- ✅ No text cutoff

### Test 7.3: 45mm Watch - Proper Layout
**Test on 45mm Apple Watch Series 9:**

**Steps:**
1. Complete full flow
2. Verify layout uses space well
3. Verify no excessive padding

**Expected Results:**
- ✅ Layout scales appropriately
- ✅ Good use of available space
- ✅ Consistent with smaller screens

### Test 7.4: 49mm Watch - Proper Layout
**Test on 49mm Apple Watch Ultra 2:**

**Steps:**
1. Complete full flow on largest screen
2. Verify layout uses space well

**Expected Results:**
- ✅ Layout scales to largest screen
- ✅ No overly large elements
- ✅ Consistent experience

---

## Category 8: Normal Browsing

**Objective:** Verify flow doesn't interfere with normal ContentView usage

### Test 8.1: Normal Browsing After Flow
**Test on all watch sizes:**

**Steps:**
1. Complete and submit a flow
2. Browse ContentView normally:
   - Scroll through all layers (0-10)
   - Navigate phases
   - Open detail views
   - Tap "Log Medicinal" on an emotion
3. Verify immediate logging works (not flow mode)
4. Verify journal feedback appears

**Expected Results:**
- ✅ All layers visible (filter = .all)
- ✅ Normal navigation works
- ✅ Tapping "Log" immediately submits (no flow)
- ✅ Journal feedback shows success/error
- ✅ No flow state interference

### Test 8.2: Flow Mode vs Normal Mode
**Test on all watch sizes:**

**Steps:**
1. **Normal mode test:**
   - Don't start flow
   - Navigate to emotion, tap "Log Medicinal"
   - Verify immediate submission (journal feedback appears)

2. **Flow mode test:**
   - Start flow via menu
   - Navigate to emotion, tap "Log Medicinal"
   - Verify capture (confirmation alert, not immediate submission)

**Expected Results:**
- ✅ Normal mode: Immediate logging, feedback
- ✅ Flow mode: Capture selection, confirmation alert
- ✅ Clear distinction between modes
- ✅ FlowCoordinator.currentStep controls behavior

---

## Success Criteria

Epic #131 is considered successful when:

### Functional Requirements
- [ ] All flow steps work correctly (entry → primary → secondary → strategy → review → submit)
- [ ] ContentView navigation works at full screen (no cramped sheets)
- [ ] Layer filtering works correctly (.all, .emotionsOnly, .strategiesOnly)
- [ ] Confirmation alerts appear between steps with correct content
- [ ] FlowReviewSheet displays all selections accurately
- [ ] Backend submission works (POST to /api/v1/journal)
- [ ] Success feedback shows after submission
- [ ] Flow state resets after submission
- [ ] Cancel works from any step
- [ ] Error handling preserves state for retry

### Device Compatibility (Critical)
- [ ] **42mm watch: NO UI crowding** (primary success criterion)
- [ ] 41mm watch: No UI crowding
- [ ] 45mm watch: Proper layout
- [ ] 49mm watch: Proper layout
- [ ] All text readable on all devices
- [ ] All buttons tappable on all devices

### Architecture Validation
- [ ] No duplicate navigation views used
- [ ] ContentView reused for all navigation
- [ ] FlowCoordinator manages state only (no UI)
- [ ] LayerFilterMode controls visibility correctly
- [ ] Normal browsing unaffected by flow implementation

### Code Quality
- [ ] All integration tests pass (from #137)
- [ ] No regression in existing ContentView features
- [ ] Error state preservation works (from #143)
- [ ] No flaky behavior

---

## Known Issues

**None** - Epic #131 resolves all UI crowding issues from Epic #92.

---

## Testing Checklist Summary

### Per Device Testing
For each device (42mm, 41mm, 45mm, 49mm):
- [ ] Complete full flow (primary + secondary + strategy)
- [ ] Test skip paths (primary only, primary + secondary only)
- [ ] Test cancellation from each step
- [ ] Verify no UI crowding
- [ ] Test normal browsing (non-flow mode)

### Backend Testing
- [ ] Verify backend running and accessible
- [ ] Test submission with all selections
- [ ] Test submission with minimal selections (primary only)
- [ ] Test network error handling
- [ ] Verify data persisted correctly

### Edge Cases
- [ ] Rapid button tapping (double-tap protection)
- [ ] Flow state after app backgrounding
- [ ] Multiple flows in sequence
- [ ] Flow cancellation then immediate restart

---

## Test Results Template

```markdown
## Test Session: [Date]
**Tester:** [Name]
**Device:** [Watch Model]
**Build:** [Commit SHA]

### Category 1: Flow Entry Points
- [ ] Test 1.1: Menu Entry - ✅ Pass / ❌ Fail

### Category 2: Primary Emotion Selection
- [ ] Test 2.1: Initial Prompt - ✅ Pass / ❌ Fail
- [ ] Test 2.2: Filter to Emotions - ✅ Pass / ❌ Fail
- [ ] Test 2.3: Full-Screen Navigation - ✅ Pass / ❌ Fail
- [ ] Test 2.4: Capture Selection - ✅ Pass / ❌ Fail
- [ ] Test 2.5: Confirmation Alert - ✅ Pass / ❌ Fail

[Continue for all categories...]

### Issues Found
1. [Issue description]
   - Severity: [Critical/High/Medium/Low]
   - Steps to reproduce:
   - Expected vs Actual:

### Overall Assessment
- UI Crowding: ✅ None / ⚠️ Minor / ❌ Major
- Functionality: ✅ All Pass / ⚠️ Minor Issues / ❌ Blocking Issues
- Recommendation: ✅ Approve / ⚠️ Fix & Retest / ❌ Reject
```

---

## Related Issues

- Epic #131: Streamlined Emotion Flow - DRY Architecture Refactor
- Supersedes: #120 (original testing plan for Epic #92)
- Resolves: #128, #129, #130 (UI crowding issues)
- Depends on: #132, #133, #134, #135, #136, #137 (implementation issues)
