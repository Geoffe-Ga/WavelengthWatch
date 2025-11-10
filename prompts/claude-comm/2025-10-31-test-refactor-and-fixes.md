# Test Refactoring and Crash Fixes - 2025-10-31

## Problem Statement

Two test suites are failing with crashes:
1. **AppConfigurationTests** - SIGSEGV crash during test bootstrap
2. **ScheduleViewModelTests** - Tests fail at 0.000 seconds (immediate crash)

The root cause is a **865-line monolithic test file** containing all 12 test suites, making it difficult to diagnose and fix issues.

## Root Causes Identified

### ScheduleViewModelTests Crash ✅ FIXED
**Issue**: `ScheduleViewModel.init()` was calling `loadSchedules()` in an async Task during initialization, attempting to access `@Published var schedules` before object was fully initialized.

**Fix Applied**:
```swift
// Before (crashed):
nonisolated init(...) {
  Task { @MainActor in
    loadSchedules()  // ❌ Accesses @Published before init complete
  }
}

// After (works):
@MainActor
init(...) {
  loadSchedules()  // ✅ Synchronous access on MainActor
}
```

**Side Effect**: Tests needed `@MainActor` annotation to call the init.

### AppConfigurationTests Crash ✅ FIXED
**Issue**: `MockBundle` was subclassing `Bundle` without proper initialization. In Swift 6, this causes SIGSEGV crashes because Bundle requires specific initialization that can't be bypassed.

**Fix Applied**:
```swift
// Before (crashed):
final class MockBundle: Bundle { ... }  // ❌ Invalid Bundle subclass

// After (works):
protocol BundleProtocol {
  func object(forInfoDictionaryKey key: String) -> Any?
  func path(forResource name: String?, ofType ext: String?) -> String?
}
extension Bundle: BundleProtocol {}
final class MockBundle: BundleProtocol { ... }  // ✅ Protocol conformance
```

**Additional Change**: Removed `Logger` from `AppConfiguration` and replaced with `print()` to avoid potential Logger initialization issues in test environment.

## Refactoring Plan

### Scope
**ONLY refactor the two failing test suites:**
- AppConfigurationTests (66 lines)
- ScheduleViewModelTests (114 lines)

**DO NOT** refactor the other 10 test suites (avoid scope creep).

### File Structure

```
WavelengthWatch Watch AppTests/
├── WavelengthWatch_Watch_AppTests.swift (keep 10 passing suites here)
├── TestUtilities.swift (NEW - shared mocks needed by extracted suites)
├── ConfigurationTests.swift (NEW - AppConfigurationTests + MockBundle)
└── ScheduleViewModelTests.swift (NEW - ScheduleViewModelTests + dependencies)
```

### Step 1: Create TestUtilities.swift

**Extract shared utilities needed by the two suites:**
- `MockBundle` (used by AppConfigurationTests)
- `MockNotificationCenter` (used by ScheduleViewModelTests)
- `BundleProtocol` (needed for MockBundle)
- Any other shared test helpers these suites depend on

**File header:**
```swift
import Foundation
import SwiftUI
import Testing
import UserNotifications
@testable import WavelengthWatch_Watch_App

// Shared test mocks and stubs used across multiple test files
```

### Step 2: Create ConfigurationTests.swift

**Contents:**
- Import statements
- Import TestUtilities
- `AppConfigurationTests` struct (all 6 tests)
- `createTempPlist()` helper function (if not moved to TestUtilities)

**Structure:**
```swift
import Foundation
import Testing
@testable import WavelengthWatch_Watch_App

struct AppConfigurationTests {
  @Test func loadsFromInfoPlistWhenAvailable() { ... }
  @Test func fallsBackToConfigurationPlist() throws { ... }
  @Test func usesPlaceholderWhenNoConfigurationFound() { ... }
  @Test func usesPlaceholderWhenURLIsInvalid() { ... }
  @Test func trimsWhitespaceFromURL() { ... }
  @Test func usesPlaceholderWhenURLIsEmpty() { ... }

  private func createTempPlist(withURL url: String) -> String { ... }
}
```

