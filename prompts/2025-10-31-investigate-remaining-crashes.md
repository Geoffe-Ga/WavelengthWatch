# 2025-10-31: Investigation Plan for Remaining Test Crashes

## Summary

After fixing the main SIGSEGV crash (accessing `@StateObject` in `App.init()`), we discovered:
- ✅ **10/12 test suites pass** when run individually
- ❌ **2/12 test suites crash** with SIGSEGV even when run alone:
  1. `AppConfigurationTests`
  2. `ScheduleViewModelTests`

## Key Insight

**These 2 crashing suites are likely contaminating the entire test bundle when running all tests together.** When xcodebuild tries to load the test bundle to discover tests, it likely initializes module-level code in the test file, which triggers the crash before any tests even run.

## Test Results from Individual Run

From `./run-tests-individually.sh`:

```
✅ CatalogRepositoryTests PASSED
✅ PhaseNavigatorTests PASSED
✅ NotificationDelegateTests PASSED
✅ NotificationSchedulerTests PASSED
✅ ContentViewModelTests PASSED
✅ ContentViewModelInitiationContextTests PASSED
✅ JournalUIInteractionTests PASSED
✅ JournalScheduleTests PASSED
✅ JournalClientTests PASSED
✅ MysticalJournalIconTests PASSED

❌ AppConfigurationTests FAILED (SIGSEGV crash)
❌ ScheduleViewModelTests FAILED (SIGSEGV crash)
```

## Investigation Plan

### Phase 1: Understand the Crashes

#### 1.1 Examine Test File Structure
- [ ] Read full test file to identify module-level code
- [ ] Look for static/global initializers
- [ ] Check for property wrappers or lazy initialization
- [ ] Identify any code that runs before tests execute

#### 1.2 Check for Common Patterns
Both failing suites might share:
- [ ] Similar test setup patterns
- [ ] Common mock objects or stubs
- [ ] UserDefaults or file system access
- [ ] Notification center usage

#### 1.3 Isolate the Crash Location
For each failing suite:
- [ ] Comment out all test functions, keep only struct definition
- [ ] Gradually uncomment tests one by one
- [ ] Identify which specific test or setup code triggers crash
- [ ] Check crash logs for stack traces

### Phase 2: Analyze AppConfigurationTests

Located in: `frontend/WavelengthWatch/WavelengthWatch Watch AppTests/WavelengthWatch_Watch_AppTests.swift`

**Known characteristics:**
- Tests `AppConfiguration` which reads from `Info.plist` and `Configuration.plist`
- Uses `MockBundle` to simulate bundle behavior
- Creates temp files with `createTempPlist(withURL:)`

**Hypothesis:**
- May be accessing actual app bundle during initialization
- Could be file system operations causing issues
- MockBundle might interact poorly with test environment

**Investigation steps:**
1. [ ] Check if `MockBundle` is `@unchecked Sendable` causing issues
2. [ ] Verify temp file creation doesn't happen at module load time
3. [ ] Look for any `Bundle.main` or `Bundle(for:)` calls
4. [ ] Check if `AppConfiguration.init()` is called at global scope

### Phase 3: Analyze ScheduleViewModelTests

Located in: `frontend/WavelengthWatch/WavelengthWatch Watch AppTests/WavelengthWatch_Watch_AppTests.swift`

**Known characteristics:**
- Tests `ScheduleViewModel` which manages journal schedules
- Uses `UserDefaults` for persistence
- Interacts with `NotificationScheduler`

**Hypothesis:**
- May be accessing `UserDefaults` at module level
- Could be initializing `NotificationScheduler` with real `UNUserNotificationCenter`
- ViewModel might be annotated with `@MainActor` causing async initialization issues

**Investigation steps:**
1. [ ] Check for UserDefaults access in test setup
2. [ ] Verify mock notification center setup
3. [ ] Look for ViewModel initialization at global scope
4. [ ] Check if tests use `@StateObject` or other SwiftUI property wrappers

### Phase 4: Fix Strategy

Once crash location identified, apply one of these fixes:

#### Option A: Lazy Initialization
Convert global/static initializers to lazy properties:
```swift
// Before (crashes)
private static let testData = SomeClass()

// After (safe)
private static func makeTestData() -> SomeClass {
  SomeClass()
}
```

#### Option B: Isolate Test Environment
Guard initialization code with environment checks:
```swift
init() {
  // Only run in non-test environment
  guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
    return
  }
  // ... initialization
}
```

#### Option C: Move to Test Functions
Move initialization from module/class level into individual test functions:
```swift
struct MyTests {
  // Instead of static let fixture = ...

  @Test func myTest() async {
    let fixture = makeFixture()
    // ... test with fixture
  }
}
```

### Phase 5: Verification

After applying fixes:
1. [ ] Run failing suite individually: `./run-tests-individually.sh AppConfigurationTests`
2. [ ] Run failing suite individually: `./run-tests-individually.sh ScheduleViewModelTests`
3. [ ] Run all suites: `./run-tests-individually.sh`
4. [ ] Attempt full bundle run: `xcodebuild test -scheme "WavelengthWatch Watch App" ...`

## Expected Outcomes

### Best Case
- Both suites fixed
- All 12 suites pass individually
- Full test bundle can run without crashes
- Can re-enable parallel testing

### Likely Case
- Both suites fixed
- All 12 suites pass individually
- Full bundle still crashes due to simulator limitations
- Continue using `run-tests-individually.sh`

### Worst Case
- Crashes require deeper Swift Testing framework changes
- Some tests need to be rewritten or disabled
- Document known issues and workarounds

## Resources

### Test File Location
`/Users/geoffgallinger/Projects/WavelengthWatchRoot/frontend/WavelengthWatch/WavelengthWatch Watch AppTests/WavelengthWatch_Watch_AppTests.swift`

### Crash Logs
- Latest run: `/tmp/appconfig_verbose.log`
- Individual suite logs: `/tmp/watchos_tests/`

### Related Fixes
- Commit `3945b6a`: Fix for @StateObject crash
- Commit `abc174f`: Fix for NotificationDelegate async tests
- Commit `b67963d`: Individual test script

## Next Steps

1. Start with **AppConfigurationTests** (simpler, involves mocking)
2. Then **ScheduleViewModelTests** (more complex, involves ViewModels)
3. Apply systematic approach from Phase 1-4
4. Document findings and fixes
5. Update this file with results
