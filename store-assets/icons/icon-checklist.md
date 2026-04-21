# App Icon Checklist

WavelengthWatch ships its watchOS icon from the asset catalog at
`frontend/WavelengthWatch/WavelengthWatch Watch App/Assets.xcassets/AppIcon.appiconset/`.
This document verifies that the icon is App-Store-ready and records the
follow-on work needed if Apple Review flags anything.

## Current state

- Single universal watchOS icon: `app-icon-1024.png` (1024 × 1024).
- Asset catalog `Contents.json` declares a single `universal` entry with
  `platform: "watchos"` and `size: "1024x1024"`. This is the modern
  single-size layout introduced in Xcode 14+, and Xcode renders down all the
  per-device sizes at build time.
- The in-app About view uses a separate asset (`AboutIcon.imageset`) and is
  not affected by App Store icon rules.

## Pre-submission verification

Run each of these before submitting. Mark them off in the PR that turns this
plan into the actual submission issue.

- [ ] `app-icon-1024.png` is exactly 1024 × 1024 pixels, RGB (no alpha).
      Confirm with `sips -g pixelWidth -g pixelHeight -g format app-icon-1024.png`.
- [ ] No transparency: Apple rejects PNGs with an alpha channel for the
      1024 × 1024 marketing icon. Flatten with Preview → Export → uncheck
      "Alpha" if in doubt.
- [ ] No rounded corners baked in. Apple applies the corner radius for
      watchOS icons automatically.
- [ ] No text overlaid on the icon. WavelengthWatch's mark is glyph-only,
      which is compliant.
- [ ] Icon renders correctly on a watchOS home screen in both light and dark
      faces. Capture in the simulator as a sanity check.
- [ ] App Store Connect preview (Media Manager → App Icon) matches the
      intended design.

## If Apple Review rejects

If the reviewer flags the icon (Guideline 2.3.8 "Accurate Metadata" or
visual-asset issues), the common fixes are:

1. **Color clash with UI** — re-export at 100% brightness, verify on an OLED
   device in Solar face.
2. **Too much detail** — simplify. Watch icons are rendered small; fine
   line-work disappears.
3. **Similarity to another app** — revise the mark. Track in a new issue and
   attach before/after screenshots.

## Future work (out of scope for issue #271)

- Design a dark-appearance variant once watchOS supports per-icon variants
  natively without a companion iOS app.
- Add a tinted version for watchOS 10+ Smart Stack presentations.
- Add a Mac Catalyst icon if a future companion app is published.

Each of these should be tracked as its own backlog issue; they are not
blockers for first submission.
