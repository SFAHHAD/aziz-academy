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

### Google Play & Apple App Store

**No Mac?** Follow the full checklist: **[docs/IOS_RELEASE_NO_MAC.md](docs/IOS_RELEASE_NO_MAC.md)** (GitHub Actions builds the iOS `.ipa` on Apple’s cloud Mac; you only add secrets and run the workflow). Secrets checklist: [docs/github_actions_secrets_checklist.txt](docs/github_actions_secrets_checklist.txt).

**Versioning:** Bump `version:` in `pubspec.yaml` (e.g. `1.0.1+5`) before each store upload — `+` number is Android `versionCode` / iOS build.

| Platform | Bundle ID | Build |
|----------|-----------|--------|
| **Android** | `com.azizacademy.aziz_academy` | `.\scripts\build_play_store.ps1` → uploads `build/app/outputs/bundle/release/app-release.aab` in [Play Console](https://play.google.com/console). |
| **iOS** | `com.azizacademy.azizAcademy` | On a Mac with Xcode: `.\scripts\build_app_store.ps1` → `build/ios/ipa/`, or Archive from Xcode. |

**Android signing (required for Play uploads):**

1. Copy `android/key.properties.example` to `android/key.properties` (gitignored).
2. Create an upload keystore under `android/app/` (see comments in the example file) and point `storeFile` at it.
3. Re-run `build_play_store.ps1` — release builds use that keystore when `key.properties` exists; otherwise they still sign with the debug key (fine for local testing only).

**iOS signing:** Open `ios/Runner.xcworkspace` in Xcode → **Runner** target → **Signing & Capabilities** → select your Team. `ITSAppUsesNonExemptEncryption` is set to **no** in `Info.plist` (standard for apps that only use HTTPS APIs like font loading).

**App Store Connect API (upload without Xcode Organizer):** In [App Store Connect](https://appstoreconnect.apple.com) → **Users and Access** → **Integrations** → **App Store Connect API**, create a key with **Admin** or **App Manager** access. Your downloaded key is `AuthKey_<KeyID>.p8` (for example Key ID `SWKQYRLMSP`). **Do not commit `.p8` files** — copy once to `~/.appstoreconnect/private_keys/` on your Mac. Copy `scripts/app_store_connect.env.example` to `scripts/app_store_connect.env`, set **Issuer ID** and **Key ID**, then after `flutter build ipa` run `scripts/upload_ipa_appstore_connect.ps1` (macOS only).

**GitHub Actions — release both stores:** Workflow **Release — Play & TestFlight** (`.github/workflows/release_stores.yml`) builds signed **`.aab`** and **`.ipa`** and uploads to Google Play and App Store Connect. In the repo → **Settings → Secrets and variables → Actions**, add:

| Secret | Used for |
|--------|----------|
| `ANDROID_KEYSTORE_BASE64` | Base64 of your Play upload `upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | Optional; defaults to `upload` if omitted |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Full JSON of a Play Console [API service account](https://developers.google.com/android-publisher/getting_started) (JSON key file contents) |
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Base64 of **Apple Distribution** `.p12` (export from Keychain or create in Apple Developer) |
| `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | `.p12` export password |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64 of **App Store** provisioning profile for `com.azizacademy.azizAcademy` |
| `IOS_TEAM_ID` | 10-character Apple Team ID |
| `IOS_PROVISIONING_PROFILE_NAME` | Exact profile **Name** from developer.apple.com (not the file name) |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer UUID from App Store Connect API page |
| `APP_STORE_CONNECT_KEY_ID` | e.g. `SWKQYRLMSP` |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64 of the entire `AuthKey_*.p8` file |

Encode binary files for secrets: PowerShell `.\scripts\encode_file_base64.ps1 -Path your.jks -CopyToClipboard` (or print without `-CopyToClipboard`). macOS/Linux: `base64 -i file.jks`.

Then **Actions → Release — Play & TestFlight → Run workflow** (choose Play track; toggle Android / iOS). The app record must already exist in [Play Console](https://play.google.com/console) and [App Store Connect](https://appstoreconnect.apple.com) with matching bundle IDs.

**Privacy:** `ios/Runner/PrivacyInfo.xcprivacy` declares UserDefaults access (used by `shared_preferences`). Adjust if Apple requests more detail.

**Store listings:** You still need screenshots, descriptions, age rating, Data safety (Play), Privacy Nutrition Labels (App Store), and — for kids’ apps — compliance with each store’s family / children policies.

If `flutter build appbundle` fails with *failed to strip debug symbols*, update the Android NDK in Android Studio SDK Manager or see [Flutter issue #181031](https://github.com/flutter/flutter/issues/181031) for NDK/AGP workarounds.

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
