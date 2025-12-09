# Emotion Logging Flow - Focused Testing Plan

**Epic:** #92 - Multi-Step Emotion Logging Flow
**Date:** 2025-11-24
**Context:** Post-Phase 5 implementation, pre-Phase 6 integration work
**Focus:** Comprehensive testing of journal entry flow from entry to submission

---

## Epic Overview

The emotion logging flow allows users to log how they're feeling through a multi-step guided experience:

1. **Primary Emotion Selection** - Choose main emotion from filtered layers
2. **Secondary Emotion Prompt** - Option to add another feeling
3. **Secondary Emotion Selection** - Choose additional emotion (optional)
4. **Strategy Selection** - Choose self-care strategy (optional)
5. **Journal Review** - Review and submit entry
6. **Backend Submission** - POST to `/api/v1/journal`

### Completed Phases

- ✅ Phase 0: Layer filtering foundation
- ✅ Phase 1: Flow coordinator and state management
- ✅ Phase 2: Primary emotion selection (#107)
- ✅ Phase 3.1: Secondary emotion prompt (#108)
- ✅ Phase 3.2: Secondary emotion selection (#109)
- ✅ Phase 4.1: Strategy selection (#110)
- ✅ Phase 5.1: Journal review and submission (#111)

### Current State

- ⏳ Phase 6.1: Notification routing (#112 - PR open)
- 📋 Phase 6.2: Detail view entry points (#88)
- 📋 Phase 6.3: End-to-end integration tests (#89)
- 📋 Phase 6.4: Accessibility & VoiceOver (#90)

---

## Testing Environment Setup

### Prerequisites

- [ ] Backend running: `uvicorn backend.app:app --reload`
- [ ] Backend accessible at: `http://127.0.0.1:8000`
- [ ] APIConfiguration-Local.plist created with localhost URL
- [ ] Database has current catalog data
- [ ] Xcode 16.4+ with watchOS 10.0+ simulator

### Test Devices

**Primary focus:** 41mm watch (most likely to show UI issues)

- [ ] 41mm Apple Watch Series 9
- [ ] 45mm Apple Watch Series 9 (verification)
- [ ] 49mm Apple Watch Ultra 2 (verification)

### Backend Verification

```bash
# Test catalog endpoint
curl http://127.0.0.1:8000/api/v1/catalog | jq '.layers | length'
# Should return number of layers (8+)

# Test journal endpoint
curl http://127.0.0.1:8000/api/v1/journal | jq 'length'
# Should return existing journal entries
```

---

## Test Categories

1. **Flow Entry Points** - How users start the flow
2. **Primary Emotion Selection** - Phase 2 testing
3. **Secondary Emotion Flow** - Phase 3.1 & 3.2 testing
4. **Strategy Selection** - Phase 4.1 testing
5. **Journal Review & Submission** - Phase 5.1 testing
6. **Flow State Management** - State consistency through flow
7. **Flow Cancellation & Exit** - Cancel at each step
8. **Backend Integration** - API calls and data persistence
9. **Error Handling** - Network failures, timeouts, validation
10. **Edge Cases & Race Conditions** - Rapid interactions, unusual paths

---

## Category 1: Flow Entry Points

**Objective:** Verify all entry points launch the flow correctly

### Test 1.1: Menu Entry Point
**Template:** `bug-template-functional.md`

**Test on all watch sizes:**

- [ ] Open menu (tap three-dot button)
- [ ] Verify "Log Emotion" option visible
- [ ] Tap "Log Emotion"
- [ ] Verify flow opens (primary emotion selection appears)
- [ ] Verify sheet presentation is smooth
- [ ] Verify navigation bar shows "Cancel" button
- [ ] Verify `initiated_by` will be set to `.self`

**Expected:**
- Flow opens as modal sheet
- Primary emotion selection visible
- All layers available for selection

**Related PR:** #111 (menu entry point)

### Test 1.2: Notification Entry Point
**Template:** `bug-template-functional.md`

**Prerequisites:**
- [ ] Notification permissions granted
- [ ] Schedule created (time set to ~2 minutes in future)

**Test steps:**

- [ ] Create schedule in Schedules view
- [ ] Toggle schedule ON
- [ ] Set time to 2 minutes from now
- [ ] Exit app or move to background
- [ ] Wait for notification to fire

**When notification arrives:**

- [ ] Verify notification title: "Journal Check-In"
- [ ] Verify notification has action button
- [ ] Tap notification
- [ ] Verify app opens
- [ ] Verify flow opens automatically
- [ ] Verify primary emotion selection appears
- [ ] Verify `initiated_by` will be set to `.scheduled`

**Expected:**
- Notification routes to flow automatically
- Flow opens with correct context
- No user interaction needed beyond tapping notification

**Related PR:** #112 (notification routing - currently open)

### Test 1.3: Detail View Entry Point
**Template:** `bug-template-functional.md`

**Status:** 🚧 Not yet implemented (#88)

**Test when implemented:**

- [ ] Navigate to CurriculumDetailView
- [ ] Look for "Log This Feeling" button or similar
- [ ] Tap button
- [ ] Verify flow opens
- [ ] Verify pre-selected emotion matches detail view context

**Expected:**
- Flow opens with emotion pre-selected
- User can proceed directly to secondary prompt or strategy

---

## Category 2: Primary Emotion Selection

**Objective:** Verify primary emotion selection works correctly

### Test 2.1: Layer Vertical Scrolling Navigation
**Template:** `bug-template-navigation.md`

**Note:** Original test incorrectly referred to "tabs". Actual UI uses vertical scrolling for layers.

**Architecture:**
- Vertical scroll (swipe up/down or Digital Crown) = Layer navigation
- Horizontal scroll (swipe left/right) = Phase navigation
- Phase card tap = Opens dosage picker

**Test steps:**

- [ ] Open flow via menu
- [ ] Verify title: "How are you feeling?"
- [ ] Verify layer indicator visible on right side (colored dots)
- [ ] Count layers by scrolling vertically through all layers
- [ ] Scroll vertically through each layer (or use Digital Crown):
  - [ ] Beige (Layer 1)
  - [ ] Purple (Layer 2)
  - [ ] Red (Layer 3)
  - [ ] Blue (Layer 4)
  - [ ] Orange (Layer 5)
  - [ ] Green (Layer 6)
  - [ ] Yellow (Layer 7)
  - [ ] Teal (Layer 8)
  - [ ] Ultraviolet (Layer 9)
  - [ ] Clear Light (Layer 10)
- [ ] Verify phase cards update for each layer
- [ ] Verify layer selection indicator (sidebar) shows current layer with color
- [ ] Verify vertical scrolling works smoothly
- [ ] Verify Digital Crown scrolls through layers

**Expected:**
- All emotion layers (1-10) accessible via vertical scroll
- Scrolling vertically switches to that layer's phase cards
- Visual indicator (right sidebar) shows selected layer with color
- Smooth transitions between layers
- Digital Crown provides alternative navigation

### Test 2.2: Phase Card and Dosage Picker Display
**Template:** `bug-template-layout.md`

**Note:** Original test misunderstood architecture. Emotions appear in dosage picker AFTER tapping phase card.

**Phase card display (for each layer):**

- [ ] Scroll horizontally through phases
- [ ] Verify phase cards display correctly (layer title, subtitle, phase name)
- [ ] Verify phase card text readable on 41mm watch
- [ ] Verify no text clipping on phase cards
- [ ] Count phases by scrolling horizontally (should match catalog)
- [ ] Verify page indicator dots show at bottom during scroll

**Dosage picker (after tapping phase card):**

- [ ] Tap a phase card
- [ ] Verify dosage picker sheet opens
- [ ] Verify layer title and phase name shown at top
- [ ] Verify "Medicinal" section visible (if data exists)
- [ ] Verify "Toxic" section visible (if data exists)
- [ ] Count emotions in each section (compare with backend data)
- [ ] Verify emotion names readable and not clipped
- [ ] Verify "Cancel" button visible
- [ ] Verify all emotions tappable with adequate touch targets

**Expected:**
- Phase cards display layer/phase context clearly
- Horizontal scrolling smooth between phases
- Dosage picker shows all medicinal and toxic emotions for the phase
- Text not clipped on 41mm watch
- Proper spacing and readability

### Test 2.3: Emotion Selection via Dosage Picker
**Template:** `bug-template-functional.md`

**Note:** Emotions are selected from dosage picker sheet, not directly from list.

**Single selection:**

- [ ] Scroll to a layer and phase
- [ ] Tap phase card
- [ ] Dosage picker opens
- [ ] Select a medicinal emotion
- [ ] Verify dosage picker closes
- [ ] Verify transition to next step (secondary prompt)
- [ ] Verify selected emotion remembered

**Test multiple selections:**

- [ ] Navigate to Beige layer
- [ ] Scroll to a phase and tap card
- [ ] Select medicinal emotion from dosage picker
- [ ] Complete or cancel flow
- [ ] Start new flow
- [ ] Navigate to Purple layer
- [ ] Scroll to a phase and tap card
- [ ] Select toxic emotion from dosage picker
- [ ] Verify different layer/dosage works
- [ ] Complete or cancel flow
- [ ] Start new flow
- [ ] Select same emotion as first test
- [ ] Verify selection still works

**Test dosage types:**

- [ ] Select medicinal emotion - verify works
- [ ] Start new flow
- [ ] Select toxic emotion - verify works

**Expected:**
- Phase card tap opens dosage picker smoothly
- Dosage picker displays all emotions for that phase
- Selection closes picker with brief delay for animation
- Smooth transition to secondary prompt
- Selection persists through flow
- Both medicinal and toxic selections work correctly

### Test 2.4: Filter Mode Integration
**Template:** `bug-template-functional.md`

**Context:** Flow uses filtered layers (excludes "Strategies" layer)

- [ ] Verify "Strategies" tab NOT present in flow
- [ ] Verify all emotion layers ARE present
- [ ] Count tabs vs main view layers
- [ ] Main view should have +1 layer (Strategies)

**Expected:**
- Strategies layer correctly filtered out
- Only emotion layers available
- Filter doesn't affect other functionality

**Related:** Layer filtering work from Phase 0

---

## Category 3: Secondary Emotion Flow

**Objective:** Verify secondary emotion prompt and selection

### Test 3.1: Secondary Emotion Prompt
**Template:** `bug-template-functional.md`

**After selecting primary emotion:**

- [ ] Verify prompt appears
- [ ] Verify title/message clear
- [ ] Verify two buttons visible:
  - [ ] "Just [emotion name]" (with actual emotion name)
  - [ ] "Add another feeling"
- [ ] Verify emotion name correctly interpolated
- [ ] Verify button sizes adequate (44pt touch target)
- [ ] Verify buttons not cut off on 41mm

**Expected:**
- Clear prompt asking about additional feelings
- Primary emotion name shown in first button
- Both buttons fully visible and tappable

**Related PR:** #108

### Test 3.2: Skip Secondary Path
**Template:** `bug-template-functional.md`

- [ ] Select primary emotion
- [ ] On secondary prompt, tap "Just [emotion]"
- [ ] Verify immediate transition to strategy selection
- [ ] Verify secondary emotion NOT set
- [ ] Complete flow
- [ ] Verify backend entry has only primary emotion
- [ ] Verify `secondary_curriculum_id` is null in database

**Expected:**
- Skip directly to strategy selection
- No secondary emotion in final submission
- Flow works correctly with single emotion

### Test 3.3: Add Secondary Path
**Template:** `bug-template-functional.md`

- [ ] Select primary emotion (note which one)
- [ ] On secondary prompt, tap "Add another feeling"
- [ ] Verify secondary selection view appears
- [ ] Verify title indicates choosing secondary
- [ ] Verify layer tabs visible
- [ ] Verify emotion list for current layer

**Expected:**
- Smooth transition to secondary selection
- Same layer tabs as primary selection
- Clear indication this is secondary emotion

**Related PR:** #109

### Test 3.4: Secondary Emotion Selection
**Template:** `bug-template-functional.md`

**In secondary selection view:**

- [ ] Verify primary emotion NOT in list (excluded)
- [ ] Verify all other emotions available
- [ ] Test layer switching works
- [ ] Select different emotion
- [ ] Verify transition to strategy selection
- [ ] Verify both emotions remembered

**Test exclusion logic:**

- [ ] Select "Joy" as primary (Purple layer)
- [ ] Add secondary
- [ ] Navigate to Purple layer in secondary view
- [ ] Verify "Joy" NOT in list
- [ ] Verify other Purple emotions ARE in list

**Expected:**
- Primary emotion correctly excluded from secondary selection
- All other emotions available
- Smooth transition to strategy

### Test 3.5: Secondary Selection Edge Cases
**Template:** `bug-template-functional.md`

**Test duplicate prevention:**

- [ ] Select primary emotion
- [ ] Add secondary
- [ ] Switch to same layer as primary
- [ ] Verify primary emotion not available
- [ ] Select different emotion from same layer
- [ ] Verify selection works

**Test multiple layer navigation:**

- [ ] Select primary from Beige
- [ ] Add secondary
- [ ] Browse multiple layers
- [ ] Switch back and forth
- [ ] Select emotion
- [ ] Verify navigation doesn't break selection

**Expected:**
- Duplicate prevention works across layers
- Layer navigation doesn't break flow
- Secondary selection robust

---

## Category 4: Strategy Selection

**Objective:** Verify strategy selection and phase filtering

### Test 4.1: Strategy List Display
**Template:** `bug-template-layout.md`

**After emotion selection(s):**

- [ ] Verify strategy selection view appears
- [ ] Verify title/header clear
- [ ] Verify strategies listed
- [ ] Count strategies (should be filtered by phase)
- [ ] Verify strategy names visible
- [ ] Verify descriptions visible (if shown)
- [ ] Verify list scrolls if many strategies
- [ ] Verify "Skip" button visible
- [ ] Verify all UI elements fit on 41mm

**Expected:**
- Clear list of strategies
- Strategies filtered by current phase
- Skip option available
- No content clipping

**Related PR:** #110

### Test 4.2: Phase Filtering
**Template:** `bug-template-functional.md`

**Context:** Strategies filtered based on phase user is in (from main view)

**Test setup:**

- [ ] Before starting flow, note current phase in main view
- [ ] Expected phase: [e.g., "Rising"]
- [ ] Start flow
- [ ] Complete to strategy selection
- [ ] Verify strategies shown match phase

**Verify filtering:**

- [ ] Check backend catalog for strategies
- [ ] Filter by noted phase
- [ ] Compare with strategies shown in app
- [ ] Should match

**Test different phases:**

- [ ] Return to main view
- [ ] Navigate to different phase (e.g., "Peaking")
- [ ] Start new flow
- [ ] Complete to strategy selection
- [ ] Verify different strategies shown
- [ ] Should match new phase

**Expected:**
- Strategies correctly filtered by phase
- Different phases show different strategies
- Filtering logic accurate

### Test 4.3: Strategy Selection
**Template:** `bug-template-functional.md`

- [ ] Tap a strategy
- [ ] Verify visual feedback (highlight)
- [ ] Verify transition to review
- [ ] Verify selected strategy remembered

**Test multiple selections:**

- [ ] Select strategy
- [ ] Complete or cancel flow
- [ ] Start new flow with different phase
- [ ] Complete to strategy selection
- [ ] Select different strategy
- [ ] Verify selection works

**Expected:**
- Clear selection feedback
- Smooth transition to review
- Selection persists to submission

### Test 4.4: Skip Strategy
**Template:** `bug-template-functional.md`

- [ ] Complete to strategy selection
- [ ] Tap "Skip" button
- [ ] Verify immediate transition to review
- [ ] Verify no strategy set
- [ ] Complete flow
- [ ] Verify backend entry has no strategy
- [ ] Verify `strategy_id` is null in database

**Expected:**
- Skip works correctly
- Review shows no strategy
- Backend entry has no strategy

### Test 4.5: Strategy Display Quality
**Template:** `bug-template-ui.md`

**For each visible strategy:**

- [ ] Verify name fully visible
- [ ] Verify description readable (if shown)
- [ ] Verify no text clipping
- [ ] Verify adequate spacing
- [ ] Verify tappable area sufficient

**Test long strategy names:**

- [ ] Find longest strategy name in catalog
- [ ] Navigate to phase with that strategy
- [ ] Complete flow to strategy selection
- [ ] Verify long name displays correctly
- [ ] No clipping on 41mm watch

**Expected:**
- All text readable
- Long names wrap or truncate gracefully
- No layout issues

---

## Category 5: Journal Review & Submission

**Objective:** Verify review screen and backend submission

### Test 5.1: Review Screen Display
**Template:** `bug-template-layout.md`

**After completing selections:**

- [ ] Verify review screen appears
- [ ] Verify title: "Review Entry" or similar
- [ ] Verify all selected data shown:
  - [ ] Primary emotion (with layer and phase)
  - [ ] Secondary emotion (if selected)
  - [ ] Strategy (if selected)
  - [ ] Timestamp (creation time)
- [ ] Verify data format readable
- [ ] Verify all content fits on screen (41mm)
- [ ] Verify "Log Entry" button visible
- [ ] Verify button enabled (tappable)

**Expected:**
- Complete summary of selections
- Clear, readable formatting
- Submit button prominent
- No content clipped

**Related PR:** #111

### Test 5.2: Review Data Accuracy
**Template:** `bug-template-functional.md`

**Test with different combinations:**

**Combination 1: Primary only**
- [ ] Select primary emotion
- [ ] Skip secondary
- [ ] Skip strategy
- [ ] Verify review shows:
  - Primary: [emotion name], [layer], [phase]
  - Secondary: [Not shown or "None"]
  - Strategy: [Not shown or "None"]

**Combination 2: Primary + Secondary**
- [ ] Select primary emotion
- [ ] Add secondary emotion
- [ ] Skip strategy
- [ ] Verify review shows both emotions

**Combination 3: Primary + Strategy**
- [ ] Select primary emotion
- [ ] Skip secondary
- [ ] Select strategy
- [ ] Verify review shows emotion and strategy

**Combination 4: Full selection**
- [ ] Select primary emotion
- [ ] Add secondary emotion
- [ ] Select strategy
- [ ] Verify review shows all three

**Expected:**
- Review accurately reflects selections
- Missing items handled gracefully
- All combinations display correctly

### Test 5.3: Backend Submission
**Template:** `bug-template-functional.md`

**Preparation:**
- [ ] Clear backend logs
- [ ] Note database journal entry count

**Test submission:**

- [ ] Complete flow with full selection (primary + secondary + strategy)
- [ ] Note selection details:
  - Primary: _______________
  - Secondary: _______________
  - Strategy: _______________
- [ ] On review screen, tap "Log Entry"
- [ ] Verify loading state shown
- [ ] Verify submission completes
- [ ] Verify success alert appears
- [ ] Alert title: "Entry Logged"
- [ ] Alert message: "Thanks for checking in."
- [ ] Tap "OK"
- [ ] Verify alert dismisses
- [ ] Verify flow dismisses
- [ ] Verify returns to main view

**Backend verification:**

```bash
# Check backend logs for POST
# Should see: POST /api/v1/journal 201

# Query database for new entry
curl http://127.0.0.1:8000/api/v1/journal | jq '.[-1]'
# Should return most recent entry
```

**Verify entry data:**
- [ ] `curriculum_id` matches primary emotion
- [ ] `secondary_curriculum_id` matches secondary emotion (if selected)
- [ ] `strategy_id` matches strategy (if selected)
- [ ] `initiated_by` is "self" (if from menu) or "scheduled" (if from notification)
- [ ] `created_at` timestamp accurate
- [ ] `user_id` present

**Expected:**
- Smooth submission with loading indicator
- Success alert shows
- Flow dismisses cleanly
- Entry saved correctly in database

### Test 5.4: Submission Error Handling
**Template:** `bug-template-functional.md`

**Test network failure:**

- [ ] Complete flow to review
- [ ] Stop backend server
- [ ] Tap "Log Entry"
- [ ] Verify submission attempts
- [ ] Verify loading state shows
- [ ] Wait for timeout (should be ~10 seconds)
- [ ] Verify error alert appears
- [ ] Alert title: "Something went wrong" or similar
- [ ] Alert message describes error
- [ ] Tap "OK"
- [ ] Verify alert dismisses
- [ ] Verify still on review screen (can retry)

**Test invalid data:**

- [ ] (This requires backend testing or manipulation)
- [ ] Attempt submission with invalid emotion ID
- [ ] Verify graceful error handling

**Expected:**
- Network errors caught and shown to user
- User-friendly error messages
- Option to retry (stay on review screen)
- No silent failures

### Test 5.5: Submission Loading State
**Template:** `bug-template-ui.md`

- [ ] Complete flow to review
- [ ] Tap "Log Entry"
- [ ] Immediately observe UI
- [ ] Verify loading indicator appears
- [ ] Verify button disabled during submission
- [ ] Verify user can't tap again (double-submission prevention)
- [ ] Wait for completion

**Expected:**
- Clear loading feedback
- Button disabled during loading
- No way to double-submit

---

## Category 6: Flow State Management

**Objective:** Verify state consistency throughout flow

### Test 6.1: Forward Navigation State
**Template:** `bug-template-state.md`

**Trace state through full flow:**

- [ ] Start flow
- [ ] Select primary: [emotion name]
- [ ] Verify `primaryCurriculum` set in ViewModel
- [ ] Add secondary
- [ ] Select secondary: [emotion name]
- [ ] Verify `secondaryCurriculum` set in ViewModel
- [ ] Select strategy: [strategy name]
- [ ] Verify `strategy` set in ViewModel
- [ ] Reach review
- [ ] Verify all three values present in review
- [ ] Submit
- [ ] Verify all three values in submission payload

**Expected:**
- State accumulates correctly through flow
- No state lost between steps
- Review and submission have all selections

### Test 6.2: Backward Navigation State
**Template:** `bug-template-state.md`

**Note:** Check if back navigation is implemented

**If back buttons available:**

- [ ] Complete to secondary selection
- [ ] Go back to secondary prompt
- [ ] Verify primary still selected
- [ ] Go forward again
- [ ] Verify can select secondary
- [ ] Complete to strategy
- [ ] Go back to secondary selection
- [ ] Change secondary emotion
- [ ] Go forward to strategy
- [ ] Verify new secondary used
- [ ] Complete to review
- [ ] Verify changed secondary shown

**Expected:**
- State preserved during back navigation
- Can change selections going backward
- Changed selections reflected in review

**If back navigation not implemented:**
- [ ] Document this as expected behavior

### Test 6.3: Flow State Isolation
**Template:** `bug-template-state.md`

**Test multiple flow instances:**

- [ ] Complete first flow: Primary=Joy, Secondary=Love, Strategy=X
- [ ] Submit
- [ ] Start second flow immediately
- [ ] Verify flow state cleared (no pre-filled selections)
- [ ] Complete second flow: Primary=Fear, Secondary=None, Strategy=None
- [ ] Verify different selections work
- [ ] Verify first flow didn't contaminate second

**Expected:**
- Each flow instance has clean state
- Previous flow selections don't leak
- Multiple flows work independently

### Test 6.4: State Persistence Across Views
**Template:** `bug-template-state.md`

**Test navigation outside flow:**

**Not expected to work (flow is modal), but verify:**

- [ ] Start flow
- [ ] Select primary
- [ ] (Try to navigate to main view - should be blocked by modal)
- [ ] Verify flow remains active
- [ ] Verify can complete or cancel flow

**Expected:**
- Flow is modal, blocks external navigation
- Must complete or cancel to exit
- State maintained within flow

---

## Category 7: Flow Cancellation & Exit

**Objective:** Verify cancel works at every step

### Test 7.1: Cancel from Primary Selection
**Template:** `bug-template-functional.md`

- [ ] Start flow
- [ ] On primary selection screen
- [ ] Verify "Cancel" button visible (top-left or similar)
- [ ] Tap "Cancel"
- [ ] Verify flow dismisses immediately
- [ ] Verify returns to main view
- [ ] Verify no entry saved

**Backend verification:**
```bash
# Check journal entries before and after
curl http://127.0.0.1:8000/api/v1/journal | jq 'length'
# Count should not increase
```

**Expected:**
- Immediate dismissal
- No partial entry saved
- Clean return to main view

### Test 7.2: Cancel from Secondary Prompt
**Template:** `bug-template-functional.md`

- [ ] Start flow
- [ ] Select primary emotion
- [ ] On secondary prompt
- [ ] Verify "Cancel" button visible
- [ ] Tap "Cancel"
- [ ] Verify flow dismisses
- [ ] Verify no entry saved

**Expected:**
- Cancel works at prompt
- Primary selection not saved

### Test 7.3: Cancel from Secondary Selection
**Template:** `bug-template-functional.md`

- [ ] Start flow
- [ ] Select primary
- [ ] Choose to add secondary
- [ ] On secondary selection screen
- [ ] Tap "Cancel"
- [ ] Verify flow dismisses
- [ ] Verify no entry saved

**Expected:**
- Cancel works from secondary selection
- No partial entry

### Test 7.4: Cancel from Strategy Selection
**Template:** `bug-template-functional.md`

- [ ] Start flow
- [ ] Complete to strategy selection
- [ ] Tap "Cancel"
- [ ] Verify flow dismisses
- [ ] Verify no entry saved

**Expected:**
- Cancel works from strategy
- Emotion selections not saved

### Test 7.5: Cancel from Review
**Template:** `bug-template-functional.md`

- [ ] Complete full flow to review
- [ ] Verify all selections shown
- [ ] Tap "Cancel" (if available)
- [ ] OR tap outside sheet to dismiss (if gesture supported)
- [ ] Verify flow dismisses
- [ ] Verify no entry saved

**Expected:**
- Can cancel even from review
- No submission occurs

### Test 7.6: Cancel Button Consistency
**Template:** `bug-template-ui.md`

**Verify cancel button at each step:**

- [ ] Primary selection: "Cancel" visible
- [ ] Secondary prompt: "Cancel" visible
- [ ] Secondary selection: "Cancel" visible
- [ ] Strategy selection: "Cancel" visible
- [ ] Review: "Cancel" visible or gesture to dismiss

**Verify placement:**
- [ ] Consistent position (top-left or top-right)
- [ ] Same label text throughout
- [ ] Same styling throughout
- [ ] Always accessible (not hidden behind content)

**Expected:**
- Cancel consistently available
- Same position and style
- Easy to find and tap

---

## Category 8: Backend Integration

**Objective:** Verify API communication and data format

### Test 8.1: Journal Entry Payload
**Template:** `bug-template-data.md`

**Monitor network request:**

- [ ] Complete flow with all selections
- [ ] Enable Xcode network debugging
- [ ] Tap "Log Entry"
- [ ] Capture HTTP request

**Expected request:**
```json
POST /api/v1/journal
Content-Type: application/json

{
  "curriculum_id": 123,
  "secondary_curriculum_id": 456,
  "strategy_id": 789,
  "initiated_by": "self",
  "created_at": "2025-11-24T12:34:56Z",
  "user_id": "pseudo-user-id"
}
```

**Verify:**
- [ ] Endpoint: `/api/v1/journal`
- [ ] Method: POST
- [ ] Content-Type: application/json
- [ ] All IDs are integers
- [ ] `initiated_by` is "self" or "scheduled"
- [ ] `created_at` is ISO 8601 format
- [ ] `user_id` present

**Expected response:**
```json
201 Created

{
  "id": 999,
  "curriculum_id": 123,
  "secondary_curriculum_id": 456,
  "strategy_id": 789,
  "initiated_by": "self",
  "created_at": "2025-11-24T12:34:56Z",
  "user_id": "pseudo-user-id",
  "curriculum": { ... },
  "secondary_curriculum": { ... },
  "strategy": { ... }
}
```

**Verify:**
- [ ] Status: 201 Created
- [ ] Response includes entry ID
- [ ] Response includes related objects (eager loaded)
- [ ] All fields match request

### Test 8.2: Backend Response Handling
**Template:** `bug-template-functional.md`

**Test success response (201):**
- [ ] Submit entry
- [ ] Verify app shows success alert
- [ ] Verify flow dismisses

**Test error responses:**

**400 Bad Request:**
- [ ] (Requires backend manipulation to trigger)
- [ ] Verify app shows error alert
- [ ] Verify error message user-friendly

**500 Internal Server Error:**
- [ ] (Requires backend manipulation)
- [ ] Verify app handles gracefully
- [ ] Verify error message shown

**Network timeout:**
- [ ] Stop backend mid-submission
- [ ] Verify timeout occurs (~10 seconds)
- [ ] Verify error message shown

**Expected:**
- All response codes handled
- User-friendly error messages
- No crashes on errors

### Test 8.3: Catalog Data Dependency
**Template:** `bug-template-data.md`

**Verify flow uses catalog correctly:**

- [ ] Ensure catalog loaded in main view
- [ ] Start flow
- [ ] Verify emotions match catalog
- [ ] Verify strategies match catalog
- [ ] Submit entry
- [ ] Verify IDs in submission match catalog IDs

**Test with stale catalog:**
- [ ] Load app with cached catalog
- [ ] Backend has updated catalog (if possible)
- [ ] Complete flow
- [ ] Verify submission uses cached IDs (expected)
- [ ] Verify backend accepts cached IDs

**Expected:**
- Flow uses current catalog data
- IDs consistent between app and backend
- Backend validates IDs

### Test 8.4: User ID Generation
**Template:** `bug-template-functional.md`

**Verify pseudo-user ID:**

- [ ] Complete and submit first entry
- [ ] Note `user_id` from backend response
- [ ] Complete and submit second entry
- [ ] Verify `user_id` same as first entry
- [ ] Force quit and relaunch app
- [ ] Complete and submit third entry
- [ ] Verify `user_id` still same

**Check UserDefaults:**
```swift
// In Xcode console
po UserDefaults.standard.string(forKey: "userId")
```

**Expected:**
- Consistent user_id across entries
- Persists across app restarts
- Stored in UserDefaults

---

## Category 9: Error Handling

**Objective:** Verify graceful error handling

### Test 9.1: Network Errors
**Template:** `bug-template-data.md`

**Test submission with backend offline:**

- [ ] Complete flow to review
- [ ] Stop backend server
- [ ] Tap "Log Entry"
- [ ] Observe behavior:
  - [ ] Loading indicator shows
  - [ ] Eventually times out
  - [ ] Error alert appears
  - [ ] Error message clear
- [ ] Tap "OK" on alert
- [ ] Verify returns to review (can retry)

**Restart backend and retry:**
- [ ] Start backend server
- [ ] Tap "Log Entry" again
- [ ] Verify submission succeeds

**Expected:**
- Timeout within reasonable time (~10 seconds)
- Clear error message
- Can retry after fixing issue

### Test 9.2: Invalid Selections
**Template:** `bug-template-functional.md`

**Test edge cases:**

**No emotion selected:**
- [ ] Attempt to skip primary selection
- [ ] Should not be possible (no "Continue" without selection)

**Invalid emotion ID:**
- [ ] (Requires code manipulation or backend testing)
- [ ] Submit entry with non-existent emotion ID
- [ ] Verify backend rejects (400 or 404)
- [ ] Verify app shows error

**Expected:**
- App prevents invalid selections
- Backend validates data
- Errors communicated to user

### Test 9.3: Validation Errors
**Template:** `bug-template-functional.md`

**Test required fields:**

- [ ] Primary emotion required: Enforced by UI (can't proceed without)
- [ ] Secondary emotion optional: Can skip
- [ ] Strategy optional: Can skip
- [ ] Timestamp required: Automatically generated
- [ ] User ID required: Automatically generated

**Verify optional fields:**
- [ ] Submit with only primary
- [ ] Verify backend accepts (201)
- [ ] Verify `secondary_curriculum_id` null
- [ ] Verify `strategy_id` null

**Expected:**
- Required fields enforced
- Optional fields truly optional
- Validation consistent app and backend

---

## Category 10: Edge Cases & Race Conditions

**Objective:** Test unusual scenarios and rapid interactions

### Test 10.1: Rapid Selections
**Template:** `bug-template-functional.md`

**Test rapid tapping:**

- [ ] Start flow
- [ ] Rapidly tap emotions in succession
- [ ] Verify only one selection registers
- [ ] Verify no double-selection
- [ ] Verify smooth transition

**Test rapid flow start/stop:**
- [ ] Open menu
- [ ] Tap "Log Emotion"
- [ ] Immediately tap "Cancel"
- [ ] Repeat 5 times rapidly
- [ ] Verify no issues (crashes, stuck states)

**Expected:**
- Debouncing prevents double-taps
- Rapid interactions handled gracefully
- No race conditions

### Test 10.2: Flow Interruption
**Template:** `bug-template-state.md`

**Test app backgrounding:**

- [ ] Start flow
- [ ] Select primary
- [ ] Background app (swipe up to app switcher)
- [ ] Wait 30 seconds
- [ ] Return to app
- [ ] Verify flow still active
- [ ] Verify selection preserved
- [ ] Complete flow

**Test force quit:**
- [ ] Start flow
- [ ] Select primary
- [ ] Force quit app (swipe up and swipe away)
- [ ] Relaunch app
- [ ] Verify flow dismissed
- [ ] Verify no partial entry saved
- [ ] Verify can start new flow

**Expected:**
- Short backgrounding: Flow preserved
- Force quit: Flow dismissed cleanly
- No corrupted state

### Test 10.3: Memory Pressure
**Template:** `bug-template-performance.md`

**Test with low memory:**

- [ ] (Difficult to simulate on simulator)
- [ ] Complete multiple flows in succession (10+)
- [ ] Monitor memory usage in Xcode
- [ ] Verify no memory leaks
- [ ] Verify app doesn't crash

**Expected:**
- No memory leaks
- Stable memory usage
- No crashes under repeated use

### Test 10.4: Unusual Catalog Data
**Template:** `bug-template-functional.md`

**Test with minimal catalog:**
- [ ] (Requires backend manipulation)
- [ ] Catalog with only 1 layer
- [ ] Catalog with only 1 emotion per layer
- [ ] Verify flow handles gracefully

**Test with maximal catalog:**
- [ ] Catalog with many layers (20+)
- [ ] Catalog with many emotions per layer (50+)
- [ ] Verify scrolling works
- [ ] Verify performance acceptable

**Expected:**
- Flow adapts to catalog size
- UI handles edge cases
- No hardcoded assumptions broken

### Test 10.5: Phase Changes During Flow
**Template:** `bug-template-state.md`

**Test phase change while in flow:**

**Setup:**
- [ ] Note current phase in main view
- [ ] Start flow
- [ ] Complete to strategy selection
- [ ] Note strategies shown (filtered by original phase)

**While flow open (if possible):**
- [ ] (This likely isn't possible since flow is modal)
- [ ] Attempt to change phase in main view
- [ ] Should be blocked by modal flow

**Expected behavior:**
- Phase locked when flow starts
- Strategy filtering uses starting phase
- Phase changes don't affect active flow

### Test 10.6: Duplicate Prevention
**Template:** `bug-template-functional.md`

**Test selecting same emotion twice:**

- [ ] Select "Joy" as primary
- [ ] Add secondary
- [ ] Attempt to select "Joy" again
- [ ] Verify "Joy" not in secondary list

**Test with different layers:**
- [ ] Select "Love" (Purple) as primary
- [ ] Add secondary
- [ ] Navigate to Purple layer
- [ ] Verify "Love" not in list
- [ ] Navigate to other layers
- [ ] Verify other emotions available

**Expected:**
- Primary emotion excluded from secondary
- Exclusion works across layers
- UI prevents duplicate selection

---

## Testing Workflow

### Before Testing Session

- [ ] Start backend: `uvicorn backend.app:app --reload`
- [ ] Verify backend: `curl http://127.0.0.1:8000/api/v1/catalog`
- [ ] Launch Xcode with 41mm simulator
- [ ] Clear any existing test data if needed
- [ ] Have backend logs visible
- [ ] Have Xcode console visible
- [ ] Open bug report templates

### During Testing Session

1. **Test systematically** - Follow categories in order
2. **Check boxes** - Mark tests as complete
3. **Take screenshots** - Capture issues immediately
4. **Note observations** - Document unexpected behavior
5. **Try to reproduce** - Reproduce bugs 2-3 times
6. **Fill templates** - Use appropriate bug template for issues found

### After Testing Session

- [ ] Review all test results
- [ ] File bug reports for issues found
- [ ] Create GitHub issues
- [ ] Update this testing plan with findings
- [ ] Create testing summary

---

## Bug Report Checklist

When you find an issue:

- [ ] Stop and reproduce 2-3 times
- [ ] Choose appropriate template:
  - Layout issues → `bug-template-layout.md`
  - Navigation issues → `bug-template-navigation.md`
  - Feature broken → `bug-template-functional.md`
  - Data issues → `bug-template-data.md`
  - Performance → `bug-template-performance.md`
  - State issues → `bug-template-state.md`
  - UI issues → `bug-template-ui.md`
- [ ] Fill out all sections
- [ ] Capture screenshots/video
- [ ] Save in `bugs/reports/`
- [ ] Create GitHub issue
- [ ] Link to epic #92

---

## Success Criteria

**Flow Functionality:**
- [ ] All entry points work
- [ ] All steps complete successfully
- [ ] All combinations work (primary only, +secondary, +strategy)
- [ ] Backend submission successful
- [ ] Data persisted correctly

**User Experience:**
- [ ] UI clear and intuitive
- [ ] No content clipping on 41mm
- [ ] Smooth transitions
- [ ] Appropriate loading states
- [ ] Clear error messages

**Technical Quality:**
- [ ] No crashes
- [ ] No memory leaks
- [ ] No race conditions
- [ ] State managed correctly
- [ ] Backend integration solid

**Edge Cases:**
- [ ] Cancel works at all steps
- [ ] Error handling graceful
- [ ] Rapid interactions handled
- [ ] Unusual data handled

---

## Known Issues to Verify

From related PRs and issues:

- [ ] #112 - Notification routing (PR open, needs testing)
- [ ] #88 - Detail view entry points (not yet implemented)
- [ ] Secondary emotion exclusion logic
- [ ] Strategy phase filtering accuracy
- [ ] Loading state during submission

---

## Testing Summary Template

After completing all tests:

```markdown
# Emotion Logging Flow Testing Summary - YYYY-MM-DD

**Tester:** [Name]
**Duration:** [Hours]
**Build:** [Commit SHA]
**Watch Sizes Tested:** 41mm, 45mm, 49mm

## Categories Tested
- [ ] 1. Flow Entry Points
- [ ] 2. Primary Emotion Selection
- [ ] 3. Secondary Emotion Flow
- [ ] 4. Strategy Selection
- [ ] 5. Journal Review & Submission
- [ ] 6. Flow State Management
- [ ] 7. Flow Cancellation & Exit
- [ ] 8. Backend Integration
- [ ] 9. Error Handling
- [ ] 10. Edge Cases

## Issues Found
- 🔴 Critical: [count]
- 🟠 High: [count]
- 🟡 Medium: [count]
- 🟢 Low: [count]

## Bug Reports Filed
- [Link to bug report 1]
- [Link to bug report 2]

## GitHub Issues Created
- #XXX - [Title]
- #XXX - [Title]

## Overall Assessment
[Pass/Fail/Conditional Pass]

[Summary of major findings]

## Recommendations
[Next steps, priority fixes, etc.]
```

---

**Ready to test the emotion logging flow! 🧪**

**Start with Category 1 (Flow Entry Points) and work through systematically.**
