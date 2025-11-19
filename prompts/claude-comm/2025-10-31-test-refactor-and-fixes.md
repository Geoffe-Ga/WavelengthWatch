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

**Note**: Logger was temporarily removed during debugging but has been restored with proper privacy controls in the final implementation (see PR #55 review feedback).

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

---

## Implementation Complete ✅

**Date**: November 18, 2025
**PR**: #55 - Fix watchOS test suite crashes and improve test organization

### Final Status

All success criteria met:
- ✅ Both failing test suites pass consistently (6/6 AppConfigurationTests, 5/5 ScheduleViewModelTests)
- ✅ No SIGSEGV crashes
- ✅ No 0.000-second test failures
- ✅ All 12 test suites discoverable and passing (12/12)
- ✅ Code follows DRY principles (TestUtilities.swift with shared mocks)
- ✅ Each new file under 200 lines
- ✅ `./run-tests-individually.sh` works with new file structure
- ✅ Full test bundle run completes without contamination

### Final File Structure

```
WavelengthWatch Watch AppTests/
├── WavelengthWatch_Watch_AppTests.swift (10 test suites, 603 lines)
├── TestUtilities.swift (shared mocks: MockBundle, MockNotificationCenter)
├── ConfigurationTests.swift (AppConfigurationTests, 70 lines)
└── ScheduleViewModelTests.swift (ScheduleViewModelTests, 122 lines)
```

### Additional Fixes Applied (PR #55 Review)

**Restored Logger** (No Shortcuts policy):
- Reverted `print()` statements back to proper `Logger` usage
- Added privacy controls: `.public` for placeholder URL logging
- Follows structured logging best practices

**Fixed Concurrency Safety**:
- Removed `@unchecked Sendable` from `MockBundle`
- Added documentation explaining single-threaded test usage
- No false safety claims in test code

**Improved Error Handling**:
- Changed `createTempPlist()` from force-unwrap (`try!`) to proper `throws`
- Tests marked with `throws` to propagate errors correctly
- Better failure diagnostics in test output

**Fixed Notification Delegate Race Condition**:
- Moved delegate registration from `.onAppear()` to `@StateObject` initialization
- Ensures delegate is registered before any notifications can arrive
- Added regression test `delegateIsRegisteredImmediately()` to prevent future issues
- Prevents dropped notifications during app launch

**CI Optimizations**:
- Fixed exit code 70 by using specific simulator instead of invalid `OS=latest`
- Implemented build-for-testing + test-without-building pattern
- Reduced test execution from 27s/suite to ~5s/suite
- Added DerivedData caching in CI
- Removed duplicate build steps

### Test Results

Local execution (M1 Mac):
```
Testing: AppConfigurationTests          ✅ PASSED
Testing: CatalogRepositoryTests         ✅ PASSED
Testing: PhaseNavigatorTests            ✅ PASSED
Testing: NotificationDelegateTests      ✅ PASSED (includes new regression test)
Testing: NotificationSchedulerTests     ✅ PASSED
Testing: ContentViewModelTests          ✅ PASSED
Testing: ContentViewModelInitiationContextTests ✅ PASSED
Testing: ScheduleViewModelTests         ✅ PASSED
Testing: JournalUIInteractionTests      ✅ PASSED
Testing: JournalScheduleTests           ✅ PASSED
Testing: JournalClientTests             ✅ PASSED
Testing: MysticalJournalIconTests       ✅ PASSED

Test Results Summary: Passed 12/12
Total execution time: ~6.5 minutes
```

### Performance Improvements Documented

Created GitHub issues for identified performance bottlenecks:
- #56: Remove 5-second UI delay from ContentView
- #57: Add timeout to URLSession waitsForConnectivity
- #58: Split monolithic test file for better performance
- #59: Use async file I/O in CatalogRepository
- #60: Optimize notification system calls in tests
- #61: Avoid running ContentView lifecycle in unit tests
- #62: Optimize test output handling (remove tee to disk)
- #63: Add xcodebuild parallelization flags

### Key Learnings

1. **Swift 6 strict concurrency**: Cannot subclass sealed system classes like `Bundle`; use protocol conformance instead
2. **@MainActor initialization**: Can call synchronous methods in `@MainActor init()` without race conditions
3. **watchOS Simulator limitations**: Must run test suites individually due to resource contention
4. **Test organization**: Splitting monolithic test files improves debuggability and maintenance
5. **No shortcuts policy**: Proper fixes (Logger, error handling) are worth the effort vs. quick hacks
6. **CI destination specifiers**: `OS=latest` is invalid; use specific simulator names or IDs
7. **@StateObject lifecycle**: Initialization closures run immediately, perfect for early setup like notification delegates
