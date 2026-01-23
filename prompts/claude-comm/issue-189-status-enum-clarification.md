# Status Enum Clarification: QueueStatus vs SyncStatus

**Issue #189 - JournalQueue Service**
**Date**: 2026-01-23
**Status**: Documentation Clarification

## Overview

The codebase uses TWO distinct status enums that serve different purposes and track different state machines. This document clarifies their roles and why both are necessary.

## The Two Status Enums

### 1. `SyncStatus` (LocalJournalEntry.swift)
**Location**: `frontend/WavelengthWatch/WavelengthWatch Watch App/Models/LocalJournalEntry.swift`

```swift
enum SyncStatus: String, Codable {
  case pending   // Entry exists only locally
  case synced    // Entry successfully synced to backend
  case failed    // Sync attempted but failed
}
```

**Purpose**: Tracks the **backend synchronization state** of a journal entry

**Lifecycle**: Permanent property of LocalJournalEntry
- Created with `.pending` status
- Updated to `.synced` after successful backend POST
- Updated to `.failed` if backend POST fails
- **Persists forever** in `journal.sqlite` (via JournalDatabase)

**Used By**:
- `JournalDatabase` (persistent storage)
- Analytics/UI to show sync health
- Historical record of which entries reached backend

### 2. `QueueStatus` (JournalQueueModels.swift)
**Location**: `frontend/WavelengthWatch/WavelengthWatch Watch App/Models/JournalQueueModels.swift`

```swift
enum QueueStatus: String, Codable {
  case pending   // Entry waiting in queue
  case syncing   // Entry currently being synced (request in-flight)
  case synced    // Entry successfully synced (ready for cleanup)
  case failed    // Sync attempt failed (needs retry)
}
```

**Purpose**: Tracks the **queue coordination state** for sync operations

**Lifecycle**: Temporary property of JournalQueueItem
- Created with `.pending` when enqueued
- Transitions to `.syncing` when sync starts
- Transitions to `.synced` or `.failed` when sync completes
- **Deleted after 30 days** if status is `.synced`

**Used By**:
- `JournalQueue` (sync coordination)
- `JournalSyncService` (Issue #214) to manage sync lifecycle
- Cleanup operations to remove old synced items

## Key Differences

| Aspect | SyncStatus | QueueStatus |
|--------|------------|-------------|
| **Scope** | Global (entire entry) | Local (queue item) |
| **Database** | `journal.sqlite` | `journal_queue.sqlite` |
| **Lifecycle** | Permanent | Temporary (cleanup after sync) |
| **State Machine** | 2 transitions | 3 transitions |
| **Purpose** | Historical sync record | Active sync coordination |
| **Has "syncing"** | No | Yes (important!) |

## Why QueueStatus Has "syncing" But SyncStatus Doesn't

### SyncStatus Logic:
```swift
// In JournalClient.createEntry()
let entry = LocalJournalEntry(...) // syncStatus = .pending
try await journalDatabase.insert(entry)

// Later, in JournalSyncService
if success {
  entry.syncStatus = .synced
  try await journalDatabase.update(entry)
} else {
  entry.syncStatus = .failed
  try await journalDatabase.update(entry)
}
```

**No need for "syncing" because**:
- It's a **binary result**: either synced or failed
- The journal entry doesn't need to track in-flight state
- If app crashes during sync, entry remains `.pending` (safe default)

### QueueStatus Logic:
```swift
// In JournalSyncService
let pending = try queue.pendingEntries()

for item in pending {
  try queue.markSyncing(id: item.id)  // CRITICAL: prevents duplicate syncs

  do {
    let response = try await backend.postJournal(item.localEntry)
    try queue.markSynced(id: item.id)
  } catch {
    try queue.markFailed(id: item.id, error: error)
  }
}
```

**"syncing" is essential because**:
- **Prevents duplicate syncs**: If another sync cycle starts, it won't pick up items with status `.syncing`
- **Handles crashes gracefully**: On restart, `.syncing` items can be reset to `.pending` or `.failed`
- **Enables monitoring**: UI can show "X items syncing, Y pending"

## State Machine Diagrams

### SyncStatus State Machine:
```
        [Create]
           ↓
       [pending] ────────→ [synced]
           ↓
           └────────────→ [failed]
```
**2 states after creation**: synced or failed

### QueueStatus State Machine:
```
       [Enqueue]
           ↓
       [pending] ────→ [syncing] ────→ [synced]
                           ↓
                           └────────→ [failed] ────→ [pending] (retry)
                                                         ↑
                                                         └──────────┘
```
**3 states after enqueue**: syncing → synced or failed (with retry loop)

## Example: Complete Flow

```swift
// 1. User creates journal entry
let entry = LocalJournalEntry(...)
// entry.syncStatus = .pending  (SyncStatus)

// 2. Persist to database
try await journalDatabase.insert(entry)

// 3. Enqueue for sync
try journalQueue.enqueue(entry)
// Creates JournalQueueItem with status = .pending (QueueStatus)

// 4. Sync cycle picks it up
try queue.markSyncing(id: entry.id)
// QueueStatus: .pending → .syncing

// 5a. Sync succeeds
try await backend.postJournal(entry)
entry.syncStatus = .synced  // Update SyncStatus
try await journalDatabase.update(entry)
try queue.markSynced(id: entry.id)  // Update QueueStatus
// Later: cleanup removes from queue

// 5b. Sync fails
entry.syncStatus = .failed  // Update SyncStatus
try await journalDatabase.update(entry)
try queue.markFailed(id: entry.id, error: error)  // Update QueueStatus
// Remains in queue for retry
```

## Why Not Use a Single Enum?

### Attempted Unification (REJECTED):
```swift
enum UnifiedSyncStatus {
  case pending   // Not yet synced
  case syncing   // Currently syncing
  case synced    // Successfully synced
  case failed    // Sync failed
}
```

**Problems:**
1. **LocalJournalEntry never needs "syncing"** - it's a persistent record, not a coordination mechanism
2. **Queue needs "syncing" to prevent duplicates** - critical for correctness
3. **Different cleanup semantics** - journal keeps all, queue removes synced items
4. **Mixing concerns** - single enum couples persistence with coordination

## Conclusion

**Both enums are necessary** because they track fundamentally different aspects of the system:
- **SyncStatus**: "Has this entry ever been synced to the backend?" (historical record)
- **QueueStatus**: "What is the current state of this sync attempt?" (active coordination)

The superficial similarity (both have `pending`, `synced`, `failed`) is coincidental. The presence of `syncing` in QueueStatus reveals their different purposes.

## Related Files

- `frontend/WavelengthWatch/WavelengthWatch Watch App/Models/LocalJournalEntry.swift` (SyncStatus)
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Models/JournalQueueModels.swift` (QueueStatus)
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Services/JournalQueue.swift` (uses QueueStatus)
- `frontend/WavelengthWatch/WavelengthWatch Watch App/Services/JournalDatabase.swift` (uses SyncStatus)
