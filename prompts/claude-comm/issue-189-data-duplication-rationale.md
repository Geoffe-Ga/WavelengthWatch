# JournalQueue Data Duplication Rationale

**Issue #189 - JournalQueue Service**
**Date**: 2026-01-23
**Status**: Architectural Decision Record

## Overview

The JournalQueue implementation uses a **separate SQLite database** (`journal_queue.sqlite`) distinct from the main journal database (`journal.sqlite` managed by `JournalDatabase`). This creates intentional data duplication that serves specific architectural purposes.

## Duplication Details

### What is Duplicated?
- **LocalJournalEntry objects** exist in both databases:
  - `journal.sqlite` via `JournalDatabase` (persistent journal records)
  - `journal_queue.sqlite` via `JournalQueue` (sync queue with metadata)

### What is NOT Duplicated?
- **Queue metadata** (status, retry_count, last_attempt) exists ONLY in queue
- **Sync state tracking** is separate from journal persistence

## Rationale for Separate Databases

### 1. **Separation of Concerns**
- **JournalDatabase**: Persistent storage of journal entries (source of truth)
- **JournalQueue**: Transient sync coordination with lifecycle metadata

### 2. **Independent Lifecycle Management**
- **Journal entries** persist indefinitely (user's historical record)
- **Queue entries** are cleaned up after successful sync (temporary coordination)

### 3. **Schema Evolution Independence**
- **Queue schema** can evolve to support retry strategies, rate limiting, batch operations without touching journal schema
- **Journal schema** changes don't affect sync coordination logic

### 4. **Performance Isolation**
- **Queue operations** (high frequency: status updates, cleanup) don't lock journal database
- **Journal queries** for analytics aren't blocked by sync operations

### 5. **Failure Domain Isolation**
- **Queue corruption** doesn't compromise journal integrity
- **Queue deletion** (for reset/debugging) doesn't lose user data

## Alternative Considered: Single Database with Status Column

### Why We Rejected This:

```swift
// REJECTED: Single table approach
CREATE TABLE journal (
  id TEXT PRIMARY KEY,
  // ... journal fields ...
  sync_status TEXT,        // 'pending', 'syncing', 'synced', 'failed'
  retry_count INTEGER,
  last_sync_attempt REAL
)
```

**Problems:**
1. **Lifecycle confusion**: When to delete a row? (Never? After sync? After 30 days?)
2. **Query complexity**: Every journal query must filter out sync metadata concerns
3. **Performance**: High-frequency sync updates cause journal table churn
4. **Schema bloat**: Sync-specific fields pollute core journal model

## Data Flow

```
User Action
   ↓
LocalJournalEntry created
   ↓
   ├─→ JournalDatabase.insert()     [Persistent storage]
   │   └─→ journal.sqlite
   │
   └─→ JournalQueue.enqueue()       [Sync coordination]
       └─→ journal_queue.sqlite
```

**Sync Cycle:**
```
JournalQueue.pendingEntries()
   ↓
Backend sync attempt
   ↓
Success: JournalQueue.markSynced()  → cleanupSynced() later removes
Failure: JournalQueue.markFailed()  → retry with backoff
```

## Storage Overhead

### Typical Entry Size:
- LocalJournalEntry JSON: ~200 bytes
- Queue metadata: ~50 bytes
- **Total per entry**: ~250 bytes

### Cleanup Strategy:
- Synced entries removed after 30 days (configurable)
- Failed entries remain for manual review/retry
- Typical steady-state: <100 pending entries = 25KB

### Verdict: Negligible
- Even 1000 pending entries = 250KB
- Modern devices: 64GB+ storage
- Trade-off: <1MB duplication for architectural clarity

## Integration with JournalClient

```swift
// JournalClient.createEntry() will do:
func createEntry(...) async throws {
  // 1. Create local entry
  let entry = LocalJournalEntry(...)

  // 2. Persist to journal (source of truth)
  try await journalDatabase.insert(entry)

  // 3. Enqueue for sync (if sync enabled)
  if syncSettings.cloudSyncEnabled {
    try journalQueue.enqueue(entry)
  }

  // 4. JournalSyncService (Issue #214) handles background sync
}
```

## Future Considerations

### Consolidation Scenarios:
- If queue metadata needed for analytics → create view joining both databases
- If performance becomes critical → benchmark before consolidating
- If storage becomes constrained → implement aggressive cleanup policies first

### Current Recommendation: **Keep Separate**
The architectural benefits outweigh the minimal storage cost.

## Related Issues

- **Issue #189**: JournalQueue implementation (this document)
- **Issue #214**: JournalSyncService (will consume queue)
- **Issue #215**: Integration with JournalClient

## References

- `frontend/WavelengthWatch/WavelengthWatch Watch App/Services/JournalQueue.swift`
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Services/JournalDatabase.swift`
- SQLite Multi-Database Pattern: https://www.sqlite.org/lang_attach.html
