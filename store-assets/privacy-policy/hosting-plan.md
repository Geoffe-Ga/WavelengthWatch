# Privacy Policy Hosting Plan

The App Store requires a publicly resolvable URL for the privacy policy. This
document captures how to publish `privacy-policy.md` so the URL in
`store-assets/metadata/app-store-metadata.md` resolves.

## Recommended: GitHub Pages from this repository

1. Create a `docs/site/` directory (out of scope for this issue — open a
   follow-on).
2. Add a minimal static site (plain HTML is fine) that renders
   `privacy-policy.md`. Options:
   - Jekyll default theme (`theme: jekyll-theme-cayman`).
   - A single `privacy.html` that embeds the policy directly, to avoid a
     build step.
3. Enable GitHub Pages → source: `docs/` on `main`.
4. Configure a custom domain: `wavelengthwatch.app`.
   - Add `CNAME` file in `docs/site/` containing `wavelengthwatch.app`.
   - Configure DNS: `CNAME wavelengthwatch.app -> geoffe-ga.github.io`.
5. Verify `https://wavelengthwatch.app/privacy` resolves and renders the
   policy before entering the URL into App Store Connect.

### Fallback URL

If the custom domain is not configured in time for submission, enter the
GitHub Pages URL directly:

```
https://geoffe-ga.github.io/WavelengthWatch/privacy.html
```

Apple allows metadata-only resubmission, so you can swap to the custom
domain after initial approval without a new binary.

## Alternative: Simple static host

Any host that serves HTTPS is acceptable:

- Cloudflare Pages
- Netlify
- Vercel
- A static HTML file on an existing personal site

In all cases, keep the canonical source in this repository at
`store-assets/privacy-policy/privacy-policy.md`. Sync changes to the host via
CI or a manual `make publish` step when the policy is updated.

## Change-management requirements

- Bump the "Last updated" date at the top of the policy whenever the content
  changes.
- If the change is material (new data types collected, new third parties,
  default-sync changes), also update `app-privacy-details.md` and file a new
  App Store Connect privacy update.
- Announce material changes in the next release's "What's New" copy so users
  are on notice.
