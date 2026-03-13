---
name: vibe
description: >-
  Code style, naming conventions, and structural patterns for consistent
  codebases. Use when writing new code, reviewing style choices, or
  establishing project conventions. Covers Python and Swift idioms.
  Do NOT use for documentation content or architectural decisions.
metadata:
  author: Geoff
  version: 1.0.0
---

# Vibe

Consistent code style: consistency over cleverness, readability over brevity, explicitness over implicitness.

## Instructions

### Step 1: Follow Language Idioms

**Python**: PEP 8/257, type hints everywhere, Pydantic models for schemas, SQLModel for DB, pathlib for paths, async/await for I/O.

**Swift**: SwiftUI declarative patterns, `@Observable` / `@StateObject` as appropriate, protocol-oriented design, small focused views (< 200 lines), `if #available` for version checks.

### Step 2: Apply Naming Conventions

| Element | Python | Swift |
|---------|--------|-------|
| Functions | `snake_case` | `camelCase` |
| Classes/Types | `PascalCase` | `PascalCase` |
| Constants | `SCREAMING_SNAKE` | `camelCase` (static let) |
| Files | `snake_case.py` | `PascalCase.swift` |
| Test functions | `test_feature_scenario` | `func feature_scenario_expected()` |

### Step 3: Follow Project Conventions

**Frontend (SwiftUI)**:
- Design system prefix: `WL` (WavelengthWatch)
- Token enums: `WLColorTokens`, `WLTypographyTokens`, `WLSpacingTokens`
- Modifiers: `WLGlassModifier`, `WLCardModifier`
- View extensions: `.wlGlass()`, `.wlCard()`, `.wlNavigationBar()`
- Backward compat: `if #available(watchOS 26, *)` with fallback

**Backend (FastAPI)**:
- Routers in `backend/routers/`
- Schemas in `backend/schemas.py`
- Models in `backend/models.py`
- Line length: 78 chars (Ruff)

### Step 4: Avoid Anti-Patterns

- No clever code over clear code
- No abbreviations (unless universally understood)
- No deep nesting (> 3 levels)
- No long functions (> 50 lines)
- No mixed abstraction levels
- No magic numbers without constants
- No global state or god objects
- No views > 200 lines (extract sub-views)

## Examples

### Example 1: Good Swift Style

```swift
struct PhaseCardView: View {
    let phase: Phase
    let layerColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: WLSpacingTokens.sm) {
            Text(phase.name)
                .font(WLTypographyTokens.cardTitle)
            Text(phase.description)
                .font(WLTypographyTokens.cardSubtitle)
                .foregroundStyle(.secondary)
        }
        .wlCard(tint: layerColor)
    }
}
```

### Example 2: Good Python Style

```python
from backend.models import Journal
from backend.schemas import JournalCreate

async def create_entry(
    entry: JournalCreate,
    session: AsyncSession,
) -> Journal:
    """Create a journal entry with validated relationships."""
    journal = Journal(**entry.model_dump())
    session.add(journal)
    await session.commit()
    return journal
```

## Troubleshooting

### Error: Inconsistent style across the codebase
- Run `swiftformat frontend` for Swift
- Run `scripts/check-backend.sh --fix` for Python
- Follow existing patterns in the codebase over personal preference
