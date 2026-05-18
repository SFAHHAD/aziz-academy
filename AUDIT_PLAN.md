# Aziz Academy — Master Audit & Action Plan

Generated: 2026-05-18
Repo state at audit: v1.1.113+118 on `master`, 1,238 changed files, 582 untracked, 6.0 GB on disk (3.5 GB in `build/`).

This plan is sequenced so each phase leaves the repo in a shippable state. Do not skip Phase 0 — every later phase assumes you can roll back.

---

## Phase 0 — Safety net (do this FIRST, ~15 min)

Everything below mutates files. Before you touch anything:

1. **Tag the current state on disk** so you can always get back to it.
   ```bash
   git tag pre-audit-2026-05-18
   git push origin pre-audit-2026-05-18      # if you have a remote
   ```
2. **Create a working branch.** Do NOT do the cleanup on `master`.
   ```bash
   git checkout -b chore/audit-cleanup
   ```
3. **Stash or commit anything you actively care about RIGHT NOW.** With 1,238 dirty files, assume there is in-progress work mixed in. If you have no idea what's in there, run:
   ```bash
   git stash push -u -m "pre-audit safety stash"
   ```
   then re-apply later with `git stash pop`. This gives you a single restore point.
4. **Verify the app still builds at HEAD** before changing anything:
   ```bash
   flutter pub get
   flutter analyze --fatal-infos --fatal-warnings
   flutter test
   flutter build web --release
   ```
   If any of these are already red, fix them BEFORE cleanup — otherwise you won't know whether cleanup broke them.
5. **Confirm a remote backup exists.** Push the branch and the tag to GitHub. If the repo has never been pushed, do that now: a 6 GB local-only repo with no remote is an unacceptable bus-factor risk.

Exit criteria: tag exists, branch checked out, CI green at HEAD, remote up to date.

---

## Phase 1 — Repo hygiene & working-tree triage (1–3 days)

The repo is carrying ~3.5 GB of build artifacts, ~93 MB of loose root files, and a working tree with 1,238 modified + 582 untracked files. Until this is clean, every other phase is harder than it needs to be.

### 1.1 Inventory the dirty tree

Bucket every change by intent. Run these and save the output:

```bash
git diff --stat > /tmp/dirty_stat.txt
git status --short > /tmp/dirty_status.txt
git ls-files --others --exclude-standard > /tmp/untracked.txt
```

Then sort by directory:

```bash
git diff --name-only | awk -F/ '{print $1"/"$2}' | sort | uniq -c | sort -rn > /tmp/dirty_by_dir.txt
```

Expected buckets (from spot-check during audit):
- `assets/images/flags/*.png` — image regen
- `assets/data/*.json` — content updates
- `lib/features/*` and `lib/core/*` — actual code work
- `android/`, `ios/`, `web/` — platform tweaks
- Config (`pubspec.yaml`, `.github/workflows/*`, `analysis_options.yaml`)
- Root docs (README, CHANGELOG, DEPLOY, CONTRIBUTING)

### 1.2 Triage into logical commits

Aim for 5–15 commits that each tell a story. Suggested order:

1. `chore: gitignore temp files and build artifacts` (Phase 1.3 below)
2. `chore: move loose root notes to docs/notes/` (Phase 1.4)
3. `assets: regenerate flags` (one commit, just `assets/images/flags/`)
4. `assets: update content packs` (`assets/data/`)
5. `feat: ...` one commit per real feature (Madrasati, Brain Boost, account hub, etc.)
6. `docs: reconcile README and Aziz Academy.md` (Phase 2)
7. `ci: ...` workflow tweaks
8. `chore: bump deps` if any

Use `git add -p` or a UI like `lazygit` / GitHub Desktop / Sourcetree to stage by hunk. If a hunk doesn't fit a commit's story, leave it for the next one.

### 1.3 Fix `.gitignore`

Add these patterns (verify each is not already present before adding):

```gitignore
# --- Local temp media (recordings, downloads) ---
/temp_*.mp3
/temp_*.wav
/temp_*.m4a
/*.mp4

# --- Local web build artifacts at root ---
/AzizAcademy_WebBuild*.zip
/aziz-academy.com-*.log

# --- Ad-hoc author/scratch files at root ---
/Imprtant.txt
/Points.txt
/Reply.txt
/Research.txt
/analyze.txt
/analyze_output.txt
/build.txt
/build_log.txt
/emoji_scan.txt
/machine_analyze.txt
/machine_analyze_utf8.txt
/res.txt
/router_paths.txt
/sitemap_paths.txt
/web_log.txt
/New Text Document.txt
/lighthouse-report.html

# --- Coverage / profiling ---
/coverage/
/.flutter-test-results/
```

