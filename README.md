# WavelengthWatch

## Overview

WavelengthWatch is a watchOS-only app that brings the Archetypal Wavelength to your wrist. You can horizontally scroll through the six phases of the Wavelength, each phase offering a pocket-sized guide to its “medicinal” and “toxic” expressions. Tap on a phase to reveal a quick box of wisdom and self-care strategies, then swipe to the next when you’re ready. The goal is maximum uptime on your personal Apple Watch: even offline, the guidance is bundled into the app, and when connectivity is available, background refresh pulls the latest updates.

## Features

- **Watch-Only App (SwiftUI)**: Built in Xcode 16.4, runs natively on watchOS 11.6.1 (Apple Watch Series 9).
- **Horizontal Scrolling UI**: Swipe through the self-care strategies corresponding to the phases of the Archetypal Wavelength.
- **Phase Details**: Tap a phase to see “medicinal” and “toxic” expressions.
- **Baseline Offline Data**: Core dataset (stages, phases, expressions, strategies) is bundled as JSON in the app, so the watch works instantly without a network.
- **Optional Refresh**: When background time is available, the app fetches the latest JSON from the backend or static hosting, ensuring freshness without breaking offline reliability.
- **FastAPI Backend**: A lightweight Python service (in `backend/app.py`) serves JSON mappings and static assets. The backend reads simple JSON files (converted from CSV during development) and can be deployed directly or fronted by S3/CloudFront for static hosting.
- **CI and Pre-commit**:
  - GitHub Actions workflow builds the watch app on a simulator, runs SwiftLint/SwiftFormat checks, and validates backend tests.
  - Pre-commit hooks enforce linting and formatting for both Swift (via Mint, SwiftLint, SwiftFormat) and Python (via Mypy, Ruff, etc. in the backend).

## Repository Structure
```aiignore
WavelengthWatch/
├── frontend/ # watchOS SwiftUI app
│ └── WavelengthWatch/ # Xcode project + assets
│
├── backend/ # FastAPI service
│ ├── app.py # FastAPI entrypoint
│ ├── data/
│ │ ├── curriculum.json # stage/phase + medicinal/toxic
│ │ ├── strategies.json # self-care strategies
│ │ └── images/ # optional static images
│ └── requirements.txt
│
├── tests/ # shared test root
│ ├── backend/ # pytest for FastAPI
│ └── frontend/ # Swift XCTest / Swift Testing (lives in Xcode)
│
├── .github/workflows/ci.yml # CI pipeline
├── .pre-commit-config.yaml # pre-commit hooks
└── AGENTS.md # Guardrails for AI Agents in pair programming
```
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
