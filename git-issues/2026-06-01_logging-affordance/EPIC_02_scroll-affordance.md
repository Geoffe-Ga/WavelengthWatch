## Epic Summary

Make the selector's directional chevrons **instantly legible at rest on both
axes**, stop them overlapping the position indicators, and bring the colored
phase card down to a **calm, translucent glass** look. Manual testing
(2026-06-01) showed opacity isn't the lever (0.85 white-on-glass still reads
dim) and that the card's brightness comes from stacked full-saturation layers,
not the glass tint. See
`prompts/claude-comm/SPEC_scroll_affordance_and_selector_visibility.md` §1–§4.

## Scope

**In scope:**
- `ScrollAffordanceView` (chevron legibility, material, sizing, scroll-emphasis
  policy) and `ScrollAffordanceModel` (edge math — kept).
- `LayerScrollView` / `LayerView` indicator overlays (`LayerSideIndicator`,
  page dots) — consolidation with the chevrons (closes #423).
- `PhaseCrystalCard` / `PhasePageView` color-bearing layers (orb, accent,
  stroke, page radial, glass tint) — holistic brightness pass.

**Out of scope:**
- Journal logging (EPIC_01).
- Scroll/depth transform stability (B3 — already fixed in #418).
- Analytics (#187); Models/Services/backend.

## Success Criteria

The epic is done when:

- [ ] Phase 0 findings recorded in
      `SPEC_scroll_affordance_and_selector_visibility.md` §5.1 (legibility levers
      + brightness attribution, with screenshots).
- [ ] Each available-direction chevron is instantly legible at rest over the
      lightest and darkest cards, at 41mm and 45/49mm, without scrolling and
      without depending on the interacting signal.
- [ ] Legibility is identical on vertical and horizontal axes; a reached edge
      suppresses its chevron.
- [ ] No overlap between chevrons and any position indicator (closes #423).
- [ ] The colored card reads as calm, translucent, subtly tinted glass (verified
      side-by-side on device).
- [ ] Reduce Transparency + large Dynamic Type remain legible.
- [ ] All child issues closed; full frontend test suite green on `main`.

## Child Issues

_Filled in after child issues are filed (Step 8/9 of spec-decomposition)._

- [ ] #430 — Phase 0: visual-audit harness; attribute legibility + brightness
- [ ] #431 — Chevron legibility rebuild (signal-independent, sized, contrast)
- [ ] #432 — Affordance consolidation + reposition (closes #423)
- [ ] #433 — Card glass calm-down (holistic brightness pass)

## Sequencing Notes

- **Blocks:** ISSUE_01 (Phase 0) blocks ISSUE_02–04 — reconcile provisional
  designs with §5.1 before implementing.
- **Parallel-safe** with EPIC_01 (different subsystem).
- ISSUE_03 closes #423; do not also fix the overlap in isolation elsewhere.

## SPEC Reference

`prompts/claude-comm/SPEC_scroll_affordance_and_selector_visibility.md` (full
document; esp. §4 diagnosis, §5 Phase 0, §6 proposed direction, §9 phased
delivery). Related RCA: `prompts/claude-comm/RCA_chevron_indicator_overlap.md`.

## Labels

`epic`, `spec-decomposition`, `navigation`
