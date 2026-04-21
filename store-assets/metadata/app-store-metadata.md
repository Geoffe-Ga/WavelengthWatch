# App Store Metadata — WavelengthWatch

This document contains the copy and configuration values that should be entered
into App Store Connect for the WavelengthWatch watchOS app. All character
counts are Apple's published maximums as of the 2026 App Store Connect schema.

> **Owner**: Product / Geoffe-Ga
> **Status**: Draft — ready for review before App Store Connect entry
> **Issue**: [#271](https://github.com/Geoffe-Ga/WavelengthWatch/issues/271)

---

## 1. App Identity

| Field | Value | Limit | Notes |
|-------|-------|-------|-------|
| App Name | `WavelengthWatch` | 30 | Verify availability in App Store Connect before reserving. |
| Subtitle | `Emotional wavelength journal` | 30 | Primary tagline shown beneath the app name in Search. |
| Bundle Display Name (watch) | `WavelengthWatch` | — | Must match the value in `Info.plist`. |
| Primary Language | English (U.S.) | — | Only localization at launch. |
| Price Tier | Free | — | See `docs/monetization` once created; v1.0 ships free. |

### Subtitle Alternatives (for A/B review)
1. `Emotional wavelength journal` *(recommended)*
2. `Self-care on your wrist`
3. `Tune in. Track your wavelength.`

---

## 2. Promotional Text (170 chars)

Promotional text appears above the description and can be updated without a new
binary submission. Use it to surface seasonal messaging or launch notes.

```text
Tune in to your emotional wavelength, right from your wrist. Log feelings, pick
a self-care strategy, and see patterns emerge — privately, offline-first.
```

Character count: 166 / 170.

---

## 3. Description (4000 chars)

The description below is the canonical launch copy. Keep paragraphs short —
watch-first readers scan on small screens and on App Store listings.

```text
WavelengthWatch is an emotional wellness companion for your Apple Watch.
Rooted in the Archetypal Wavelength framework, it helps you notice what you
feel, name the phase you're moving through, and pick a self-care strategy in
seconds — directly from your wrist.

WHY WAVELENGTHWATCH
Most journaling apps ask you to stop, pull out your phone, and write. That
friction is why most people quit. WavelengthWatch is designed for the small
window when you actually notice a feeling: a few taps on your wrist, and you've
logged an entry and chosen how to respond to it.

HOW IT WORKS
1. Browse layers of experience — Beige, Purple, Red, Blue, Orange, Green,
   Yellow, Turquoise — and the Rising, Peaking, Falling, and Resting phases
   within each.
2. Tap the curriculum that matches what you feel right now. Each entry shows
   its medicinal expression alongside its toxic counterpart, so you can see
   where you are and where the pattern can drift.
3. Choose a self-care strategy tuned to the layer and phase you're in. Log
   the moment in one tap.

PRIVACY-FIRST BY DESIGN
Your journal lives in a local SQLite database on your watch. Cloud sync is
strictly opt-in — not a default, not buried in settings. Turn it off and the
app is fully functional. Turn it on and entries sync to a backend you can
self-host. There are no third-party analytics, no ad SDKs, no trackers.

OFFLINE-FIRST
The entire Archetypal Wavelength curriculum is bundled in the app, so you can
browse, log, and reflect without a network connection. When connectivity
returns, the app can quietly refresh content in the background.

ANALYTICS WITHOUT SURVEILLANCE
Patterns in your entries are computed on-device. See the feelings you return
to most often, the strategies that actually help, and the shape of your week.
The insight is yours — it never leaves the watch unless you choose cloud sync.

DESIGNED FOR THE WRIST
- Dual-axis navigation: swipe vertically through layers, horizontally through
  phases.
- Large touch targets and single-tap journaling built around watchOS Liquid
  Glass design.
- Haptic confirmations so you know an entry landed without looking.
- Works on Apple Watch Series 6 and later, running watchOS 11 or newer.

WHO IT'S FOR
- People in therapy, coaching, or recovery who want a lightweight reflection
  tool between sessions.
- Anyone interested in Spiral Dynamics, Integral Theory, or somatic practice,
  looking for a phase-aware self-care companion.
- Users who care about privacy and want a journal that is not a surveillance
  product.

WHAT YOU WON'T FIND
- No ads. No in-app purchases at launch. No account required.
- No health data read from HealthKit without an explicit future opt-in.
- No background location, no contacts access, no microphone.

GETTING STARTED
Open WavelengthWatch on your Apple Watch, pick the layer and phase that match
your moment, and tap. That's the whole loop. Cloud sync, export, and longer
analytics views can be enabled from Settings when you're ready.

Questions, feedback, or bug reports: support@wavelengthwatch.app
Privacy policy: https://wavelengthwatch.app/privacy
```

Character count (approximate): **~3,050 / 4,000**. Leaves headroom for copy
tweaks during review.

---

## 4. Keywords (100 chars, comma-separated)

App Store Connect charges each comma as a character. Keep distinct tokens; do
not repeat words already in the title or subtitle — Apple already indexes
those.

```text
mood,feelings,wellness,mindful,selfcare,spiral,somatic,reflection,therapy,coach,private,offline
```

Character count: 99 / 100.

### Rationale

| Token | Rationale |
|-------|-----------|
| mood / feelings | Competitor category terms users actually search. |
| wellness / mindful / selfcare | Category-defining terms. |
| spiral / somatic | Framework-adjacent terms for the target audience. |
| reflection / therapy / coach | Use-case terms without trademark risk. |
| private / offline | Differentiation terms for privacy-focused users. |

Intentionally omitted: `watch`, `journal`, `emotional`, `analytics` — all
already present in title, subtitle, and description.

---

## 5. Categories

| Slot | Category |
|------|----------|
| Primary | Health & Fitness |
| Secondary | Lifestyle |

**Rationale**: Health & Fitness is the closest native category for emotional
wellness on Apple Watch and is where competing journaling/mood apps sit.
Lifestyle is the secondary because WavelengthWatch is not a clinical product
and is as much about personal practice as it is about wellness tracking.

---

## 6. Age Rating

Target rating: **4+**.

See `store-assets/metadata/age-rating-questionnaire.md` for the full
questionnaire answers.

**Summary**: No objectionable content, no unrestricted web access, no user-
generated content shared with others, no gambling, no simulated violence.

---

## 7. URLs

| Field | Value | Required? |
|-------|-------|-----------|
| Support URL | `https://wavelengthwatch.app/support` | Required |
| Marketing URL | `https://wavelengthwatch.app/` | Optional |
| Privacy Policy URL | `https://wavelengthwatch.app/privacy` | Required |
| EULA | Apple Standard EULA | Default |

All three URLs must resolve before submission. Interim plan:

1. **Short term** — publish the privacy policy and a one-page support page via
   GitHub Pages hosted from this repository (`docs/site/` can be added later
   without changing these URLs by pointing the custom domain at the Pages
   site).
2. **Long term** — move to a static marketing site on the same domain.

If the `wavelengthwatch.app` domain is not yet registered at submission time,
fall back to a GitHub Pages URL (`https://geoffe-ga.github.io/WavelengthWatch/privacy.html`)
and update to the custom domain in a subsequent metadata-only revision.

---

## 8. Contact & Review Information

| Field | Value |
|-------|-------|
| First Name | *(Developer account owner)* |
| Last Name | *(Developer account owner)* |
| Phone | *(Developer account owner)* |
| Email | `support@wavelengthwatch.app` |
| Demo Account | Not required — app has no sign-in gate |
| Notes for Reviewer | See `review-notes.md` in this folder |

---

## 9. Version Information

| Field | Value |
|-------|-------|
| Version | `1.0.0` |
| Build | Set by CI at submission time |
| Copyright | `© 2026 WavelengthWatch` |
| Release Type | Manual release after approval |

### What's New in This Version (4000 chars)

For the initial submission the "What's New" text is not shown — Apple displays
the description instead. Reserve the following for the first post-launch
update:

```text
Welcome to WavelengthWatch 1.0. This is the first public release.

- Dual-axis navigation through the Archetypal Wavelength.
- One-tap journal entries with haptic confirmation.
- Privacy-first local storage with opt-in cloud sync.
- On-device analytics across feelings, strategies, and time.
```

---

## 10. Review Notes (submitted to App Review)

```text
WavelengthWatch is a standalone watchOS app. It does not require an iPhone
companion app and works fully offline.

- No account is required. The app generates a random pseudo-user ID stored in
  UserDefaults so that journal entries can be grouped if the user opts in to
  cloud sync. This ID is not tied to Apple ID, email, or device identifiers.
- Cloud sync is OFF by default. To test sync, open Settings inside the app
  and toggle "Cloud Sync". A development backend URL is configured via
  `APIConfiguration.plist` and is pointed at a reviewer-accessible endpoint
  for the submission build.
- No HealthKit, location, contacts, microphone, or camera permissions are
  requested.
- The Archetypal Wavelength curriculum is bundled in-app as JSON, so the
  reviewer can browse the entire experience with airplane mode enabled.

Expected reviewer flow:
1. Launch the app from the watch home screen.
2. Swipe vertically to change "layer" and horizontally to change "phase".
3. Tap any curriculum card to see its medicinal and toxic expressions.
4. Tap a strategy to log an entry. A haptic confirms the save.
5. Open Settings to view the privacy toggles and analytics view.
```

---

## 11. Localization

Ship English (U.S.) only at launch. Track future localizations as follow-on
issues rather than blocking v1.0 on additional language coverage.

---

## 12. In-App Purchases

None at launch. If monetization is added in a future release, update this
file and disclose in the App Privacy details.

---

## 13. Submission Checklist

- [ ] App name reserved in App Store Connect
- [ ] Subtitle entered
- [ ] Promotional text entered
- [ ] Description entered
- [ ] Keywords entered
- [ ] Primary + secondary category selected
- [ ] Age rating questionnaire completed (see sibling file)
- [ ] Support, marketing, privacy policy URLs live and entered
- [ ] Screenshots uploaded (see `store-assets/screenshots/README.md`)
- [ ] App icon verified (see `store-assets/icons/icon-checklist.md`)
- [ ] App Privacy details completed (see sibling `app-privacy-details.md`)
- [ ] Review notes entered
- [ ] Build uploaded and selected for submission
