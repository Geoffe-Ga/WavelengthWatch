# Apple Watch Testing Program for WavelengthWatch

**Purpose:** Comprehensive testing protocol for watchOS Journal feature on Simulator and physical Apple Watch devices.

**Last Updated:** 2025-10-20

---

## Pre-Testing Setup

### Environment Requirements
- **Xcode:** 16.4+
- **watchOS Simulator:** Apple Watch Series 10 (46mm) - watchOS 11.0+
- **Physical Device:** Apple Watch Series 6+ recommended
- **Backend:** FastAPI server running on `http://localhost:8000` or configured API endpoint

### Initial Setup Checklist
- [ ] Backend server is running and accessible
- [ ] API_BASE_URL configured in Xcode project (Info.plist or APIConfiguration.plist)
- [ ] Simulator paired with iPhone simulator
- [ ] Physical watch paired and development profile installed
- [ ] Notification permissions granted (will prompt on first launch)

---

## Testing Phases

## Phase 1: Simulator Functional Testing

### 1.1 Basic Journal Flow (Self-Initiated)

**Objective:** Verify primary journal entry flow works end-to-end

**Steps:**
1. Launch app on simulator
2. Navigate through layers (vertical scroll with Digital Crown)
3. Navigate through phases (horizontal swipe or Digital Crown)
4. Tap a curriculum card (e.g., "Commitment" in Beige layer, Rising phase)
5. Tap the mystical journal icon (glowing + button)
6. Confirm "Log Commitment" alert → Tap "Yes"

**Expected Results:**
- [ ] Secondary feeling prompt appears: "Pick a secondary feeling?"
- [ ] Tapping "No" shows self-care prompt: "Log what self-care you will use?"
- [ ] Tapping "No" shows success feedback
- [ ] Backend receives POST to `/api/v1/journal` with:
  - `curriculum_id` = selected ID
  - `initiated_by` = "self_initiated"
  - `created_at` = current UTC timestamp

**Verification:**
```bash
# Check backend logs or query database
curl http://localhost:8000/api/v1/journal | jq '.[-1]'
```

### 1.2 Secondary Feeling Selection

**Objective:** Verify secondary curriculum flow

**Steps:**
1. Log primary curriculum (as in 1.1)
2. When "Pick a secondary feeling?" appears → Tap "Yes"
3. Navigate to different phase/layer
4. Tap secondary curriculum card
5. Tap journal icon and confirm

**Expected Results:**
- [ ] Secondary feeling prompt closes after tapping "Yes"
- [ ] User can navigate freely to select secondary
- [ ] After logging secondary, self-care prompt appears
- [ ] Backend receives entry with both `curriculum_id` and `secondary_curriculum_id`

### 1.3 Self-Care Strategy Flow

**Objective:** Verify strategy logging with primary curriculum preservation

**Steps:**
1. Log primary curriculum (as in 1.1)
2. Tap "No" for secondary feeling
3. Tap "Yes" for self-care prompt
4. Verify navigation to Strategies layer (layer 0)
5. Verify phase matches primary curriculum's phase
6. Tap strategy journal icon (+ button)
7. Confirm "Log Strategy" alert → Tap "Yes"

**Expected Results:**
- [ ] Automatically navigates to Strategies layer
- [ ] Phase is preserved from primary selection
- [ ] Strategy list shows strategies for correct phase
- [ ] Backend receives entry with `curriculum_id` (primary) and `strategy_id`
- [ ] `pendingJournalEntry` is cleared after logging

**Critical Test:** Verify strategy is logged against PRIMARY curriculum ID, not a fallback
```bash
# Check last journal entry has correct curriculum_id
curl http://localhost:8000/api/v1/journal | jq '.[-1] | {curriculum_id, strategy_id}'
```

### 1.4 Offline Queue Functionality

**Objective:** Verify offline persistence and retry

