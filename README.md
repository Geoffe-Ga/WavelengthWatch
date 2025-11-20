# WavelengthWatch

## Overview

WavelengthWatch is a watchOS-only companion for the Archetypal Wavelength. The watch app lets you browse every layer and phase, surfaces “medicinal” and “toxic” expressions side-by-side, and offers context-aware self-care strategies. Background refresh keeps the content current, while offline storage guarantees the curriculum is always available from your wrist.

_Status_: The project has not yet been deployed to production. An eventual App Store launch is planned, so formal database migrations are not currently required.

- **watchOS SwiftUI app** – The `frontend/WavelengthWatch/WavelengthWatch.xcodeproj` target drives the UI with `ContentViewModel`, coordinating catalog loading, user selections, and journal submission feedback for the active layer and phase state.
- **Aggregated curriculum API** – The FastAPI service (`backend/app.py`) mounts routers for catalog, layer, phase, curriculum, strategy, and journal data, seeding its SQLite database on startup before serving `/api/v1/*` routes.
- **Disk-backed catalog caching** – `CatalogRepository` persists the aggregated `/api/v1/catalog` payload to the watch’s caches directory with a 24-hour TTL, instantly replaying saved data before attempting a refresh.
- **Journal logging loop** – `JournalClient` stamps a stable pseudo-user ID, posts the selected curriculum, secondary curriculum (when relevant), and strategy IDs to `/api/v1/journal`, and surfaces success or retry messaging in the UI. The backend validates those references and returns hydrated curriculum/strategy objects.
- **Configurable networking** – `AppConfiguration` reads the API base URL from `APIConfiguration.plist`, asserting in debug builds when the placeholder host is still active so local development misconfigurations are caught early.

## Implementation Snapshot

- **Catalog delivery** – `build_catalog` aggregates layers, phases, curriculum entries, and strategies into a single payload, ordering phases consistently and attaching cache headers so clients can reuse responses. The watch reverses the layer list for presentation, keeps the server-provided phase order, and rewinds persisted selections when phase data changes.
- **Journal system** – The `Journal` table stores the primary curriculum, optional secondary curriculum, and strategy identifiers alongside a timestamp and generated user ID. Router helpers validate references, eagerly hydrate relationships for every CRUD operation, and expose filtering by user, strategy, or date range.
- **Offline behaviour** – `ContentViewModel` immediately applies any cached catalog, displays loading or retry UI states, and persists selected indices via `AppStorage`. `CatalogRepository` encodes cached payloads with their fetch timestamp, automatically evicting stale data or decoding failures before requesting a fresh copy.

## Repository Structure

Use the detailed tree below to locate major components quickly when joining the project or pairing with an agent:

```text
WavelengthWatch/
├── backend/ — FastAPI + SQLModel service with routers, schemas, and CSV/JSON fixtures powering the curriculum and journal APIs.​
│   ├── data/ — Source CSV/JSON catalogs bundled for backend seeding and the watch experience.
│   ├── routers/ — Endpoint modules covering catalog, curriculum, journal, layer, phase, and strategy routes.
│   └── tools/ — Utilities like CSV-to-JSON conversion and database seeding scripts used during setup and builds.
├── frontend/ — watchOS SwiftUI project containing the main watch target, tests, and configuration docs for collaborators.
│   └── WavelengthWatch/ — Contains the Xcode project, watch app sources, and related tests/resources.
├── tests/ — Pytest suite validating backend configuration and each API surface area.​
├── prompts/ — Product and process prompts that capture planning notes for AI-assisted development.
│   └── claude-comm/ — Centralized Markdown notes authored by Claude or other agents for async communication.
├── scripts/ — Automation helpers, including the CSV→JSON build script for bundling data with the app.​
├── .github/workflows/ — Continuous integration workflows handling backend checks and automated reviews.
├── README.md, XCODE_BUILD_SETUP.md — Contributor onboarding guide and Xcode build automation instructions.
├── dev-setup.sh, pyproject.toml, mypy.ini, ruff.toml, pytest.ini — Repo-wide tooling bootstrap plus lint/type/test configuration defaults.
```

## Configuring the Watch API Base URL

The watch target reads `API_BASE_URL` from `frontend/WavelengthWatch/WavelengthWatch Watch App/Resources/APIConfiguration.plist`. The default host intentionally points at `https://api.not-configured.local`, so the app refuses to talk to the network until you choose a real backend.

- **Simulator / local development** – Update the plist (or override it per build configuration) to `http://127.0.0.1:8000` or your tunnel before launching the watch app.
- **Release builds / TestFlight** – Override the same key in **Build Settings → Info.plist Values** or check in configuration-specific plists so every build channel targets the correct environment.
- `AppConfiguration` logs and asserts in debug builds when the placeholder host is still active, giving you an early warning about misconfiguration.

When the backend changes environment (e.g., staging vs. production), check in the plist change so other developers inherit the same defaults. See `frontend/WavelengthWatch/API_CONFIGURATION.md` for more operational notes.

## Getting Started

### Frontend (watchOS)
1. Open `frontend/WavelengthWatch/WavelengthWatch.xcodeproj` in Xcode 16.4 or newer.
2. Select an Apple Watch simulator (or paired device) as the run destination.
3. Update `APIConfiguration.plist` with your backend URL, then press ▶ to build and run.

### Backend (FastAPI)
1. Create and activate a virtual environment, then install dependencies:
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install --upgrade pip
   pip install -r backend/requirements.txt
   pip install -r backend/requirements-dev.txt
   ```
2. Start the API (from either the repository root or `backend/` directory):
   ```bash
   python -m uvicorn backend.app:app --reload
   ```
   The server seeds its SQLite database on first run; re-run `python -m backend.tools.seed_data` if you need to repopulate tables manually.
3. Visit http://127.0.0.1:8000/health to confirm the service is responding, or hit `/api/v1/catalog` to inspect the aggregated payload.

### Tests

**Backend (pytest)**:
```bash
pytest
```

**Frontend (watchOS)**:
```bash
cd frontend/WavelengthWatch
./run-tests-individually.sh                    # Run all 12 test suites (optimized, ~1 min)
./run-tests-individually.sh --individual       # Legacy mode (~12 min)
./run-tests-individually.sh AppConfigurationTests  # Run specific suite
```

After fixing the `@StateObject` initialization bug (commit 3945b6a), all test suites can run together on a single simulator. The optimized mode is ~12x faster than individual execution. See `CLAUDE.md` for more testing details.
