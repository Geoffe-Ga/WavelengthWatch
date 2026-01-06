# Epic #186: Offline Journal Queue - Summary

**Created:** 2026-01-05
**Epic URL:** https://github.com/Geoffe-Ga/WavelengthWatch/issues/186

## Overview

Complete offline queueing system for journal entries, allowing users to log emotions and self-care when offline. Entries automatically sync when connectivity is restored.

## Issue Breakdown

### Phase 1: Foundation (Parallel Development Possible)

1. **#189 - JournalQueue Service**
   - File-based persistent queue
   - FIFO ordering with UUID-based idempotency
   - Atomic writes, corruption recovery
   - **Complexity:** Medium
   - **Files:** New `Services/JournalQueue.swift`

2. **#201 - NetworkMonitor Service**
   - NWPathMonitor-based connectivity detection
   - Published state for SwiftUI observation
   - Distinguishes wifi/cellular/none
   - **Complexity:** Easy-Medium
   - **Files:** New `Services/NetworkMonitor.swift`

3. **#213 - Backend Idempotency**
   - In-memory cache for MVP (24h TTL)
   - Accepts `Idempotency-Key` header
   - Returns existing entry for duplicate keys
   - **Complexity:** Medium
   - **Files:** `backend/routers/journal.py`, new test file

### Phase 2: Sync Logic (Requires Phase 1)

4. **#214 - JournalSyncService**
   - Orchestrates queue + network + client
   - Exponential backoff retry (1s, 2s, 4s)
   - Differentiates validation vs network errors
   - Triggers on: network restore, manual sync
   - **Complexity:** Medium-High
   - **Files:** New `Services/JournalSyncService.swift`

5. **#215 - JournalClient Integration**
   - Auto-queue on retryable errors
   - Pass idempotency keys from queue
   - New error type: `JournalError.queuedForRetry`
   - Update ContentViewModel feedback
   - **Complexity:** Medium
   - **Files:** `Services/JournalClient.swift`, `ViewModels/ContentViewModel.swift`

### Phase 3: UI Integration (Requires Phase 2)

6. **#216 - Queue Status UI**
   - Queue count indicator in main view
   - Enhanced feedback: success/queued/syncing/failure
   - Optional: SyncStatusView for detailed management
   - Sync progress updates
   - **Complexity:** Medium
   - **Files:** `ContentView.swift`, `JournalReviewView.swift`, possibly new `SyncStatusView.swift`

### Phase 4: Testing (Requires All Above)

7. **#218 - Comprehensive Testing**
   - Integration tests for offline → online flows
   - Idempotency verification
   - App lifecycle (restart, termination during sync)
   - Performance benchmarks
   - Manual test scenarios (airplane mode, etc.)
   - **Complexity:** High (but critical)
   - **Files:** New `OfflineQueueIntegrationTests.swift`, test utilities

## Key Design Decisions

### Data Flow
```
[User logs emotion]
  ↓
[JournalClient.submit()]
  ↓
[Online?] → Yes → [POST to backend with idempotency key]
  ↓ No
[Enqueue to JournalQueue]
  ↓
[Show "Saved locally" feedback]
  ↓
[Network restored]
  ↓
[JournalSyncService.processQueue()]
  ↓
[Submit with idempotency key]
  ↓
[Backend checks cache, returns existing if duplicate]
  ↓
[Dequeue on success]
```

### Storage Strategy
- **Queue:** JSON file in Documents directory
- **Idempotency cache:** In-memory dict for MVP (migrate to DB post-production)
- **Queue limit:** 100 entries max

### Retry Strategy
- **Attempts:** 3 per entry
- **Backoff:** 1s, 2s, 4s (exponential)
- **Validation errors:** Remove from queue immediately
- **Network/server errors:** Keep in queue, increment retry count

### Error Categorization
- **Retryable:** Network timeouts, 5xx server errors
- **Non-retryable:** 400 validation errors, decoding failures

## Implementation Order

**Sequential (by phase):**
1. Phase 1: #189, #201, #213 (can work in parallel)
2. Phase 2: #214 (needs Phase 1 complete)
3. Phase 2: #215 (needs #214)
4. Phase 3: #216 (needs Phase 2)
5. Phase 4: #218 (needs everything)

**Estimated Timeline:**
- Phase 1: ~2-3 days (parallel)
- Phase 2: ~2-3 days (sequential dependency)
- Phase 3: ~1-2 days
- Phase 4: ~2-3 days
- **Total:** ~7-11 days for full implementation

## Success Metrics

- [ ] Users can log entries offline without errors
- [ ] Queue persists across app restarts
- [ ] No duplicate entries in backend
- [ ] Sync happens automatically within 5s of reconnection
- [ ] All tests pass (unit + integration)
- [ ] Code coverage > 80% for queue/sync components

## Documentation References

- **Full spec:** `prompts/claude-comm/offline-journal-queue-spec.md`
- **This summary:** `prompts/claude-comm/epic-186-summary.md`
- **Test results:** (will be created) `prompts/claude-comm/offline-testing-report.md`

## Next Steps for Future Agents

1. Read this summary + full spec
2. Start with Phase 1 issues (#189, #201, #213)
3. Each issue contains complete implementation details
4. Follow TDD: write tests first, then implementation
5. Update epic #186 checkboxes as issues are completed
6. Run comprehensive tests (#218) before closing epic

## Questions/Decisions Made

1. **Queue size:** 100 entries (reasonable for watch app)
2. **Retry attempts:** 3 with backoff (balance reliability vs UX)
3. **Idempotency storage:** In-memory for MVP (OK per CLAUDE.md)
4. **Sync triggers:** Network change + manual (no background tasks for MVP)
5. **UI feedback:** Distinct messages for queued vs failed

## Future Enhancements (Post-MVP)

- BackgroundTasks framework for sync while app is suspended
- Database-backed idempotency keys (migration to production)
- User-facing sync history view
- Push notifications for background sync results
- Analytics on queue metrics
- Conflict resolution for server-modified entries
