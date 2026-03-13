---
name: ci-debugging
description: >-
  Debug CI test failures on pull requests with structured protocol.
  Use when CI fails on your PR, tests pass locally but fail in CI,
  or you're tempted to say "pre-existing issue". Covers state comparison,
  error reading, local reproduction, and common root causes.
  Do NOT use for local-only test failures or feature development.
metadata:
  author: Geoff
  version: 1.0.0
---

# CI Debugging

If tests passed before and fail now, YOUR changes broke something. Debug properly.

## Instructions

### Step 1: Compare States (2 minutes)

```bash
# What did the last passing PR have?
gh pr view <last-passing-pr> --json checks

# What does my PR have?
gh pr checks <my-pr>

# What changed between them?
git diff <last-passing-commit> HEAD
```

Ask: Did I modify config files? Add dependencies? Change imports or module structure?

### Step 2: Read the Actual Error (5 minutes)

```bash
gh run view --job=<failing-job-id> --log | grep -A 50 "ERROR\|FAILED\|AssertionError"
```

Look for: path issues, configuration errors, dependency problems, file artifacts.

CI jobs in this project:
- **Pre-commit**: lint, type, security checks
- **Backend**: Ruff lint, Mypy type check, pytest
- **Frontend**: SwiftFormat lint, xcodebuild build + test

### Step 3: Reproduce Locally (5 minutes)

```bash
# Backend
scripts/check-backend.sh

# Frontend
frontend/WavelengthWatch/run-tests-individually.sh

# Pre-commit
pre-commit run --all-files
```

If it passes locally but fails in CI, check:
- Xcode version differences (CI uses macos-15 runner)
- Simulator availability (Series 10 vs Series 11)
- Python dependency versions
- SwiftFormat version differences

### Step 4: Inspect Your Changes (10 minutes)

```bash
# Config changes
git diff HEAD~1 -- .github/workflows/
git diff HEAD~1 -- pyproject.toml ruff.toml mypy.ini pytest.ini

# Swift changes that might break build
git diff HEAD~1 -- "frontend/WavelengthWatch/WavelengthWatch.xcodeproj/"

# Import validation
python -c "from backend.app import app; print('OK')"
```

### Step 5: Fix and Verify

Make a targeted fix, verify locally, push, confirm CI passes.

## Examples

### Example 1: SwiftFormat Failure

**Symptom**: "SwiftFormat check" step fails in CI.

**Debug**:
```bash
swiftformat --lint frontend  # See which files need formatting
swiftformat frontend         # Auto-fix
```

### Example 2: Simulator Not Found

**Symptom**: "Unable to find a destination matching the provided destination specifier"

**Root Cause**: CI runner has different simulators than local machine.

**Fix**: Use `run-tests-individually.sh` which auto-detects available simulators.

## Troubleshooting

### Error: "Passes locally, fails in CI"
- Check Xcode version on CI runner vs local
- Ensure test cleanup removes all artifacts
- Verify SwiftFormat version matches (CI installs via brew)
- Check if CI uses different simulator than local

### Error: Spending more than 30 minutes debugging
- Re-read the actual error message carefully
- Check if you modified any config files
- Compare your branch with the last green commit line by line