**Steps:**
1. **Disconnect backend:** Stop FastAPI server
2. Log a journal entry (self-initiated)
3. Observe failure feedback: "We couldn't log your entry. It's been saved and will retry automatically."
4. Check pending count indicator (should show "1 pending")
5. **Reconnect backend:** Restart FastAPI server
6. Trigger retry (app should auto-retry on next launch or network change)

**Expected Results:**
- [ ] Entry is queued locally (UserDefaults persistence)
- [ ] UI shows pending count
- [ ] On retry, entry successfully submits to backend
- [ ] Pending count decreases to 0
- [ ] Original timestamp and `initiated_by` preserved

**Manual Retry Trigger:**
- Force quit app and relaunch (should trigger `processOfflineQueue()`)

### 1.5 Scheduled Notification Flow

**Objective:** Verify scheduled notification triggers journal flow

**Steps:**
1. Open Schedule Settings (need to integrate into UI first - see Issues below)
2. Add new schedule:
   - Time: 2 minutes from now
   - Days: Today
   - Enable toggle ON
3. Wait for notification to fire
4. Tap notification
5. Log journal entry

**Expected Results:**
- [ ] Notification appears at scheduled time: "Journal Check-In"
- [ ] Tapping notification opens app
- [ ] `initiated_by` is set to `scheduled` (not `self_initiated`)
- [ ] Backend receives entry with `initiated_by: "scheduled"`

**Current Issues:**
- ⚠️ `ScheduleSettingsView` exists but not integrated into main navigation
- ⚠️ Need to add settings button/icon to ContentView
- ⚠️ NotificationDelegateShim doesn't forward to NotificationDelegate (line 67 TODO)

---

## Phase 2: Simulator UI/UX Testing

### 2.1 Visual Consistency

**Objective:** Verify mystical aesthetic consistency

**Areas to Check:**
- [ ] Curriculum cards have glowing circles with phase colors
- [ ] Mystical journal icon (+ button) animates/glows
- [ ] Layer transitions smooth (90° rotation)
- [ ] Phase horizontal scroll works with Digital Crown
- [ ] Alert modals match app aesthetic (not default iOS blue)
- [ ] Success feedback appears and dismisses correctly

**Screenshots to Capture:**
- [ ] Each layer (Strategies, Beige, Purple, Red, Orange, Yellow, Green, Blue, Turquoise)
- [ ] Each phase (Rising, Peaking, Falling, Recovering, Integrating, Embodying)
- [ ] Secondary feeling prompt
- [ ] Self-care prompt
- [ ] Strategy list view
- [ ] Success feedback

### 2.2 Navigation Testing

**Objective:** Verify all navigation paths work

**Test Matrix:**
| From Layer | To Layer | Method | Expected Result |
|------------|----------|--------|-----------------|
| Beige | Purple | Vertical scroll down | Smooth transition, Purple phase appears |
| Beige | Strategies | Tap journal → Yes → No → Yes | Auto-navigate to Strategies layer |
| Rising | Peaking | Horizontal swipe left | Phase changes, curriculum updates |
| Peaking | Rising | Horizontal swipe right | Phase changes, curriculum updates |
| Any | Detail | Tap chevron | CurriculumDetailView opens |
| Detail | Any | Swipe down/back | Returns to layer/phase view |

### 2.3 Accessibility Testing

**Objective:** Verify VoiceOver compatibility

**Steps:**
1. Enable VoiceOver: Settings → Accessibility → VoiceOver
2. Navigate through app using VoiceOver gestures
3. Test all interactive elements

**VoiceOver Checklist:**
- [ ] Layer titles announced correctly
- [ ] Phase names announced
- [ ] Curriculum cards have meaningful labels (e.g., "Commitment, Medicinal")
- [ ] Journal icon has label: "Log this feeling"
- [ ] Alert buttons have clear labels
- [ ] Toggle switches announce state (on/off)

**Minimum Tap Targets:**
- [ ] All buttons ≥ 44x44 pt
- [ ] Curriculum cards tappable area sufficient
- [ ] Journal icon easily tappable

