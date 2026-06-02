> **PROVISIONAL — reconcile with `SPEC_journal_logging_pipeline.md` §5.1 (Phase 0
> findings) before starting.** Implement against the *confirmed* mechanism.

## Role

You are a senior watchOS/SwiftUI engineer with strong command of SwiftUI state
propagation (`@Published` / `onChange` coalescing), navigation, and presentation
ordering in this repo's `frontend/WavelengthWatch` target.

## Goal

Make the guided multi-step flow explicit (not auto-started by every tap) and give
navigation + presentation a **single owner**, so no journal write is ever gated
behind a presentation requested in the same transaction as a dismiss/pop/filter
change.

## Context

- **Parent epic:** #424
- **Predecessor issue(s):** EPIC_01_ISSUE_02 (quick-log) merged first.
- **SPEC section:** `SPEC_journal_logging_pipeline.md` §4.1–§4.3, §6.3.
- **Files involved:**
  - `ViewModels/FlowCoordinator.swift` — flow state machine; entry points.
  - `Views/Navigation/MainContentDialogsModifier.swift` — `onChange(currentStep)`
    → `popNavigationPath` (one of the competing observers).
  - `Views/Navigation/RootPresentationHost.swift` — `bridges.onChange(currentStep)`
    (the other observer) + the presentation host.
  - `Views/Journal/FlowConfirmationAlertsModifier.swift` — the flow's own
    confirmation alerts (the "second" confirmation system).
  - `ViewModels/PresentationCoordinator.swift` — candidate single owner for
    "what is on screen."
- **Prior decisions:** the existing `popNavigationPath` semantics fix #157/#162/#164
  — preserve that behavior under the single-owner model. Keep `FlowCoordinator`'s
  "pure state, no UI" boundary.
- **State of the world:** two `currentStep` observers + two confirmation systems
  race on watchOS's single-presentation-per-scene constraint.

## Output Format

Deliverable is a single PR containing:

- [ ] The guided flow entered via an explicit affordance, not auto-started on a
      single emotion tap.
- [ ] Exactly one component deciding navigation pops, and one deciding the visible
      alert/sheet (collapse the duplicate `currentStep` side-effects).
- [ ] A guarantee (test + code structure) that the flow's submit/write is never
      requested in the same transaction as a navigation pop / filter change.
- [ ] Tests: flow-step transitions don't double-drive navigation; quick-log path
      from ISSUE_02 still never enters `.selecting*`.
- [ ] Regression guards for #157/#162/#164 navigation behavior remain green.

## Examples

**Example: state-machine assertion that should pass**
```swift
@Test("a single emotion tap never auto-enters the guided flow")
func singleTap_doesNotAutoStartFlow() async {
  let (vm, flow, _, catalog) = await setup()
  let entry = catalog.layers[1].phases[0].medicinal[0]
  let handler = LogConfirmationHandler(flowCoordinator: flow, viewModel: vm)
  await handler.perform(.curriculum(entry: entry))
  #expect(flow.currentStep == .idle)   // quick-log, not selectingPrimary
}
```

## Constraints

**Scope fence:** Do not delete the duplicate confirmation system or remove
instrumentation yet — that is ISSUE_04. Do not modify Services/Models. Preserve
the offline-queue behavior (#186).

**Anti-bypass (verbatim, non-negotiable):**

> No `swiftlint:disable`, `swiftformat:disable`, `noqa`, `# type: ignore`,
> `pylint: disable`, `eslint-disable`, or equivalent linter/formatter/type-checker
> silencers. Fix the root cause. The only exception is the documented 4-line
> escape hatch (third-party library bug / language-version compatibility /
> benchmarked performance necessity / generated code) — and it must include the
> reason, a reference URL, an alternative considered, and a review date. See the
> `max-quality-no-shortcuts` skill.

**Tracer-code invariant:** Quick-log and guided flow both work after this PR;
navigation pop fixes (#157/#162/#164) preserved.

## Definition of Done (stay-green)

- [ ] Full frontend suite passes (`frontend/WavelengthWatch/run-tests-individually.sh`).
- [ ] `pre-commit run --all-files` clean.
- [ ] New + regression logic seams covered (no ViewInspector/XCUITest).
- [ ] On-device QA: guided flow end-to-end logs without back-out; nav-pop bugs
      do not regress.
- [ ] PR body: `Refs #424`, `Closes #428`.
- [ ] If the Claude reviewer Action runs: latest `Verdict:` on HEAD is `LGTM`.

## Labels

`spec-decomposition`, `core`, `journal`