### Step 3: Create ScheduleViewModelTests.swift

**Contents:**
- Import statements
- Import TestUtilities
- `ScheduleViewModelTests` struct (all 5 tests)

**Structure:**
```swift
import Foundation
import Testing
import UserNotifications
@testable import WavelengthWatch_Watch_App

struct ScheduleViewModelTests {
  @MainActor
  @Test func requestsNotificationPermission() async throws { ... }

  @MainActor
  @Test func addsScheduleAndPersists() throws { ... }

  @MainActor
  @Test func updatesSchedule() { ... }

  @MainActor
  @Test func deletesSchedule() { ... }

  @MainActor
  @Test func togglesScheduleEnabledViaDirectBinding() { ... }
}
```

### Step 4: Update WavelengthWatch_Watch_AppTests.swift

**Remove from the monolithic file:**
- `MockBundle` class (move to TestUtilities)
- `MockNotificationCenter` class (move to TestUtilities)
- `AppConfigurationTests` struct (moved to ConfigurationTests.swift)
- `ScheduleViewModelTests` struct (moved to ScheduleViewModelTests.swift)
- `createTempPlist()` helper (move to ConfigurationTests or TestUtilities)

**Keep in the monolithic file:**
- All 10 passing test suites
- Their associated mocks/stubs (unless also needed by extracted suites)

### Step 5: Verification

Run tests individually to ensure they pass:
```bash
./run-tests-individually.sh AppConfigurationTests
./run-tests-individually.sh ScheduleViewModelTests
./run-tests-individually.sh  # Run all 12 suites
```

**Expected outcome:**
- ✅ AppConfigurationTests: 6/6 passing
- ✅ ScheduleViewModelTests: 5/5 passing
- ✅ All 12 test suites: 100% passing
- ✅ No SIGSEGV crashes
- ✅ No 0.000-second failures

## Dependencies Between Suites

**AppConfigurationTests depends on:**
- MockBundle (extract to TestUtilities)
- BundleProtocol (extract to TestUtilities)
- createTempPlist() helper (keep in ConfigurationTests.swift)

**ScheduleViewModelTests depends on:**
- MockNotificationCenter (extract to TestUtilities)
- NotificationCenterProtocol (check if already in main app or needs extraction)

## DRY Principles

**Shared code to extract:**
1. `MockBundle` - Used by AppConfigurationTests, potentially useful for other config tests
2. `MockNotificationCenter` - Used by multiple notification-related tests
3. `BundleProtocol` - Needed by both app code and tests

**Keep specialized:**
1. `createTempPlist()` - Only used by AppConfigurationTests, keep in that file
2. Test-specific helper methods - Keep within their respective test structs

## Success Criteria

1. ✅ Both failing test suites pass consistently
2. ✅ No SIGSEGV crashes
3. ✅ No 0.000-second test failures
4. ✅ All 12 test suites still discoverable by xcodebuild
5. ✅ Code follows DRY principles (shared mocks in TestUtilities)
6. ✅ Each file is under 200 lines (maintainability)
7. ✅ `./run-tests-individually.sh` works with new file structure
8. ✅ Full test bundle run completes without contamination

## Out of Scope

- Refactoring the other 10 passing test suites
- Fixing non-crash issues (warnings, flaky tests)
- Optimizing test performance
- Adding new tests
- Changing test infrastructure

## Implementation Order

1. Create `TestUtilities.swift` with shared mocks
2. Create `ConfigurationTests.swift` with AppConfigurationTests
3. Create `ScheduleViewModelTests.swift`
4. Remove extracted code from monolithic file
5. Run tests to verify
6. Update investigation plan document with results

## Notes

- The test script `run-tests-individually.sh` should automatically discover the new test files
- Watch for import issues - ensure all files can access needed protocols/mocks
- Swift Testing uses automatic test discovery, no need to register new files
- Keep all tests using Swift Testing framework (not XCTest)
