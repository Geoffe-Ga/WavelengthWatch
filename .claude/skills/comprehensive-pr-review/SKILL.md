---
name: comprehensive-pr-review
description: >-
  Structured 10-section PR review covering security, quality, testing,
  and documentation. Use when reviewing pull requests, evaluating code
  changes, or doing code review. Produces verdicts with specific references.
  Do NOT use for backlog grooming or issue triage.
metadata:
  author: Geoff
  version: 1.0.0
---

# Comprehensive PR Review

Structured code review evaluating PRs across security, quality, testing, documentation, and project compliance.

## Instructions

### Step 1: Summarize the PR
Brief overview of what the PR does (2-3 sentences).

### Step 2: Identify Strengths
What is done well: good design decisions, well-written code, comprehensive tests, clear documentation, proper error handling.

### Step 3: Security Review
Flag security issues with severity:
- **BLOCKING**: Must fix before merge (injection, auth bypass, secrets exposure)
- **HIGH**: Should fix soon (missing input validation, weak crypto)
- **LOW**: Nice to have (hardening, defense-in-depth)

### Step 4: Identify Problems
Critical issues blocking merge: bugs, incorrect logic, failing tests, missing required features.

### Step 5: Evaluate Code Quality
Non-blocking improvements: readability, naming, organization, complexity.

### Step 6: Check Project Compliance
Verify against project standards:
- Backend: Ruff lint passes, Mypy type check passes, pytest passes
- Frontend: SwiftFormat passes, Xcode build succeeds, tests pass
- No linter bypass comments (`# noqa`, `# type: ignore`, `// swiftlint:disable`)
- Conventional commits used
- View files <= 200 lines (frontend guideline)
- Protocol-based ViewModels for testability (frontend guideline)

### Step 7: Assess Testing
- Test coverage adequate?
- Edge cases covered?
- Swift Testing (`@Test`) used for new frontend tests?
- pytest used for backend tests?

### Step 8: Review Documentation
- Code comments where logic isn't self-evident?
- CLAUDE.md updated if commands/architecture changed?

### Step 9: List Requests
Medium-priority suggestions that would improve the PR.

### Step 10: Deliver Verdict
- **LGTM** - Ready to merge
- **CHANGES_REQUESTED** - Must fix blocking issues
- **COMMENTS** - Suggestions only, can merge as-is

Include reasoning with specific file:line references.

## Examples

### Example 1: Approval with Suggestions

```markdown
## Summary
Adds glass effect modifier with backward compatibility for watchOS < 26.

## Strengths
- Clean `if #available` pattern for version checking
- Good test coverage with Swift Testing framework
- Follows design system token conventions

## Verdict: LGTM
Well-structured PR. Suggestions are non-blocking.
```

### Example 2: Changes Requested

```markdown
## Summary
Adds new journal entry view with inline editing.

## Problems
- View file is 340 lines (guideline: <= 200)
- ViewModel uses concrete types instead of protocols

## Verdict: CHANGES_REQUESTED
Extract sub-views and add protocol conformance for testability.
```

## Troubleshooting

### Error: PR is too large to review effectively
- Ask the author to split into smaller PRs
- Focus on the most critical files first
- Use `gh pr diff --name-only` to prioritize which files to review
