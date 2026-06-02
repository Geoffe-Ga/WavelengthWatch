## Role

You are a senior watchOS/SwiftUI engineer working in this repo's
`frontend/WavelengthWatch` target, comfortable with SwiftUI presentation/
navigation internals and `os.Logger` signposting. You can drive the watch
simulator and read its console.

## Goal

Produce a confirmed, timestamped account of **exactly where the journal save is
deferred** when a user logs an emotion, and record it in
`SPEC_journal_logging_pipeline.md` §5.1 — confirming or refuting the §4.2
hypothesis. No production behavior changes ship in this issue.

## Context

- **Parent epic:** #424
- **Predecessor issue(s):** none — this is the Phase 0 (skeleton/diagnostic) gate.
- **SPEC section:** `prompts/claude-comm/SPEC_journal_logging_pipeline.md` §5
  (Phase 0) and §4 (hypothesis).
- **Files involved (instrument with temporary `Logger(subsystem:…, category: "journal.flow")` signposts — removed before merge):**
  - `Views/Curriculum/CurriculumCard.swift`, `ClearLightEmotionCard.swift`,
    `StrategyCard.swift`, `StrategyListView.swift` — tap → `request(...)`.
  - `Views/Navigation/RootPresentationHost.swift` — "Yes" button, `Task` start,
    `handler.perform` branch.
  - `ViewModels/LogConfirmation.swift` — `LogConfirmationHandler.perform` branch taken.
  - `ViewModels/FlowCoordinator.swift` — every `currentStep` set (old→new),
    every `layerFilterMode` set.
  - `Views/Navigation/MainContentDialogsModifier.swift` — `popNavigationPath` entry + whether it pops.
  - `Views/Journal/FlowConfirmationAlertsModifier.swift` — `presenter(.confirmingPrimary)` get transitions.
  - `ViewModels/FlowSubmissionPresenter.swift`, `ContentViewModel.journalThrowing`,
    `Services/JournalClient.persistAndSync`, `JournalRepository.save` — entry/return timestamps.
- **State of the world:** the confirmation alert presents immediately; the entry
  is not observed as logged until the user backs out. Cloud sync is opt-in (off
  by default), so `repository.save` is local + effectively immediate once reached.

## Output Format

Deliverable is a single PR containing:

- [ ] Temporary `os.Logger` signposts at the boundaries above (clearly marked
      `// PHASE0-INSTRUMENTATION — remove before EPIC_01 closes`).
- [ ] `SPEC_journal_logging_pipeline.md` §5.1 filled in with: the ordered,
      timestamped log of the failing repro; a screen recording or step list; the
      precise step where the chain stalls; the precise action that unblocks it;
      and an explicit confirm/refute of the §4.2 hypothesis.
- [ ] If §4.2 is refuted, a short "corrected mechanism" subsection in §5.1 and a
      note on `EPIC_01_ISSUE_02..04` that they must be re-planned.
- [ ] No production behavior change; no new user-facing strings.

## Examples

**Example: the kind of ordered evidence §5.1 must contain**
```
T+0.000  CurriculumCard.tap → request(.logConfirmation)
T+0.010  RootPresentationHost: logConfirmation alert presented
T+1.2    user taps "Yes" → Task started → handler.perform(.curriculum) [idle branch]
T+1.2    FlowCoordinator.currentStep idle→selectingPrimary; layerFilterMode→emotionsOnly
T+1.2    MainContentDialogsModifier.popNavigationPath: POP (path emptied)
T+1.2    FlowCoordinator.currentStep selectingPrimary→confirmingPrimary
T+1.2    FlowConfirmationAlertsModifier.presenter(.confirmingPrimary)=true  ← requested
T+?      (no alert visible)  ← STALL
T+5.0    user navigates back → presenter alert finally appears → "Done" → submit → repository.save
```
The exit artifact names the stall row and the unblock row explicitly.

## Constraints

**Scope fence:** Do **not** implement any fix (no quick-log command, no flow
de-entangling) — that is ISSUE_02/03. This issue only observes and documents. If
you find yourself changing control flow, stop.

**Anti-bypass (verbatim, non-negotiable):**

> No `swiftlint:disable`, `swiftformat:disable`, `noqa`, `# type: ignore`,
> `pylint: disable`, `eslint-disable`, or equivalent linter/formatter/type-checker
> silencers. Fix the root cause. The only exception is the documented 4-line
> escape hatch (third-party library bug / language-version compatibility /
> benchmarked performance necessity / generated code) — and it must include the
> reason, a reference URL, an alternative considered, and a review date. See the
> `max-quality-no-shortcuts` skill.

**Tracer-code invariant:** The app remains fully demoable — instrumentation is
additive logging only.

## Definition of Done (stay-green)

- [ ] Full frontend suite passes (`frontend/WavelengthWatch/run-tests-individually.sh`).
- [ ] `pre-commit run --all-files` is clean — no skipped or bypassed hooks.
- [ ] Logic seams unchanged, so no new tests required; existing tests stay green
      (project view-test philosophy — no ViewInspector/XCUITest).
- [ ] `SPEC_journal_logging_pipeline.md` §5.1 is filled and the hypothesis
      confirmed/refuted.
- [ ] PR body uses the repo PR template and includes `Refs #424` and
      `Closes #426`.
- [ ] If the Claude reviewer Action runs: latest `Verdict:` on HEAD is `LGTM`.

## Labels

`spec-decomposition`, `tracer-skeleton`, `journal`
