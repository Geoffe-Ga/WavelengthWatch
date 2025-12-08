# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Communication files**: Store any Markdown you author for coordination or planning in `prompts/claude-comm/` so future agents can locate prior discussions quickly.

**Deployment status**: The project has not yet been deployed to production. Shipping to the App Store is on the roadmap, so database migrations are not currently required.

## Development Commands

### Setup
```bash
bash dev-setup.sh  # Complete dev environment setup (Python venv, pre-commit, SwiftFormat)
```

### Backend (FastAPI)
```bash
# Development server
uvicorn backend.app:app --reload

# Testing
pytest -q                    # Run all tests
pytest tests/backend/ -v     # Verbose backend tests

# Linting & Type Checking
ruff check backend tests/backend        # Lint Python code
ruff format backend tests/backend       # Format Python code
mypy --config-file mypy.ini backend     # Type check
```

### Frontend (watchOS SwiftUI)
```bash
# Format Swift code
swiftformat frontend
swiftformat --lint frontend  # Check formatting without modifying

# Build (use Xcode for running)
# Open frontend/WavelengthWatch/WavelengthWatch.xcodeproj in Xcode 16.4+
# Select Apple Watch target and build/run

# Testing
frontend/WavelengthWatch/run-tests-individually.sh                       # Run all test suites (optimized - single simulator)
frontend/WavelengthWatch/run-tests-individually.sh --individual          # Run suites individually (legacy mode)
frontend/WavelengthWatch/run-tests-individually.sh PhaseNavigatorTests   # Run specific suite
```

**Test Optimization (Nov 2025)**
After fixing the `@StateObject` initialization bug (commit 3945b6a), all test suites can now run together on a single simulator without crashes. The script runs all suites together by default (~12x faster than individual execution). Use `--individual` flag for legacy behavior if needed.

### Pre-commit and CI
```bash
pre-commit run --all-files   # Run all pre-commit hooks
pre-commit install           # Install hooks (done by dev-setup.sh)
```

## Command Execution Guidelines

**CRITICAL RULES FOR ALL AGENTS:**

### Never Use `cd` Commands
All commands MUST be run with relative paths from the project root. **Never use `cd`.**

❌ **WRONG:**
```bash
cd frontend/WavelengthWatch
./run-tests-individually.sh
```

✅ **CORRECT:**
```bash
frontend/WavelengthWatch/run-tests-individually.sh
```

**Why:** Using `cd` creates hidden directory state that causes confusion, breaks command sequences, and makes debugging harder. Always specify full relative paths from project root.

### Always Use Test Scripts, Not Direct Tool Invocation
For frontend tests, **always use the test script** instead of direct `xcodebuild` or `xcrun` commands.

❌ **WRONG:**
```bash
xcodebuild test -scheme "WavelengthWatch Watch App" -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (42mm)'
```

✅ **CORRECT:**
```bash
frontend/WavelengthWatch/run-tests-individually.sh
```

**Why:** Test scripts encapsulate proper configuration, simulator management, and cleanup. Direct invocation bypasses these safeguards and can leave simulators in bad states.

## Repository Directory Overview

Use this directory snapshot to quickly orient agents and contributors before they jump into implementation details:

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
│   └── claude-comm/ — Centralized Markdown notes for async agent communication.
├── scripts/ — Automation helpers, including the CSV→JSON build script for bundling data with the app.​
├── .github/workflows/ — Continuous integration workflows handling backend checks and automated reviews.
├── README.md, XCODE_BUILD_SETUP.md — Contributor onboarding guide and Xcode build automation instructions.
├── dev-setup.sh, pyproject.toml, mypy.ini, ruff.toml, pytest.ini — Repo-wide tooling bootstrap plus lint/type/test configuration defaults.
```

## Architecture Overview

### High-Level Structure
WavelengthWatch is a **watch-only app** that displays the Archetypal Wavelength phases with embedded self-care strategies. The architecture prioritizes **offline-first functionality** with optional backend data refresh.

### Key Components

**Frontend (SwiftUI watchOS)**:
- `ContentView.swift`: Main watch UI for browsing curriculum, logging journal entries, and surfacing quick confirmations.
- **Dual-axis scrolling**: Vertical for layers (Beige→Purple→Red→etc.), horizontal for phases (Rising→Peaking→etc.).
- **Embedded data**: Curriculum and strategies are bundled as JSON strings to ensure offline functionality, while live updates come from `/api/v1/catalog` when connectivity exists.
- **Journal integration**: `JournalClient` lives in `Services/` and posts entries directly to the backend, deriving a stable pseudo-user identifier from `UserDefaults`.

**Backend (FastAPI)**:
- `backend/app.py`: Application factory wiring routers and middleware.
- `backend/models.py`: SQLModel tables for layers, phases, curriculum items, strategies, and the shipping `Journal` table.
- `backend/routers/journal.py`: CRUD routes under `/api/v1/journal` with eager relationship loading so responses include related curriculum/strategy payloads.
- `backend/schemas.py`: Pydantic models that coerce timestamps to UTC and validate foreign keys via the service layer.

### Journal System Notes
- **Data model**: A single `Journal` row ties back to `Curriculum` (required) and optionally `Strategy`/`secondary_curriculum` using SQLModel relationships. The `InitiatedBy` enum tracks whether the entry was self-started or triggered by automation.
- **Request lifecycle**: The watch sends `created_at`, `user_id`, curriculum IDs, and optional strategy data. The router guards referential integrity and re-queries with joined relationships before returning the hydrated response.
- **Strengths**: Minimal schema surface, strong alignment with existing catalog tables, and straightforward to extend with analytics queries. Because joins happen on the server, clients can stay slim and reuse the same curriculum models.
- **Trade-offs**: No offline queue or retry buffer yet, so failures must be retried manually. Additional relationships (e.g., multiple secondary feelings) will require schema evolution once migrations become part of the deployment story.

### Data Flow
1. The watch renders bundled JSON immediately.
2. Optional background refresh hits `/api/v1/catalog` for updated curriculum and `/api/v1/journal` for history when needed.
3. Journal submissions call `/api/v1/journal` and rely on backend joins to return hydrated entries for UI confirmation.

### Navigation Architecture
- **Outer TabView**: Vertical scrolling through "layers" (Strategies, Beige, Purple, Red, etc.) with 90° rotation.
- **Inner TabView**: Horizontal scrolling through phases within each layer.
- **Detail Views**: `CurriculumDetailView` for medicine/toxic pairs, `StrategyListView` for strategies.

## Development Guidelines (from AGENTS.md)

### Test-Driven Development
- Write tests before or alongside new features
- Every bug fix must include a failing test first
- Backend uses pytest with isolated tests

### CI Requirements
- All CI checks must pass before merging
- Never comment out failing tests
- GitHub Actions workflow covers: backend linting/testing, SwiftFormat checks, Xcode building

### Code Quality Standards
- Python: Ruff linting (line length 78), Mypy type checking, Pydantic models
- Swift: SwiftFormat formatting, no custom linting rules
- Make small, meaningful commits with clear messages

### No Shortcuts or Workarounds
**IMPORTANT**: Always fix issues properly, never use shortcuts or workarounds that bypass quality checks:
- **No commenting out failing tests** - fix the underlying issue
- **No linter bypass comments** (`# type: ignore`, `# noqa`, etc.) - address the actual problem
- **No disabling CI checks** - make the code pass legitimately
- **Exception**: Missing type stubs for third-party libraries are acceptable to ignore with proper documentation
- Fix root causes, not symptoms
