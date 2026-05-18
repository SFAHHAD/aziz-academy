# App Store Kids-Category Compliance Checklist

Both Apple "Made for Kids" and Google "Designed for Families" require
substantially the same posture. This is the launch checklist.

## Apple — Kids Category (5.1.4)

- [x] No third-party advertising SDK
- [x] No third-party analytics SDK
- [x] No external links to web pages outside the app from gameplay screens
- [x] Parental gate before any non-gameplay action that could initiate
  purchases, share content externally, or change app behavior
  (`/parent` requires a math gate)
- [x] No collection of personal info from children
- [x] In-app purchases (none today; if added later → guard behind gate)
- [x] No social network features
- [x] Privacy policy linked from inside the app (`/privacy`)
- [x] Age range declaration in App Store Connect: **6–8** primary,
  **9–11** secondary

## Google — Designed for Families

- [x] App content age-appropriate
- [x] No interest-based ads
- [x] No personally identifiable information collected
- [x] Comply with the Families Policy
- [x] Privacy policy URL set in Play Console
- [x] Target API level current (managed by Flutter)

## Common gates we still need before submission

- [ ] Real `privacy@aziz-academy.app` mailbox (placeholder today)
- [ ] App Store Connect privacy questionnaire filled out
  (the answer is mostly "Data Not Collected" given no remote backend)
- [ ] Screenshots showing the parent gate and on-device-only badge
- [ ] Localized Arabic store listing copy

## Web (Vercel) considerations

The web build also targets kids; same posture applies:

- [x] No third-party fonts/scripts that drop tracking cookies
- [x] PWA manifest declares the app as `kids` category
- [x] Service worker caches assets only — no network telemetry
- [ ] Add `Permissions-Policy` header to deny camera/mic/geolocation
  (planned in `vercel.ts`)
