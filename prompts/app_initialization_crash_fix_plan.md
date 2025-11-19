# 2025-10-29: App Initialization Crash - Property Access Before Initialization

**Status**: 🔴 CRITICAL ROOT CAUSE IDENTIFIED
**Problem**: `@StateObject` accessed in `init()` before SwiftUI initializes it
**Location**: `WavelengthWatchApp.swift:16`
**Impact**: All tests crash during app bootstrap

---

## Root Cause: Property Initialization Order Bug

### The Fatal Code Pattern

```swift
@main
struct WavelengthWatch_Watch_AppApp: App {
  @StateObject private var notificationDelegate = NotificationDelegate()

  init() {
    // ❌ CRASH: Accessing @StateObject before SwiftUI initializes it!
    NotificationDelegateShim.shared.delegate = notificationDelegate
    UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared
    configureNotificationCategories()
  }
}
```

### Why This Crashes

1. `@StateObject` is a property wrapper managed by SwiftUI
2. SwiftUI initializes property wrappers AFTER `init()` completes
3. Accessing `notificationDelegate` in `init()` tries to read uninitialized memory
4. This causes SIGSEGV (segmentation fault) during app bootstrap
5. Tests crash because they instantiate the app to run

### Why Tests Worked Before

**PR #54 introduced this code pattern**. Before PR #54, there was NO `NotificationDelegate` being accessed in `init()`.

**The @MainActor refactoring didn't cause the crash** — it just happened to be implemented AFTER the buggy code was merged, so we blamed the wrong thing.

---

## Solution: Move Delegate Setup Out of init()

### Option A: Use onAppear in ContentView (RECOMMENDED)

Move delegate setup to SwiftUI lifecycle hooks where `@StateObject` is guaranteed initialized:

```swift
@main
struct WavelengthWatch_Watch_AppApp: App {
  @StateObject private var notificationDelegate = NotificationDelegate()

  init() {
    // ✅ Safe: Only configure categories, don't access notificationDelegate
    configureNotificationCategories()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(notificationDelegate)
        .onAppear {
          // ✅ Safe: @StateObject is initialized by this point
          NotificationDelegateShim.shared.delegate = notificationDelegate
          UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared
        }
    }
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
}
```

**Pros**:
- Guaranteed @StateObject initialization
- Minimal code changes
- Standard SwiftUI pattern

**Cons**:
- Setup happens slightly later (after first view appears)
- If user goes to background before onAppear, notifications won't be configured (unlikely)

---

### Option B: Use Static/Singleton Pattern

Remove `@StateObject` and use a singleton:

```swift
@main
struct WavelengthWatch_Watch_AppApp: App {
  private let notificationDelegate = NotificationDelegate.shared  // Singleton

  init() {
    NotificationDelegateShim.shared.delegate = notificationDelegate
    UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared
    configureNotificationCategories()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(notificationDelegate)
    }
  }
}

// In NotificationDelegate:
final class NotificationDelegate: ObservableObject {
  static let shared = NotificationDelegate()  // Singleton

  @Published var scheduledNotificationReceived: ScheduledNotification?

  private init() {}  // Private init for singleton

  @MainActor
  func handleNotificationResponse(_ response: UNNotificationResponse) {
    // ...
  }
}
```

**Pros**:
- Setup happens immediately in init()
- No timing issues
- Simpler lifecycle

**Cons**:
- Singleton pattern (less testable)
- Breaks SwiftUI's ownership model
- Harder to inject dependencies in tests

---

### Option C: Remove init() Entirely

Let SwiftUI handle everything:

```swift
@main
struct WavelengthWatch_Watch_AppApp: App {
  @StateObject private var notificationDelegate = NotificationDelegate()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(notificationDelegate)
        .task {
          // Setup on app launch
          NotificationDelegateShim.shared.delegate = notificationDelegate
          UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared
          configureNotificationCategories()
        }
    }
  }

  private func configureNotificationCategories() {
    // ...
  }
}
```

**Pros**:
- Clean SwiftUI approach
- @StateObject definitely initialized
- `.task` runs once on appear

**Cons**:
- Setup happens async (slightly delayed)
- If notifications come in immediately, they might be missed

---

## Recommended Solution: Option A (onAppear)

**Why**: Balance between correct lifecycle and minimal changes.

### Implementation Steps

1. **Remove delegate setup from init()**

```swift
init() {
  // Remove these lines:
  // NotificationDelegateShim.shared.delegate = notificationDelegate
  // UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared

  // Keep this:
  configureNotificationCategories()
}
```

2. **Add setup to body**

```swift
var body: some Scene {
  WindowGroup {
    ContentView()
      .environmentObject(notificationDelegate)
      .onAppear {
        NotificationDelegateShim.shared.delegate = notificationDelegate
        UNUserNotificationCenter.current().delegate = NotificationDelegateShim.shared
      }
  }
}
```

3. **Test**

```bash
xcodebuild test \
  -scheme "WavelengthWatch Watch App" \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)"
```

**Expected result**: All tests pass, no SIGSEGV crashes.

---

## About the @MainActor Refactoring

### Should We Keep It?

**YES, keep the refactoring** — it was good architectural improvement even though it didn't fix the crash.

**Benefits of nonisolated init + @MainActor methods**:
- More explicit about what code needs main thread
- Better matches Swift Concurrency best practices
- Makes ViewModels more testable
- Reduces boilerplate in tests

**What to revert**:
- Nothing! The refactoring is solid.
- Just fix the app initialization bug separately.

---

## Timeline

| Task | Time |
|------|------|
| Move delegate setup to onAppear | 5 minutes |
| Test and verify | 5 minutes |
| Commit fix | 5 minutes |
| **Total** | **15 minutes** |

---

## Verification Checklist

After fix:
- [ ] All unit tests pass (82+ tests)
- [ ] No SIGSEGV crashes
- [ ] Tests show execution time > 0.000s
- [ ] UI tests still pass (3/3)
- [ ] App launches in Simulator
- [ ] Notifications work when tapped

---

## Commit Message Template

```
fix(app): Move notification delegate setup to onAppear

Fixes SIGSEGV crash caused by accessing @StateObject in init() before
SwiftUI initializes property wrappers.

Root cause: WavelengthWatchApp.swift:16 accessed notificationDelegate
in init(), but @StateObject properties aren't initialized until after
init() completes. This caused segmentation fault during app bootstrap,
which manifested as all tests crashing with "operation never finished
bootstrapping" error.

Solution: Move delegate setup to .onAppear {} where @StateObject is
guaranteed to be initialized by SwiftUI's lifecycle.

Result: All 82+ tests now execute successfully without crashes.

Fixes crash introduced in PR #54.
```

---

## Key Learning

**Always check property initialization order in SwiftUI Apps:**

❌ **WRONG**:
```swift
@StateObject var thing = Thing()

init() {
  useThing(thing)  // CRASH: Not initialized yet!
}
```

✅ **CORRECT**:
```swift
@StateObject var thing = Thing()

var body: some Scene {
  WindowGroup {
    MyView()
      .onAppear {
        useThing(thing)  // Safe: Initialized by now
      }
  }
}
```

This is a common SwiftUI pitfall that causes crashes in tests because tests bootstrap the entire app.

---

## Next Steps

1. **IMMEDIATE**: Implement Option A (onAppear)
2. Test thoroughly
3. Commit fix
4. Update documentation about SwiftUI property wrapper lifecycle
5. Consider adding linting rule to catch `@StateObject` access in `init()`
