> **PROVISIONAL — reconcile with `SPEC_scroll_affordance_and_selector_visibility.md`
> §5.1 before starting.** Closes #423.

## Role

You are a senior watchOS/SwiftUI engineer working in this repo's
`frontend/WavelengthWatch` target with a layout/composition focus.

## Goal

Eliminate the overlap between the directional chevrons and the position
indicators by completing the spec §4.2 consolidation: remove or fold in the
redundant `LayerSideIndicator` + page dots and position the chevrons over the
card body rather than the screen edges. **Closes #423.**

## Context

- **Parent epic:** #425
- **Predecessor issue(s):** EPIC_02_ISSUE_02 (legibility) merged first.
- **SPEC section:** `SPEC_…visibility.md` §4.4, §6.3; RCA
  `prompts/claude-comm/RCA_chevron_indicator_overlap.md`; issue **#423**.
- **Files involved:**
  - `Views/Navigation/ScrollAffordanceView.swift` — chevron placement (currently
    `.frame(maxWidth/maxHeight: .infinity, alignment:)` → extreme edges).
  - `Views/Navigation/LayerScrollView.swift` — `.overlay(alignment: .trailing)`
    hosting `LayerSideIndicator`.
  - `Views/Navigation/LayerView.swift` — `.overlay(alignment: .bottom)` hosting
    the page dots.
  - `Views/Navigation/LayerSideIndicator.swift` — the position rail (remove/fold).
- **Prior decisions:** §4.2 intended the chevrons to *replace* both indicators;
  the implementation added chevrons but kept the indicators → the overlap.
- **State of the world:** right chevron overlaps the trailing rail; down chevron
  overlaps the bottom dots.

## Output Format

Deliverable is a single PR containing:

- [ ] No overlap between any chevron and any position indicator (the literal #423
      fix), verified on 41mm and 45/49mm screenshots.
- [ ] Either the indicators removed (chevrons carry the signal) or a single
      minimal, non-overlapping rail retained — per §5.1/§6.3.
- [ ] Chevrons repositioned over the card body, not the extreme edges.
- [ ] Construction tests updated for any removed/renamed views; no crash.
- [ ] `#423` referenced with `Closes #423` in the PR.

## Examples

**Example: acceptance check**
```
Before: right chevron sits on top of "layer 3 of 9" rail; down chevron sits on
        the page dots.
After:  chevrons float over the card; rail/dots removed (or relocated) — zero
        pixel overlap at 41mm and 45/49mm.
```

## Constraints

**Scope fence:** Do not re-tune chevron legibility (ISSUE_02) or the card color
layers (ISSUE_04). Keep `ScrollAffordanceModel` edge math and dual-axis nav intact.

**Anti-bypass (verbatim, non-negotiable):**

> No `swiftlint:disable`, `swiftformat:disable`, `noqa`, `# type: ignore`,
> `pylint: disable`, `eslint-disable`, or equivalent linter/formatter/type-checker
> silencers. Fix the root cause. The only exception is the documented 4-line
> escape hatch (third-party library bug / language-version compatibility /
> benchmarked performance necessity / generated code) — and it must include the
> reason, a reference URL, an alternative considered, and a review date. See the
> `max-quality-no-shortcuts` skill.

**Tracer-code invariant:** Navigation + position legibility preserved; app demoable.

## Definition of Done (stay-green)

- [ ] Full frontend suite passes (`frontend/WavelengthWatch/run-tests-individually.sh`).
- [ ] `pre-commit run --all-files` clean.
- [ ] Construction tests for changed views pass; looks QA-verified at 2 sizes.
- [ ] PR body: `Refs #425`, `Closes #432`, `Closes #423`.
- [ ] If the Claude reviewer Action runs: latest `Verdict:` on HEAD is `LGTM`.

## Labels

`spec-decomposition`, `core`, `navigation`
