> **PROVISIONAL — reconcile with `SPEC_journal_logging_pipeline.md` §5.1 (Phase 0
> findings) before starting.** If Phase 0 refuted the §4.2 hypothesis, re-plan
> this issue against the corrected mechanism rather than implementing the design
> below verbatim.

## Role

You are a senior watchOS/SwiftUI engineer working in this repo's
`frontend/WavelengthWatch` target, fluent in `@MainActor` async flow and the
`ContentViewModel` / `JournalClient` seam.

## Goal

Introduce a direct **quick-log command** so that confirming a single emotion
writes exactly one `LocalJournalEntry` to SQLite **synchronously within the
confirm action**, independent of navigation/presentation state, and renders
feedback from the command's result.

## Context

- **Parent epic:** #424
- **Predecessor issue(s):** EPIC_01_ISSUE_01 (Phase 0) — must be merged and its
  §5.1 findings reconciled with this design first.
- **SPEC section:** `SPEC_journal_logging_pipeline.md` §6.1, §6.2.
- **Files involved:**
  - `ViewModels/LogConfirmation.swift` — `LogConfirmationHandler.perform`; today
    its `idle` branch starts the guided flow instead of logging.
  - `ViewModels/ContentViewModel.swift` — `journal` / `journalThrowing` (the
    persistence entry point; keep its public contract).
  - `Views/Navigation/RootPresentationHost.swift` — the "Yes" action.
  - Leaf cards already emit `.logConfirmation` intents (no change needed there).
- **Prior decisions:** Models/Services/backend are frozen; persistence already is
  local-first + opt-in sync. The defect is *reaching* the save, not the save.
- **State of the world:** a single tap from `idle` enters a multi-step flow; the
  write happens only at flow submit.

## Output Format

Deliverable is a single PR containing:

- [ ] A quick-log command/path that persists immediately on confirm (a `idle`
      curriculum confirmation logs directly via `journalThrowing`, not via
      `startPrimarySelection`).
- [ ] Feedback (success/queued/failure) rendered from the command result for that
      same action, without backing out.
- [ ] Tests at the command seam (use `InMemoryJournalRepository` / `JournalClientMock`,
      as in `LogConfirmationTests`) proving: one confirm → exactly one persisted
      row; no `layerFilterMode` change; no `.selecting*` transition.
- [ ] No drive-by changes to Services/Models.

## Examples

**Example: test that should pass after this issue lands**
```swift
@Test("confirming a curriculum log from idle persists one row immediately")
func quickLog_fromIdle_persistsImmediately() async {
  let (vm, flow, client, catalog) = await setup()           // as in LogConfirmationTests
  let entry = catalog.layers[1].phases[0].medicinal[0]
  let handler = LogConfirmationHandler(flowCoordinator: flow, viewModel: vm)

  await handler.perform(.curriculum(entry: entry))

  #expect(client.submissions.count == 1)                    // saved now, not later
  #expect(flow.currentStep == .idle)                        // did NOT enter the flow
  #expect(vm.layerFilterMode == .all)                       // no filter side-effect
}
```

## Constraints

**Scope fence:** Do not collapse the multiple `currentStep` observers or remove
the guided flow — that is ISSUE_03. Do not touch `JournalClient`/`Repository`/
`Database`. Keep the guided flow reachable (it's de-entangled, not deleted, in
ISSUE_03).

**Anti-bypass (verbatim, non-negotiable):**

> No `swiftlint:disable`, `swiftformat:disable`, `noqa`, `# type: ignore`,
> `pylint: disable`, `eslint-disable`, or equivalent linter/formatter/type-checker
> silencers. Fix the root cause. The only exception is the documented 4-line
> escape hatch (third-party library bug / language-version compatibility /
> benchmarked performance necessity / generated code) — and it must include the
> reason, a reference URL, an alternative considered, and a review date. See the
> `max-quality-no-shortcuts` skill.

**Tracer-code invariant:** After this PR, both quick-log and the (still-present)
guided flow work; the app is demoable.

## Definition of Done (stay-green)

- [ ] Full frontend suite passes (`frontend/WavelengthWatch/run-tests-individually.sh`).
- [ ] `pre-commit run --all-files` clean.
- [ ] New command seam covered by tests (project view-test philosophy: logic in
      VM/handler, no ViewInspector/XCUITest).
- [ ] On-device QA: log from a normal layer AND Clear Light; row exists and
      feedback shows **without** backing out.
- [ ] PR body: `Refs #424`, `Closes #427`.
- [ ] If the Claude reviewer Action runs: latest `Verdict:` on HEAD is `LGTM`.

## Labels

`spec-decomposition`, `core`, `journal`
