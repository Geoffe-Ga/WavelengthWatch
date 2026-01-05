# Contributing to WavelengthWatch

Thanks for helping evolve WavelengthWatch! This guide summarizes the expectations that keep the project healthy and describes the current journal architecture so you can propose changes with shared context.

## Workflow Expectations

- **TDD first**: Write a failing test before shipping a feature or bug fix. Backend tests live under `tests/backend/`. Watch tests reside in the Xcode test targets.
- **Green CI**: Run `pre-commit run --all-files`, `pytest`, and the relevant Xcode tests locally before pushing. Every pull request must ship with passing GitHub Actions checks.
- **Small, atomic commits**: Group related changes together. Include a short summary of what changed and why.
- **Documentation parity**: Update `README.md`, `AGENTS.md`, or other docs when you alter the system. Place any coordination or planning notes in `prompts/claude-comm/` so future contributors inherit the full story.

## Journal System Reference

Understanding the shipping journal flow prevents redundant rewrites:

- **Local storage**: `LocalJournalEntry` models are saved to SQLite via `JournalRepository` with sync status tracking (pending/synced/failed). Cloud sync is opt-in via `SyncSettings`.
- **Backend data model**: `backend/models.py` exposes a `Journal` SQLModel table referencing `Curriculum` and optional `Strategy` rows. The `InitiatedBy` enum differentiates self-started entries from scheduled ones.
- **Schemas & validation**: `backend/schemas.py` validates timestamps (UTC-normalized) and defers foreign-key checks to `backend/routers/journal.py`, which re-queries with `joinedload` so responses come back hydrated.
- **Watch client**: `JournalClient` (Swift) derives a pseudo-user ID from `UserDefaults`, saves entries to local SQLite first, then optionally syncs to `/api/v1/journal` if cloud sync is enabled. UI alerts trigger submissions and present success/failure feedback immediately.
- **Strengths**: Offline-first (works without connectivity), privacy-first (sync opt-in), simple backend schema, reusable joins with existing catalog data, and production-friendly HTTP contracts.
- **Trade-offs**: Automatic retry for failed sync not yet implemented; expanding to multi-combo journaling will require additional schema changes and migration planning.

Bring proposals that build on these merits or explicitly outline how you plan to mitigate the known trade-offs.

## Pull Request Checklist

1. `pre-commit run --all-files`
2. `pytest tests/backend -q`
3. Run targeted Xcode tests (or provide an explanation and follow-up plan)
4. Update documentation and changelog entries as needed
5. Confirm communication artifacts live under `prompts/claude-comm/`

We appreciate thorough write-ups in your PR description—call out assumptions, data migrations (if any), and manual test steps performed. Happy building!
