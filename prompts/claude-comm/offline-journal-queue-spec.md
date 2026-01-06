# Offline Journal Queue - Technical Specification

**Created:** 2026-01-05
**Epic:** TBD (will be created as GitHub issue)

## Executive Summary

Implement offline queueing for journal entries to allow users to log emotions and self-care even when the watch or backend is unreachable. Queued entries will automatically submit once connectivity is restored.

## Current State

### Journal Submission Flow
1. User completes emotion/self-care flow in `JournalReviewView`
2. `FlowCoordinator.submit()` calls `ContentViewModel.journalThrowing()`
3. `ContentViewModel` calls `JournalClient.submit()` (frontend/WavelengthWatch Watch App/Services/JournalClient.swift:80)
4. `JournalClient` makes immediate POST to `/api/v1/journal` via `APIClient`
5. Backend validates and persists (backend/routers/journal.py:124)

### Current Error Handling
- Network/backend errors throw from `JournalClient`
- `FlowCoordinator.submit()` propagates errors to `JournalReviewView`
- User sees generic error: "We couldn't log your entry. Please try again."
- Entry is **lost** - no retry, no queuing

### Existing Infrastructure
- **Persistence:** Only `UserDefaults` for user identifier (JournalClient.swift:56)
- **Network monitoring:** None
- **Queue mechanism:** None
- **Idempotency:** None

## Requirements

### Functional Requirements

**FR1: Offline Detection**
- Detect when network is unavailable or backend is unreachable
- Distinguish between network errors and validation errors (400 Bad Request should NOT queue)

**FR2: Local Queue Persistence**
- Store failed journal entries locally on device
- Persist queue across app restarts
- Include all entry data: curriculum IDs, strategy ID, timestamp, initiated_by

**FR3: Automatic Retry**
- Submit queued entries when connectivity is restored
- Retry in chronological order (oldest first)
- Exponential backoff for transient failures

**FR4: Idempotency**
- Prevent duplicate submissions if entry was actually saved but response was lost
- Use client-generated unique IDs for deduplication

**FR5: User Feedback**
- Show clear status: "Saved locally" vs "Submitted to backend"
- Display queue count in UI when entries are pending
- Indicate when queue is syncing

**FR6: Data Integrity**
- Never lose user data - queue must be durable
- Handle edge cases: app termination during sync, low storage, etc.

### Non-Functional Requirements

**NFR1: Performance**
- Queue operations must not block UI (<100ms)
- Background sync should not drain battery excessively

**NFR2: Storage**
- Reasonable queue size limits (suggest 100 entries max)
- Automatic cleanup of old synced entries

**NFR3: Testing**
- Full offline scenario test coverage
- Simulate network failures, backend errors, app restarts

## Architecture Design

### Components

#### 1. JournalQueue (New Service)
**Location:** `frontend/WavelengthWatch Watch App/Services/JournalQueue.swift`

**Responsibilities:**
- Persist pending entries to disk
- Manage queue operations (enqueue, dequeue, peek)
- Expose queue state (count, isEmpty)

**Storage Format:** JSON file in app's documents directory
```swift
struct QueuedEntry: Codable {
  let id: UUID  // Client-generated for idempotency
  let payload: JournalPayload
  let createdAt: Date
  let retryCount: Int
  let lastRetryAt: Date?
}
```

#### 2. NetworkMonitor (New Service)
**Location:** `frontend/WavelengthWatch Watch App/Services/NetworkMonitor.swift`

**Responsibilities:**
- Monitor network reachability using NWPathMonitor
- Publish connectivity state changes
- Detect when backend is reachable (optional: health check endpoint)

**API:**
```swift
@Observable
class NetworkMonitor {
  var isConnected: Bool
  var connectionType: ConnectionType // wifi, cellular, none
}
```

#### 3. JournalSyncService (New Service)
**Location:** `frontend/WavelengthWatch Watch App/Services/JournalSyncService.swift`

**Responsibilities:**
- Orchestrate queue + network state
- Trigger automatic sync when connectivity restored
- Implement retry logic with exponential backoff
- Handle idempotency

**Sync Strategy:**
- Trigger on: Network becomes available, app foreground, manual retry
- Process queue sequentially (one at a time)
- On success: Remove from queue
- On validation error (400): Remove from queue, log warning
- On network/server error (500, timeout): Keep in queue, backoff

#### 4. JournalClient (Modified)
**Changes:**
- Add idempotency key header to POST requests
- Return more detailed error types (NetworkError vs ValidationError vs ServerError)

#### 5. Backend Endpoint (Modified)
**Changes:**
- Accept optional `Idempotency-Key` header
- Track processed idempotency keys (in-memory cache or database table)
- Return 200 with existing entry if duplicate key detected

### Data Flow

