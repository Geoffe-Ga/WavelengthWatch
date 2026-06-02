> **PROVISIONAL — reconcile with `SPEC_scroll_affordance_and_selector_visibility.md`
> §5.1 (brightness attribution) before starting.** Tune the layers Phase 0
> actually fingered, not just the glass tint.

## Role

You are a senior watchOS/SwiftUI engineer with a strong visual-design sense,
working in this repo's `frontend/WavelengthWatch` target with Liquid Glass.

## Goal

Bring the colored phase card down to a **calm, translucent, subtly tinted glass**
surface — not a bright/opaque colored block — by adjusting every color-bearing
layer per the Phase 0 attribution, keeping the real `glassEffect` material and a
legible Reduce-Transparency fallback.

## Context

- **Parent epic:** #425
- **Predecessor issue(s):** EPIC_02_ISSUE_01 (Phase 0) — brightness attribution in
  §5.1 reconciled; safe to land after ISSUE_02/03 or in parallel if non-colliding.
- **SPEC section:** `SPEC_…visibility.md` §4.3, §6.2.
- **Files involved:**
  - `Views/Navigation/PhaseCrystalCard.swift` — `backgroundOrb` (`color` 0.3→0.1),
    `crystalAccent` (full-`color` inner capsule + `color.opacity(0.8)` glow),
    `crystalStroke` (color gradients), the `wlGlass` tint.
  - `Views/Navigation/PhasePageView.swift` — page background radial `color.opacity(0.18)`.
  - `DesignSystem/Modifiers/WLGlassModifier.swift` — material + Reduce-Transparency
    fallback (`applyOpaque`).
- **Prior decisions:** the earlier "dampen the glass tint to 0.45" change did NOT
  move perceived brightness — the orb/accent/stroke dominate. Treat holistically.
- **State of the world:** card reads too bright/saturated; user wants "less opaque,
  not so bright."

## Output Format

Deliverable is a single PR containing:

- [ ] Each color-bearing layer adjusted per §5.1 attribution (or the card
      composition redesigned) so the card reads as calm translucent glass.
- [ ] Reduce-Transparency fallback remains legible (explicit check).
- [ ] Before/after screenshots at 41mm and 45/49mm over ≥2 layer colors.
- [ ] Any preview/audit scaffolding from ISSUE_01 removed if no longer needed.
- [ ] No change to layout, navigation, or the chevrons.

## Examples

**Example: acceptance check**
```
Before: Red layer card glows as a saturated red block; text fights the fill.
After:  Red layer card is a translucent glass panel with a subtle red tint;
        content legible; not a bright block. Verified at 41mm + 45/49mm, and
        with Reduce Transparency on.
```

## Constraints

**Scope fence:** Do not touch chevrons/indicators (ISSUE_02/03) or any
logic/navigation. Visual-only. Do not change Models/Services.

**Anti-bypass (verbatim, non-negotiable):**

> No `swiftlint:disable`, `swiftformat:disable`, `noqa`, `# type: ignore`,
> `pylint: disable`, `eslint-disable`, or equivalent linter/formatter/type-checker
> silencers. Fix the root cause. The only exception is the documented 4-line
> escape hatch (third-party library bug / language-version compatibility /
> benchmarked performance necessity / generated code) — and it must include the
> reason, a reference URL, an alternative considered, and a review date. See the
> `max-quality-no-shortcuts` skill.

**Tracer-code invariant:** App demoable; only the card's visuals change.

## Definition of Done (stay-green)

- [ ] Full frontend suite passes (`frontend/WavelengthWatch/run-tests-individually.sh`).
- [ ] `pre-commit run --all-files` clean.
- [ ] No logic change, so existing tests stay green; looks QA-verified (incl.
      Reduce Transparency + large Dynamic Type).
- [ ] PR body: `Refs #425`, `Closes #433`.
- [ ] If the Claude reviewer Action runs: latest `Verdict:` on HEAD is `LGTM`.

## Labels

`spec-decomposition`, `polish`, `navigation`
