# SPEC — Journal Logging Pipeline (rebuild)

**Status:** Draft for review
**Author:** Claude (with Geoff)
**Date:** 2026-06-01
**Supersedes the B2 theory in:** `spec-primary-selector-rebuild.md` §2 (and the
`PresentationCoordinator`/`RootPresentationHost` work done for #406/#407, insofar
as it was justified as the B2 fix).
**Related:** #186 (offline queue — unchanged), #292 (Liquid Glass rebuild)

---

## 0. Why this spec exists

We have "fixed" the journal-logging bug several times and it is still broken.
Every prior attempt jumped from a *plausible* root cause straight to a refactor
without first **instrumenting the running app to confirm where the deferral
actually happens.** This spec's non-negotiable rule: **Phase 0 (instrument &
confirm) must complete and its findings must be recorded here before any fix
code is written.** If the confirmed mechanism contradicts this spec's
hypothesis, we update the spec — we do not code around it.

The user is open to rebuilding the logging subsystem from scratch. That is on
the table.

---

## 1. Problem statement

**User words:** "The logging doesn't occur until you hit the back button to leave
the screen where the emotions are listed. It must be awaiting behind something
it shouldn't be."

**Confirmed observations (sim, 2026-06-01, built from working tree):**
- Happens on **both** normal colored layers (`CurriculumCard`) **and** the Clear
  Light "All Emotions" screen (`ClearLightEmotionCard`).
- The "Would you like to log …?" confirmation dialog **appears immediately** on
  tap. The defect is that the **entry is not logged** until the user backs out.

**What that rules out:** the bug is **not** "the confirmation alert is deferred
behind a navigation push" (the old B2 theory). The first confirmation presents
fine. The **save** — or more precisely, *the path that reaches the save* — is
what is deferred.

---

## 2. What we know vs. what we assume

| Fact | Status | Evidence |
|------|--------|----------|
| The local SQLite write happens *before* any network await, and cloud sync is opt-in (off by default). So once `await viewModel.journal(...)` runs, the row is persisted essentially immediately. | **Known** | `JournalClient.persistAndSync` saves at `:212` then `guard syncSettings.cloudSyncEnabled else { return }` at `:214`; `journalThrowing` `ContentViewModel.swift:151`. |
| The first confirmation ("Would you like to log X?") presents immediately. | **Known** | User-observed. |
| Tapping an emotion from `idle` does **not** call `journal()` directly — it *starts a multi-step flow*. | **Known** | `LogConfirmationHandler.perform` idle branch calls `startPrimarySelection()` + `capturePrimary()`, not `journal()` (`LogConfirmation.swift:60-63`). |
| A single emotion log therefore requires a **second** confirmation (`FlowConfirmationAlertsModifier` "Primary emotion selected" → **Done**), and the save runs only on that `Done`. | **Known** | `FlowConfirmationAlertsModifier.swift:27` `Done` → `onPrimarySubmit` → `FlowSubmissionPresenter.submit` → `FlowCoordinator.submit` → `journalThrowing`. |
| The exact runtime ordering of the alert hand-off vs. the navigation pop vs. the `layerFilterMode` rebuild. | **ASSUMED** (hypothesis below) | Needs Phase 0 instrumentation. |

---

## 3. Failed hypotheses (and why they didn't hold)

1. **"Leaf `.alert` inside a pushed destination is deferred behind navigation"
   (the spec B2 theory).** Drove the `PresentationCoordinator` + `RootPresentationHost`
   rebuild and the per-card migrations. **Disproven:** the confirmation now
   *does* present immediately, yet logging still defers — and it defers even on
   `CurriculumCard`, which is fully on the root host. Presentation was never the
   blocked layer.
