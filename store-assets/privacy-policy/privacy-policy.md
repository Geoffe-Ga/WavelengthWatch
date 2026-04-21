# WavelengthWatch Privacy Policy

**Effective date**: *Set to the App Store approval date before publishing.*
**Last updated**: 2026-04-21
**Canonical URL**: `https://wavelengthwatch.app/privacy`

WavelengthWatch is designed to be a private, offline-first journal for your
emotional life. This policy explains what the app does and does not do with
your data. We write it plainly because the product is plain.

## 1. Who we are

- **Controller**: Geoffrey Eisenbarth ("we", "us", "our").
- **Contact**: `support@wavelengthwatch.app`
- **Jurisdiction**: United States. We apply GDPR rights to all users regardless
  of where they live.

## 2. The short version

- By default, your journal entries never leave your Apple Watch. They are
  stored in an on-device SQLite database.
- Cloud sync is **opt-in**. You turn it on deliberately in Settings, and you
  can turn it off at any time.
- If you turn cloud sync on, the app sends your journal entries, the
  curriculum you tagged them with, and a randomly generated pseudo-user ID to
  a backend you (or we) control. That pseudo-user ID is not linked to your
  Apple ID, email address, name, or any device identifier.
- We do not sell your data.
- We do not share your data with advertisers.
- We do not include third-party analytics, advertising, or crash-reporting
  SDKs.

## 3. What we collect, and when

### 3.1 Always — on your device

The following data lives only on your Apple Watch:

- The timestamps and content of your journal entries (layer, phase,
  curriculum item, self-care strategy).
- Your selected layer/phase state so the app can resume where you left off.
- A locally generated pseudo-user UUID stored in `UserDefaults`. This ID
  exists so that entries can later be grouped if you ever enable cloud sync.

This data is removed when you uninstall the app or tap **Settings → Delete
All Entries**.

### 3.2 Only when cloud sync is enabled

If you turn cloud sync on in Settings, the app transmits the same journal
entries described above to a backend server. The payload for each entry
contains:

- Timestamp (UTC).
- Layer, phase, curriculum, and strategy identifiers you selected.
- The random pseudo-user UUID described in Section 3.1.

We do **not** transmit:

- Your Apple ID or iCloud account details.
- Your name, email, or phone number.
- Your device identifier (IDFA, IDFV, MAC address, or serial).
- Your location.
- Any HealthKit data.

### 3.3 What we never collect

- We do not request HealthKit access at launch.
- We do not request access to your contacts, microphone, camera, motion
  sensors, location, or Bluetooth devices.
- We do not embed a browser or load remote web content inside the app.
- We do not include advertising or analytics SDKs (Google Analytics,
  Firebase, Amplitude, Mixpanel, Segment, Meta, TikTok, or similar).

## 4. How we use data

Cloud-synced journal data is used only to:

1. Show you your own history when you open the app on a paired device.
2. Compute on-server analytics views that are returned only to your watch,
   identified by your pseudo-user UUID.

We do not profile you, target you, sell derived insights, or train machine-
learning models on your data.

## 5. Legal basis (GDPR)

For users in the European Economic Area, the UK, or other GDPR-aligned
jurisdictions:

- On-device processing relies on the **legitimate interest** of operating the
  app you asked for.
- Cloud sync relies on your **explicit consent**, given by toggling sync on in
  Settings. Withdrawing consent (toggling sync off, or deleting the app)
  stops future transmission immediately.

## 6. Your rights

Regardless of where you live, you may:

- **Access** — Export journal data by turning cloud sync on and querying the
  `/api/v1/journal` endpoint for your pseudo-user UUID. (A first-party
  export UI is planned for v1.1.)
- **Correct** — Re-log or delete individual entries inside the app.
- **Delete** — Tap **Settings → Delete All Entries** to remove all on-device
  data. To delete cloud-synced entries, turn cloud sync off and email
  `support@wavelengthwatch.app`; we will delete all rows tied to your
  pseudo-user UUID within 30 days.
- **Portability** — Receive a JSON copy of your cloud-synced entries on
  request.
- **Withdraw consent** — Toggle cloud sync off at any time.
- **Complain** — Contact your local data protection authority if you believe
  we have violated your rights.

We do not discriminate against users for exercising any of these rights.

## 7. Data retention

- On-device data is retained until you delete entries or uninstall the app.
- Cloud-synced data is retained indefinitely unless you request deletion, at
  which point it is purged within 30 days.
- Request logs on the backend (IP address, request path, response code) are
  retained for no more than 14 days for abuse prevention and are not linked
  to your pseudo-user UUID.

## 8. Children

WavelengthWatch is rated 4+ but is not directed at children. We do not
knowingly collect information about children under 13. If you believe a child
has provided data through cloud sync, contact us and we will delete it.

## 9. International transfers

If cloud sync is enabled and you are located outside the country hosting the
backend, your data may be transferred across borders. We rely on standard
contractual clauses where applicable.

## 10. Security

- On-device data is stored in the app's sandboxed container and protected by
  iOS/watchOS file encryption when the device is locked.
- Cloud sync uses HTTPS/TLS for every request.
- Pseudo-user UUIDs are random values, not derived from personal identifiers.

No system is perfectly secure. If we learn of a breach affecting your data,
we will notify affected users and the relevant authorities as required by
law.

## 11. Third parties

We do not share your data with third parties. The backend is operated by us
(or, if you self-host, by you). There are no advertising partners, data
brokers, or analytics vendors.

If this ever changes, we will update this policy and the App Privacy details
in App Store Connect, and we will notify users through the app before the
change takes effect.

## 12. Changes to this policy

Material changes will be announced in the app's release notes and at the top
of this page. The "Last updated" date at the top will always reflect the most
recent revision. Historical versions are kept in the project Git history at
`store-assets/privacy-policy/privacy-policy.md`.

## 13. Contact

- Privacy questions: `support@wavelengthwatch.app`
- Data deletion or export requests: `support@wavelengthwatch.app` with the
  subject line "Data request"
- Source: https://github.com/Geoffe-Ga/WavelengthWatch
