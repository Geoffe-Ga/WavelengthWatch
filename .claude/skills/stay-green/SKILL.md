---
name: stay-green
description: >-
  2-gate TDD development workflow: Gate 1 is Red-Green-Refactor testing,
  Gate 2 is pre-commit quality checks. Use when implementing features,
  fixing bugs, or doing any development work. Ensures code is never
  committed without passing tests and quality checks.
  Do NOT use for bug-specific debugging (use bug-squashing-methodology).
metadata:
  author: Geoff
  version: 1.0.0
---

# Stay Green

Write tests first, then code. Never declare work finished until all checks pass.

## Instructions

### Gate 1: TDD (Red-Green-Refactor)

1. **Red** - Write a failing test describing the behavior you want
   ```bash
   # Backend
   scripts/check-backend.sh --test
   # Frontend
   frontend/WavelengthWatch/run-tests-individually.sh
   ```

2. **Green** - Write just enough code to make the test pass
   ```bash
   # Same commands — should now pass
   ```

3. **Refactor** - Clean up while keeping tests green
   ```bash
   # Same commands — should still pass
   ```

Repeat for each small piece of functionality. Write tests incrementally, not all at once.

### Gate 2: Pre-Commit Quality Checks

```bash
pre-commit run --all-files
```

When checks fail: read errors, fix issues, run again. Repeat until all green.

Quality checks include:
- **Backend**: Ruff lint + format, Mypy type checking, pytest, bandit security
- **Frontend**: SwiftFormat formatting
- File hygiene (trailing whitespace, EOF, YAML/JSON/TOML validity)

### Work is DONE when:
1. All tests pass (Gate 1 complete)
2. All pre-commit checks pass (Gate 2 complete)

No exceptions.

## Examples

### Example 1: Adding a New Backend Endpoint

```python
# Gate 1 - Red: Write failing test
def test_get_phase_returns_expected_fields():
    response = client.get("/api/v1/phases/1")
    assert response.status_code == 200
    assert "name" in response.json()

# Gate 1 - Green: Implement endpoint
# Gate 1 - Refactor: Clean up
# Gate 2: pre-commit run --all-files -> All passed!
```

### Example 2: Adding a SwiftUI View

```swift
// Gate 1 - Red: Write failing test (Swift Testing)
@Test func phaseCard_displaysTitle() {
    let card = PhaseCardView(phase: .mock)
    #expect(card.title == "Rising")
}

// Gate 1 - Green: Implement view
// Gate 2: pre-commit run --all-files -> SwiftFormat passes
```

## Troubleshooting

### Error: Frontend tests fail with simulator issues
```bash
# Use the test script — it handles simulator lifecycle
frontend/WavelengthWatch/run-tests-individually.sh
# Never invoke xcodebuild directly
```

### Error: Backend type errors from Mypy
```bash
scripts/check-backend.sh --type  # See specific errors
# Fix type annotations
scripts/check-backend.sh         # Verify all checks pass
```
