# Store Assets

Artifacts required to submit WavelengthWatch to the App Store. This folder
is the single source of truth for copy, policy, and asset plans. Binary
screenshots and finalized icons live alongside their respective plans once
captured.

Tracks issue
[#271 — Create App Store metadata, screenshots, and privacy policy](https://github.com/Geoffe-Ga/WavelengthWatch/issues/271).

## Layout

```
store-assets/
├── metadata/
│   ├── app-store-metadata.md      # Name, subtitle, description, keywords, URLs
│   ├── age-rating-questionnaire.md# App Store Connect age-rating answers
│   ├── app-privacy-details.md     # App Privacy disclosure (nutrition label)
│   └── review-notes.md            # Notes pasted into App Review Information
├── privacy-policy/
│   ├── privacy-policy.md          # Canonical privacy policy to be hosted
│   └── hosting-plan.md            # Where and how to publish the policy
├── screenshots/
│   └── README.md                  # Capture plan (PNGs to be added later)
└── icons/
    └── icon-checklist.md          # Pre-submission icon verification
```

## How to use this folder

1. **Read `metadata/app-store-metadata.md` end to end** before touching App
   Store Connect. Every field, limit, and URL you need is there.
2. **Publish the privacy policy first.** The App Store will not let you
   submit without a resolvable privacy URL. Follow
   `privacy-policy/hosting-plan.md`.
3. **Capture screenshots** per `screenshots/README.md`. Save finished PNGs
   in that same folder using the stated naming convention, then upload to
   App Store Connect in order.
4. **Verify the icon** using `icons/icon-checklist.md`. This is fast — do it
   before you reserve a submission slot.
5. **Paste `metadata/review-notes.md` into App Review Information.** It
   tells the reviewer how to exercise the app without creating an account.

## What's in scope for issue #271

- ✅ Launch copy (name, subtitle, description, keywords, categories, age
  rating).
- ✅ Privacy policy ready to host.
- ✅ App Privacy disclosure entries for App Store Connect.
- ✅ Screenshot capture plan with exact sizes and naming.
- ✅ Icon pre-submission checklist.

## What's explicitly out of scope (follow-on issues)

- Actual screenshot PNGs (captured on hardware once the submission window
  is scheduled).
- Marketing site HTML (tracked separately — only the privacy URL is needed
  for submission).
- App preview video.
- Localizations beyond English (U.S.).
- In-app purchase copy.
- Self-service data export UI (Epic #244).

## Change management

- Update the "Last updated" date at the top of `privacy-policy.md` whenever
  the policy changes.
- Keep `metadata/app-privacy-details.md` in sync with any new data types,
  SDKs, or default-sync behavior.
- If copy changes materially after submission, file a metadata-only update
  in App Store Connect; a new binary is not required for text-only edits.
