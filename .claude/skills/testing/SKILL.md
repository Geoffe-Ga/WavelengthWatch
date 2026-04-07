---
name: testing
description: >-
  Write comprehensive, maintainable tests following TDD and AAA pattern.
  Use when writing unit tests, integration tests, setting up fixtures,
  mocking dependencies, or improving test coverage. Covers Python (pytest)
  and Swift (Swift Testing framework).
  Do NOT use for mutation testing specifics.
metadata:
  author: Geoff
  version: 1.0.0
---

# Testing

Test behavior, not implementation. One assertion concept per test. Follow AAA (Arrange-Act-Assert).

## Instructions

### Step 1: Follow the Principles

1. Test behavior, not implementation
2. One assertion concept per test
3. Follow AAA pattern (Arrange-Act-Assert)
4. Write tests first (TDD) when possible
5. Keep tests fast and isolated
6. Make tests readable and self-documenting

### Step 2: Apply Language-Specific Patterns

**Python (pytest)**:
- Use pytest classes to group related tests
- Use fixtures for setup/teardown
- Use `@pytest.mark.parametrize` for data-driven tests
- Use `httpx.AsyncClient` for FastAPI endpoint tests
- Mock external dependencies, not internal logic

**Swift (Swift Testing)**:
- Use `@Test` attribute (not XCTest)
- Use `#expect()` for assertions (not XCTAssert)
- Use `@Suite` to group related tests
- Use descriptive test function names: `func featureName_scenario_expectedResult()`
- Keep test files in `WavelengthWatch Watch AppTests/`

### Step 3: Follow Coverage Best Practices

- Test edge cases: empty inputs, boundary values, nil, concurrent access
- Test error paths, not just happy paths
- Don't test third-party code - mock external services
- Backend: `pytest --cov=backend --cov-report=html`
- Frontend: test via `run-tests-individually.sh`

## Examples

### Example 1: Python Unit Test with Parametrize

```python
class TestJournalValidation:
    def test_valid_entry_creates_successfully(self, db_session):
        entry = create_journal_entry(feeling_id=1, strategy_id=1)
        assert entry.id is not None
        assert entry.feeling_id == 1

    @pytest.mark.parametrize("feeling_id,expected_error", [
        (None, "feeling_id is required"),
        (999, "feeling not found"),
    ])
    def test_invalid_feeling_raises_error(self, db_session, feeling_id, expected_error):
        with pytest.raises(ValueError, match=expected_error):
            create_journal_entry(feeling_id=feeling_id)
```

### Example 2: Swift Testing

```swift
@Suite struct WLColorTokensTests {
    @Test func namedLayerColors_allElevenAreDefined() {
        let colors = [
            WLColorTokens.beige, WLColorTokens.purple, WLColorTokens.red,
            WLColorTokens.blue, WLColorTokens.orange, WLColorTokens.green,
        ]
        #expect(colors.count == 6)
    }

    @Test func layerColor_returnsNonNilForValidStage() {
        let color = WLColorTokens.layer("Beige")
        #expect(color != nil)
    }
}
```

## Troubleshooting

### Error: Tests are slow
- Mock external dependencies (HTTP, database)
- Use `tmp_path` fixture for filesystem tests
- Profile with `pytest --durations=10`

### Error: Tests are flaky
- Look for shared state between tests
- Check for test order dependencies
- Mock time-dependent code
- Avoid sleep() in tests

### Error: Frontend tests crash simulator
- Always use `run-tests-individually.sh`, never direct xcodebuild
- Try `--individual` flag if all-at-once mode crashes
