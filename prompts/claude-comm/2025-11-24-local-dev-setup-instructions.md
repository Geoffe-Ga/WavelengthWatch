# Local Development Setup Instructions

**Date:** 2025-11-24
**Context:** PR #118 - Menu replacement work
**Issue:** Configuration reversion after accidentally committing dev URLs

---

## Problem

During PR #118, local development URLs were accidentally committed to production configuration files:
- `APIConfiguration.plist` - Production config was overridden with localhost
- `WavelengthWatch-Watch-App-Info.plist` - Created with hardcoded dev URL
- `project.pbxproj` - Added `INFOPLIST_KEY_API_BASE_URL` pointing to localhost

These changes violated project conventions in `CLAUDE.md`.

## Proper Local Development Setup

### For Developers

To connect the watchOS app to your local backend during development:

1. **Navigate to Resources directory:**
   ```bash
   cd frontend/WavelengthWatch/WavelengthWatch\ Watch\ App/Resources
   ```

2. **Copy template to local config:**
   ```bash
   cp APIConfiguration-Template.plist APIConfiguration-Local.plist
   ```

3. **Verify the URL in APIConfiguration-Local.plist:**
   - Default: `http://127.0.0.1:8000`
   - Update if your backend runs on a different port

4. **Start your local backend:**
   ```bash
   cd backend
   uvicorn backend.app:app --reload
   ```

5. **Build and run the watch app in Xcode**
   - The app will automatically load `APIConfiguration-Local.plist` BEFORE `APIConfiguration.plist`
   - See `AppConfiguration.swift:37-60` for loading hierarchy

### Configuration Loading Order

From `AppConfiguration.swift`:

1. **Info.plist** - `Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL")`
2. **APIConfiguration-Local.plist** - Local dev config (gitignored) ⭐
3. **APIConfiguration.plist** - Production fallback

### Why This Approach?

✅ **Keeps production config clean** - No localhost URLs in committed files
✅ **Gitignored** - `APIConfiguration-Local.plist` won't be committed
✅ **Developer-friendly** - One-time setup per machine
✅ **Follows conventions** - Documented in `CLAUDE.md`

### Files to NEVER Commit

- ❌ `APIConfiguration-Local.plist` (gitignored)
- ❌ Changes to `APIConfiguration.plist` that add localhost URLs
- ❌ Changes to `project.pbxproj` that hardcode `INFOPLIST_KEY_API_BASE_URL`
- ❌ Custom Info.plist files with dev URLs

### Files That Should Stay Production-Ready

- ✅ `APIConfiguration.plist` - Should contain `https://api.not-configured.local`
- ✅ `APIConfiguration-Template.plist` - Template for creating -Local.plist
- ✅ `project.pbxproj` - Should NOT have hardcoded API URLs in build settings

---

## Commits Reverted

- `c20b77b` - Configure watch app API base URL (cherry-picked from old branch)
- `5d2a8e3` - fix(config): Add API_BASE_URL to Info.plist
- Reverted in: `f6c8337` - revert: Remove local dev configuration from production files

## Lesson Learned

When enabling local development:
1. ❌ Don't modify production config files
2. ✅ Use the gitignored `-Local.plist` approach
3. ✅ Follow existing conventions in `CLAUDE.md`
4. ✅ Document setup for other developers

---

**Status:** Configuration properly reverted, local dev setup documented
