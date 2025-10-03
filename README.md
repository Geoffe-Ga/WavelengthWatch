# WavelengthWatch

## Overview

WavelengthWatch is a watchOS-only app that brings the Archetypal Wavelength to your wrist. You can horizontally scroll through the six phases of the Wavelength, each phase offering a pocket-sized guide to its “medicinal” and “toxic” expressions. Tap on a phase to reveal a quick box of wisdom and self-care strategies, then swipe to the next when you’re ready. The goal is maximum uptime on your personal Apple Watch: even offline, the guidance is bundled into the app, and when connectivity is available, background refresh pulls the latest updates.

_Status_: The project has not yet been deployed to production. An eventual App Store launch is planned, so formal database migrations are not currently required.

- **Watch-Only App (SwiftUI)**: Built in Xcode 16.4, runs natively on watchOS 11.6.1 (Apple Watch Series 9).
- **Dynamic Curriculum Catalog**: The watch loads the `/api/v1/catalog` endpoint, which delivers joined layer/phase/strategy data (with IDs) and caches it locally for 24 hours.
- **Journaling Support**: When a user records how they feel, the watch posts real curriculum and strategy identifiers to the backend journal endpoint.
- **Offline-first Caching**: Cached catalog responses are stored on disk and surfaced immediately when the network is unavailable; stale caches are refreshed in the background.
- **FastAPI Backend**: A lightweight Python service (`backend/app.py`) exposes CRUD endpoints plus the new aggregated catalog feed with appropriate cache headers.
- **CI and Pre-commit**:
  - GitHub Actions workflow builds the watch app on a simulator, runs SwiftLint/SwiftFormat checks, and validates backend tests.
  - Pre-commit hooks enforce linting and formatting for both Swift (via Mint, SwiftLint, SwiftFormat) and Python (via Mypy, Ruff, etc. in the backend).

## Journal System Architecture

The shipping journal experience is a coordinated loop between the FastAPI backend and the watch app. Understanding the current solution helps future contributors reason about requested upgrades without discarding the working baseline.

- **Backend data model**: `backend/models.py` defines a single `Journal` SQLModel table keyed by curriculum and optional strategy references. A `sqlalchemy.Enum` (`InitiatedBy`) tracks whether an entry is self-started or scheduled. The model intentionally keeps the schema narrow—most denormalized context (layer/phase metadata) is resolved at query time via relationships so reads return rich objects without duplicating data.
- **Validation & serialization**: Pydantic schemas in `backend/schemas.py` validate ISO timestamps, coerce them to UTC, and ensure foreign keys exist before writes. `JournalRead` embeds the joined curriculum and strategy payloads the watch already understands, which keeps the API single-purpose.
- **API surface**: `backend/routers/journal.py` exposes CRUD endpoints under `/api/v1/journal`. The router loads related curriculum/strategy rows using `joinedload` so clients always receive hydrated objects. Filtering by user, strategy, and time range is supported today and is covered by `tests/backend/test_journal_api.py`.
- **Watch client flow**: `JournalClient` (Swift) derives a stable pseudo-user identifier from `UserDefaults`, stamps the current time, and posts straight to `/api/v1/journal`. The UI asks for lightweight confirmation before calling `submit`, then reuses the API response to update on-device state.
- **Merits**: The approach is simple to reason about, works offline until submission time, and keeps the backend schema aligned with the catalog tables. Having the backend join related curriculum/strategy information reduces the amount of state the watch must maintain.
- **Trade-offs**: There is no batching or offline queue yet, so failed submissions must be retried manually. The single-table approach makes analytics that depend on multiple combos or self-care selections harder, and introducing additional relationships will require new migrations when production deployment begins.

## Repository Structure

Use the detailed tree below to locate major components quickly when joining the project or pairing with an agent:

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
│   └── claude-comm/ — Centralized Markdown notes authored by Claude or other agents for async communication.
├── scripts/ — Automation helpers, including the CSV→JSON build script for bundling data with the app.​
├── .github/workflows/ — Continuous integration workflows handling backend checks and automated reviews.
├── README.md, XCODE_BUILD_SETUP.md — Contributor onboarding guide and Xcode build automation instructions.
├── dev-setup.sh, pyproject.toml, mypy.ini, ruff.toml, pytest.ini — Repo-wide tooling bootstrap plus lint/type/test configuration defaults.
```

## Configuring the Watch API Base URL

The watch app resolves its networking configuration from `Resources/APIConfiguration.plist` inside the watch target. The plist contains an `API_BASE_URL` key that defaults to `https://api.not-configured.local`, a sentinel host that intentionally fails if you try to talk to it.

- **Simulator / local development**: duplicate the `Debug` configuration or edit the plist entry so it points at your tunnel or `http://127.0.0.1:8000` (expose the port via ngrok if you need to reach a real watch).
- **Release builds / TestFlight**: override the same key in Xcode’s Build Settings (`Info.plist Values`) or provide an environment-specific plist per configuration.
- The `AppConfiguration` helper logs (and asserts in debug builds) when the app still points at the placeholder host so you notice misconfigurations before shipping.

When the backend changes environment (e.g., staging vs. production), check in a plist update so other developers inherit the same defaults. See `frontend/WavelengthWatch/API_CONFIGURATION.md` for more operational notes.

## Getting Started

### Frontend (watchOS)
1. Open `frontend/watch-frontend/WavelengthWatch.xcodeproj` in Xcode 16.4.
2. Select your Apple Watch (or simulator) as the run destination.
3. Press ▶ to build and run.

### Backend (FastAPI)
1. Install dependencies:
   ```bash
   cd backend
   pip install -r requirements.txt

2. Run locally:
```bash
uvicorn app:app --reload
```

3. Visit http://127.0.0.1:8000/curriculum
 to see the JSON served.
