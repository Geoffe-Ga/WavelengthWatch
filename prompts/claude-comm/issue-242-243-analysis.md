# Issues 242 & 243: Analytics Local-First and Cloud Sync Preferences

## Issue 242 Analysis: Analytics Fails Without Backend

### Problem
The `AnalyticsView` in `ContentView.swift` (lines 1564-1569) initializes `AnalyticsViewModel` with ONLY the `analyticsService` parameter:

```swift
init() {
  let configuration = AppConfiguration()
  let apiClient = APIClient(baseURL: configuration.apiBaseURL)
  let analyticsService = AnalyticsService(apiClient: apiClient)
  _viewModel = StateObject(wrappedValue: AnalyticsViewModel(analyticsService: analyticsService))
}
```

However, `AnalyticsViewModel` requires additional dependencies for offline functionality:
- `localCalculator: LocalAnalyticsCalculatorProtocol?`
- `journalRepository: JournalRepositoryProtocol?`
- `catalogRepository: CatalogRepositoryProtocol?`

When these are nil, the local fallback in `tryLocalCalculation()` (lines 70-93) returns nil and analytics fails when the backend is unreachable.

### Root Cause
The production code doesn't wire up the local-first dependencies that already exist elsewhere in the app:
- `ContentView.init()` already creates a `journalRepository` (lines 97-106)
- `ContentView.init()` already creates a `CatalogRepository` (lines 93-96)
- The embedded catalog data exists and is ready to use
- The local calculation logic exists in `LocalAnalyticsCalculator` and is tested

### Solution
Pass the necessary dependencies to `AnalyticsViewModel` so it can fall back to local data when the backend fails:

1. Create `LocalAnalyticsCalculator` with the cached catalog
2. Pass `journalRepository` (already available)
3. Pass `catalogRepository` (already available)

### Test Strategy
The existing test suite (`AnalyticsViewModelTests.swift`) already validates:
- Local fallback works when backend fails (line 323-371)
- Backend is used when available (line 401-442)
- Error reported when both fail (line 373-399)

We need an integration test that verifies the production wiring in `ContentView` passes the right dependencies.

## Issue 243: Cloud Sync Preference

### Current State
- `SyncSettings` already exists with `cloudSyncEnabled` property (defaults to false)
- `JournalClient` already checks `syncSettings.cloudSyncEnabled` before syncing
- UI already exists: `SyncSettingsView` with a toggle

### Problem
Analytics wasn't using local data (Issue 242), so the sync preference couldn't be properly tested or demonstrated.

### Dependencies
Issue 243 builds on 242 - once analytics works offline, the sync preference will control whether journal entries sync to the backend while analytics always works locally.

## Implementation Plan

### Issue 242 (Foundation)
1. Write failing integration test for AnalyticsView initialization
2. Fix ContentView to pass local dependencies to AnalyticsViewModel
3. Verify all tests pass
4. Create PR and iterate until merged

### Issue 243 (Enhancement)
1. After 242 is merged, rebase 243 branch
2. Write tests for sync preference behavior
3. Verify existing SyncSettingsView works correctly
4. Add any missing user guidance/documentation
5. Create PR and iterate until merged
