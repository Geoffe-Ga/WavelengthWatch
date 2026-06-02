# SPEC — Scroll Affordance & Selector Visibility (rebuild)

**Status:** Draft for review
**Author:** Claude (with Geoff)
**Date:** 2026-06-01
**Supersedes the B1 approach in:** `spec-primary-selector-rebuild.md` §4.2 (the
opacity-driven emphasis model) and PR #422's resting-opacity bump.
**Related:** #423 (chevron/indicator overlap — layout sibling of this work),
#419/#420 (affordance system), #421 (glass on selector), #292.

---

## 0. Why this spec exists

The directional chevrons and the colored selector card have been tuned several
times (timer hide → phase-driven opacity → resting-opacity bump) and the user
still reports they don't read well. As with the logging spec, the failure mode
is **tuning constants without first confirming, against the running app, what is
actually controlling perceived visibility.** Rule: **Phase 0 (visual audit on
device/sim) must complete and be recorded here before further constant-tuning or
rewrite.**

The user is open to rewriting these views from scratch.

---

## 1. Problem statement

Two coupled complaints about the primary selector screen.

### 1.1 Directional chevrons ("arrows")
**User words (original):** "The chevrons don't appear until you scroll
left/right; on every scroll up/down they disappear… these are the only way to get
into a curriculum screen to log."
**User words (after PR #422, confirmed in sim):** "They are **always dimly
visible** and then **all arrows light up during scrolling** itself." Plus: they
**overlap the scroll indicators** (tracked separately in #423).

So the post-#422 state: no longer *disappearing*, but **too dim at rest** and the
"only lights up while scrolling" behavior still reads as wrong. They are also the
user's perceived entry point into the logging screens, so legibility is
high-value.

### 1.2 Colored selector card ("squares too bright/opaque")
**User words:** "You made them opaque… it would be cool if they were less
opaque… not so bright." After PR #422 dampened the *glass tint* to 0.45, the card
still reads too bright — suggesting the brightness isn't (only) the glass tint.

---

## 2. What we know vs. what we assume

| Fact | Status | Evidence |
|------|--------|----------|
| Post-#422 the chevrons are always visible but dim at rest and brighten during scroll. | **Known** | User-observed in sim built from working tree (`restingOpacity = 0.85`, `interactingOpacity = 1.0` in `ScrollAffordanceView.swift`). |
| Raising opacity 0.35→0.85 stopped the "disappear," but 0.85 white-on-translucent-glass still reads "dim." | **Known** | Implies opacity is **not** the dominant lever for legibility. |
| The card's color comes from several full-saturation layers stacked over the glass, not just the glass tint. | **Known** | `PhaseCrystalCard`: `backgroundOrb` (`color` 0.3→0.1), `crystalAccent` inner capsule uses full `color` + `shadow(color.opacity(0.8))` (`:103-119`), `crystalStroke` color gradients (`:125-138`), plus the page background radial `color.opacity(0.18)` in `PhasePageView`. |
| Vertical navigation is largely programmatic (crown/drag → `scrollTo`), so the `onScrollPhaseChange` "interacting" signal is unreliable for vertical moves. | **Known/strong** | `LayerScrollView.swift:46-48` vs `:49-75`, `:100-112`; matches "lights up on horizontal but not vertical." |
| What *actually* makes the chevrons read as "dim" (material translucency? symbol size? contrast vs. background? lack of a solid backing?). | **ASSUMED** | Needs Phase 0 visual audit. |
| Whether the scroll-coupled emphasis (resting<interacting) is even desirable. | **OPEN DESIGN Q** | The "only lights up on scroll" complaint suggests maybe not. |

---

## 3. Failed hypotheses (and why)

1. **Timer-based hide (`scheduleHide`).** Faded chevrons mid-gesture. Deleted in
   #420. Correct to remove, but…
2. **"Phase-driven opacity makes B1 impossible" (#420).** The interacting signal
   only fires for the *native horizontal* axis; vertical is programmatic, so
   resting opacity dominated and was too faint → "disappears on vertical."
3. **"Just raise resting opacity" (PR #422).** Stopped the disappearing, but
   0.85 over translucent glass still reads dim — proving **opacity ≠ legibility**.
   Contrast, material, and symbol weight/size were never addressed.
4. **"Dampen the glass tint to fix brightness" (PR #422).** The card's brightness
   is dominated by the *full-saturation orb/accent/stroke* layers, not the glass
   tint — so the tint change didn't move perceived brightness.

Through-line: we kept turning one opacity knob; legibility and brightness are
multi-layer, multi-factor visual problems.

---

## 4. First-principles diagnosis

### 4.1 Chevrons — legibility is contrast + material + size, not opacity
A small white `chevron` (`font .system(size: 12)`) on a `.regular` translucent
glass chip, over a dark-but-busy phase card, at 0.85 opacity, has **low contrast**
and **small target size**. Brightening to 1.0 during scroll is the only time it
crosses the legibility threshold — hence "lights up only when scrolling." The
real levers: symbol size/weight, a backing with reliable contrast (solid or
darker glass), and possibly a shadow/outline — and deciding whether emphasis
should track scroll at all.

### 4.2 Chevrons — visibility must not depend on the scroll-phase signal
Because the vertical axis is programmatic, any visibility tied to
`isInteracting` will be asymmetric between axes. Baseline legibility must be
**signal-independent**: a direction's chevron is fully legible whenever that
direction is available, full stop. Any scroll emphasis is decorative only and
must never be the difference between legible and not.

### 4.3 Card — brightness is the sum of stacked color layers
Reducing one layer (glass tint) can't calm the card while the orb, the
full-`color` accent capsule (+ its `color.opacity(0.8)` glow), the colored
stroke, and the page radial all push saturated color. The card needs a
**holistic** treatment: decide the target (a calm, translucent, *subtly* tinted
glass card) and bring every color-bearing layer in line with it — or redesign the
card composition.

### 4.4 Redundant affordance systems (cross-ref #423)
Chevrons coexist with `LayerSideIndicator` + page dots, which both overlap and
duplicate the position/direction signal. The intended §4.2 consolidation was
never completed. Resolving visibility and overlap together avoids re-pixel-pushing.

---

## 5. Phase 0 — Visual audit & confirmation (MANDATORY, before rewrite/tuning)

Capture, on the sim **and** a real device if available, at ≥2 watch sizes (41mm &
45/49mm), with screenshots pasted into §5.1:

1. **Chevron legibility matrix:** chevrons at rest vs. during vertical scroll vs.
   during horizontal scroll, over the lightest and darkest phase cards. Note
   where they fall below "instantly readable."
2. **Isolate the lever:** test variants in a `#Preview` — (a) larger/heavier
   symbol, (b) solid vs. glass chip, (c) added shadow/outline, (d) constant
   full-opacity vs. scroll-coupled — and record which actually fixes legibility.
3. **Card brightness audit:** screenshot the card with each color layer toggled
   off in turn (orb / accent capsule / stroke / page radial / glass tint) to
   attribute perceived brightness to specific layers.
4. **Accessibility:** repeat key cases with Reduce Transparency on and at large
   Dynamic Type.

**Exit criteria:** §5.1 names the specific levers that fix (a) chevron legibility
and (b) card brightness, with before/after screenshots. Only then do we design.

### 5.1 Findings (to be filled in)
> _TBD — populated during Phase 0._

---

## 6. Proposed direction (conditioned on Phase 0)

### 6.1 Chevrons
- **Signal-independent legibility:** a chevron is fully legible whenever its
  direction is available; no dependence on `isInteracting` for *legibility*.
- **Right-size the mark:** larger/heavier symbol and a backing tuned for contrast
  on both light and dark cards (Phase 0 picks solid vs. glass vs. outlined).
- **Decide on scroll emphasis explicitly:** default recommendation — drop the
  resting/interacting opacity differential (it's the source of "only lights up on
  scroll"); if any motion cue is wanted, make it a subtle scale/spring, not a
  legibility gate.
- **Edge honesty retained:** absent chevron = that edge is reached (`ScrollAffordanceModel`
  edge math stays; it's correct).

### 6.2 Card / glass
- Define the target visual (calm translucent tinted glass) and bring **every**
  color-bearing layer in line: reduce orb opacity, desaturate/soften the accent
  capsule + its glow, calm the stroke, reduce the page radial — or redesign the
  composition outright (rewrite is on the table).
- Keep the real `glassEffect` material; ensure the Reduce-Transparency fallback
  stays legible.

### 6.3 Consolidate affordances (with #423)
- Complete the §4.2 consolidation: the directional chevrons are the single
  affordance; remove or fold in `LayerSideIndicator` + page dots; position
  chevrons over the card body, not the edges.

---

## 7. Acceptance criteria

- [ ] **Phase 0 findings recorded** in §5.1 (legibility levers + brightness
      attribution, with screenshots) before rewrite/tuning.
- [ ] Each available-direction chevron is **instantly legible at rest** over both
      the lightest and darkest phase cards, at 41mm and 45/49mm — *without*
      scrolling and *without* relying on the interacting signal.
- [ ] Chevron legibility is identical on the vertical and horizontal axes (no
      axis asymmetry).
- [ ] A reached edge suppresses its chevron (affordance honesty preserved).
- [ ] The colored card reads as a **calm, translucent, subtly tinted glass**
      surface, not a bright/opaque colored block — verified by side-by-side
      before/after on device.
- [ ] No overlap between chevrons and any position indicator (closes #423).
- [ ] Reduce Transparency + large Dynamic Type remain legible.
- [ ] Existing tests green; new logic seams (edge math, any visibility helper)
      covered per the project's view-test philosophy.

---

## 8. Test plan
- **Unit:** `ScrollAffordanceModel` edge math (kept); any new visibility helper is
  a pure function with tests. Per project philosophy, *legibility itself is QA-
  verified*, not unit-tested (it's visual) — so tests pin logic, screenshots pin
  looks.
- **Construction tests:** rebuilt views construct without crashing with correct
  child wiring.
- **Manual QA matrix:** the Phase 0 matrix, re-run as acceptance: rest vs. scroll
  vs. both axes, light/dark cards, 2 sizes, Reduce Transparency, large type.

---

## 9. Phased delivery (proposed sub-issues)
1. **Phase 0 — Visual audit.** Build the `#Preview` variant harness, capture the
   matrices, record §5.1. *Gate.*
2. **Phase 1 — Chevron legibility rebuild.** Signal-independent legibility;
   right-sized mark + contrast backing; decide scroll emphasis. Closes the B1
   "don't read" problem.
3. **Phase 2 — Affordance consolidation.** Remove/fold the redundant indicators;
   reposition chevrons over the card body. Closes #423.
4. **Phase 3 — Card glass calm-down.** Holistic brightness/translucency pass (or
   card redesign). Closes the "too bright/opaque" feature request.

Each phase is independently shippable and leaves the app green.

---

## 10. Risks & mitigations
| Risk | Mitigation |
|------|------------|
| Phase 0 shows a different dominant lever than §4.1/§4.3. | Update the spec; design to the confirmed lever. |
| Higher-contrast chevrons feel loud / fight the calm aesthetic. | Tune in Phase 0 with Geoff; "legible but calm" is the target, and constant legibility lets us *lower* peak brightness vs. the current scroll-spike. |
| Removing indicators loses position context. | Chevrons + (optional) a single minimal, non-overlapping rail can retain "N of M" without duplication. |
| Glass rework regresses Reduce-Transparency fallback. | Explicit AC + QA for that path. |

---

## 11. Out of scope
- Journal logging pipeline (separate spec).
- Scroll/depth transform stability (B3 — already fixed in #418).
- Analytics (#187); Models/Services/backend.
