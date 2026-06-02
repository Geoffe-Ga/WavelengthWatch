# SPEC Decomposition Batch — Journal Logging + Scroll Affordance/Visibility

**Date:** 2026-06-01
**Source specs:**
- `prompts/claude-comm/SPEC_journal_logging_pipeline.md`
- `prompts/claude-comm/SPEC_scroll_affordance_and_selector_visibility.md`
**Related issue:** #423 (chevron/indicator overlap — closed by EPIC_02_ISSUE_03)
**Supersedes:** the never-filed flat decomposition in `git-issues/EPIC_0{1..4}_*`
(from the superseded `spec-primary-selector-rebuild.md`).

## Why these specs exist

Three user-reported defects on the watch selector survived several refactors:
chevrons that don't read, a too-bright colored card, and journal logging that
"doesn't happen until you hit back." Manual sim testing on 2026-06-01 disproved
the prevailing theories — most importantly, **logging is a save-path deferral,
not a presentation deferral** (the confirmation appears immediately). Each spec
therefore opens with a **mandatory Phase 0 "instrument/audit and confirm the
mechanism" gate** before any fix code.

## Epics

| # | Epic | Outcome | Source spec |
|---|------|---------|-------------|
| EPIC_01 | Journal Logging Pipeline | Logging one emotion persists immediately, with feedback, no back-out required — on both normal layers and Clear Light. | `SPEC_journal_logging_pipeline.md` |
| EPIC_02 | Scroll Affordance & Selector Visibility | Directional chevrons are instantly legible at rest on both axes, don't overlap the indicators, and the colored card reads as calm translucent glass. | `SPEC_scroll_affordance_and_selector_visibility.md` |

## Cross-epic sequencing

- **Parallel-safe.** The two epics touch different subsystems (journal flow/VM
  vs. selector views). They can proceed concurrently.
- **Within each epic, ISSUE_01 (Phase 0) is a hard gate.** ISSUE_02+ are
  **provisional**: their design is conditioned on the Phase 0 findings recorded
  in the spec's §5.1 and must be reconciled with those findings before work
  starts. If Phase 0 contradicts the hypothesis, update the spec, then re-plan
  ISSUE_02+ (do not implement the provisional design verbatim).

## Issue inventory

**EPIC_01 — Journal Logging Pipeline**
1. ISSUE_01 — Phase 0: instrument the tap→persist path; confirm where the save is deferred. *(gate)*
2. ISSUE_02 — Quick-log command: persist immediately on confirm, decoupled from UI flow. *(provisional)*
3. ISSUE_03 — De-entangle the guided flow; single owner for navigation/presentation. *(provisional)*
4. ISSUE_04 — Cleanup: remove duplicate confirmation system + instrumentation; docs/tests. *(provisional)*

**EPIC_02 — Scroll Affordance & Selector Visibility**
1. ISSUE_01 — Phase 0: visual-audit harness; attribute chevron legibility + card brightness to specific levers. *(gate)*
2. ISSUE_02 — Chevron legibility rebuild: signal-independent, right-sized, contrast-backed. *(provisional)*
3. ISSUE_03 — Affordance consolidation: remove/fold redundant indicators, reposition chevrons (closes #423). *(provisional)*
4. ISSUE_04 — Card glass calm-down: holistic brightness/translucency pass. *(provisional)*

## Recommended starting point

`EPIC_01_ISSUE_01` (journal-logging Phase 0) — highest user-value defect
(data-logging) and the gate that unblocks the rest of EPIC_01.
