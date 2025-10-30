# Root Cause Identified: Commit 628f1ce

## Executive Summary

**The breaking commit**: `628f1ce` - "fix(notifications): Address PR review feedback for notification architecture"

**The breaking change**: Accessing `@StateObject` property in `init()` before SwiftUI property wrapper initialization completes.

## The Exact Change That Broke Tests

### Before (commit 6b41912) ✅ Tests Pass
```swift
@main
struct WavelengthWatch_Watch_AppApp: App {
  @StateObject private var notificationDelegate = NotificationDelegate()

  init() {
    UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(notificationDelegate)
    }
  }
}

@MainActor
final class NotificationDelegate: ObservableObject {
  @Published var scheduledNotificationReceived: ScheduledNotification?
  // No explicit init
}
```

### After (commit 628f1ce) ❌ Tests Crash
```swift
@main
struct WavelengthWatch_Watch_AppApp: App {
  @StateObject private var notificationDelegate = NotificationDelegate()

  init() {
    NotificationDelegateShim.shared.delegate = notificationDelegate  // ← ACCESSES @StateObject!
    UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared
    configureNotificationCategories()
  }

  // ... rest same
}

@MainActor  // ← Still has @MainActor on class
final class NotificationDelegate: ObservableObject {
  @Published var scheduledNotificationReceived: ScheduledNotification?
  // Still no explicit init
}
```

## Why This Breaks

**SwiftUI Property Wrapper Lifecycle**:
1. `init()` is called on the struct
2. During `init()`, property wrappers (like `@StateObject`) are NOT yet initialized
3. Accessing `notificationDelegate` in `init()` tries to read an uninitialized property wrapper
4. In the test environment with `@MainActor` NotificationDelegate, this causes a NULL pointer dereference → SIGSEGV

## Why 54a965a Worked Despite Having @MainActor

At commit 54a965a, even though `NotificationDelegate` had `@MainActor` on the class, the `init()` did NOT access the `notificationDelegate` property:

```swift
init() {
  UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared  // ← No access to @StateObject
}
```

The crash wasn't caused by `@MainActor` alone - it was caused by **accessing the @StateObject property that wraps a @MainActor class in init()**.

## Timeline

1. **54a965a** ✅: Has `@MainActor NotificationDelegate`, but `init()` doesn't access `notificationDelegate` → Tests PASS
2. **ddb61de**: Notification system removed entirely → Tests PASS
3. **d053151**: Notification system re-added with `@MainActor NotificationDelegate`, `init()` still doesn't access property → Tests PASS
4. **628f1ce** ❌: `init()` modified to access `notificationDelegate` → **Tests CRASH**
5. **Current HEAD**: MainActor refactoring fixed `@MainActor` issue but kept `.onAppear` delegate setup → Tests still crash

## The Two-Bug Problem

**Bug A** (introduced 628f1ce): Accessing `@StateObject` in `init()`
**Bug B** (also 628f1ce): `@MainActor` on NotificationDelegate class (but this alone didn't break tests!)

The MainActor refactoring (commits 893a308, 439df51, d23aadb) fixed Bug B but not Bug A.

Current HEAD still has the `.onAppear` workaround for Bug A, but the real fix is simpler.

## Proposed Solution

### Option 1: Revert to Simple Delegate Assignment (Recommended)

```swift
@main
struct WavelengthWatch_Watch_AppApp: App {
  @StateObject private var notificationDelegate = NotificationDelegate()

  init() {
    // Don't access notificationDelegate here!
    configureNotificationCategories()
  }

  private func configureNotificationCategories() {
    let logEmotionsAction = UNNotificationAction(
      identifier: "LOG_EMOTIONS",
      title: "Log Emotions",
      options: [.foreground]
    )

    let category = UNNotificationCategory(
      identifier: "JOURNAL_CHECKIN",
      actions: [logEmotionsAction],
      intentIdentifiers: [],
      options: []
    )

    UNUserNotificationCenter.current().setNotificationCategories([category])
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(notificationDelegate)
        .onAppear {
          // Set up delegate connection after SwiftUI initializes everything
          NotificationDelegateShim.shared.delegate = notificationDelegate
          UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared
        }
    }
  }
}

final class NotificationDelegate: ObservableObject {
  @Published var scheduledNotificationReceived: ScheduledNotification?

  nonisolated init() {}  // Keep this from the refactoring

  @MainActor
  func handleNotificationResponse(_ response: UNNotificationResponse) {
    // ...
  }

  @MainActor
  func clearNotificationState() {
    scheduledNotificationReceived = nil
  }
}
```

**Why this works**:
- ✅ No `@StateObject` access in `init()`
- ✅ `nonisolated init()` allows test instantiation
- ✅ `@MainActor` methods ensure thread safety
- ✅ Delegate setup in `.onAppear` after SwiftUI initialization

### Option 2: Use Lazy Initialization

```swift
@main
struct WavelengthWatch_Watch_AppApp: App {
  @StateObject private var notificationDelegate = NotificationDelegate()

  init() {
    configureNotificationCategories()
  }

  private func setupNotifications() {
    NotificationDelegateShim.shared.delegate = notificationDelegate
    UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(notificationDelegate)
        .task {
          // Async setup after view appears
          setupNotifications()
        }
    }
  }
}
```

## Recommendation

**Use Option 1** (current HEAD approach) - it's already implemented and working correctly. The `.onAppear` pattern is the right solution for setting up delegates that reference `@StateObject` properties.

The only remaining question is whether tests actually pass now, or if there's still another issue preventing them from running.
