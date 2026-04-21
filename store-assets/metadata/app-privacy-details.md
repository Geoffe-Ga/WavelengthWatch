# App Privacy Details — App Store Connect

Apple requires a structured privacy disclosure in App Store Connect
(App Privacy → Data Types). This document lists every field and the exact
answer to enter.

**Last reviewed**: 2026-04-21
**Driven by**: Issue [#271](https://github.com/Geoffe-Ga/WavelengthWatch/issues/271)

---

## Summary

WavelengthWatch has two privacy modes:

1. **Default (privacy-first)**: All data stays on the device. No data is
   collected by the developer.
2. **Opt-in cloud sync**: Journal entries (emotional state, strategy choice,
   timestamp, and a random pseudo-user ID) are sent to a backend the user
   controls.

The App Store Connect disclosure must cover the **worst-case** data flow —
i.e., what happens when cloud sync is enabled.

---

## Section 1 — Data Collection

> "Does this app collect data?"

**Answer**: **Yes** — but only when the user explicitly enables cloud sync.
Disclose the data types below.

### Types Collected

| Data Type | Collected? | Linked to User? | Used for Tracking? | Purpose |
|-----------|------------|-----------------|--------------------|---------|
| **Health & Fitness → Other Health Data** (emotional state entries, self-care strategy usage) | Yes, when cloud sync is on | Linked to a random pseudo-user ID generated on device | No | App Functionality, Analytics |
| **User Content → Other User Content** (journal entries and the layer/phase/strategy metadata chosen) | Yes, when cloud sync is on | Linked to the same pseudo-user ID | No | App Functionality |
| **Identifiers → User ID** (random UUID generated in `UserDefaults`) | Yes, when cloud sync is on | Linked to entries | No | App Functionality |
| **Diagnostics → Crash Data** | Not collected at launch | — | — | Out of scope for v1.0. |
| **Contact Info** | Not collected | — | — | — |
| **Location** | Not collected | — | — | — |
| **Contacts** | Not collected | — | — | — |
| **Browsing/Search History** | Not collected | — | — | — |
| **Purchases** | Not collected | — | — | — |
| **Financial Info** | Not collected | — | — | — |
| **Sensitive Info** | Not collected | — | — | — |
| **Usage Data** | Not collected | — | — | — |

### Field-by-field answers for Health & Fitness data

- **Purposes**: App Functionality, Analytics.
- **Is this data linked to the user's identity?** Yes (to the random pseudo-
  user ID, which is not linked to Apple ID, email, name, or device ID).
- **Is this data used for tracking?** No. The app does not share it with third
  parties and does not combine it with data from other apps or websites.

### Field-by-field answers for User Content

- **Purposes**: App Functionality.
- **Linked to user?** Yes, to the pseudo-user ID.
- **Used for tracking?** No.

### Field-by-field answers for User ID

- **Purposes**: App Functionality.
- **Linked to user?** Yes (it *is* the linkage mechanism).
- **Used for tracking?** No.

---

## Section 2 — Third-Party SDKs

WavelengthWatch does **not** include any third-party analytics SDKs, ad SDKs,
or crash reporters at launch. When App Store Connect asks:

> "Does the app include any third-party SDKs or code that collect data?"

Answer: **No**.

---

## Section 3 — Privacy Policy URL

Enter the canonical privacy policy URL from
`store-assets/metadata/app-store-metadata.md`:

```
https://wavelengthwatch.app/privacy
```

This must serve the document stored in
`store-assets/privacy-policy/privacy-policy.md`.

---

## Section 4 — Privacy Nutrition Label Preview

The expected rendered labels are:

- **Data Used to Track You**: *None*.
- **Data Linked to You**: Health & Fitness; User Content; Identifiers.
- **Data Not Linked to You**: *None*.

If cloud sync is disabled, the effective collection is *None*; however, Apple
requires the label to reflect the worst case. The app's Settings screen
clearly explains this to users before they enable sync.

---

## Section 5 — Data Deletion & Export

Apple (and GDPR) require users to be able to delete and export their data.
WavelengthWatch handles this as follows:

| Capability | v1.0 status |
|------------|-------------|
| Delete on-device entries | Implemented — via Settings → Delete All Entries. |
| Delete cloud-synced entries | v1.0 scope: user disables cloud sync, then contacts `support@wavelengthwatch.app` to request deletion; backend team removes entries within 30 days. Self-service deletion tracked as a follow-on issue for v1.1. |
| Export entries | v1.0 scope: manual export via the `/api/v1/journal` endpoint for cloud-sync users. Local-only users retain the SQLite database, which is replaced by a proper export in v1.1 (see Epic #244). |
| Account deletion | No account exists. Deleting the app removes the local database; the pseudo-user ID is regenerated if the app is reinstalled. |

Document these limitations in the privacy policy so the App Review team can
match our stated behavior against the submitted disclosures.

---

## Section 6 — Periodic Review

Re-verify this document whenever any of the following change:

- New data types are collected.
- A third-party SDK is added (analytics, crash reporting, ads, auth).
- The cloud sync default changes from opt-in to on-by-default.
- HealthKit integration is added.
- Background modes are enabled beyond the current set.

A mismatch between this document and what App Store Connect shows is a
submission blocker.
