> **PROVISIONAL — reconcile with `SPEC_journal_logging_pipeline.md` §5.1 and the
> shape that ISSUE_02/03 actually landed before starting.**

## Role

You are a senior watchOS/SwiftUI engineer doing a disciplined cleanup pass in
this repo's `frontend/WavelengthWatch` target — removing dead code and temporary
instrumentation without changing behavior.

## Goal

Remove the now-redundant duplicate confirmation plumbing and the Phase 0
instrumentation, leaving a single coherent logging path, and update tests/docs to
match the landed design.

## Context

- **Parent epic:** #424
- **Predecessor issue(s):** EPIC_01_ISSUE_02 and ISSUE_03 merged first.
- **SPEC section:** `SPEC_journal_logging_pipeline.md` §9 (Phase 3).
- **Files involved (final set depends on ISSUE_02/03):**
  - The Phase 0 `// PHASE0-INSTRUMENTATION` signposts (all of them) — delete.
  - Whichever confirmation surface became redundant after ISSUE_02/03 (e.g. a
    duplicate "Would you like to log?" vs. the flow's own confirmation).
  - Any `popNavigationPath` side-effects superseded by the single-owner model.
  - `prompts/claude-comm/SPEC_journal_logging_pipeline.md` — mark resolved
    sections and link the landed PRs.
- **State of the world:** logging works (ISSUE_02/03); some transitional scaffolding remains.

## Output Format

Deliverable is a single PR containing:

- [ ] All Phase 0 instrumentation removed (grep for `PHASE0-INSTRUMENTATION`
      returns nothing).
- [ ] Redundant confirmation/observer code deleted; one logging path remains.
- [ ] Tests updated/trimmed to the final design; no test commented out or skipped.
- [ ] SPEC updated to "resolved" with links to the landed PRs.
- [ ] No behavior change vs. the end of ISSUE_03 (pure cleanup).

## Examples

**Example: the grep gate that must pass**
```
$ grep -rn "PHASE0-INSTRUMENTATION" "frontend/WavelengthWatch"
(no matches)
```

## Constraints

**Scope fence:** No new features and no behavior changes — if a deletion changes
behavior, it belongs in ISSUE_03, not here. Do not touch Services/Models.

**Anti-bypass (verbatim, non-negotiable):**

> No `swiftlint:disable`, `swiftformat:disable`, `noqa`, `# type: ignore`,
> `pylint: disable`, `eslint-disable`, or equivalent linter/formatter/type-checker
> silencers. Fix the root cause. The only exception is the documented 4-line
> escape hatch (third-party library bug / language-version compatibility /
> benchmarked performance necessity / generated code) — and it must include the
> reason, a reference URL, an alternative considered, and a review date. See the
> `max-quality-no-shortcuts` skill.

**Tracer-code invariant:** App fully demoable; logging path unchanged in behavior.

## Definition of Done (stay-green)

- [ ] Full frontend suite passes (`frontend/WavelengthWatch/run-tests-individually.sh`).
- [ ] `pre-commit run --all-files` clean.
- [ ] No skipped/commented tests; logic seams still covered.
- [ ] `grep PHASE0-INSTRUMENTATION` is empty.
- [ ] PR body: `Refs #424`, `Closes #429`.
- [ ] If the Claude reviewer Action runs: latest `Verdict:` on HEAD is `LGTM`.

## Labels

`spec-decomposition`, `polish`, `journal`
