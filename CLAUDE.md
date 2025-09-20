# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
```

### Pre-commit and CI
```bash
pre-commit run --all-files   # Run all pre-commit hooks
pre-commit install           # Install hooks (done by dev-setup.sh)
```

## Repository Directory Overview

Use this directory snapshot to quickly orient agents and contributors before they jump into implementation details:

```text
WavelengthWatch/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── claude-code-review.yml
│       └── claude.yml
├── AGENTS.md
├── CLAUDE.md
├── README.md
├── XCODE_BUILD_SETUP.md
├── backend/
│   ├── README.md
│   ├── __init__.py
│   ├── app.py
│   ├── database.py
│   ├── models.py
│   ├── schemas.py
│   ├── schemas_catalog.py
│   ├── requirements-dev.txt
│   ├── requirements.txt
│   ├── data/
│   │   ├── a-w-curriculum.csv
│   │   ├── a-w-headers.csv
│   │   ├── a-w-strategies.csv
│   │   ├── curriculum.json
│   │   ├── headers.json
│   │   ├── strategies.json
│   │   └── prod/
│   │       ├── a-w-curriculum.json
│   │       ├── a-w-headers.json
│   │       └── a-w-strategies.json
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── catalog.py
│   │   ├── curriculum.py
│   │   ├── journal.py
│   │   ├── layer.py
│   │   ├── phase.py
│   │   └── strategy.py
│   ├── services/
│   │   ├── __init__.py
│   │   └── catalog.py
│   └── tools/
│       ├── csv_to_json.py
│       ├── data/
│       │   ├── curriculum.csv
│       │   ├── journal.csv
│       │   ├── layer.csv
│       │   ├── phase.csv
│       │   └── strategy.csv
│       └── seed_data.py
├── dev-setup.sh
├── frontend/
│   └── WavelengthWatch/
│       ├── API_CONFIGURATION.md
│       ├── WavelengthWatch Watch App/
│       │   ├── App/
│       │   │   └── AppConfiguration.swift
│       │   ├── Assets.xcassets/
│       │   │   ├── AccentColor.colorset
│       │   │   ├── AppIcon.appiconset
│       │   │   └── Contents.json
│       │   ├── ContentView.swift
│       │   ├── Models/
│       │   │   └── CatalogModels.swift
│       │   ├── PhaseNavigator.swift
│       │   ├── Resources/
│       │   │   └── APIConfiguration.plist
│       │   ├── Services/
│       │   │   ├── APIClient.swift
│       │   │   ├── CatalogRepository.swift
│       │   │   └── JournalClient.swift
│       │   ├── ViewModels/
│       │   │   └── ContentViewModel.swift
│       │   └── WavelengthWatchApp.swift
│       ├── WavelengthWatch Watch AppTests/
│       │   └── WavelengthWatch_Watch_AppTests.swift
│       ├── WavelengthWatch Watch AppUITests/
│       │   ├── WavelengthWatch_Watch_AppUITests.swift
│       │   └── WavelengthWatch_Watch_AppUITestsLaunchTests.swift
│       ├── WavelengthWatch.xcodeproj/
│       │   ├── project.pbxproj
│       │   ├── project.xcworkspace/
│       │   │   └── contents.xcworkspacedata
│       │   └── xcuserdata/
│       │       └── geoffgallinger.xcuserdatad/
│       │           └── xcschemes/
│       │               └── xcschememanagement.plist
│       └── XCODE_PROJECT_UPDATES.md
├── mypy.ini
├── prompts/
│   ├── add-headers.md
│   ├── add-layers.md
│   ├── ci-and-pre-commit-bootstrap.md
│   ├── front-end-tracer-code.md
│   └── journal_feature.md
├── pyproject.toml
├── pytest.ini
├── ruff.toml
├── scripts/
│   └── convert_csv_to_json.sh
└── tests/
    └── backend/
        ├── conftest.py
        ├── test_app_config.py
        ├── test_catalog_api.py
        ├── test_curriculum_api.py
        ├── test_journal_api.py
        ├── test_layer_api.py
        ├── test_phase_api.py
        └── test_strategy_api.py
```

## Architecture Overview

### High-Level Structure
WavelengthWatch is a **watch-only app** that displays the Archetypal Wavelength phases with embedded self-care strategies. The architecture prioritizes **offline-first functionality** with optional backend data refresh.

### Key Components

**Frontend (SwiftUI watchOS)**:
- `ContentView.swift`: Main app with embedded JSON datasets and layered navigation
- **Dual-axis scrolling**: Vertical for layers (Beige→Purple→Red→etc.), horizontal for phases (Rising→Peaking→etc.)
- **Embedded data**: All curriculum and strategies are bundled as JSON strings to ensure offline functionality
- **Data structures**: `Phase` enum, `Strategy`, `CurriculumEntry`, and `LayerHeader` models

**Backend (FastAPI)**:
- `backend/app.py`: Minimal API serving JSON endpoints (`/curriculum`, `/strategies`, `/health`)
- `backend/data/`: JSON files converted from CSV sources using `csv_to_json.py`
- Designed for static hosting (S3/CloudFront) or lightweight deployment

### Data Flow
1. **Primary**: App uses embedded JSON datasets in Swift code
2. **Optional**: Background refresh can fetch latest data from backend endpoints
3. **Development**: CSV files in `backend/data/` are converted to JSON for both backend serving and frontend embedding

### Navigation Architecture
- **Outer TabView**: Vertical scrolling through "layers" (Strategies, Beige, Purple, Red, etc.) with 90° rotation
- **Inner TabView**: Horizontal scrolling through phases within each layer
- **Detail Views**: `CurriculumDetailView` for medicine/toxic pairs, `StrategyListView` for strategies

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
