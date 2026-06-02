# RCA — Directional chevrons overlap the scroll indicators

**Date:** 2026-06-01
**Author:** Claude (with Geoff)
**Severity:** P2 (readability / polish; not data-loss)
**Related:** `spec-primary-selector-rebuild.md` §4.2, #419/#420 (affordance system)
**Scope of this RCA:** the *layout collision* only. The separate "chevrons are
too dim / don't reliably read as available" problem is covered by
`SPEC_scroll_affordance_and_selector_visibility.md`.

## Problem statement

On the primary selector, the up/down/left/right directional arrows sit directly
on top of the existing scroll-position indicators (the trailing "layer N of M"
rail and the bottom page dots). The overlap looks sloppy and reduces
readability of both. User's preference: the arrows should sit **over the card
in the middle** rather than colliding with the edge indicators.

## Root cause

The affordance spec (§4.2, Component Inventory) explicitly called for the new
`ScrollAffordanceView` to **replace** `LayerSideIndicator` (the position rail)
and `LayerView`'s page dots — folding both into one coherent affordance. The
implementation instead **added** the chevrons while **keeping both old
indicators**, and positioned the chevrons at the four screen edges, where the
old indicators already live:

- `ScrollAffordanceView.chevron(_:alignment:)` lays each chevron out with
  `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment:)` + `.padding(4)`
  → the chevrons hug the extreme top/bottom/leading/**trailing** edges.
- `LayerScrollView.swift:88` → `.overlay(alignment: .trailing) { sideIndicator }`
  places `LayerSideIndicator` on the **trailing-center** edge → collides with
  the right chevron.
- `LayerView.swift` → `.overlay(alignment: .bottom) { pageIndicator }` places
  the page dots on the **bottom-center** edge → collides with the down chevron.

So two redundant systems occupy the same pixels. Both convey "position /
direction," so the redundancy is also conceptual, not just visual.

## Impact

Cosmetic but persistent; present on every selector screen at all watch sizes.
Reduces the legibility of the very affordance that signals how to navigate into
the logging screens.

## Fix strategy (options — final design deferred to the affordance spec)

1. **Complete the §4.2 consolidation (recommended).** Remove `LayerSideIndicator`
   and the `LayerView` page dots; let the directional chevrons be the single
   affordance. Fewest overlapping elements; matches original intent.
2. **Reposition the chevrons inboard.** Inset them off the extreme edges so they
   float over the card body (user's suggestion), leaving the edge indicators in
   their corners. Keeps position context but needs careful spacing.
3. **Both** — consolidate *and* inset — likely the cleanest end state.

This issue tracks the concrete collision; its fix should land with (or be
informed by) `SPEC_scroll_affordance_and_selector_visibility.md` so we don't
re-pixel-push it in isolation.

## Prevention

When a spec says "replace X with Y," the migration PR must **delete X**, not
leave it alongside Y. A grep for the replaced component names in the
component-inventory table should gate the phase's "done."
