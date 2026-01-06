## ⚙️ Agent Behavior and Development Philosophy

To set up the full development environment, run:

```bash
bash dev-setup.sh
```

**Deployment status**: WavelengthWatch has not yet been deployed to production. The team plans to ship to the App Store in the future.

Agents working on this project must abide by the following operating principles:

1. **Test-Driven Development (TDD) Is Required**
  - Write tests before or alongside new features.

  - For the backend (FastAPI), use pytest with lightweight, isolated tests.

  - Every bug fix must include a failing test that reproduces the bug before it is resolved.

2. **CI is Your Feedback Loop**
  - GitHub Actions is the source of truth for project health.

  - CI should pass green on every merge to main.

  - If CI fails, fix it before continuing. You are not permitted to “comment out the failing test.”

  - Agents must:

    - Iterate on .github/workflows until builds, linting, typing, and tests all pass.

    - Use caching, parallelism, and fail-fast behavior where beneficial.

    - Add new jobs for new language environments or tools as needed (e.g. SwiftLint, Expo CLI, Docker health checks).

3. **Make Small, Meaningful Commits**

  - Each commit should introduce one small logical change or fix.

  - Each pull request should include:

    - A brief human-readable summary

    - A short explanation for agents (if relevant)

    - Assurance that all CI steps have passed

    - `pre-commit run --all-files` status of Green

4. **Optimize for Learning and Maintainability**

  - Write code that teaches.

  - Comment your intentions more than your syntax.

  - Leave TODOs only if they are actionable and necessary.

  - Never introduce magic numbers or clever hacks without explanation.

5. **No Untested Assumptions**

  - Agents must validate their changes by:

    - Writing or updating relevant tests

    - Running the app in a simulated environment

    - Checking network requests for accurate backend interaction

6. **Respect the Archetypal Wavelength**

  - Restoration leads to Rising.

 - Agents are expected to work in cycles: test → think → implement → test → think → refine → repeat (until all green).

### Journal Implementation Snapshot

- **Local storage**: `LocalJournalEntry` models are stored in SQLite via `JournalRepository` with sync status tracking (pending/synced/failed). Cloud sync is opt-in via `SyncSettings`.
- **Backend schema**: `backend/models.py` defines a `Journal` SQLModel table linked to curriculum and optional strategy rows with an `InitiatedBy` enum tracking self vs. scheduled entries.
- **Validation surface**: Pydantic schemas in `backend/schemas.py` coerce incoming timestamps to UTC and ensure required fields exist before writes. `backend/routers/journal.py` rehydrates responses with joined curriculum/strategy payloads so clients stay simple.
- **Watch client**: `JournalClient` builds a stable pseudo-user ID from `UserDefaults`, saves entries to local SQLite first, then optionally syncs to backend if cloud sync is enabled. Alerts inside `ContentView` trigger submissions and surface success/failure feedback.
- **Merits**: Offline-first (works without connectivity), privacy-first (sync opt-in), minimal backend schema footprint, single endpoint for create/read/update/delete, and strong reuse of existing curriculum relationships.
- **Trade-offs**: Automatic retry for failed sync not yet implemented; analytics beyond the existing joins will require additional persistence decisions and migration planning.

Keep this baseline in mind when evaluating new prompts—most redesign requests start from this already-functional flow.

## Repository Directory Overview

Use this quick reference tree to understand where major assets live before collaborating or delegating work:

```text
WavelengthWatch/
├── backend/ — FastAPI + SQLModel service with routers, schemas, and CSV/JSON fixtures powering the curriculum and journal APIs.​
│   ├── data/ — Source CSV/JSON catalogs bundled for backend seeding and the watch experience.
│   ├── routers/ — Endpoint modules covering catalog, curriculum, journal, layer, phase, and strategy routes.
│   └── tools/ — Utilities like CSV-to-JSON conversion and database seeding scripts used during setup and builds.
├── frontend/ — watchOS SwiftUI project containing the main watch target, tests, and configuration docs for collaborators.
│   └── WavelengthWatch Watch App/ — SwiftUI code organized into App, Assets, Models, Services, Resources, and ViewModels for the watch experience.
├── tests/ — Pytest suite validating backend configuration and each API surface area.​
├── prompts/ — Product and process prompts that capture planning notes for AI-assisted development.
│   └── claude-comm/ — Centralized Markdown notes for Claude/agent communication (add new coordination docs here).
├── scripts/ — Automation helpers, including the CSV→JSON build script for bundling data with the app.​
├── .github/workflows/ — Continuous integration workflows handling backend checks and automated reviews.
├── README.md, XCODE_BUILD_SETUP.md — Contributor onboarding guide and Xcode build automation instructions.
├── dev-setup.sh, pyproject.toml, mypy.ini, ruff.toml, pytest.ini — Repo-wide tooling bootstrap plus lint/type/test configuration defaults.
```
