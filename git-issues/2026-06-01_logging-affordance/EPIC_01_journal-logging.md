## Epic Summary

Rebuild the journal-logging control path so confirming a log **persists the
entry immediately** and shows feedback, without requiring the user to back out
of the screen. Manual testing (2026-06-01) confirmed the confirmation dialog
already presents immediately on both normal layers and Clear Light — so this is
a **save-path / control-flow** problem, not a presentation problem. See
`prompts/claude-comm/SPEC_journal_logging_pipeline.md` §1–§4.

## Scope

**In scope:**
- The path from a leaf tap (`CurriculumCard` / `ClearLightEmotionCard` /
  `StrategyCard` / `StrategyListView`) through confirmation to a persisted
  `LocalJournalEntry`.
- `LogConfirmationHandler`, `FlowCoordinator`, `FlowSubmissionPresenter`, the
  `currentStep` observers (`MainContentDialogsModifier.popNavigationPath`,
  `RootPresentationHost.bridges`), and the two confirmation systems.
- Decoupling persistence from navigation/presentation transitions.

**Out of scope:**
- `JournalClient` / `JournalRepository` / `JournalDatabase` / queue internals
  (the local-first save + opt-in sync are sound — frozen).
- Scroll affordance / selector visuals (EPIC_02).
- Analytics (#187).

## Success Criteria

The epic is done when:

- [ ] Phase 0 findings are recorded in `SPEC_journal_logging_pipeline.md` §5.1 and
      the deferral mechanism is confirmed.
- [ ] Logging a single emotion (quick log) writes exactly one SQLite row **within
      the confirm action**, with **no navigation action required**, verified by a
      test at the command seam and by on-device QA on a normal layer AND Clear Light.
- [ ] Success/queued/failure feedback appears for that same action immediately.
- [ ] Strategy logging has the same correctness.
- [ ] The guided multi-step flow (if retained) never gates the write behind a
      deferred presentation.
- [ ] No regression to the offline queue (#186) or sync-status reporting.
- [ ] All child issues are closed; full frontend test suite green on `main`.

## Child Issues

_Filled in after child issues are filed (Step 8/9 of spec-decomposition)._

- [ ] #426 — Phase 0: instrument tap→persist, confirm the deferral
- [ ] #427 — Quick-log command (persist on confirm, decoupled)
- [ ] #428 — De-entangle the guided flow (single nav/presentation owner)
- [ ] #429 — Cleanup: remove duplicate confirmation + instrumentation

## Sequencing Notes

- **Blocks:** ISSUE_01 (Phase 0) blocks ISSUE_02–04 — their provisional designs
  must be reconciled with the §5.1 findings before implementation.
- **Parallel-safe** with EPIC_02 (different subsystem).
- **Unblocks:** a reliable logging path is a prerequisite for any future
  analytics work that depends on entries actually being written.

## SPEC Reference

`prompts/claude-comm/SPEC_journal_logging_pipeline.md` (full document; esp. §4
diagnosis, §5 Phase 0, §6 proposed architecture, §9 phased delivery).

## Labels

`epic`, `spec-decomposition`, `journal`
