## ⚙️ Agent Behavior and Development Philosophy

To set up the full development environment, run:

```bash
bash dev-setup.sh
```

**Deployment status**: WavelengthWatch has not yet been deployed to production. The team plans to ship to the App Store in the future, so schema migrations are not currently required.

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

## Repository Directory Overview

Use this quick reference tree to understand where major assets live before collaborating or delegating work:

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