After updating, run:
```bash
git rm --cached -r .                         # un-stage everything
git add .                                    # re-stage with new ignore
git status                                   # confirm clutter is gone
```
DO NOT commit `git rm --cached -r .` blindly — review the resulting `git status` carefully. The point is to make ignored files actually be ignored on existing copies.

### 1.4 Move root clutter

Create `docs/notes/` and move loose `.txt` files there (preserve them — `Reply.txt` and `Imprtant.txt` have real context):

```bash
mkdir -p docs/notes
git mv Imprtant.txt docs/notes/important.md       # also fix the typo
git mv Points.txt docs/notes/points.md
git mv Reply.txt  docs/notes/reply.md
git mv Research.txt docs/notes/research.md
```

Delete the empties:
```bash
rm "New Text Document.txt" router_paths.txt
```

Move one-off Python authoring scripts already in repo root into `scripts/authoring/`:
```bash
mkdir -p scripts/authoring
git mv crop_v2.py download_audio.py extract_logo.py fetch_logos.py \
       fill_missing_capitals.py fix_flags.py fix_fun_facts.py \
       generate_capitals.py generate_logos.py generate_sciences.py \
       scripts/authoring/
```

Verify nothing in `.github/workflows/*.yml`, `pubspec.yaml`, or any script references the old paths:
```bash
grep -rE "crop_v2|download_audio|extract_logo|fetch_logos|fill_missing_capitals|fix_flags|fix_fun_facts|generate_capitals|generate_logos|generate_sciences" \
  .github scripts pubspec.yaml *.md 2>/dev/null
```

### 1.5 Purge `build/` from disk (optional, frees 3.5 GB)

```bash
flutter clean
```
This recreates fresh on next `flutter build`. Don't commit anything from `build/` — it's already gitignored.

### 1.6 Inspect the giant log

`aziz-academy.com-1778322930947.log` is 14 MB. Decide:
- If it's a one-off Vercel/CDN log dump, gitignore it and delete the local copy.
- If it has incident data you want to keep, move it to `docs/notes/incidents/` and compress (`gzip`).

### 1.7 Clean the `temp_*.mp3` files

These are ~80 MB of intermediate audio at the root (azkar, dua, hadith, names, tajweed, word). Decide:
- If they're already mirrored under `assets/audio/<category>/` after `collect_real_audio.py` ran, **delete them**.
- If they're sources for an in-progress regeneration, move to `scripts/authoring/_tmp_audio/` (gitignored) so they're out of the root.

Verify with:
```bash
ls -la assets/audio/azkar/ assets/audio/dua/ assets/audio/hadith/ \
       assets/audio/names/ assets/audio/tajweed/ | head -40
```

Exit criteria: `git status` < 20 lines, root has only directories + canonical files (README, pubspec, CHANGELOG, configs), `flutter build web --release` still works.

---

## Phase 2 — Documentation reconciliation (½–1 day)

You have two README-shaped files describing different apps. Pick one source of truth.

### 2.1 README vs `Aziz Academy.md`

`README.md` (the newer one) says: "130+ bilingual activities", lists 7 categories, references `lib/features/home/activity_catalog.dart` (131 entries as of v1.1.97).

`Aziz Academy.md` says: 8 modules — Capitals, Flags, Maps, Logos, Sciences, Math, Trophy, Privacy. This is the pre-v1.0 description.

**Action:** delete `Aziz Academy.md` OR rename it to `docs/HISTORY.md` and add a header noting it's the original feature scope from v0.x. The canonical project README is `README.md`.

### 2.2 Verify `README.md` itself is accurate

Re-read it line by line against current reality:

| Claim | How to verify |
|-------|--------------|
| "131 activities" | `grep -c "id:" lib/features/home/activity_catalog.dart` — also update the version number in the README comment |
| "Live at https://aziz-academy.com" | Curl it; check `vercel.json` redirects still point right |
| Vercel + Firebase + GitHub Pages deploy paths | Run each `scripts/deploy_*.ps1` end-to-end on a non-prod target once |
| `docs/IOS_RELEASE_NO_MAC.md` exists | `ls docs/IOS_RELEASE_NO_MAC.md` |
| Brand colors `#1B2A6B` / `#C9A84C` | `grep -rE "1B2A6B\|C9A84C" lib/core/theme/` |

### 2.3 CHANGELOG audit

