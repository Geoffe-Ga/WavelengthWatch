---
name: max-quality-no-shortcuts
description: >-
  Anti-bypass philosophy for linter and type checker warnings. Activates
  when you consider adding noqa, type-ignore, swiftlint-disable, or similar
  bypasses. Fix the root cause instead. Covers complexity refactoring,
  type fixes, and argument reduction patterns.
  Do NOT use for general code quality guidance (use vibe or stay-green).
metadata:
  author: Geoff
  version: 1.0.0
---

# MAX QUALITY: No Shortcuts

When you're about to add a linter bypass: STOP. Fix the root cause instead.

## Instructions

### Step 1: Understand the Warning

Read the error message carefully. Look up the rule if unfamiliar. Understand the underlying principle the tool is enforcing.

### Step 2: Identify the Root Cause

Ask:
- Is my code too complex? -> Refactor into smaller functions
- Is my type annotation wrong? -> Fix the type or implementation
- Is my import unused? -> Remove it
- Is my function too long? -> Extract helper functions
- Is my SwiftUI view too large? -> Extract sub-views

### Step 3: Fix Properly

| Bypass | Proper Fix |
|--------|-----------|
| `# noqa: C901` (complexity) | Refactor into smaller functions |
| `# type: ignore` | Fix the type annotation or implementation |
| `# noqa: F401` (unused import) | Remove the import |
| `# noqa: E501` (line too long) | Break into multiple lines |
| `// swiftlint:disable` | Fix the actual issue |
| `@available(*, deprecated)` hacks | Use proper version checking |

### Step 4: Handle Genuine Exceptions

Bypasses are acceptable ONLY for:
1. Third-party library type stub gaps (document with link)
2. Platform version compatibility (`if #available`)
3. Auto-generated code you don't control

For these cases, you MUST include:
```python
# type: ignore[no-untyped-call]
# Reason: uvicorn.run() missing type stubs in current version
# Reference: https://github.com/encode/uvicorn/issues/XXX
```

## Examples

### Example 1: Python Complexity Too High

```python
# BAD: # noqa: C901
def process_journal_entry(entry, user, feelings, strategy):
    if entry.status == "pending":
        if user.is_verified:
            # 30 more lines of nested ifs...

# GOOD: Extract validation functions
def process_journal_entry(entry, user, feelings, strategy) -> Result:
    _validate_entry(entry)
    _validate_user(user)
    return _create_entry(entry, user, feelings, strategy)
```

### Example 2: SwiftUI View Too Large

```swift
// BAD: 400-line ContentView with everything inline

// GOOD: Decompose into focused sub-views
var body: some View {
    NavigationStack {
        contentStack           // Loading/error/main states
            .toolbar { toolbarContent }
            .sheet(isPresented: $showSheet) { sheetContent }
    }
}
```

## Troubleshooting

### Error: "I genuinely can't fix this without a bypass"
- Is it a third-party library issue? Document it with a link
- Can you restructure the code to avoid the situation entirely?
- If truly necessary, add full justification comment

### Error: "Fixing this properly will take too long"
- 10 minutes fixing properly now saves 2 hours debugging later
- Each bypass makes the next one easier to justify
