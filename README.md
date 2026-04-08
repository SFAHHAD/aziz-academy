# أكاديمية عزيز — Aziz Academy

> An interactive educational app for kids aged 8–12: geography, flags, maps, logos, math, and sciences — with achievements and daily streaks.

---

## About

**Aziz Academy** is a Flutter app built around a **navy & gold** brand. It includes quizzes, an interactive map flow, text-to-speech, audio feedback, and a trophy room for badges.

## Modules

| Module | Route | Description |
|--------|-------|-------------|
| **Capitals** | `/capitals` | Match countries to capitals |
| **Flags** | `/flags` | Guess the country from the flag |
| **Maps** | `/maps` | Explore continents and map quizzes |
| **Logos** | `/logos` | Recognise brand logos |
| **Sciences** | `/sciences` | Science & discovery questions |
| **Math** | `/math` | Arithmetic challenges |
| **Trophy room** | `/trophy` | Badges and cups (قاعة الكؤوس) |
| **Privacy** | `/privacy` | Summary for parents (Arabic) |

## Tech stack

- **Flutter** (Dart ^3.11)
- **State:** Riverpod
- **Navigation:** GoRouter
- **Localisation:** `flutter gen-l10n` (Arabic is the default runtime locale in `main.dart`; English ARBs remain for future use)
- **Persistence:** SharedPreferences (achievements, streaks, quiz stats)
- **Maps:** flutter_map + latlong2
- **Audio / TTS:** audioplayers, flutter_tts

## Getting started

```bash
flutter pub get
flutter run
```

### Quality checks (same as CI)

```bash
flutter analyze --fatal-infos --fatal-warnings
flutter test
```

### Deploy (all options)

| Target | How |
|--------|-----|
| **GitHub** (source + CI) | Push to `main` / `master` — `flutter_ci.yml` runs analyze, test, and web builds. |
| **GitHub Pages** | Repo → **Settings → Pages → Build and deployment → Source: GitHub Actions**. On each push to `main`/`master`, `deploy_github_pages.yml` builds and publishes `build/web` (SPA uses `404.html` = `index.html` for client routes). |
| **Vercel** | Install Node, run `npx vercel login` once. Preview: `.\scripts\deploy_web.ps1` · Production: `.\scripts\deploy_web.ps1 --prod` · Or combined: `.\scripts\deploy_all.ps1` / `.\scripts\deploy_all.ps1 -VercelProd` |
| **Firebase Hosting** | [Firebase Console](https://console.firebase.google.com) → create project → Hosting. Copy `.firebaserc.example` to `.firebaserc` and set your project id. `npm i -g firebase-tools` → `firebase login` → `.\scripts\deploy_firebase.ps1` · Or: `.\scripts\deploy_all.ps1 -VercelProd -Firebase` after `.firebaserc` exists. |

`vercel.json` in the repo root is copied into `build/web` for SPA rewrites on Vercel. Firebase uses `firebase.json` rewrites instead.

The repo remote is **GitHub**; push to enable CI and (once Pages is configured) automatic static hosting.

## Project layout

```
lib/
  core/           theme, router, providers, services, models
  features/       home, maps, capitals, flags, logos, math, sciences, achievements, legal
  l10n/           generated localisations
assets/
  data/           JSON quiz datasets
  images/         flags, logos, branding
test/             unit + widget tests
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for conventions and how to add quiz data.

## Brand

- **Primary:** Navy `#1B2A6B`
- **Accent:** Gold `#C9A84C`
- **Fonts:** Cairo (Arabic) / Nunito (English copy where used)

## Privacy & data

Quiz content and progress are stored **on-device** (SharedPreferences). No remote account is required for the flows in this repo.

---

For CI, this project includes a GitHub Actions workflow (`.github/workflows/flutter_ci.yml`) that runs `flutter analyze` and `flutter test` on push/PR to `main` or `master`.
