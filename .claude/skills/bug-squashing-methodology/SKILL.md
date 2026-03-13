---
name: bug-squashing-methodology
description: >-
  Structured 5-step bug fix process with root cause analysis and TDD.
  Use when fixing bugs, debugging failures, or investigating defects.
  Covers RCA documentation, reproduction, TDD fix cycle, and PR workflow.
  Do NOT use for general feature development (use stay-green), CI
  environment issues (use ci-debugging), or code reviews.
metadata:
  author: Geoff
  version: 1.0.0
---

# Bug Squashing Methodology

Systematic process for fixing bugs: Document, Understand, Fix, Verify. Never skip straight to coding.

## Instructions

### Step 1: Root Cause Analysis (RCA)

Create `prompts/claude-comm/RCA_ISSUE_XXX.md` with:
- **Problem Statement**: Error message, reproduction steps
- **Root Cause**: Exact line/logic causing failure
- **Analysis**: Why it happens, what was confused/wrong
- **Impact**: Severity, scope, frequency
- **Contributing Factors**: Why wasn't it caught earlier?
- **Fix Strategy**: Options with recommendation
- **Prevention**: How to avoid similar bugs

### Step 2: File a GitHub Issue

```bash
gh issue create --title "bug(component): Brief description" \
  --body "Reproduction steps, root cause summary, proposed fix" \
  --label "bug"
```

### Step 3: Branch and Fix with TDD

```bash
git checkout -b fix-component-issue-XXX
```

1. **Red**: Write a test that reproduces the bug (should fail)
2. **Green**: Write minimal code to fix the bug (test passes)
3. **Refactor**: Clean up the fix while keeping tests green

### Step 4: Quality Gates

Run both gates before committing:

```bash
# Gate 1: All tests pass
scripts/check-backend.sh --test                        # Backend
frontend/WavelengthWatch/run-tests-individually.sh     # Frontend

# Gate 2: All quality checks pass
pre-commit run --all-files
```

### Step 5: Commit and PR

Use conventional commit format: `fix(component): brief description (#XXX)`

## Examples

### Example 1: Backend Data Bug

**Problem**: Journal entries return null strategy when strategy_id is valid.

**RCA**: `backend/routers/journal.py` missing eager load for strategy relationship.

**Fix**:
```python
# Red: Test reproducing the bug
def test_journal_entry_includes_strategy():
    entry = create_test_entry(strategy_id=1)
    response = client.get(f"/api/v1/journal/{entry.id}")
    assert response.json()["strategy"] is not None

# Green: Add eager loading
query = select(Journal).options(joinedload(Journal.strategy))
```

### Example 2: SwiftUI State Bug

**Problem**: Navigation pops to root unexpectedly during flow.

**RCA**: `onChange(of: flowCoordinator.currentStep)` fires during detail view transitions.

**Fix**:
```swift
// Red: Test the state transition
@Test func flowTransition_doesNotPopDuringDetail() {
    // ...
}

// Green: Guard against premature navigation pop
case .selectingPrimary, .selectingSecondary:
    if !navigationPath.isEmpty {
        navigationPath.removeLast(navigationPath.count)
    }
```

## Troubleshooting

### Error: Can't reproduce the bug locally
- Check environment differences (Xcode version, watchOS simulator)
- Add debug logging at the failure point
- Try running with the exact same data/input as the report

### Error: Fix breaks other tests
- Your fix may have changed shared behavior
- Run the full test suite, not just the new test
- Consider if the other tests were relying on buggy behavior
