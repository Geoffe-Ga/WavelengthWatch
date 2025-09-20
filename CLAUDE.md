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

Always rerun `pre-commit run --all-files` until every hook reports success before wrapping up any assigned task.

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
