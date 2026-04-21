# App Review Notes

Copy the block below into App Store Connect → App Review Information → Notes.

```text
WavelengthWatch is a standalone watchOS app (no iPhone companion required).

How to exercise the full app without an account:
1. Launch the app on a paired Apple Watch or the watchOS simulator.
2. Swipe vertically to cycle through "layers" of emotional experience
   (Beige → Purple → Red → Blue → Orange → Green → Yellow → Turquoise).
3. Swipe horizontally to cycle through the Rising, Peaking, Falling, and
   Resting phases within each layer.
4. Tap any curriculum card to open a detail view that shows the medicinal
   and toxic expressions of that feeling.
5. Tap a self-care strategy to log an entry. A haptic confirms success.
6. Open the Settings tab to see the privacy toggle and on-device analytics.

Notes for the reviewer:
- The app works fully offline. The entire Archetypal Wavelength curriculum is
  bundled as JSON so airplane-mode testing will still exercise every screen.
- Cloud sync is OFF by default. No sign-in, no OAuth, no demo account needed.
- A random UUID is generated in UserDefaults to group entries if cloud sync
  is later enabled. It is not linked to Apple ID, email, name, or any device
  identifier.
- No HealthKit, location, contacts, microphone, camera, or Bluetooth
  permissions are requested.
- Crash reporting, analytics SDKs, and ad SDKs are not embedded.

If cloud sync needs to be tested:
- Open Settings → Cloud Sync → toggle ON.
- The app uses the backend URL configured at build time in
  APIConfiguration.plist. The submission build points at a reviewer-
  accessible development backend.

Contact for review questions: support@wavelengthwatch.app
```
