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
| **Trophy room** | `/trophy` | Badges and progress |

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

## Project layout

```
lib/
  core/           theme, router, providers, services, models
  features/       home, maps, capitals, flags, logos, math, sciences, achievements
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
