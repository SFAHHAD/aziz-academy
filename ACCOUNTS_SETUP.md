# Accounts — setup checklist (Apple / Google sign-in)

The accounts system runs on **Supabase** (project `aziz-academy`, ref
`pwdhwhpnwrlzrerrdqvg`, Q8VISION org, eu-central-1).

**Already working — no setup needed:**
- Guest mode (no registration)
- **Email** parent accounts — sign up / sign in / sign out
- **Cloud backup & restore** of all progress (the `account_sync` table)

**This document covers the one thing left:** enabling **Apple** and
**Google** sign-in. Those require OAuth credentials that only you can
create — Apple and Google issue them exclusively to the verified account
owner. Once done, ping me and I flip the Apple/Google buttons on
`/account` from "(soon)" to live (the Flutter side is a small, ready
change: `auth.signInWithOAuth`).

---

## A. Google sign-in  *(~10 min)*

1. **Google Cloud Console** → APIs & Services → Credentials → **Create
   credentials → OAuth client ID** → type **Web application**.
2. Authorized JavaScript origins:
   - `https://aziz-academy.com`
   - `https://pwdhwhpnwrlzrerrdqvg.supabase.co`
3. Authorized redirect URI:
   - `https://pwdhwhpnwrlzrerrdqvg.supabase.co/auth/v1/callback`
4. Copy the **Client ID** and **Client secret**.
5. **Supabase dashboard** → Authentication → Providers → **Google** →
   enable, paste the Client ID + Client secret, Save.

## B. Apple sign-in  *(~15 min, needs an Apple Developer account)*

1. **Apple Developer** → Certificates, IDs & Profiles → Identifiers →
   **Services ID** (e.g. `com.q8vision.azizacademy.web`). Enable
   **Sign In with Apple**, then **Configure**:
   - Primary App ID: your iOS app id
   - Domains: `aziz-academy.com`
   - Return URL: `https://pwdhwhpnwrlzrerrdqvg.supabase.co/auth/v1/callback`
2. Create a **Key** with **Sign In with Apple** enabled — download the
   `.p8` (one-time download). Note the **Key ID** and your **Team ID**.
3. **Supabase dashboard** → Authentication → Providers → **Apple** →
   enable. Provide the **Services ID** as the client id, and the secret
   (Supabase accepts the Team ID + Key ID + `.p8` contents to build the
   client secret). Save.

> The `.p8` key, Team ID and Google client secret are secrets — they
> live only in the Apple / Supabase dashboards. Never commit them.

## C. Supabase URL configuration  *(~2 min)*

Supabase dashboard → Authentication → **URL Configuration**:
- Site URL: `https://aziz-academy.com`
- Additional redirect URLs: add `https://aziz-academy.com` and, for
  local testing, `http://localhost`.

## D. Then tell me

When A–C are done I will:
- Add `signInWithOAuth(OAuthProvider.google / .apple)` to `AuthService`.
- Replace the "(soon)" Apple/Google buttons on `/account` with live
  ones (still behind the parental gate).
- Deploy.

No app rebuild is needed from you — just the dashboard work above.

---

## Where the accounts roadmap stands

| Phase | Scope | State |
|---|---|---|
| 1a | Guest identity + parental gate + Account screen | ✅ v1.1.110 |
| 1b | Email parent accounts (Supabase) | ✅ v1.1.111 |
| 1b+ | Apple / Google sign-in | ⬜ blocked on A–C above |
| 2 | Cloud backup & restore of progress | ✅ v1.1.112 |
| 3 | Monetization (pricing model + Stripe / store IAP) | ⬜ needs a pricing decision + your payment accounts |
| 4 | School / classroom (teacher accounts, class codes, licensing) | ⬜ separate B2B project — needs scoping |

### Privacy copy

Now that opt-in cloud backup ships, the "on-device only" wording in
`web/index.html` meta, `manifest.json`, and the store listings should
become the honest: **"guest by default · optional private cloud backup
· no ads · no behavioural tracking."** (Tracked as a copy task.)
