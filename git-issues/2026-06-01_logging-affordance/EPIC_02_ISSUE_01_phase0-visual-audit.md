## Role

You are a senior watchOS/SwiftUI engineer with a strong design eye, fluent in
SwiftUI `#Preview`, Liquid Glass (`glassEffect`), and on-device visual QA in this
repo's `frontend/WavelengthWatch` target.

## Goal

Attribute, with screenshots, **which specific levers** control (a) directional-
chevron legibility and (b) the colored card's perceived brightness — and record
the findings in `SPEC_scroll_affordance_and_selector_visibility.md` §5.1. No
production behavior changes ship in this issue.

## Context

- **Parent epic:** #425
- **Predecessor issue(s):** none — this is the Phase 0 (skeleton/diagnostic) gate.
- **SPEC section:** `prompts/claude-comm/SPEC_scroll_affordance_and_selector_visibility.md`
  §5 (Phase 0) and §4 (diagnosis).
- **Files involved (preview/audit harness only — no shipped behavior change):**
  - `Views/Navigation/ScrollAffordanceView.swift` — chevron mark, glass chip,
    opacity policy (`chevronOpacity`).
  - `Views/Navigation/PhaseCrystalCard.swift` — `backgroundOrb`, `crystalAccent`
    (full-`color` capsule + `color.opacity(0.8)` glow), `crystalStroke`, glass tint.
  - `Views/Navigation/PhasePageView.swift` — page background radial `color.opacity(0.18)`.
  - `DesignSystem/Modifiers/WLGlassModifier.swift` — material + Reduce-Transparency fallback.
- **State of the world:** post-PR-#422-revert, chevrons read "always dimly visible,
  brighten on scroll"; opacity alone didn't fix legibility; card still reads bright.

## Output Format

Deliverable is a single PR containing:

- [ ] A `#Preview`-based audit harness (gated/marked, not shipped UI) that renders:
      chevrons at rest vs. vertical-scroll vs. horizontal-scroll, over the lightest
      and darkest phase cards, at 41mm and 45/49mm; and the card with each
      color-bearing layer toggled off in turn.
- [ ] `SPEC_…visibility.md` §5.1 filled with before/after screenshots and an
      explicit statement of: the chevron-legibility lever(s) that actually work
      (symbol size/weight? solid vs. glass chip? shadow/outline? constant vs.
      scroll-coupled opacity?) and the card-brightness attribution (orb / accent /
      stroke / page radial / tint).
- [ ] A recommendation in §5.1 on whether to keep any scroll-coupled emphasis.
- [ ] Repeat key cases with Reduce Transparency on and large Dynamic Type.
- [ ] No change to shipped rendering.

## Examples

**Example: the kind of attribution §5.1 must contain**
```
Chevron legibility: size 12→17 + .bold + solid dark chip = legible at rest on
  both light/dark cards; opacity alone (0.85→1.0) = NOT sufficient on light card.
Card brightness: orb (−40% perceived), crystalAccent inner capsule + glow
  (−35%), stroke (−15%), page radial (−10%); glass tint already minor.
Recommendation: drop scroll-coupled opacity differential (source of "only lights
  up on scroll"); keep constant high legibility.
```

## Constraints

**Scope fence:** Do **not** ship the rebuilt chevrons, consolidation, or card
changes — those are ISSUE_02/03/04. This issue only measures and documents.

**Anti-bypass (verbatim, non-negotiable):**

> No `swiftlint:disable`, `swiftformat:disable`, `noqa`, `# type: ignore`,
> `pylint: disable`, `eslint-disable`, or equivalent linter/formatter/type-checker
> silencers. Fix the root cause. The only exception is the documented 4-line
> escape hatch (third-party library bug / language-version compatibility /
> benchmarked performance necessity / generated code) — and it must include the
> reason, a reference URL, an alternative considered, and a review date. See the
> `max-quality-no-shortcuts` skill.

**Tracer-code invariant:** Shipped UI unchanged; only previews/audit added.

## Definition of Done (stay-green)

- [ ] Full frontend suite passes (`frontend/WavelengthWatch/run-tests-individually.sh`).
- [ ] `pre-commit run --all-files` clean.
- [ ] No shipped-behavior change, so no new runtime tests required; existing tests
      stay green (project view-test philosophy).
- [ ] `SPEC_…visibility.md` §5.1 filled with screenshots + lever attribution.
- [ ] PR body: `Refs #425`, `Closes #430`.
- [ ] If the Claude reviewer Action runs: latest `Verdict:` on HEAD is `LGTM`.

## Labels

`spec-decomposition`, `tracer-skeleton`, `navigation`
