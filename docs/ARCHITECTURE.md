# Aziz Academy — Architecture

Audience: a new engineer or AI agent picking up this codebase. Read this once and you should be able to find your way around in 30 minutes.

Last reviewed: 2026-05-18 against `pubspec.yaml` v1.1.113+118.

---

## 1. What this app is

Aziz Academy is a Flutter app for kids aged 6–12 that ships to **web**, **Android**, and **iOS** from a single Dart codebase. The web build is the primary surface (live at https://aziz-academy.com); the mobile builds reach the Google Play "Designed for Families" track and the Apple App Store "Kids" category.

The product is a catalog of ~130 short bilingual activities — quizzes, brain games, action games, and Islamic-content learners — plus a parent dashboard, achievements / streaks, and a hidden admin console.

Brand: navy `#1B2A6B`, gold `#C9A84C`. Fonts: Cairo (AR), Nunito-where-used (EN), Amiri (Quran text), NotoColorEmoji (color emoji on platforms that don't ship them).

---

## 2. Layering

```
lib/
├── main.dart                      # bootstraps the app, NEVER blocks startup
├── core/                          # cross-cutting, no feature-specific code
│   ├── agents/                    # in-app AI helpers (tutor, mistake-pattern, etc.)
│   ├── data/                      # static bundled content (e.g. madrasati_data.dart)
│   ├── l10n/                      # localisation helpers used by core
│   ├── logic/                     # pure-Dart business rules with no Flutter deps
│   ├── models/                    # data classes; should be Freezed-style immutables
│   ├── providers/                 # Riverpod providers — 36 of them, mostly StateNotifier
│   ├── quiz/                      # shared quiz engines (multiple-choice, etc.)
│   ├── router/                    # GoRouter table (lib/core/router/app_router.dart)
│   ├── services/                  # IO boundary — see §4
│   ├── teaching/                  # adaptive-tutor scaffolding
│   ├── theme/                     # app_colors, app_theme, font fallback config
│   ├── utils/                     # pure helpers — date, math, gender-aware AR strings
│   └── widgets/                   # reusable widgets (BreakReminder, ErrorBoundary, …)
└── features/<name>/               # one folder per activity / screen group
    └── presentation/screens/      # (legacy nesting — see §6 "naming consistency")
```

**Rule:** features may depend on `core/`, never on each other. If two features need the same widget, lift it into `core/widgets/`.

---

## 3. Startup sequence (`lib/main.dart`)

```text
main()
├── WidgetsFlutterBinding.ensureInitialized()
├── ErrorWidget.builder = friendlyErrorWidgetBuilder       # bilingual error card
├── AdminErrorLog.install()                                # ring-buffer for /admin
├── AdminTraffic.recordAppOpen()                           # fire-and-forget metrics
├── await initSupabase()                                   # never throws
├── SystemChrome.setPreferredOrientations(...)             # mobile only
└── runApp(ProviderScope(child: AzizAcademyApp()))
```

Two principles:

- **Startup never blocks on the network.** `initSupabase()` swallows errors and sets `supabaseReady = false` — every code path then degrades to guest mode.
- **Startup never blocks on errors.** Both the framework error widget and uncaught framework errors are caught and surfaced gracefully.

---

## 4. Services (`lib/core/services/`)

Everything that touches the outside world or a platform API lives here, never in a widget.

| Service | Owns |
|---------|------|
| `supabase_bootstrap.dart` | Supabase init + public anon key + `supabaseReady` flag |
| `auth_service.dart` | Sign-up, sign-in, sign-out, sign-up errors. Safe to call when Supabase is down — returns `AuthResult.fail('backend_unavailable')`. |
| `sync_service.dart` | Push/pull a user's progress to Supabase rows. RLS-guarded server-side. |
| `audio_service.dart` | Generic playback wrapper over `audioplayers`. |
| `tts_service.dart`, `cloud_tts_service.dart` | Local + cloud TTS (cloud is feature-flagged). |
| `islamic_audio_service.dart`, `islamic_audio_registry.dart`, `quran_recitation_service.dart` | Surah / dua / hadith / azkar audio loading from CDN + local cache. |
| `connectivity_watcher*.dart` | Online/offline state. Web and IO have separate implementations selected by conditional import. |
| `local_backup_*.dart` | Parent-initiated JSON export / import of on-device progress. Web and IO platforms split. |
| `billing_config.dart` | Plus-tier entitlement constants (checkout itself is not wired yet — see backlog). |

**Pattern:** every service is a plain Dart class. Riverpod providers in `core/providers/` wrap them. UI code reads providers, never services directly.

---

## 5. State management

- **Library:** Riverpod (`flutter_riverpod ^3.3.1`), `ProviderScope` at the top of the tree in `main.dart`.
- **Providers live under `lib/core/providers/`.** Examples: `achievement_provider.dart` (859 lines — owns badge unlocks), `auth_session_provider.dart`, `premium_provider.dart`, `family_profiles_provider.dart`, `daily_quiz_streak_provider.dart`, `hijri_date_provider.dart`.
- **Conventions:**
  - `*Provider` if it's the canonical name, e.g. `achievementProvider`.
  - `StateNotifierProvider` for mutable state; `FutureProvider` for one-shot loads; `Provider` for stateless services.
  - Persistence layer is **SharedPreferences** (sync, on-device). When the user signs in, `sync_service.dart` mirrors selected keys to Supabase rows that are protected by RLS.
  - Tests should drive Riverpod via `ProviderContainer` directly, not `WidgetTester`, except for golden tests.

---

## 6. Routing (`lib/core/router/app_router.dart`)

GoRouter (`go_router ^17.1.0`), declared in one large table (1,889 lines — flagged for splitting in `AUDIT_PLAN.md` §3.1).

- Routes are namespaced by feature: `/capitals`, `/flags`, `/maps`, `/iq`, `/quran`, `/parent`, …
- The hidden admin console lives at `/x9k2-admin-portal`. Never link to it from the UI.
- Deep links resolve to the same routes — sitemap at `web/sitemap.xml` (137 URLs) drives SEO.

---

## 7. Localisation

- **ARB files under `lib/l10n/`**: `app_en.arb`, `app_ar.arb`. Tooling config in `l10n.yaml`.
- **Build step:** `flutter gen-l10n` (runs implicitly because `pubspec.yaml` has `generate: true`). Outputs `lib/l10n/app_localizations*.dart` — these are generated, **do not edit by hand**.
- **Runtime locale:** persisted via `localeProvider`; AR is default, EN is opt-in. RTL toggles automatically when locale is AR.
- **Adding a string:** add to **both** `app_en.arb` and `app_ar.arb`. A test (`test/.../l10n_*.dart`, to be added — see AUDIT_PLAN.md §5.2) should assert key parity.

---

## 8. Assets

- **`assets/data/*.json`** — every quiz pack, brain-game item set, Islamic content list. ~200 packs. Listed individually in `pubspec.yaml` today (AUDIT_PLAN.md §8.1 proposes switching to directory listing).
- **`assets/images/`** — flags (per ISO country code), logos (brand recognition activity), emojis (regenerated set), branding.
- **`assets/audio/`** — `hadith/`, `azkar/`, `names/`, `dua/`, `tajweed/`. Per-item MP3s. CDN-backed at runtime; bundle is the fallback.
- **`assets/lottie/`** — small animations for trophies and onboarding.
- **`assets/fonts/`** — Cairo, Amiri, NotoColorEmoji.

Authoring scripts live under `scripts/authoring/` (or — currently — at the repo root; AUDIT_PLAN.md §1.4 moves them).

---

## 9. Persistence model

**On-device only by default.**

| Layer | Where | Notes |
|-------|-------|-------|
| Settings (locale, theme, reduced motion, larger text, dyslexia font) | SharedPreferences via `appSettingsProvider` | Synced on sign-in if cloud is enabled. |
| Achievements, streaks, quiz bests | SharedPreferences keys, owned by `achievement_provider.dart` et al. | Mirrored to Supabase rows when signed in. |
| Family profiles (sibling switching) | SharedPreferences | Local first; cloud copy if parent is signed in. |
| Premium entitlement | `premium_provider.dart` reads from server (`entitlements` table) when signed in; falls back to free. | **Server-write-only**: client cannot INSERT/UPDATE this table. |

---

## 10. Supabase backend

- Project: `aziz-academy` (Q8VISION org, eu-central-1).
- Client URL + anon key are in `lib/core/services/supabase_bootstrap.dart`. The anon key is **public by design**; row-level security on every table is what actually protects data.
- See AUDIT_PLAN.md §4.1 for the RLS verification checklist.

---

## 11. Hidden surfaces

- **Admin console** at `/x9k2-admin-portal` — error log (ring buffer), traffic counters, content-pack inspector, self-audit linter. Never linked from UI. Code in `lib/features/admin/`.
- **Dev gallery** at `/dev` — widget gallery / design-system showcase for engineers. Code in `lib/features/dev/`.
- **Self-challenge & boss modes** — endgame difficulty unlocked via achievements; not in the main grid.

---

## 12. CI / CD

- `.github/workflows/flutter_ci.yml` and `ci.yml` — analyze + test (AUDIT_PLAN.md §6.1 consolidates).
- `.github/workflows/deploy_github_pages.yml` — builds `build/web` and publishes to GitHub Pages.
- `.github/workflows/release_stores.yml` — signed `.aab` to Play, signed `.ipa` to App Store Connect. Secrets enumerated in `README.md`.
- Vercel (production), Firebase Hosting (secondary), GitHub Pages (mirror) — all three deploy `build/web`.
- Local deploy commands live under `scripts/` (`deploy_web.ps1`, `deploy_firebase.ps1`, `deploy_all.ps1`, `build_play_store.ps1`, `build_app_store.ps1`).

---

## 13. Where to look first when…

| Goal | File / folder |
|------|---------------|
| Add a new activity | `lib/features/<name>/`, then register in `lib/features/home/activity_catalog.dart` and add a GoRouter entry in `lib/core/router/app_router.dart`. |
| Add a quiz content pack | New JSON under `assets/data/`, register in `pubspec.yaml` `flutter.assets`, add to `test/content/bundled_pools_test.dart` schema check. |
| Add a string | Edit both `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`, run `flutter gen-l10n`. |
| Tune theme | `lib/core/theme/app_colors.dart`, `app_theme.dart`. |
| Change route behavior | `lib/core/router/app_router.dart`. |
| Hook a server call | Add a service in `lib/core/services/`, wrap in a Riverpod provider in `lib/core/providers/`. |
| Fix a bug observed in production | Reproduce locally → check `lib/features/<name>/`; if it touches data sync, also check `sync_service.dart` and the relevant RLS policy. |

---

## 14. Glossary

- **Brain Boost** — the IQ/brain-training section (4 categories planned in v1; see `docs/notes/reply.md`).
- **Madrasati** — the Kuwait-curriculum-aligned learning section (data in `lib/core/data/madrasati_data.dart`, 8,829 lines, flagged for refactor).
- **Recap queue** — re-shows items the learner got wrong recently.
- **Trophy room** — `/trophy`, badge / cup display.
- **Plus** — `/plus`, paid tier (checkout not yet wired).
- **EveryAyah** — CDN host for Quran recitation audio.

---

## 15. Open architectural debts

Tracked in `AUDIT_PLAN.md`. Top three:

1. `lib/core/data/madrasati_data.dart` is 8,829 lines — should be JSON or split.
2. `lib/features/admin/admin_dashboard_screen.dart` is 5,932 lines — should be one file per section.
3. `lib/core/router/app_router.dart` is 1,889 lines — should be partitioned per feature.

These do not block shipping but every change near them is painful. Plan §3 sequences the cleanup.