---

## Phase 3: Physical Apple Watch Testing

### 3.1 Performance Testing

**Objective:** Verify app performs well on actual hardware

**Metrics to Observe:**
- [ ] **Launch time:** App opens < 2 seconds
- [ ] **Layer scroll smoothness:** No frame drops during vertical scroll
- [ ] **Phase scroll smoothness:** No frame drops during horizontal scroll
- [ ] **API response time:** Journal submission < 1 second (local network)
- [ ] **Offline queue:** Retry happens within 10 seconds of reconnection

**Test on Multiple Devices:**
- Apple Watch Series 6 (baseline)
- Apple Watch Series 10 (latest)
- Apple Watch SE (budget model)

### 3.2 Battery Impact Testing

**Objective:** Verify app doesn't drain battery excessively

**Setup:**
1. Charge watch to 100%
2. Normal usage: 10 journal entries spread over 4 hours
3. With scheduling: 5 scheduled notifications over 4 hours

**Acceptable Thresholds:**
- [ ] Battery drain < 5% over 4 hours with normal usage
- [ ] Background refresh doesn't cause excessive drain
- [ ] Notifications don't wake screen unnecessarily

**Instruments Profiling:**
```bash
# Run from Xcode → Product → Profile
# Select "Energy Log" template
# Monitor for 15 minutes during active use
```

### 3.3 Network Conditions Testing

**Objective:** Verify app handles poor connectivity gracefully

**Test Scenarios:**

| Scenario | Network | Expected Behavior |
|----------|---------|-------------------|
| 1 | WiFi + Cellular | Immediate success, no queue |
| 2 | WiFi only, weak signal | May queue, retries successfully |
| 3 | No WiFi, cellular only | Works if iPhone in range |
| 4 | Airplane mode | Queues immediately, shows pending count |
| 5 | Intermittent (toggle WiFi) | Retries on reconnection |

**Verification:**
- Watch backend logs for retry attempts
- Check `pendingJournalCount` updates correctly
- Verify no duplicate submissions

### 3.4 Real-World Notification Testing

**Objective:** Verify notifications work in daily use

**Setup:**
1. Configure 3 schedules:
   - Morning: 8:00 AM, weekdays only
   - Lunch: 12:30 PM, every day
   - Evening: 8:00 PM, weekends only
2. Wear watch for 1 week

**Observations to Log:**
- [ ] Notifications fire at correct times
- [ ] Watch vibrates/sounds appropriately
- [ ] Tapping notification opens app correctly
- [ ] `initiated_by` is always `scheduled` for notification-triggered entries
- [ ] No duplicate notifications
- [ ] Disabled schedules don't fire

**Edge Cases:**
- [ ] Watch charging during scheduled time
- [ ] Watch in Theater Mode
- [ ] Watch in Do Not Disturb
- [ ] User already using app when notification fires
- [ ] Notification arrives while watch locked

---

## Phase 4: Integration Testing

### 4.1 Backend Integration

**Objective:** Verify frontend-backend contract

**API Endpoints to Test:**

#### GET /api/v1/catalog
```bash
curl http://localhost:8000/api/v1/catalog | jq
```
- [ ] Returns all layers with phases
- [ ] Includes medicinal/toxic curriculum entries
- [ ] Includes strategies per phase
- [ ] Response time < 500ms

#### POST /api/v1/journal
```bash
curl -X POST http://localhost:8000/api/v1/journal \
  -H "Content-Type: application/json" \
  -d '{
    "curriculum_id": 1,
    "user_id": 123456,
    "initiated_by": "self_initiated",
    "created_at": "2025-10-20T12:00:00Z"
  }'
```
- [ ] Returns 201 Created
- [ ] Response includes ID, relationships loaded
- [ ] Invalid curriculum_id returns 400
- [ ] Missing fields return 422

