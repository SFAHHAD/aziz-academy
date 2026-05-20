# Authentication & Parental Gate — Design Decision

_Last reviewed: 2026-05-18._

## Decisions

1. **Signup is open to multiple providers, no parental gate in front.** Available auth methods, in this order:
   1. **Phone OTP** — `+<country><number>`, SMS code. Lowest friction in MENA where many parents prefer phone over email.
   2. **Google** — one-tap on Android, popup on web/iOS.
   3. **Apple** — required on iOS to ship in App Store if any third-party SSO is offered.
   4. **Email + password** — kept as fallback for users without phone or social.
2. **The parental gate (math challenge) is preserved**, but moved from "blocks signup" to "blocks high-stakes operations":
   - Enable ads (when Phase 4 ships)
   - Delete account / export data
   - Sign in to an existing account on a shared device
   - Manage child profiles' age band, gender, school
   - Change locale of the device-level settings
3. **Identity is parent-only.** Children have **profiles** (up to 4 per family, already supported). Children do not sign in; they tap a profile tile. This is the COPPA-safe pattern.

## Why this design

- **More signups, more revenue.** Friction directly correlates with conversion. Phone+social methods typically 2-3× email-only conversion.
- **Compliance preserved.** Because the account holder is an adult parent and child profiles store only an age band + display name (no email, no phone, no PII), COPPA's parental-consent requirement is naturally satisfied by signup itself — Supabase auth is the adult, child data is derived under that adult.
- **No surface-area regression.** Stripping the gate from in front of signup doesn't expose any kid-facing flow that wasn't already open (browsing as a guest is allowed today; signup is upgrading from guest to family).

## What still requires the parental gate (post-change)

| Surface | Gate required? | Why |
|---|---|---|
| Open the app, pick a profile, play quizzes | ❌ | Kid surface; no PII |
| Sign up with phone / Google / Apple / email | ❌ | Adult provider auth is the consent |
| Sign in to an existing account | ✅ | Defence against a kid signing in to someone else's account |
| Open Parent Dashboard | ❌ (once signed in) | Account holder is the parent |
| Delete account / export data | ✅ | Irreversible, high-stakes |
| Toggle ads on parent screens (Phase 4) | ✅ | Money / policy |
| Edit child profile age band / gender | ✅ | Affects recommendations |
| Sign out | ❌ | Always allowed |

## Implementation map

| Component | Status | File |
|---|---|---|
| Email auth | ✅ shipped | `lib/core/services/auth_service.dart` — `signInWithEmail`, `signUpWithEmail` |
| Google auth | ✅ scaffolded | `lib/core/services/auth_service.dart` — `signInWithGoogle()` |
| Apple auth | ✅ scaffolded | `lib/core/services/auth_service.dart` — `signInWithApple()` |
| Phone OTP send | ✅ scaffolded | `signInWithPhoneStart()` |
| Phone OTP verify | ✅ scaffolded | `signInWithPhoneVerify()` |
| Onboarding flow without gate | 🔧 needs UI change | `lib/features/onboarding/presentation/welcome_screen.dart` + the parent-account onboarding step |
| Parental gate on high-stakes ops | ✅ widget exists | `lib/core/widgets/parental_gate.dart` — `showParentalGate(...)` |

## Supabase provider setup (one-time)

The auth_service code is ready. The Supabase project itself needs the providers turned on. In your Supabase dashboard:

### Phone OTP

1. **Authentication → Providers → Phone → Enable.**
2. Pick an SMS provider: Twilio is the safest default. You get a Twilio account, create a "Verify Service", and paste the Account SID + Auth Token + Service SID into Supabase.
3. Whitelist countries you serve to keep your spend predictable. Start with KW, SA, AE, EG, QA, OM.
4. Test from the Supabase dashboard's "Send test SMS" before wiring the UI.

### Google

1. [Google Cloud Console](https://console.cloud.google.com) → Create OAuth 2.0 Client ID (Web application + iOS + Android each get their own client ID).
2. Authorized redirect URI for the web client:
   `https://pwdhwhpnwrlzrerrdqvg.supabase.co/auth/v1/callback`
3. Authentication → Providers → Google → paste the **web** client ID + secret. Save.
4. For Android: edit `android/app/build.gradle.kts` and add the Android client ID; for iOS, add to `ios/Runner/Info.plist`.

### Apple

1. [Apple Developer](https://developer.apple.com) → Identifiers → register a new **Services ID** with "Sign in with Apple" capability.
2. Configure the return URL:
   `https://pwdhwhpnwrlzrerrdqvg.supabase.co/auth/v1/callback`
3. Generate a **Sign in with Apple key** (download once — Apple won't show it again).
4. Authentication → Providers → Apple → paste Services ID, Team ID, Key ID, and the .p8 contents.

### Email

Already enabled. Configure SMTP if you want branded emails (Authentication → Email Templates).

## App-side changes needed (next session)

1. **Replace** the email-only auth sheet (`lib/features/account/presentation/email_auth_sheet.dart`) with a multi-provider sheet:
   - Top: 3 big buttons — Continue with Google · Continue with Apple · Continue with Phone
   - Below: collapsed "Use email and password instead" link
2. **Remove** the parental gate that currently runs INSIDE the email auth sheet before signup. Per the onboarding flow described in `CHANGELOG.md` 1.1.113, the parental gate ran "inside the email sheet — account creation stays a grown-up action." Move it to:
   - sign-in flow (gate before showing the sign-in form)
   - delete-account flow
   - ads-toggle flow
3. **Add** a new screen `lib/features/account/presentation/phone_otp_sheet.dart` for the phone flow (number entry → code entry → done).
4. **Add** deep-link return handling in `main.dart` for the OAuth callback (Supabase docs: `SupabaseAuth.initialDeeplinkObserver`).

These are mechanical edits — the scaffolding in `auth_service.dart` provides every call the UI needs.

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| Apple rejects iOS app because it has third-party (Google) sign-in but no "Sign in with Apple" | We're adding both. Apple's rule is "if you have any social SSO, you must also have Apple SSO." We satisfy that. |
| Phone OTP cost (each SMS ≈ $0.01–$0.05) | Whitelist countries; rate-limit by IP via Supabase's built-in rate-limit settings. |
| OAuth state CSRF | Supabase handles state token; we don't need to. |
| User signs in with Google then later with email and ends up with two accounts | Supabase merges by email when configured. Make sure that toggle is ON in Authentication → Providers → Email → "Confirm new users". |
| Gate removed from signup → some COPPA reviewer worries | The decision rationale above is the answer. Signup IS the parent's adult-provider consent. Children don't get accounts. |

## After this change ships

Update `docs/PRIVACY.md` to declare the new auth providers (Google, Apple, phone). The current PRIVACY.md describes only email; the list of identifying systems should grow to: Google account ID (via OAuth), Apple Sign-In identifier (private relay supported), phone number (E.164), email address.
