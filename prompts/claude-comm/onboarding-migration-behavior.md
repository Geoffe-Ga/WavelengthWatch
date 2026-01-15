# Onboarding Migration Behavior

## Context
PR #247 introduces a first-run onboarding flow that educates users about cloud sync options before they start using the app.

## Existing User Behavior

**IMPORTANT: Existing users WILL see the onboarding screen on their next app launch.**

This is **intentional behavior** for the following reasons:

### 1. New Feature Education
Cloud sync is a significant new feature that affects data privacy and persistence. All users deserve to make an informed choice about how their journal data is stored, regardless of when they installed the app.

### 2. No Risk of Data Loss
- Existing journal entries remain safely stored in local SQLite database
- Onboarding only affects future sync behavior, not existing data
- Users who skip/dismiss onboarding default to local-only mode (same as current behavior)

### 3. Privacy-First Migration Path
- Default selection is "Privacy First" (local-only), matching pre-onboarding behavior
- Users must explicitly opt-in to cloud sync
- No automatic migration or data transmission without user consent

### 4. Clean Implementation
- Single source of truth: `SyncSettings.hasCompletedOnboarding` (defaults to `false`)
- No version checks, no migration flags, no legacy user detection
- Simple and maintainable code path

## User Experience Timeline

### New Users (Fresh Install)
1. Launch app for first time
2. See onboarding immediately
3. Choose storage mode
4. Never see onboarding again

### Existing Users (App Update)
1. Update app from version without onboarding to version with onboarding
2. Launch app
3. See onboarding (first time only)
4. Choose storage mode (default: local-only, matching previous behavior)
5. Never see onboarding again

## Technical Implementation

The onboarding state is tracked via:
- **Key**: `com.wavelengthwatch.onboardingCompleted`
- **Storage**: UserDefaults
- **Default**: `false`
- **Updated**: Set to `true` when user completes onboarding

This means:
- Fresh installs: `hasCompletedOnboarding == false` → show onboarding
- Updates from pre-onboarding versions: `hasCompletedOnboarding == false` → show onboarding
- Users who completed onboarding: `hasCompletedOnboarding == true` → skip onboarding

## Alternative Approaches Considered and Rejected

### ❌ Skip Onboarding for Existing Users
**Why rejected**: Deprives existing users of learning about a significant new privacy feature. They deserve the same informed choice as new users.

### ❌ Check for Existing Journal Entries
**Why rejected**:
- Adds complexity (need to query database on every launch)
- Creates inconsistent UX (some users see it, some don't, based on arbitrary criteria)
- Doesn't distinguish between "real" users and test installs

### ❌ Version-Based Detection
**Why rejected**:
- Requires tracking app version numbers in UserDefaults
- Breaks in TestFlight/development builds with version resets
- Adds migration code that needs maintenance forever

### ❌ Prompt for Permission vs Full Onboarding
**Why rejected**: Privacy choice deserves full context, not a quick dialog. Users need to understand the trade-offs.

## Future Considerations

If we receive user feedback that existing users are confused by the onboarding:
1. Add release notes explaining the new feature
2. Consider adding a "Skip" button with default to local-only
3. Monitor support requests and adjust messaging if needed

The current approach prioritizes user privacy and informed consent over minimizing UI friction for existing users.

## Testing

To verify behavior:
1. Install version without onboarding
2. Create some journal entries
3. Update to version with onboarding
4. Launch app → should see onboarding
5. Complete onboarding → should not see it again
6. Verify existing entries are still present and accessible

## Related Files
- `/frontend/WavelengthWatch/WavelengthWatch Watch App/Views/OnboardingView.swift`
- `/frontend/WavelengthWatch/WavelengthWatch Watch App/Models/SyncSettings.swift`
- `/frontend/WavelengthWatch/WavelengthWatch Watch App/ViewModels/SyncSettingsViewModel.swift`