#### GET /api/v1/journal
```bash
curl http://localhost:8000/api/v1/journal?user_id=123456 | jq
```
- [ ] Returns user's journal entries
- [ ] Includes related curriculum/strategy data
- [ ] Supports filtering by date, initiated_by

#### GET /api/v1/strategy
```bash
curl http://localhost:8000/api/v1/strategy?phase_id=1 | jq
```
- [ ] Returns strategies for specific phase
- [ ] Includes Cache-Control header (max-age=3600)
- [ ] Response time < 300ms

### 4.2 Data Consistency Testing

**Objective:** Verify data integrity across offline/online cycles

**Test Sequence:**
1. **Online:** Log 3 entries (primary only)
2. **Offline:** Log 2 entries (primary + secondary)
3. **Offline:** Log 1 entry (primary + strategy)
4. **Online:** Trigger retry
5. **Verify:** All 6 entries in backend with correct data

**Expected Results:**
- [ ] All 6 entries present in database
- [ ] Timestamps match original creation time (not retry time)
- [ ] `initiated_by` values preserved
- [ ] Relationships (secondary_curriculum_id, strategy_id) intact
- [ ] No duplicate entries

---

## Phase 5: Regression Testing

### 5.1 Post-Phase 4 Verification

**Critical Paths to Retest:**
- [ ] Task 4.15: Strategy endpoint cache headers present
- [ ] Task 4.16: Navigation to Strategies layer preserves phase
- [ ] Task 4.17: Strategy logging uses PRIMARY curriculum ID (not fallback)
- [ ] Task 4.18: End-to-end flow (primary → secondary → self-care → strategy)

**Automated Tests:**
```bash
# Backend tests
cd /Users/geoffgallinger/Projects/WavelengthWatchRoot
.venv/bin/python -m pytest tests/backend/ -v

# Expected: 27/27 passing
```

**Frontend Tests:**
```bash
# Run from Xcode
xcodebuild test \
  -scheme "WavelengthWatch Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)'

# Key tests:
# - preservesPendingJournalEntryForStrategyLogging
# - preservesPhaseWhenNavigatingToStrategies
# - endToEndFlowFromPrimaryToStrategyLogging
```

### 5.2 Edge Case Testing

**Scenario 1: Rapid Submissions**
- Log 10 entries in < 10 seconds
- Expected: All queued/submitted, no race conditions

**Scenario 2: Invalid Data**
- Attempt to log with non-existent curriculum_id
- Expected: 400/422 error, entry NOT queued

**Scenario 3: Queue Overflow**
- Fill queue with 50 entries (offline)
- Expected: All persist, process in order

**Scenario 4: App Backgrounded**
- Start journal flow → background app → return
- Expected: Flow state preserved, can continue

**Scenario 5: Watch Restart**
- Queue 5 entries → restart watch
- Expected: Queue persists, retries on launch

---

## Testing Checklist Summary

### Simulator (Required Before Physical Device)
- [ ] 1.1 Basic journal flow
- [ ] 1.2 Secondary feeling selection
- [ ] 1.3 Self-care strategy flow
- [ ] 1.4 Offline queue functionality
- [ ] 1.5 Scheduled notification flow
- [ ] 2.1 Visual consistency
- [ ] 2.2 Navigation testing
- [ ] 2.3 Accessibility testing

### Physical Apple Watch (Pre-Production)
- [ ] 3.1 Performance testing
- [ ] 3.2 Battery impact testing
- [ ] 3.3 Network conditions testing
- [ ] 3.4 Real-world notification testing

### Integration (Continuous)
- [ ] 4.1 Backend integration
- [ ] 4.2 Data consistency testing

### Regression (After Each Feature)
- [ ] 5.1 Post-phase verification
- [ ] 5.2 Edge case testing

---

## Known Issues & Workarounds

### Issue 1: Schedule Settings Not Accessible
**Status:** ⚠️ Blocker for 1.5 testing
**Description:** `ScheduleSettingsView` exists but no UI to access it
**Workaround:** Manually navigate in code or add temporary button
**Fix Required:** Add settings icon to ContentView toolbar