#### Scenario 1: Online Submission (Happy Path)
```
User completes flow
  → FlowCoordinator.submit()
  → ContentViewModel.journalThrowing()
  → JournalClient.submit() [with idempotency key]
  → POST /api/v1/journal
  → Success
  → Remove from queue (if was queued)
  → Show success feedback
```

#### Scenario 2: Offline Submission (Queue Path)
```
User completes flow
  → FlowCoordinator.submit()
  → ContentViewModel.journalThrowing()
  → JournalClient.submit() [fails with network error]
  → Catch error, enqueue to JournalQueue
  → Show "Saved locally, will sync when online" feedback
  → [Later: network restored]
  → NetworkMonitor fires connectivity change
  → JournalSyncService.processQueue()
  → Submit each queued entry with idempotency key
  → On success: dequeue
```

#### Scenario 3: Duplicate Prevention
```
User submits entry
  → Request sent with idempotency key X
  → Backend saves entry, response lost in transit
  → Client thinks it failed, queues entry
  → Client retries with same idempotency key X
  → Backend detects duplicate, returns existing entry
  → Client dequeues successfully
```

## Implementation Plan

### Phase 1: Foundation (Issues #1-3)
1. **Issue #1:** Implement JournalQueue service with file-based persistence
2. **Issue #2:** Implement NetworkMonitor service
3. **Issue #3:** Add idempotency support to backend endpoint

### Phase 2: Sync Logic (Issues #4-5)
4. **Issue #4:** Implement JournalSyncService with retry logic
5. **Issue #5:** Integrate queue into JournalClient error handling

### Phase 3: UI Integration (Issue #6)
6. **Issue #6:** Update UI to show queue status and sync feedback

### Phase 4: Testing (Issue #7)
7. **Issue #7:** Comprehensive offline scenario testing

## Testing Strategy

### Unit Tests
- JournalQueue: enqueue, dequeue, persistence across restarts
- NetworkMonitor: state changes, edge cases
- JournalSyncService: retry logic, backoff, error categorization

### Integration Tests
- End-to-end offline flow: submit → queue → connectivity → sync
- Idempotency: duplicate submissions detected
- App lifecycle: queue survives termination/restart

### Manual Testing Scenarios
1. Submit entry while airplane mode enabled
2. Submit entry while backend is down
3. Submit multiple entries offline, verify ordered sync
4. Kill app during sync, verify recovery on restart
5. Low storage scenarios

## Edge Cases & Error Handling

### Edge Case 1: Queue Full
**Solution:** Limit queue to 100 entries. When full, show error: "Local queue full. Please connect to internet to sync."

### Edge Case 2: Entry Too Old
**Solution:** Backend may reject entries >7 days old. Client should warn user before discarding.

### Edge Case 3: Schema Migration
**Solution:** If backend schema changes (e.g., curriculum IDs become invalid), queue entries may fail validation. Show detailed error to user, allow manual discard.

### Edge Case 4: Clock Skew
**Solution:** Use client timestamp but validate on backend. Large skew (>24h) triggers warning.

### Edge Case 5: Battery/Performance
**Solution:** Use BackgroundTasks framework for sync, not aggressive polling. Respect low power mode.

## Security Considerations

- **Idempotency keys:** Use UUIDs, not predictable values
- **Local storage:** Queue file stored in app sandbox, encrypted by iOS
- **No credentials in queue:** User ID is pseudo-anonymous hash

## Metrics & Observability

### Metrics to Track (Future)
- Queue size distribution
- Sync success rate
- Average time-to-sync
- Network error frequency

### Logging
- Log all queue operations (enqueue, dequeue, retry)
- Log network state changes
- Log sync failures with error details

## Rollout Strategy

### MVP (This Epic)
- Basic queue + sync for journal entries
- File-based persistence
- Simple retry logic (3 attempts with backoff)

### Future Enhancements (Post-MVP)
- Background sync using BackgroundTasks framework
- Conflict resolution for entries modified on server
- Analytics on queue metrics
- User-facing sync history view

## References

- Current JournalClient: `frontend/WavelengthWatch Watch App/Services/JournalClient.swift`
- Current backend endpoint: `backend/routers/journal.py:124`
- Journal models: `backend/schemas.py:110-149`
- Flow coordinator: `frontend/WavelengthWatch Watch App/ViewModels/FlowCoordinator.swift:107`

## Open Questions

1. **Queue size limit:** 100 entries reasonable? Adjust based on testing.
2. **Retry attempts:** 3 attempts with exponential backoff? Or unlimited until success?
3. **Health check endpoint:** Should we add `/health` to backend for connectivity testing?
4. **Background sync:** Use BackgroundTasks or rely on app foreground events?

---

**Note:** This document will be updated as implementation progresses and new insights emerge.