2. **"`ClearLightEmotionCard` was the one un-migrated leaf" (this session's PR
   #422).** Migrating it changed nothing user-visible because the deferral isn't
   in the leaf-vs-root presentation distinction at all. (PR #422 should be held
   / not merged as a B2 fix — see §9.)
3. **"Fire-and-forget `Task` in the leaf gets cancelled on view teardown."**
   Plausible-sounding, but the direct-log `Task` is created at the root host now,
   and idle taps don't even hit that path. Not the mechanism for the observed
   repro.

The through-line: each fix targeted *presentation plumbing*; the defect lives in
the **flow-to-save control path**.

---

## 4. First-principles diagnosis (hypothesis to confirm in Phase 0)

### 4.1 There are two confirmation systems for one action

Tapping an emotion now triggers **two** independent confirmation surfaces in
series:

1. `PresentationCoordinator.logConfirmation` — "Would you like to log X?" (added
   by #406), rendered by `RootPresentationHost`.
2. `FlowCoordinator` confirmation steps — "Primary emotion selected" /
   "Secondary…" / "Strategy…" (`FlowConfirmationAlertsModifier`), rendered on the
   main content.

The save is behind surface **2** (`Done`). Surface **1**'s "Yes" doesn't save;
it *starts the flow that eventually shows surface 2*.

### 4.2 The hand-off from surface 1 → surface 2 races navigation + filtering

On surface-1 "Yes" (`RootPresentationHost.swift:49-53`):
`Task { await handler.perform(action) }` →
- `flowCoordinator.startPrimarySelection()` sets `currentStep = .selectingPrimary`
  **and** `contentViewModel.layerFilterMode = .emotionsOnly`, then
- `capturePrimary(entry)` sets `currentStep = .confirmingPrimary`.

These `currentStep` mutations are observed by **multiple** modifiers at once:
- `MainContentDialogsModifier.onChange(currentStep)` → `popNavigationPath` (pops
  the NavigationStack to root for `.selecting*`/`.idle`; `:45-47`, `:90-99`).
- `RootPresentationHost.bridges.onChange(currentStep)` → flow-review routing
  (`:89-95`).
- `FlowConfirmationAlertsModifier` presenters → want to show surface 2 for
  `.confirmingPrimary` (`:20`).

So in one synchronous burst we: dismiss surface 1, mutate `layerFilterMode`
(triggering a filtered re-render of the whole layer list), potentially pop the
navigation stack, and request surface 2. **Hypothesis:** watchOS, serializing
presentations per scene, defers surface 2 behind the still-settling
dismiss/navigation/rebuild transaction. The user perceives "nothing happened,"
backs out, the transaction settles, surface 2 flushes, they hit `Done`, and only
*then* does the save run — i.e. "it logs when I back out."

### 4.3 The deeper design flaw

The act of **logging one emotion** is entangled with: a guided multi-step state
machine, a layer-filter mode change, a navigation-stack pop, and two separate
presentation owners. Persistence is the *last* link in a fragile UI chain
instead of a direct consequence of the user's confirmed intent. No amount of
re-plumbing the presentation layer fixes a *control-flow* problem.

---

## 5. Phase 0 — Instrument & confirm (MANDATORY, before any fix)

Add lightweight `os_log`/`Logger` (category `journal.flow`) signposts — temporary,
removed before merge — at each boundary, then reproduce the exact failing repro
on the sim and paste the ordered log + a screen recording into §5.1:

- `CurriculumCard` / `ClearLightEmotionCard` tap → `request(logConfirmation)`.
- `RootPresentationHost` "Yes" button entered; `Task` started; `handler.perform`
  entered + which branch.
- `FlowCoordinator`: every `currentStep` set (old → new), every `layerFilterMode`
  set.
- `MainContentDialogsModifier.popNavigationPath` entered + whether it pops.
- `FlowConfirmationAlertsModifier.presenter(.confirmingPrimary)` get → true/false
  over time (when does the binding actually read true and the alert appear?).
- `FlowSubmissionPresenter.submit` entered; `FlowCoordinator.submit` entered;
  `journalThrowing` entered; `repository.save` entered/returned (timestamp).
- Back-out action (which one: nav pop vs. toolbar `cancel()`).

**Exit criteria for Phase 0:** we can state, with timestamps, the precise step at
which the chain stalls and the precise action that unblocks it. Record findings
in §5.1 and confirm/deny the §4.2 hypothesis.

### 5.1 Findings (to be filled in)

> _TBD — populated during Phase 0._

---

## 6. Proposed architecture (rebuild)

Design conditioned on Phase 0 confirming a §4.2-class mechanism. Two coherent
modes, one persistence path:

### 6.1 Separate "quick log" from "guided flow"

- **Quick log (default for a single tap):** tapping an emotion → one confirmation
  → **write to SQLite immediately** in the confirm action → show feedback. No
  flow state machine, no `layerFilterMode` change, no navigation pop. This is the
  path that must be bulletproof; it is what the user means by "log a dosage."
- **Guided flow (explicit, opt-in):** the existing primary→secondary→strategy→
  review journey, entered deliberately (e.g. a "Log a sequence" affordance), not
  auto-started by every single tap.

### 6.2 Persistence is decoupled from UI transitions

- A single `logEntry(...)` command persists synchronously-as-possible and returns
  a result; **it never depends on navigation or presentation state.**
- UI feedback (success/queued/failure) is rendered *after* the write from the
  command's result — not used as the trigger for the write.
- No save is ever gated behind a second presentation that is requested in the
  same transaction as a dismiss/pop/filter change.

### 6.3 One owner for "what is on screen"

- Collapse the competing `currentStep` observers. Exactly one component decides
  navigation pops; exactly one decides which alert/sheet is visible. (This is the
  *correct* role for a presentation coordinator — but driven off an explicit
  flow command result, not a web of `onChange` side-effects.)

### 6.4 Consider deleting, not patching

Given the entanglement, a from-scratch rebuild of the logging path (leaf intent →
command → persistence → feedback) is likely cleaner than untangling the current
`FlowCoordinator` + `FlowSubmissionPresenter` + two-alert-system + `popNavigationPath`
mesh. Models/Services/backend (`JournalClient`, `JournalRepository`,
`JournalDatabase`, queue) are sound and stay; only the ViewModel-flow and view
plumbing are rebuilt.

---

## 7. Acceptance criteria

- [ ] **Phase 0 findings recorded** in §5.1 and the mechanism confirmed before any
      fix lands.
- [ ] Logging a single emotion (quick log) persists the SQLite row **within the
      confirm action**, with **no** navigation action required — verified by an
      automated assertion at the command seam *and* by on-device QA on both a
      normal layer and Clear Light.
- [ ] Success/queued/failure feedback appears for that same action, immediately,
      without backing out.
- [ ] Same correctness for strategy logging.
- [ ] The guided multi-step flow (if retained) still works and also never gates
      the write behind a deferred presentation.
- [ ] No regression to the offline queue (#186) or sync status reporting.
- [ ] Temporary Phase 0 instrumentation removed before merge.

---

## 8. Test plan

- **Command/seam unit tests:** "confirming a log writes exactly one row to the
  repository synchronously, independent of any flow/nav state" (use
  `InMemoryJournalRepository` / `JournalClientMock`, as in `LogConfirmationTests`).
- **State-machine tests:** quick-log path never sets `layerFilterMode` and never
  enters `.selecting*`.
- **Regression guards:** keep `LogConfirmationTests`, `PresentationPolicyTests`,
  `ContentViewFlowIntegrationTests`, flow tests green.
- **Manual QA matrix:** quick log from normal layer; quick log from Clear Light;
  strategy log; airplane mode (queued path); guided flow end-to-end. For each:
  confirm the row exists (and feedback shows) *without* backing out.

---

## 9. Phased delivery (proposed sub-issues)

1. **Phase 0 — Instrumentation & confirmation.** Land temporary signposts, capture
   the failing repro, record §5.1, confirm/deny §4.2. *Gate for everything else.*
2. **Phase 1 — Quick-log command.** Introduce a direct `logEntry` command that
   persists immediately + returns a result; wire `CurriculumCard` /
   `ClearLightEmotionCard` / `StrategyCard` taps to it; feedback from the result.
3. **Phase 2 — De-entangle the flow.** Stop auto-starting the guided flow on every
   tap; make it explicit. Collapse the multiple `currentStep` observers to one
   owner. Ensure no save is gated behind a deferred presentation.
4. **Phase 3 — Cleanup.** Remove now-dead plumbing (duplicate confirmation
   system, redundant `popNavigationPath` side-effects), remove instrumentation,
   update tests/docs.

**Holdover:** PR #422's `ClearLightEmotionCard` migration was justified as a B2
fix and is now known not to fix B2. Recommend **not merging it as such**; either
close it or fold its (harmless, consistency-only) card change into Phase 1.

---

## 10. Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Phase 0 reveals a different mechanism than §4.2. | That's the point — update the spec, then design the fix to the *confirmed* cause. |
| Splitting quick-log vs. guided flow changes UX expectations. | Get Geoff's sign-off on the two-mode model before Phase 1; keep guided flow reachable. |
| Touching `FlowCoordinator` regresses fixed nav bugs (#157/#162/#164). | Keep regression tests; the single-owner navigation rule should make those *more* robust, not less. |
| Scope creep into Services. | Hard boundary: Services/Models/backend frozen; only ViewModel-flow + views change. |

---

## 11. Out of scope
- Backend, Models, `JournalClient`/`Repository`/`Database`/queue internals.
- Analytics (#187).
- The scroll-affordance / selector-visual work (separate spec).
