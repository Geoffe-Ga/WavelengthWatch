> **PROVISIONAL — reconcile with `SPEC_scroll_affordance_and_selector_visibility.md`
> §5.1 (Phase 0 findings) before starting.** Use the lever(s) Phase 0 actually
> confirmed, not the guesses below.

## Role

You are a senior watchOS/SwiftUI engineer with a design eye, working in this
repo's `frontend/WavelengthWatch` target.

## Goal

Make every available-direction chevron **instantly legible at rest on both axes**
— independent of the scroll-phase `isInteracting` signal — over the lightest and
darkest cards, at 41mm and 45/49mm.

## Context

- **Parent epic:** #425
- **Predecessor issue(s):** EPIC_02_ISSUE_01 (Phase 0) merged; §5.1 reconciled.
- **SPEC section:** `SPEC_…visibility.md` §4.1, §4.2, §6.1.
- **Files involved:**
  - `Views/Navigation/ScrollAffordanceView.swift` — chevron mark size/weight,
    backing/material, `chevronOpacity` policy.
  - `ViewModels/ScrollAffordanceModel.swift` — edge math (KEEP; it's correct).
  - `Views/Navigation/LayerScrollView.swift` — where the affordance overlay +
    `onScrollPhaseChange` live (vertical axis is programmatic → signal unreliable).
- **Prior decisions:** absent chevron = edge reached (affordance honesty — keep).
  Vertical nav is programmatic, so legibility must NOT depend on `isInteracting`.
- **State of the world:** chevrons render but read dim at rest; brighten only on
  the native horizontal scroll.

## Output Format

Deliverable is a single PR containing:

- [ ] Signal-independent legibility: a chevron is fully legible whenever its
      direction is available (no dependence on `isInteracting` for legibility).
- [ ] Right-sized mark + contrast backing per Phase 0 (e.g. larger/bolder symbol,
      solid/outlined chip) — exact choice from §5.1.
- [ ] Scroll-emphasis decision implemented per §5.1 (recommended default: drop the
      resting/interacting opacity differential).
- [ ] Updated `ScrollAffordanceViewTests` for any new pure visibility helper;
      `ScrollAffordanceModelTests` stay green.
- [ ] No change to edge math or scroll mechanics.

## Examples

**Example: a pure-logic assertion (looks are QA-verified via screenshots)**
```swift
@Test("an available-direction chevron is legible regardless of the scroll signal")
func chevron_legibleIndependentOfInteracting() {
  #expect(ScrollAffordanceView.chevronOpacity(isInteracting: false)
          == ScrollAffordanceView.chevronOpacity(isInteracting: true))
  // (if Phase 0 keeps a differential, assert the resting value clears the
  //  measured legibility floor instead.)
}
```

## Constraints

**Scope fence:** Do not remove/relocate the position indicators or reposition the
chevrons over the card body — that is ISSUE_03 (#423). Do not touch the card's
color layers — that is ISSUE_04. Do not change `ScrollAffordanceModel` edge math.

**Anti-bypass (verbatim, non-negotiable):**

> No `swiftlint:disable`, `swiftformat:disable`, `noqa`, `# type: ignore`,
> `pylint: disable`, `eslint-disable`, or equivalent linter/formatter/type-checker
> silencers. Fix the root cause. The only exception is the documented 4-line
> escape hatch (third-party library bug / language-version compatibility /
> benchmarked performance necessity / generated code) — and it must include the
> reason, a reference URL, an alternative considered, and a review date. See the
> `max-quality-no-shortcuts` skill.

**Tracer-code invariant:** App demoable; dual-axis navigation unaffected.

## Definition of Done (stay-green)

- [ ] Full frontend suite passes (`frontend/WavelengthWatch/run-tests-individually.sh`).
- [ ] `pre-commit run --all-files` clean.
- [ ] Pure visibility logic covered by tests; looks QA-verified per §7 matrix
      (rest vs. both axes, light/dark, 2 sizes, Reduce Transparency, large type).
- [ ] PR body: `Refs #425`, `Closes #431`.
- [ ] If the Claude reviewer Action runs: latest `Verdict:` on HEAD is `LGTM`.

## Labels

`spec-decomposition`, `core`, `navigation`