`CHANGELOG.md` is 273 KB. That's enormous for a v1.x changelog. Options:
- **Keep as-is** if every entry has been useful (e.g., it's the actual release notes feeding store listings).
- **Archive old entries** below 1.0 to `docs/CHANGELOG_archive.md` and keep only the last ~6 months in the root.
- **Adopt [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format** consistently — looks like you already do, just verify.

Make sure the latest entry (`1.1.113`) matches `pubspec.yaml` (`1.1.113+118`). It does — good. Add a version-consistency check to CI (Phase 6.4).

### 2.4 CONTRIBUTING.md

Open it. Make sure it covers:
- Branch naming convention (`feat/...`, `fix/...`, `chore/...`)
- Commit message format (Conventional Commits, looking at your git log you already use them)
- How to add a new feature module (`lib/features/<name>/...` layout)
- How to add a quiz pack (`assets/data/<name>.json` + register in `pubspec.yaml`)
- How to add a new locale string (`lib/l10n/app_*.arb` → `flutter gen-l10n`)
- Running tests locally
- Lint expectations

If anything's missing, add it.

### 2.5 Architecture doc

Add `docs/ARCHITECTURE.md` covering:
- Layer responsibilities: `core/` vs `features/`
- State management: Riverpod providers, where each lives
- Routing: GoRouter route table location, deep-link conventions
- Persistence: SharedPreferences keys (list them or point at the constants file)
- Supabase: which tables, which RLS policies, which client-side providers read them
- Asset pipeline: where audio/flags/logos come from, how to regenerate

A diagram in mermaid is fine. Don't try to be exhaustive — the goal is to onboard a new engineer in 30 minutes.

### 2.6 Privacy policy + data safety

You ship to kids. Apple "Kids" and Google "Designed for Families" both require this. Check:
- `lib/features/legal/` has a privacy screen — does its content match what the app actually does?
- Is the privacy URL on the Play Console / App Store Connect listings publicly hosted (e.g., on aziz-academy.com)?
- Does the app actually only use on-device storage + Supabase? Any analytics SDK (`firebase_analytics`, Mixpanel, etc.) in `pubspec.yaml`? — none in the current `pubspec.yaml`, good.

Exit criteria: README accurately describes the live app, no duplicate/stale doc files, `docs/` has ARCHITECTURE + CONTRIBUTING + privacy policy, CHANGELOG matches pubspec version.

---

## Phase 3 — Code quality (1–2 weeks, parallelizable)

### 3.1 Break up the largest files

| File | Lines | Suggested split |
|------|-------|-----------------|
| `lib/core/data/madrasati_data.dart` | 8,829 | Split by subject/grade into `madrasati/<subject>_<grade>.dart`, or move to `assets/data/madrasati_*.json` and load at runtime |
| `lib/features/admin/admin_dashboard_screen.dart` | 5,932 | Split each admin section into its own widget under `lib/features/admin/sections/` |
| `lib/features/home/home_screen.dart` | 2,285 | Extract section widgets (subject grid, daily challenge banner, hijri header, etc.) |
| `lib/core/router/app_router.dart` | 1,889 | Group routes by feature into `app_router.<area>.dart` part files, or one route table per feature |
| `lib/features/home/activity_catalog.dart` | 1,649 | Acceptable if it's a flat catalog of 131 entries; consider moving to JSON if it's purely data |
| `lib/features/capitals/.../capitals_quiz_screen.dart` | 1,111 | Likely has reusable quiz scaffolding mixed with capitals-specific code — extract a `QuizScreenBase` into `core/quiz/` |
| `lib/features/sciences/.../sciences_quiz_screen.dart` | 1,084 | Same — should share scaffolding with capitals |

Do this one file at a time. After each split, run `flutter analyze` + `flutter test` and commit before moving to the next.

### 3.2 Hunt for hardcoded data that should be JSON

`madrasati_data.dart` and `activity_catalog.dart` look like prime candidates. Anything that is "list of records with no logic" belongs in `assets/data/*.json`, loaded once at startup, validated against a schema in a test.

### 3.3 Replace `debugPrint` with structured logging where it matters

28 `debugPrint`/`print` calls in `lib/`. Categorize:
- Genuine debug noise → leave or delete
- "This error happened in production but we silently swallowed it" → route through a real logger (`package:logging`) so you can disable in release and capture in dev.

Audit:
```bash
grep -rn "debugPrint\|print(" --include="*.dart" lib > /tmp/log_audit.txt
```

### 3.4 Enforce a stricter lint set

Current `analysis_options.yaml` extends `package:flutter_lints/flutter.yaml` and adds nothing. Consider:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore   # only if you use Freezed/json_serializable
    todo: ignore

linter:
  rules:
    always_use_package_imports: true
    avoid_dynamic_calls: true
    avoid_returning_null_for_future: true
    avoid_slow_async_io: true
    avoid_unused_constructor_parameters: true
    cancel_subscriptions: true
    close_sinks: true
    prefer_const_constructors: true
    prefer_const_constructors_in_immutables: true
    prefer_const_declarations: true
    prefer_const_literals_to_create_immutables: true
    prefer_final_locals: true
    prefer_single_quotes: true
    sort_pub_dependencies: true
    unawaited_futures: true
    use_super_parameters: true
```

Add lints **one at a time**, fix the resulting errors, commit, repeat. Do not add all at once — you'll get hundreds of errors and lose appetite.

### 3.5 Naming consistency

Spot-checked features list shows mixed conventions:
- Most features are `snake_case` directory names — good.
- Some files have inconsistent suffixes (`_screen.dart`, `_page.dart`, `screens/`, `presentation/screens/`). Pick one and migrate.

Rough rule:
- One feature = one folder under `lib/features/`
- Inside: `<feature>_screen.dart`, `<feature>_provider.dart`, `<feature>_models.dart`, plus a `widgets/` subfolder for sub-widgets.

`capitals/presentation/screens/` is over-nested for a Flutter app of this size. `features/capitals/capitals_screen.dart` + `features/capitals/widgets/...` is enough. But: only flatten this if you also update every `import` — search-and-replace + analyze pass.

### 3.6 Test coverage by feature

63 test files for 140 features. Many features have zero tests. List which ones:

```bash
for f in lib/features/*/; do
  name=$(basename "$f")
  count=$(find test -path "*${name}*" -name "*.dart" 2>/dev/null | wc -l)
  printf "%-30s %d\n" "$name" "$count"
done | sort -k2 -n
```

For the bottom of the list, write at minimum a smoke test that pumps the feature's main screen and asserts it doesn't throw. Pattern after `test/features/restructure_smoke_test.dart`.

Exit criteria: every file < ~1,000 lines, `flutter analyze` clean with the stricter lint set, every feature has at least one smoke test, no `print()` outside `if (kDebugMode)`.

---

## Phase 4 — Security & privacy (2–4 days)

### 4.1 Supabase RLS audit

`lib/core/services/supabase_bootstrap.dart` correctly notes that the anon key ships in the client and RLS is the real guard. Verify:

1. List every table the client reads/writes:
   ```bash
   grep -rE "\.from\(['\"]" --include="*.dart" lib | \
     sed -E "s/.*\.from\(['\"]([^'\"]+)['\"].*/\1/" | sort -u
   ```
2. For each, log into the [Supabase dashboard](https://supabase.com/dashboard) → your `aziz-academy` project → Authentication → Policies. Confirm every table has:
   - `enable row level security` ON
   - At least one policy for SELECT, and explicit policies for INSERT/UPDATE/DELETE if the client does them
   - `auth.uid() = user_id` (or equivalent) in every policy
3. Test as anon and as a fake-other-user:
   - Open the SQL editor in Supabase → `set role anon;` → try `select * from <table>;` → should return only your row.
   - Set `set local "request.jwt.claims" to '{"sub":"<some-other-uid>"}'` → confirm you can't read your own row through someone else's JWT.
4. Check the `entitlements` table (Plus subscription). The CHANGELOG says it's "server-write-only" — verify that policy actually exists and the client cannot INSERT/UPDATE.

### 4.2 Permissions audit

Open `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`. Confirm every permission is justified:
- `INTERNET` — yes, for Supabase + audio CDN
- `RECORD_AUDIO` — only if a feature genuinely uses the mic (do you?)
- Anything else — every kid-app extra permission is a Play Store review risk.

```bash
grep -E "uses-permission|NSUsageDescription" android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
```

### 4.3 Secrets sweep

Grep for accidentally-checked-in secrets:

```bash
git log -p --all -S "BEGIN PRIVATE KEY"
git log -p --all -S "BEGIN RSA PRIVATE KEY"
git log -p --all -S "service_role"
git log -p --all -S "SUPABASE_SERVICE"
git log -p --all -S ".p8"
git log -p --all --pickaxe-regex -S "[A-Za-z0-9_-]{40,}"   # high-entropy strings
```

If anything turns up, rotate the secret in the source system AND scrub history with `git filter-repo`. Notify yourself in a TODO comment if you're punting.

### 4.4 Dependencies CVE check

```bash
flutter pub outdated
flutter pub upgrade --dry-run
```

For each direct dependency in `pubspec.yaml`, glance at pub.dev for advisories:
- `audioplayers ^6.1.1`
- `go_router ^17.1.0`
- `flutter_riverpod ^3.3.1`
- `supabase_flutter ^2.8.0`
- `flutter_map ^8.2.2`
- `flutter_tts ^4.2.5`
- `share_plus ^12.0.2`
- `file_picker ^11.0.2`
- `url_launcher ^6.3.0`

Pin minor versions if you've been bitten by breaking changes; otherwise `^` is fine.

### 4.5 COPPA / GDPR-K / Kuwait-DPA compliance walkthrough

Reference: `docs/notes/important.md` (the auditor list).

- Identify every datum collected from a child: name, age band, score history, profile photo (if implemented), email (parent).
- For each, document: where stored (device-only? Supabase row?), how deleted, who can access.
- Parental consent flow: confirm the onboarding's parent-account step (introduced in 1.1.113) is the gate for cloud sync. Confirm child profile creation does NOT require email until/unless parent opts in.
- Add a "delete my data" path in the Parent dashboard. If Supabase rows exist, deleting must purge them server-side (`delete from <table> where user_id = auth.uid()`).
- Avoid third-party tracking SDKs. Confirm: none in `pubspec.yaml`.
- Write a one-page compliance summary in `docs/COMPLIANCE.md` that lawyers can read.

### 4.6 AI agent safety (if/when you ship the tutor)

`lib/core/agents/` exists. Before turning any LLM-backed agent on for end-users:
- Prompts are server-side OR signed; never let a child's free-text reach a model with no system-prompt scaffolding.
- Output is filtered for safety (Anthropic + OpenAI both have moderation endpoints — use them).
- Add a kill switch (a `featureFlag` you can flip without a release).
- Add a content escalation path: child reports inappropriate response → logged + reviewable.

Exit criteria: every Supabase table has tested RLS, no secrets in git history, permissions minimal, COPPA summary written, AI agents either gated behind a feature flag or have explicit safety review.

---

## Phase 5 — Testing strategy (1–2 weeks, ongoing)

### 5.1 Coverage baseline

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```
Note current coverage. Set a CI gate at "current - 1%" so it can never regress.

### 5.2 What to test

Tier 1 — must have:
- Every Riverpod provider that owns state (achievements, streaks, family profiles, premium, hijri, daily quiz). You already have most of these.
- Every quiz engine in `lib/core/quiz/` — give it a fixture pack, assert correct/incorrect counts, edge cases (empty pool, all wrong, all right).
- Every Supabase service: mock the client, assert that calls route correctly when `supabaseReady` is false.
- Every JSON content pack loads and validates against a schema (you already have `test/content/bundled_pools_test.dart` — extend it to cover all 200+ packs).

Tier 2 — should have:
- Smoke test per feature screen.
- Golden tests for the home screen, the trophy room, and one quiz screen in AR + EN + RTL.
- l10n drift test: every key in `app_en.arb` exists in `app_ar.arb` and vice versa.

Tier 3 — nice to have:
- Integration tests with `integration_test/` driving end-to-end flows (onboarding → first quiz → trophy unlock).
- Performance tests asserting first-frame budget on a CI emulator.

### 5.3 Test conventions

- One test file per source file under `test/<mirror_of_lib_path>/...`.
- Always use `ProviderContainer` directly (not `pumpWidget`) for provider tests — faster and isolation is cleaner.
- Use `WidgetTester.runAsync` for anything involving timers or audio.

Exit criteria: `flutter test` < 60 s, coverage gate in CI, every feature has a smoke test.

---

## Phase 6 — CI/CD (3–5 days)

Current workflows: `ci.yml`, `flutter_ci.yml`, `deploy_github_pages.yml`, `release_stores.yml`.

### 6.1 Consolidate

You have two CI workflows (`ci.yml` and `flutter_ci.yml`). Read both, merge, delete the redundant one.

### 6.2 Cache aggressively

In every workflow, cache:
- `~/.pub-cache`
- `.dart_tool/`
- Gradle: `~/.gradle/caches`, `~/.gradle/wrapper`
- iOS: `Pods/`, `~/Library/Developer/Xcode/DerivedData`

Pattern (GitHub Actions):
```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.pub-cache
      .dart_tool
    key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
```

### 6.3 CI matrix

Run `flutter analyze` + `flutter test` on Linux. Run `flutter build apk --debug` on Linux and `flutter build ios --no-codesign` on macOS — at minimum on PRs that touch `android/` or `ios/`.

### 6.4 Version consistency check

Add a CI step that asserts:
- `pubspec.yaml` version matches the top entry in `CHANGELOG.md`
- `android/app/build.gradle.kts` `versionName`/`versionCode` matches
- `ios/Runner/Info.plist` `CFBundleShortVersionString`/`CFBundleVersion` matches

You already have `scripts/audit_version_consistency.py`. Wire it into CI:
```yaml
- name: Version consistency
  run: python3 scripts/audit_version_consistency.py
```

### 6.5 Bundle-size budget

Add a step that builds the web bundle and fails if it exceeds N MB:
```bash
SIZE=$(du -k build/web | tail -1 | cut -f1)
test "$SIZE" -lt 30000 || { echo "Web bundle > 30 MB"; exit 1; }
```

### 6.6 Lighthouse on every web deploy

Already have `lighthouse-report.html` at root, presumably one-off. Wire `treosh/lighthouse-ci-action` into the GitHub Pages deploy workflow, fail PRs that regress Performance below 80 or A11y below 95.

### 6.7 Release workflow audit

Open `.github/workflows/release_stores.yml`. Confirm:
- Triggered only on a release tag (`v*.*.*`), not on every push.
- Reads every required secret from the list in `README.md` lines 88–103.
- Posts the resulting Play `.aab` and TestFlight build numbers to a Slack channel or commits a release note.

Exit criteria: one CI workflow, one release workflow, both green, secrets audit clean, version consistency enforced, bundle-size guard in place.

---

## Phase 7 — Store readiness (1–2 weeks per platform)

### 7.1 Pre-flight checklist (both stores)

- Bundle ID locked: Android `com.azizacademy.aziz_academy`, iOS `com.azizacademy.azizAcademy`.
- Version + build numbers consistent (see 6.4).
- App icon at every required size (use `flutter_launcher_icons` if not already).
- Splash/launch screen matches the navy/gold brand.
- Privacy policy URL is live and matches `docs/COMPLIANCE.md`.
- Support email is monitored.

### 7.2 Google Play (Designed for Families)

- Target API level meets Play's current bar (`android/app/build.gradle.kts` → `targetSdk`).
- Data Safety form filled in: declare on-device storage, Supabase, no analytics, no ads.
- Content rating: complete the IARC questionnaire as "ages 6–12".
- Family policy compliance: no behavioral ads, no third-party tracking, mediation parental gate before any external link or purchase.
- App content → Target audience → "Children" toggle.
- Pre-launch report green (Play runs your app on real devices automatically).
- Internal testing track green for 7 days before Production push.

### 7.3 Apple App Store (Kids Category)

- Kids category requires NO third-party analytics or advertising **and** a parental gate before any external link / external purchase.
- App Privacy nutrition labels filled in matching `docs/COMPLIANCE.md`.
- `ITSAppUsesNonExemptEncryption = NO` already set per README.
- `PrivacyInfo.xcprivacy` declares UserDefaults. Confirm no other declared APIs are missing.
- TestFlight internal testing green.
- App Review submission with a kid-friendly demo account.

### 7.4 Store listing assets

Generate (or commission) for each platform:
- Screenshots: 5–8 per device size, AR + EN, showing the home screen, a quiz, the trophy room, the parent dashboard, the Islamic section.
- Promo video: 30 sec.
- Feature graphic (Play): 1024×500.
- App Store hero (1.0): optional but punchy.
- Descriptions: short (80 chars), long (4000 chars), keywords (100 chars iOS). Both AR + EN.

Store assets go under `store/` (you already have the folder). Add a `store/README.md` with naming convention so a designer knows where each one belongs.

### 7.5 Localization for the store listings

You ship in AR + EN. Your store listing MUST also be in both — and ideally also `ar-SA`, `ar-KW`, etc. for Khaleeji markets, since search ranks per-locale.

Exit criteria: app is live on TestFlight + Play Internal Testing, every metadata field filled in both languages, privacy policy live, pre-launch reports clean.

---

## Phase 8 — Performance (3–5 days)

### 8.1 Bundle size

Current `pubspec.yaml` declares ~200 individual JSON asset paths, each individually listed. That's brittle (every new pack needs a line) and forces the entire `assets/data/` to be enumerated. Replace with a directory listing:

```yaml
flutter:
  assets:
    - assets/data/                  # whole dir
    - assets/images/
    - assets/images/flags/
    - assets/images/logos/
    - assets/images/emojis/
    - assets/audio/
    - assets/audio/hadith/
    - assets/audio/azkar/
    - assets/audio/names/
    - assets/audio/dua/
    - assets/audio/tajweed/
    - assets/lottie/
```

Then verify: `flutter pub get && flutter run` — confirm assets still resolve. If your pubspec uses individual files because you want to lazy-load some, document why.

### 8.2 Image audit

```bash
find assets/images -type f -name "*.png" -size +200k -exec ls -lh {} \;
```
For anything over 200 KB, run through `pngquant` (lossless-ish):
```bash
pngquant --quality=80-95 --skip-if-larger --ext .png --force assets/images/flags/*.png
```
Or convert to WebP if the supported Flutter widgets handle it.

### 8.3 Audio audit

`flutter analyze`-style sanity: every audio file referenced in code must exist in `assets/audio/`. You already have `scripts/audit_islamic_audio.py` — wire it into CI.

For size: `temp_*.mp3` are big because they're full chapter recordings. After the cleanup in 1.7, the production audio under `assets/audio/<cat>/` should be per-item, bitrate-controlled. Verify:
```bash
find assets/audio -type f -name "*.mp3" -exec ls -lh {} \; | awk '{print $5,$9}' | sort -h | tail -20
```
Files > 1 MB on a per-ayah/per-dua basis are probably overkill — re-encode at 64 kbps mono.

### 8.4 Cold-start trace

```bash
flutter run --profile --trace-startup --verbose
```
Open the resulting `start_up_info.json`. Target:
- Engine init < 200 ms on a mid-range device
- First Flutter frame < 1 s
- First useful frame < 2 s

If you exceed, look for synchronous I/O in `main.dart` — `initSupabase()` already runs async-safely, good. Make sure SharedPreferences reads and asset JSON loads are not awaited in series before `runApp`.

### 8.5 Frame budget

In dev:
```bash
flutter run --profile
```
Open DevTools → Performance tab → record a typical session (open app → home → start a quiz → answer 3 questions → return). Look for jank > 16 ms frames. Common culprits in a quiz app:
- Rebuilding the whole `home_screen.dart` (2,285 lines!) on every Riverpod change → use `Consumer` scoping.
- Loading a 100 KB JSON pack on the UI thread on first navigation → preload in a `FutureProvider` during splash.

### 8.6 Web-specific

Web is your primary surface (live at aziz-academy.com). Run:
- Lighthouse on the live URL.
- Verify deferred-loading of CanvasKit; first paint should NOT block on `canvaskit.wasm` (~2 MB).
- Verify Service Worker is registered and caches the bundle for repeat visits.

Exit criteria: bundle < 30 MB web, cold start < 2 s, no >16 ms frame in steady-state quiz play, Lighthouse Perf ≥ 80, A11y ≥ 95.

---

## Phase 9 — Accessibility & i18n polish (3–5 days)

### 9.1 ARB completeness

```bash
diff <(jq -r 'keys[]' lib/l10n/app_en.arb | sort) \
     <(jq -r 'keys[]' lib/l10n/app_ar.arb | sort)
```
Any key in one but not the other is a localization hole.

Add a test for it:
```dart
test('AR and EN ARB have the same key set', () { ... });
```

### 9.2 RTL audit

Walk every screen in `ar` locale and check:
- Text alignment is right by default.
- Icons that imply direction (back arrow, "next" chevron) flip with `Directionality`.
- `Row`s of mixed content render in the right order — use `start`/`end` not `left`/`right`.

A golden test on a sample of screens in both locales catches regressions cheap.

### 9.3 Screen reader

Every `IconButton`, `InkWell`, and tap target needs a semantic label. Audit:
```bash
grep -rE "IconButton|InkWell|GestureDetector" --include="*.dart" lib | \
  grep -vE "tooltip:|Semantics\b|excludeFromSemantics" | wc -l
```
Any number > 0 needs review.

### 9.4 Color contrast

Brand is navy `#1B2A6B` and gold `#C9A84C`. Verify:
- Body text on background ≥ 4.5:1
- Large text / UI elements ≥ 3:1
- Test in both light + dark themes (you have `values-night/styles.xml` so a dark theme exists somewhere).

Tools: WebAIM contrast checker, or `flutter_a11y` package.

### 9.5 Font size

Kids' apps need bigger tap targets than adult apps. Minimum 48×48 dp. `MediaQuery.of(context).textScaler` must propagate — verify by setting the device font size to "largest" and replaying onboarding + a quiz.

Exit criteria: ARB drift test in CI, every screen passes RTL spot-check, every interactive widget has a label, contrast meets WCAG AA.

---

## Phase 10 — Feature backlog (ongoing)

From `docs/notes/points.md` (was `Points.txt`):

- [ ] التاريخ الميلادي — Gregorian date display alongside Hijri (you already have `hijri_date_test.dart`; add the Gregorian widget)
- [ ] Show username on home
- [ ] Avatar/photo support in profile (Phase 4.5 — extra COPPA care needed)
- [ ] User profile screen polish
- [ ] Islamic section: Sirah, Quran, Hadith, Athkar, شخصيات
- [ ] Regenerate icons + emojis
- [ ] Add emojis inside games

From `docs/notes/reply.md` (Brain Boost scaled v1):

- [ ] Rename to "Brain Boost" / "تنمية الذكاء"
- [ ] 4 categories, 15 items each (~360 total) — deferring Spatial + Memory
- [ ] Per-category EMA in `learner_state.dart`
- [ ] Parent radar chart
- [ ] Onboarding disclaimer (AR + EN)
- [ ] **Sample-batch gate:** review 12 items (one easy/medium/hard × 4 categories) BEFORE authoring all 360
- [ ] Keep items in structured JSON/YAML, not Dart
- [ ] Instrument drill-in rate + session length for new section vs. capitals/flags for one week before deciding on Spatial/Memory

From CHANGELOG 1.1.113 forward-looking notes:

- [ ] Wire a real payment processor to the Plus screen — currently the screen "says so honestly" that checkout is closed
- [ ] Entitlements table: server-write-only — verify the policy is enforced (Phase 4.1)

From the auditor list in `docs/notes/important.md`:

- [ ] Engage a COPPA / GDPR-K consultant for a one-time review
- [ ] Engage an App Store compliance reviewer who's shipped Kids-category apps
- [ ] Engage a child UX designer for a usability pass with real kids in the target age band
- [ ] Engage an Arabic cultural/dialect reviewer for content tone

---

## Cross-cutting: cadence & ownership

This plan is ~6–10 weeks of focused work for one person, or 3–5 weeks for two. Sequence advice:

- **Week 1:** Phase 0 + Phase 1 + Phase 2 (clean repo, fix docs). Everything else is easier afterward.
- **Week 2–3:** Phase 4 (security/privacy). Required before any store submission.
- **Week 2–3 in parallel:** Phase 6 (CI/CD). Once green, the rest of the plan gets safer.
- **Week 4–5:** Phase 3 (code quality) + Phase 5 (tests). These reinforce each other.
- **Week 5–6:** Phase 7 (store readiness). Submit to internal tracks.
- **Week 6+:** Phase 8 (perf) + Phase 9 (a11y). Ship-blockers if they regress, otherwise iterate.
- **Ongoing:** Phase 10 (backlog).

Track this plan in GitHub Projects or a similar tracker — copy each `- [ ]` checkbox into an issue with a clear acceptance criterion. Don't try to keep state in this file alone; it's a starting map, not a live tracker.

---

## Appendix A — One-command verifications

Run these any time to spot regressions:

```bash
# Repo hygiene
git status --short | wc -l                 # should be < 20 in steady state
du -sh build .git                          # build cleanable, .git should stay small

# Code health
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage

# Asset integrity
python3 scripts/audit_islamic_audio.py
python3 scripts/audit_font_coverage.py
python3 scripts/audit_sitemap_routes.py
python3 scripts/audit_version_consistency.py

# Build
flutter build web --release
flutter build apk --release      # if Android SDK installed
flutter build ipa                # macOS only

# Size guard
du -sh build/web                 # should be < 30 MB
```

## Appendix B — Files / paths referenced in this plan

- `lib/core/services/supabase_bootstrap.dart` — Supabase init, public anon key
- `lib/core/data/madrasati_data.dart` — 8,829-line data file flagged for split
- `lib/features/admin/admin_dashboard_screen.dart` — 5,932-line screen flagged for split
- `lib/features/home/home_screen.dart` — 2,285-line screen flagged for split
- `lib/features/home/activity_catalog.dart` — 131-entry catalog, may move to JSON
- `lib/core/router/app_router.dart` — 1,889-line router, candidate for splitting
- `pubspec.yaml` — version `1.1.113+118`, ~200 hand-listed assets
- `.github/workflows/{ci.yml,flutter_ci.yml,deploy_github_pages.yml,release_stores.yml}` — CI/CD
- `vercel.json`, `netlify.toml`, `firebase.json` — multi-host web deploy
- `analysis_options.yaml` — minimal lints today, expand per Phase 3.4
- `scripts/audit_*.py` — wire into CI per Phase 6
- `docs/IOS_RELEASE_NO_MAC.md`, `docs/github_actions_secrets_checklist.txt` — release docs
