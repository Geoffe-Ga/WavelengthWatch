# Mystery Solved: Test Crash Root Cause Timeline

## The Investigation

We discovered a paradox: `MockNotificationCenter` subclassing `UNUserNotificationCenter` worked at commit 54a965a but failed at commit b0c2642, even though both commits used the same subclassing pattern.

## The Timeline

### Commit 54a965a ("fix(tests): Fix all remaining test failures") ✅ TESTS PASS
```swift
final class NotificationDelegate: ObservableObject {
  @Published var scheduledNotificationReceived: (scheduleId: String, initiatedBy: InitiatedBy)?

  nonisolated init() {}  // ← Explicit nonisolated init

  @MainActor
  func handleNotificationResponse(_ response: UNNotificationResponse) { }
}
```
- No `@MainActor` on class itself
- Explicit `nonisolated init()`
- Tests: **PASS** ✅

### Commits ddb61de → eb485b3
- Notification system REMOVED from `WavelengthWatchApp.swift`
- App temporarily has NO notification handling

### Commit 096600b ("feat(journal): Add notification tap handling with tests") ❌ TESTS CRASH
```swift
@MainActor  // ← @MainActor on ENTIRE CLASS
final class NotificationDelegate: ObservableObject {
  @Published var scheduledNotificationReceived: (scheduleId: String, initiatedBy: InitiatedBy)?

  // No explicit init - compiler generates @MainActor init

  func handleNotificationResponse(_ response: UNNotificationResponse) { }
}
```
- **@MainActor annotation added to entire class**
- No explicit init → compiler generates `@MainActor init()`
- This makes `@StateObject` initialization fail in test environment
- Tests: **CRASH** ❌ (SIGSEGV)

### Current HEAD (e7b7d5a after MainActor refactoring) ❌ TESTS STILL CRASH
```swift
final class NotificationDelegate: ObservableObject {
  @Published var scheduledNotificationReceived: ScheduledNotification?

  nonisolated init() {}  // ← Fixed: explicit nonisolated init

  @MainActor
  func handleNotificationResponse(_ response: UNNotificationResponse) { }
}
```
- `@MainActor` removed from class
- Explicit `nonisolated init()` added
- BUT tests still crash!
- Tests: **CRASH** ❌ (SIGSEGV)

## The Root Cause

**Bug #1**: Adding `@MainActor` to `NotificationDelegate` class at commit 096600b caused the implicit initializer to become `@MainActor`, which conflicts with `@StateObject` initialization in tests.

**Bug #2**: The MainActor refactoring CORRECTLY fixed Bug #1 by removing `@MainActor` from the class and adding `nonisolated init()`.

**Bug #3**: Despite fixing Bug #1, tests STILL crash. This means there's ANOTHER issue introduced between commits 54a965a and current HEAD that's independent of the `NotificationDelegate` @MainActor issue.

## What Changed Between 54a965a and Current HEAD?

The notification system was completely rewritten:
- Removed and then re-added with different architecture
- Added `configureNotificationCategories()` method
- Changed delegate setup pattern (moved to `.onAppear`)
- Added `ScheduledNotification` struct
- Changed published property type from tuple to struct

## Next Steps

Since the MainActor refactoring fixed the `NotificationDelegate` issue but tests still crash, we need to investigate what else changed that could cause test crashes. The crash must be in one of these areas:

1. **App initialization**: `init()` calling `configureNotificationCategories()`
2. **@StateObject lifecycle**: When/how `notificationDelegate` is accessed
3. **Delegate setup timing**: The `.onAppear` pattern vs. `init()` setup
4. **Test environment**: Something about the test harness that conflicts with the new architecture

## Conclusion

The "mystery" wasn't a paradox - it was TWO separate bugs:
- **Bug A** (096600b → refactoring): `@MainActor NotificationDelegate` class caused crashes
- **Bug B** (54a965a → current): Something else changed that also causes crashes

The refactoring fixed Bug A, but Bug B remains.
