# RCA — Selector glass brightness, chevron visibility, Clear Light logging deferral

**Date:** 2026-06-01
**Author:** Claude (with Geoff)
**Related:** #292 (Liquid Glass Rebuild), `spec-primary-selector-rebuild.md` (B1/B2/B3)
**Branch:** `fix-selector-glass-chevrons-clearlight-logging`

The selector rebuild shipped in #417–#421 implemented spec Phases B (B3 bump — fixed),
C (B1 chevrons), and D (glass). Phase A (B2 — journal confirmation deferral) was only
partially landed. This RCA covers three user-reported follow-ups.

---

## Issue 1 — Colored selector card too bright/opaque (feature request)

**Problem.** The phase card reads as a bright, saturated colored square rather than a
translucent liquid-glass surface.

**Root cause.** `PhaseCrystalCard.cardContent` applies
`.wlGlass(.regular, tint: color, …)` with the layer's **full-saturation** color
(`PhaseCrystalCard.swift:56`). On watchOS 26 this becomes
`glassEffect(style.tint(color), in: shape)` (`WLGlassModifier.swift:71`); a fully
opaque tint saturates the glass and removes the translucency. (On the pre-26 fallback
the fill is `color.opacity(surfaceOpacityLow=0.1)`, already subtle.)

**Fix strategy.** Dampen the tint alpha at the call site so the glass tints subtly and
stays translucent. Pure styling change; flagged as visually unverifiable in CI
(watch UI), per the project's "ship unverifiable UI if flagged" convention.

---

## Issue 2 — Directional chevrons vanish on vertical scroll (B1 regression)

**Problem (user words).** "The chevrons don't appear until you scroll left/right; on
every scroll up/down they disappear. They don't load automatically." These are the
primary visual cue for entering the curriculum/logging screen, so this is P0.

**Root cause.** `ScrollAffordanceView` emphasis is gated on `isInteracting`
(resting `0.35`, interacting `0.9` — `ScrollAffordanceView.swift`). `isInteracting`
is fed only by `.onScrollPhaseChange` on the **vertical** `ScrollView`
(`LayerScrollView.swift:46-48`). But vertical navigation is **programmatic** — the
digital crown and the drag gesture mutate `layerSelection`, and an `onChange`
animates `proxy.scrollTo(...)` (`LayerScrollView.swift:49-75`, `100-112`). A
programmatic `scrollTo` does not reliably emit a user-driven `scrollPhase`, so
`isInteracting` rarely flips true during vertical moves → chevrons stay at the faint
`0.35` resting opacity (reads as "disappeared"). The horizontal phase axis is a native
`TabView(.page)` whose own scroll phase *does* fire, briefly brightening them to `0.9`
(reads as "they appear when I scroll left/right"). Exactly the reported asymmetry.

**Fix strategy.** Decouple baseline visibility from the unreliable scroll-phase signal:
raise the resting opacity so an available-direction chevron is **always clearly
visible**, with interaction remaining a small additional emphasis. This makes B1
structurally impossible regardless of whether the phase signal fires (spec Principle 4).

---

## Issue 3 — Journal logging deferred until back-out (B2, Clear Light)

**Problem (user words).** "Logging doesn't occur until you hit the back button to leave
the screen where the emotions are listed. It must be awaiting behind something it
shouldn't be."

**Root cause.** Phase A migrated `CurriculumCard`, `StrategyCard`, and
`StrategyListView` off their local confirmation alerts onto
`PresentationCoordinator.request(.logConfirmation(...))`, rendered by
`RootPresentationHost` above the navigation push so it presents immediately. But
**`ClearLightEmotionCard` was never migrated**: it still owns
`@State private var showingJournalConfirmation` and renders an `.alert` from inside the
**pushed** `CurriculumDetailView` (`ClearLightEmotionCard.swift:9, 48-66`), and its
direct-log branch is a fire-and-forget `Task { await viewModel.journal(...) }`
(`:87`). That is precisely the B2 deferral pattern from the spec §2: a child
presentation requested inside a pushed destination is serialized behind the root's
presentation context and only flushes when the navigation state re-evaluates — i.e.
when the user backs out. The "All Emotions" Clear Light screen is the
"screen where the emotions are listed" the user describes.

**Fix strategy.** Migrate `ClearLightEmotionCard` to emit
`presentationCoordinator.request(.logConfirmation(LogConfirmationRequest(... action:
.curriculum(entry: emotion.entry))))`, exactly mirroring `CurriculumCard`. The
existing `LogConfirmationHandler.perform` already reproduces the card's former
`handleLogAction` branching verbatim and `await`s the journal call at the root, so the
local `.alert`, `@State`, `handleLogAction`, and fire-and-forget `Task` are deleted.

---

## Prevention

- When a spec defines a leaf-card migration set, grep every card that owns a journal
  `.alert`/`showingJournalConfirmation` before closing the phase — `ClearLightEmotionCard`
  slipped through because it lives under `Curriculum/` but isn't named `*Card` like the
  others were inventoried.
- Affordance/visibility should never depend on a signal that only fires for one of the
  two navigation axes; prefer always-visible-when-available with interaction as a bonus.