### Issue 2: NotificationDelegate Not Wired
**Status:** ⚠️ Medium priority
**Location:** `WavelengthWatchApp.swift:67`
**Description:** NotificationDelegateShim doesn't forward to NotificationDelegate
**Impact:** Notification response handling may not work correctly
**Fix Required:** Forward `didReceive response:` to NotificationDelegate

### Issue 3: No Visual Feedback for Pending Queue
**Status:** ℹ️ Enhancement
**Description:** Pending count exists but not prominently displayed
**Impact:** Users unaware of queued entries
**Fix Required:** Add badge or indicator to main view

### Issue 4: Schedule UI Not Mystical
**Status:** ℹ️ Enhancement
**Description:** Settings use standard iOS components, not app aesthetic
**Impact:** Inconsistent UX
**Fix Required:** Redesign with cosmic gradients, glowing toggles, etc.

---

## Test Results Log Template

Use this template to document test runs:

```markdown
## Test Run: [Date] - [Phase Number]

**Tester:** [Name]
**Device:** [Simulator | Apple Watch Model]
**watchOS Version:** [e.g., 11.0]
**Backend:** [localhost:8000 | production URL]

### Results

| Test ID | Test Name | Status | Notes |
|---------|-----------|--------|-------|
| 1.1 | Basic journal flow | ✅ Pass | |
| 1.2 | Secondary feeling | ❌ Fail | Navigation didn't preserve phase |
| ... | ... | ... | ... |

### Issues Found

1. **[Issue Title]**
   - Severity: [Critical | High | Medium | Low]
   - Steps to reproduce: ...
   - Expected: ...
   - Actual: ...
   - Screenshot: [attach if available]

### Coverage Summary

- **Total Tests:** 25
- **Passed:** 23
- **Failed:** 2
- **Skipped:** 0
- **Pass Rate:** 92%

### Next Steps

- [ ] Fix failing tests
- [ ] Retest on physical device
- [ ] Update documentation
```

---

## Simulator Testing Commands

### Launch Simulator
```bash
# List available simulators
xcrun simctl list devices | grep "Apple Watch"

# Boot specific simulator
xcrun simctl boot "Apple Watch Series 10 (46mm)"

# Open Simulator app
open -a Simulator
```

### Build and Run
```bash
# Build for simulator
xcodebuild build \
  -scheme "WavelengthWatch Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)'

# Run tests
xcodebuild test \
  -scheme "WavelengthWatch Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)'
```

### Debug Logs
```bash
# Watch simulator logs
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.geoffgallinger.WavelengthWatch"'

# Check notification state
xcrun simctl push booted com.geoffgallinger.WavelengthWatch notification.apns
```

---

## Physical Device Testing Commands

### Install on Device
```bash
# List connected devices
xcrun xctrace list devices

# Install app (replace with actual device UDID)
xcodebuild install \
  -scheme "WavelengthWatch Watch App" \
  -destination 'platform=watchOS,id=<DEVICE_UDID>'
```

### Capture Logs
```bash
# Real-time logs from physical watch
idevicesyslog -u <DEVICE_UDID> | grep WavelengthWatch
```

---

## Success Criteria

### Minimum Viable Product (MVP)
- [ ] All Phase 1-4 tests passing on simulator
- [ ] Core journal flow works on physical device
- [ ] Offline queue tested and verified
- [ ] No crashes during 30-minute stress test
- [ ] Backend integration working

### Production Ready
- [ ] All tests passing on simulator AND physical device
- [ ] Battery impact < 5% over 4 hours
- [ ] All accessibility issues resolved
- [ ] Notification flow fully working
- [ ] Real-world testing completed (1 week)
- [ ] Performance benchmarks met
- [ ] All known issues resolved or documented

---

**End of Testing Program**

For questions or to report issues, update this document or create an entry in `/prompts/claude-comm/`.
