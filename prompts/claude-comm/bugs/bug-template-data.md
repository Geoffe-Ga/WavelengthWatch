# Bug Report: [Brief Title - Data Issue]

**Date:** YYYY-MM-DD
**Reporter:** [Your Name]
**Category:** Data / Loading / Sync
**Status:** 🔴 New

---

## Bug Summary

[One sentence description of the data issue]

---

## Severity & Priority

**Severity:** [Choose one]
- 🔴 Critical - Data loss, corruption, or app unusable without data
- 🟠 High - Incorrect data displayed, sync failures
- 🟡 Medium - Data loading issues, stale data
- 🟢 Low - Minor data inconsistencies

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

**Backend:**
- Status: [ ] Running [ ] Offline
- URL: [e.g., http://127.0.0.1:8000]
- Database state: [ ] Fresh [ ] Has data

---

## Data Type

**What kind of data is affected?**

- [ ] Catalog data (layers, phases, emotions, strategies)
- [ ] Journal entries
- [ ] User preferences (UserDefaults)
- [ ] Cache data
- [ ] Schedule data
- [ ] Other: _________________

---

## Steps to Reproduce

1. [First step - be specific about data state]
2. [Second step]
3. [Third step]
4. [Continue until issue appears]

**Example:**
1. Delete app to clear all cached data
2. Stop backend server (offline mode)
3. Launch app
4. Observe loading behavior
5. Check what data is displayed

---

## Expected Behavior

[What should happen with the data]

**Example:**
The app should show "Loading curriculum…" briefly, then display an error message: "Unable to load curriculum. Please check your connection." A "Retry" button should be available.

---

## Actual Behavior

[What actually happens with the data]

**Example:**
The app shows "Loading curriculum…" indefinitely. No error message appears. The app is stuck in loading state and cannot be used. Logs show repeated timeout errors.

---

## Visual Evidence

### Screenshots

**Location:** `prompts/claude-comm/bugs/screenshots/[issue-name]/`

- [ ] Screenshot of incorrect data display
- [ ] Screenshot of loading state
- [ ] Screenshot of error message (if any)
- [ ] Screenshot of backend logs

### Video

- [ ] Screen recording showing data loading flow: `[filename].mov`
- [ ] Duration: [X seconds]

---

## Data Details

**Expected Data:**

```json
{
  "layers": [...],
  "phases": [...],
  "curriculum": [...]
}
```

**Actual Data:**

```json
{
  // Paste actual data or describe what's wrong
}
```

**Missing Fields:**
- [ ] layers
- [ ] phases
- [ ] curriculum
- [ ] strategies
- [ ] Other: _________________

**Incorrect Values:**
- Field: _________ | Expected: _________ | Actual: _________
- Field: _________ | Expected: _________ | Actual: _________

---

## Network Activity

**Backend Requests:**

**Expected:**
- Endpoint: [e.g., GET /api/v1/catalog]
- Status: [e.g., 200 OK]
- Response time: [e.g., <1s]

**Actual:**
- Request sent: [ ] Yes [ ] No
- Status: [e.g., 500 Error, Timeout, No response]
- Response time: [e.g., 30s timeout]
- Error message: _______________

**Backend Logs:**

```
[Paste relevant backend logs]
```

**Frontend Logs:**

```
[Paste relevant console output from Xcode]
```

---

## Cache State

**Is caching involved?**

- [ ] Yes
- [ ] No
- [ ] Unknown

**Cache Status:**

- Cache file exists: [ ] Yes [ ] No
- Cache file location: [path]
- Cache file size: [bytes]
- Cache timestamp: [when created]
- Cache validity: [ ] Valid [ ] Stale [ ] Corrupted

**Cache Behavior:**

- [ ] Cache loaded successfully
- [ ] Cache failed to load
- [ ] Cache loaded but data is stale
- [ ] Cache corrupted
- [ ] Cache not used when it should be
- [ ] Cache used when it shouldn't be

---

## Offline Behavior

**Test with backend offline:**

- App behavior: [Describe what happens]
- Data available: [ ] Yes (from cache) [ ] No
- Error handling: [ ] Graceful [ ] Poor [ ] None
- User can continue: [ ] Yes [ ] No [ ] Partially

---

## Data Persistence

**Is data persisted correctly?**

**UserDefaults:**
- [ ] Values saved correctly
- [ ] Values loaded correctly
- [ ] Values missing/corrupted

**FileSystem (Cache):**
- [ ] Files written correctly
- [ ] Files read correctly
- [ ] Files missing/corrupted

**Backend Database:**
- [ ] Entries created correctly
- [ ] Entries retrieved correctly
- [ ] Entries missing/corrupted

---

## Data Integrity

**Is there data loss or corruption?**

- [ ] Yes - Data lost permanently
- [ ] Yes - Data corrupted
- [ ] No - Data intact
- [ ] Unknown

**If yes, describe:**

[What data was lost or corrupted?]

**Can data be recovered?**

- [ ] Yes
- [ ] No
- [ ] Unknown

---

## Code Locations

**Suspected files:**

- [ ] `CatalogRepository.swift` - Lines: _______
- [ ] `JournalClient.swift` - Lines: _______
- [ ] `APIClient.swift` - Lines: _______
- [ ] `ContentViewModel.swift` - Lines: _______
- [ ] Cache implementation: _______ - Lines: _______
- [ ] Backend routers: _______
- [ ] Other: _________________

**Suspected causes:**

- [ ] Network timeout
- [ ] API endpoint issue
- [ ] Data parsing error
- [ ] Cache invalidation issue
- [ ] Missing error handling
- [ ] Race condition
- [ ] Database query issue
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

[Describe any way to work around this issue]

**Example:**
Restart the app with backend running. The catalog will load correctly from the API.

---

## User Impact

**Who is affected?**

- [ ] All users (no cached data)
- [ ] Users in offline mode
- [ ] Users with stale cache
- [ ] Users on first launch
- [ ] Other: _________________

**App usability:**

- [ ] App completely unusable
- [ ] Core features blocked
- [ ] Some features available
- [ ] App fully usable (data cosmetic issue)

---

## Regression

- [ ] This worked correctly before
- [ ] This is a new feature/endpoint
- [ ] Unknown

**If regression, when did it break?**

- Commit/PR: [SHA or PR number]
- What changed: [Brief description]

---

## Suggested Fix

**Proposed solution:**

[If you have ideas for how to fix this, describe them here]

**Example:**
1. Add timeout configuration to URLSession (currently 2 minutes, should be 10 seconds)
2. Add retry logic with exponential backoff
3. Show user-facing error message after timeout
4. Provide "Retry" button
5. Fall back to cached data if available

**Files to modify:**

- [ ] File: _____________ - Change: _____________
- [ ] File: _____________ - Change: _____________

---

## Test Coverage

**Are there tests for this data loading path?**

- [ ] Yes, tests exist
- [ ] No, tests needed
- [ ] Unknown

**Tests to add/fix:**

**Example:**
```swift
@Test func testCatalogLoadingWithTimeout() async {
  // Given backend is offline
  // When catalog is requested
  // Then should timeout after 10 seconds
  // And should show error message
}

@Test func testCatalogFallbackToCache() async {
  // Given cache exists
  // And backend is offline
  // When catalog is requested
  // Then should load from cache
  // And app should be functional
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

**Conditions:**

[What conditions are needed to reproduce?]

---

## Checklist

- [ ] Bug reproduced at least twice
- [ ] Backend logs captured
- [ ] Frontend logs captured
- [ ] Network requests logged
- [ ] Cache state verified
- [ ] Data samples collected
- [ ] All relevant information filled out
- [ ] GitHub issue created: #______
- [ ] Related issues linked

---

## Notes

[Any additional notes, observations, or context about the data issue]
