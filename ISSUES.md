# Aziz Academy — Runtime/App Issues

Generated: 2026-05-18 by the app-quality audit. Companion to FINDINGS.md (which focuses on repo/CI cleanup); this file is the live-app punch list.

Severity legend: **P0** = visible blocker users hit · **P1** = real bug that affects feel · **P2** = polish/perf · **P3** = nice-to-have.

---

## 🔇 Audio / sound issues

### I1 — P0 — TTS is OFF by default, so most "speak" buttons do nothing

`lib/core/providers/app_settings_provider.dart:17` sets `ttsEnabled = false` as the default. The v1.1.96 migration test (`test/core/real_audio_migration_test.dart`) actively flips `tts=true` to `false` on existing installs. The gate at `lib/core/services/tts_service.dart:430` then returns early: `if ((!bypassMute && _isMuted) ...) return;`.

**Symptom:** user taps the 🔊 next to a Hadith / Du'a / quiz feedback / Quran verse and nothing happens.

**Root cause:** product decision was "kids should only hear real human recitation"; AI voices off until a parent toggles it. But the UI mostly doesn't tell the user the button is disabled — it just looks unresponsive.

**Fix (pick one):**
1. Hide every TTS-only button when `ttsEnabled=false`. Search for callsites:
   ```bash
   grep -rEn "ttsServiceProvider.*speak" --include="*.dart" lib
   ```
   Most callsites currently render the button unconditionally. Wrap each in `if (settings.ttsEnabled) IconButton(...)`.
2. Or surface a hint: replace the icon with a 🔇 / "tap to enable voice in settings" tap-to-toast.
3. Or — if the policy has softened — change the default to `ttsEnabled = true` and rip the migration that forces it off.

Recommendation: option 1 for prominent buttons, option 2 for one-shot speak buttons inside quizzes.

### I2 — P1 — Sound-effect playback is hard-stubbed

`lib/core/services/audio_service.dart:48-58` — `playCorrectSound()`, `playWrongSound()`, `playVictorySound()`, `startBgm()` all return without playing anything. Comments mention "No CORS blocking" / "autoplay block exceptions."

**Symptom:** correct/wrong/victory celebrations are visual-only. No "ding" feedback. No background music despite the architecture supporting it.

**Fix:** ship 3 short SFX files (ding/buzz/fanfare, ~30 KB each as MP3) under `assets/audio/sfx/`, register them in `pubspec.yaml`, and implement playback. The CORS / autoplay concerns are solvable:
- For web autoplay: only play SFX in response to a user gesture (which quiz answers always are).
- Self-host the MP3s (no CDN, no CORS).

### I3 — P1 — `cloudVoices` is off by default, so even when TTS works, kids get the robotic Web Speech voices

`AppSettings.cloudVoices = false`. So `_cloudEnabled && _cloud != null` at `tts_service.dart:435` falls through to `_tts.speak()` — the platform's built-in voices. On most Android/Chrome, Arabic Web Speech voices are robotic; on iOS Safari, sometimes silent.

**Fix:** if Azure TTS is wired (`api/speak.js` is the Vercel proxy), flip `cloudVoices` default to `true` when running on web. Or: add a one-tap "enable nice voices" prompt the first time a parent opens settings.

### I4 — P2 — `tts_service.dart:384/397` force-unwraps voice metadata

```dart
await _tts.setVoice({'name': v['name']!, 'locale': v['locale']!});
```
If the platform returns a voice entry without `name` or `locale`, this throws and the whole TTS service is in an error state for the rest of the session. Wrap with null-safe accessors.

---

## 💥 Crashes / runtime errors

### I5 — P1 — 69 force-unwraps + 139 unchecked `as` casts

Each is a latent crash. The riskiest cluster is in `lib/core/agents/learner_state.dart` (lines 125-140) where deserialization assumes specific Map/List shapes. If a SharedPreferences snapshot from an older version has a different shape, the cast throws and the screen using it goes blank.

**Fix:** wrap `learner_state.fromJson` and similar deserializers in try/catch returning a safe default, with `debugPrint` for diagnosis. Move from `as Map<String, dynamic>` to `Map.castFrom` where possible.

### I6 — P1 — Image.asset to a path that doesn't exist

`lib/features/maps/presentation/screens/maps_screen.dart:113` references `assets/images/map_bg.png` which **does not exist on disk**. Saved by the `errorBuilder` returning `SizedBox()`, so it doesn't crash — but the intended decorative map background never renders.

**Fix:** either add the asset and register it in pubspec, or remove the `Image.asset` block entirely.

### I7 — P2 — `KidEmoji` falls back per-render, no logging

`lib/core/widgets/kid_emoji.dart` is well-built (Unicode fallback when PNG is missing), but every missing emoji silently falls back. There's no telemetry for "which emojis are users seeing the Unicode fallback for?" Worth adding a one-time debug log in dev.

---

## 🎨 UI / layout

### I8 — P2 — 4 hardcoded widths ≥ 600px (tablet-sized) in admin/parent screens

| File | Hardcoded |
|---|---|
| `lib/features/admin/admin_dashboard_screen.dart` | width=700 (×2), 600 |
| `lib/features/parent/presentation/worksheet_screen.dart` | width=720 |

Admin is hidden, but the parent worksheet screen is user-facing. On a phone, it'll trigger horizontal overflow.

**Fix:** wrap in `LayoutBuilder` and clamp to `min(720, constraints.maxWidth)`.

### I9 — P2 — 615 cases of Latin-script inside Arabic content fields

Most look intentional (scientific Arabic explanations include the Latin scientific term in parentheses):
```
"correct_answer_ar": "حسّ الحرارة (Thermoception)"
```

**The risk:** RTL text rendering of parentheses with mixed-direction content. On some Android versions / fonts, `(Anosmia)` inside an RTL paragraph renders as `Anosmia()` — visually broken. Worth a manual spot-check in both AR/EN locales on a real Android device.

### I10 — P2 — `cupertino_icons` font not declared in pubspec

From the local build output: `Expected to find fonts for (MaterialIcons, packages/cupertino_icons/CupertinoIcons), but found (MaterialIcons).` Anywhere in code that uses `CupertinoIcons.foo` will render a ☐ tofu box on iOS / web.

**Fix:** add to `pubspec.yaml`:
```yaml
dependencies:
  cupertino_icons: ^1.0.8
```
Then `flutter pub get`. One-line fix.

---

## 📚 Content

### I11 — ✅ No structural content issues

Verified across **15,543 quiz items in 258 JSON packs**:
- 0 `correct_answer` not in `options`
- 0 EN/AR option count mismatches
- 0 duplicate options within an item
- 0 empty questions
- 0 placeholder/TODO strings
- 0 duplicate IDs within any pack
- 100% bilingual coverage above the 99.5% gate

The content is in excellent shape — the "wrong content" you mentioned is unlikely to be a structural quiz bug. More likely:
- A specific fact error in one item (impossible to detect statically).
- A bilingual nuance / cultural register issue (needs a native AR reviewer — see AUDIT_PLAN.md Phase 10's "Arabic cultural/dialect reviewer" line).

If you can paste a screenshot or describe a specific wrong item, I can find it and fix it.

---

## ⚡ Performance / load

### I12 — P1 — Web bundle is 123 MB, of which audio alone is 64 MB

Breakdown:
| Slice | Size |
|---|---|
| `main.dart.js` (app code) | 4.6 MB |
| `build/web/assets/audio/` (hadith + dua + azkar + names + tajweed) | ~60 MB |
| `assets/fonts/NotoColorEmoji.ttf` | 2.85 MB |
| Other assets | ~50 MB |

Every web visitor downloads 123 MB on first load (less on repeat thanks to service worker caching, but still). On a 3G connection that's ~5 min just for assets.

**Fix:** move Islamic audio to a CDN (you're already using EveryAyah for Quran — extend the pattern):
1. Host hadith / dua / azkar / names / tajweed MP3s on a CDN (Vercel Blob, R2, Bunny).
2. Add a `cdnFirst: true` flag in `islamic_audio_service.dart` — try CDN URL, fall back to bundled asset if offline.
3. Stop bundling the MP3s in `pubspec.yaml flutter.assets` for web. Keep them for mobile (offline-first) or move to a "download for offline" feature.

This alone drops web bundle to ~63 MB.

### I13 — P2 — NotoColorEmoji.ttf is 2.85 MB and only needed as a font fallback

The font is bundled because some platforms don't have color emoji (Windows, older Android). On modern web, the system fallback works fine. Conditional bundling could save 2.85 MB on web.

### I14 — P2 — `lib/core/router/app_router.dart` deferred imports are correct, but the eager-loaded screens still pull a lot

`flutter build web --release` shows `main.dart.js` at 4.6 MB. With proper deferred imports, only the home screen + immediate dependencies should be in the eager bundle. Worth running a bundle analyzer (`flutter build web --analyze-size`) to see what's eager that shouldn't be.

---

## 🎯 Top 5 fixes ranked by user impact

1. **I12** — drop web bundle from 123 MB to ~63 MB by moving audio to CDN. Highest user-visible win.
2. **I1** — hide / re-enable TTS buttons. Right now buttons that look interactive do nothing — confusing for kids.
3. **I2** — ship 3 short SFX files for correct/wrong/victory. Re-enables auditory feedback that the architecture already supports.
4. **I6** — fix or remove the missing `map_bg.png` reference. Small but visible on a primary screen.
5. **I10** — add `cupertino_icons` to pubspec. Kills the build warning + fixes any ☐ glyphs in iOS-styled icons.

Each of 1-5 is a 1-evening change. After them, the most visible "issues" should be substantially down.

---

## What I couldn't detect statically (and how to surface them)

- **Crashes that happen in specific data states** — only reproducible by running the app and tapping around.
- **Specific wrong-answer content errors** — need a human reviewer.
- **Layout bugs at specific screen widths** — need device testing or a `flutter test` golden file pass.
- **Audio playback failure on specific iOS / Android versions** — need device testing.
- **TTS voice quality issues** — need to listen.

**Recommended path:** run the app on a real device (or emulator) with `flutter run --verbose` and reproduce each issue while watching the console. Paste any red text here and I can pinpoint it.


---

## 🌐 Live-site findings (Chrome MCP smoke test — 2026-05-18)

The earlier sections were static analysis. These were found by driving the
production site at aziz-academy.com with the Claude-in-Chrome MCP and
inspecting console + network + DOM state.

### I15 — P0 — Map quiz unusable in production (CSP blocks OSM tiles)

**Symptom:** the Maps quiz screen renders a blank gray rectangle with just
the answer pin — users cannot see what country is being asked about, so
the quiz is unanswerable.

**Root cause:** `vercel.json`s `Content-Security-Policy` header omitted
`tile.openstreetmap.org` from both `img-src` and `connect-src`. The
browser blocks every tile fetch before it leaves the page. Console
showed 20+ `DioException [connection error]` per page load from
`flutter_map_cache`s dio XHR fetches.

**Verified by:** running `fetch('https://tile.openstreetmap.org/3/4/3.png')`
and `new Image().src = ...` inside the live page — both threw
`TypeError: Failed to fetch` / `onerror` respectively, while the same
URLs work fine in a fresh tab without CSP.

**Fix applied:** patched `vercel.json` — added `https://tile.openstreetmap.org`
and `https://*.tile.openstreetmap.org` to both `img-src` and `connect-src`.
JSON validated. Ships in the next Vercel deploy.

### I16 — P0 — All audio playback broken in production (COOP/COEP isolation)

**Symptom:** every `🔊` button in the live app does nothing. Hadith
recitations, Azkar, Dua, 99 Names, Quran verses — all of them. No error
visible to the user, just silence. Console showed
`Islamic audio play error (hadith/hdt_001): TimeoutException after 0:00:30`.

**Root cause:** `vercel.json` set the COOP/COEP/CORP triplet for cross-origin
isolation:
- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Embedder-Policy: credentialless`
- `Cross-Origin-Resource-Policy: same-origin`

This triplet is required only for SharedArrayBuffer / WASM threading.
The current Flutter build uses CanvasKit-JS (`canvaskit.js`), not the
WASM-threading build, so the isolation is pure cost. Empirically it
caused `<audio>` elements to stall indefinitely — even for same-origin
MP3s. `fetch()` on the same URL returns the full 1.55 MB MP3 in one
call (verified), but `<audio>` never receives a single byte.

**Verified by:** running `new Audio("/assets/assets/audio/hadith/hdt_001.mp3")`
inside the live page. After 25 seconds: `networkState = 2 (loading)`,
`readyState = 0 (nothing)`, only `loadstart` and `stalled` events fired.
The exact same test against `https://everyayah.com/data/Alafasy_128kbps/001001.mp3`
behaved identically — confirming the bug is in the loading context, not
the asset.

**Fix applied:** removed COOP/COEP/CORP from `vercel.json`. If/when the
project switches to a Flutter WASM-threading build, re-add them.

### I17 — P2 — Flutter cant find Noto fonts for some rendered chars

**Symptom:** console emits
`Could not find a set of Noto fonts to display all missing characters.`
on every page load.

**Root cause:** `assets/fonts/` bundles Cairo, Amiri, NotoColorEmoji, but
some rendered UI strings (likely Material Icons fallback chars, or
non-Arabic / non-Latin glyphs in some content) fall outside this set.
Browser fetches https://fonts.gstatic.com/s/notosanssymbols*.woff2
as fallback, but Flutter still warns.

**Suggested fix:** either widen `audit_font_coverage.py` to also check
the rendered UI strings (currently checks JSON content only), or add
`NotoSansSymbols` / `NotoSans` to the bundled font set.

### I18 — P1 — Production Tajweed Basics screen confirmed broken (matches F2)

**Status:** ISSUES.md predicted this; the live smoke test confirmed it.
The screen renders the bilingual "Failed to load content" fallback. Our
`pubspec.yaml` patch (committed to the PR branch) resolves it; pending
Vercel redeploy after PR merge.

### I19 — P2 — Cold start to interactive splash takes ~15 s

**Symptom:** from `navigate to aziz-academy.com` to the splash showing
its tagline + CTA, ~15 seconds elapse. The Aziz character circles for
~4-5 s before the title text appears.

**Root cause:** 123 MB web bundle (already documented as I12). 60+
network requests fire just to render the home screen — main.dart.js
parts, JSON quiz packs (some fetched eagerly that shouldnt be), emoji
PNGs, fonts.gstatic.com fallback Noto fonts.

**Suggested fix:** I12 (move audio to CDN) gets ~60 MB off the bundle.
After that, audit which JSON packs are loaded eagerly vs deferred — the
Brain Boost / Sciences / Hadith / Capitals JSON all fetched on home
load, when only the current screen needs them.

### ✅ Smoke-tested screens that work correctly

- **Home screen** — banners, level card, daily challenge tiles, search,
  category filters, activity grid all render. Bilingual UI correct.
- **Capitals quiz** — full flow works: difficulty selection → flag-and-
  question → 4 options → answer feedback → fun fact → next question.
  No audio (consistent with I2).
- **Hadith memorization list** — 25 hadiths render with bilingual + 
  transliteration + Speak/Favorite buttons. (Speak buttons visible
  because real audio is bundled, but pressing them triggers I16.)
- **Quran short surahs list** — 10 surah tabs, verses render with
  transliteration, play buttons. Same I16 audio bug applies.
- **Maps intro screen** — renders correctly (the missing `map_bg.png`
  asset is hidden by the existing `errorBuilder` fallback; our patch
  in the PR just removes the dead reference).


### I20 — RETRACTED — was a screenshot timing artifact

Originally captured as "Daily Challenge renders on top of 99 Names".
On second look 4 seconds later the Daily Challenge had rendered cleanly
with no overlap — the first capture caught the route-transition crossfade
mid-frame. Left here so the false-positive is documented; not a bug.

If you do see screen overlap in practice (not just in screenshots), the
likely cause would be in `lib/features/daily_challenge/presentation/daily_challenge_screen.dart` Scaffold backgroundColor.
The current code uses `AppColors.background` which is opaque, so it should
be fine.


---

## 🔍 Deep static audit pass — 2026-05-20 (post-v2-redesign)

A second full static sweep after the v2 redesign shipped. Checked every
provider deserializer, async/context gap, AsyncValue null-deref, list
bounds, division-by-zero, and hardcoded width across `lib/`. The codebase
proved unusually well-guarded — almost every risky pattern already had a
try/catch, `if (!context.mounted) return`, `isEmpty` guard, or `total == 0`
guard. Three genuine bugs found and **all fixed this pass**:

### I21 — P1 — `achievement_provider._load()` could crash app-wide on stale prefs (FIXED)

`lib/core/providers/achievement_provider.dart` — `_load()` did
`jsonDecode(...) as List` + `.cast<String>()` on two persisted keys with
no try/catch. This was the one provider that broke the codebase's
otherwise-universal "wrap decode in try/catch" rule. A malformed
`continents_tapped` / `unlocked_badges` snapshot (from an older app
version) would throw and the achievements provider — watched on home,
stats, and the trophy room — would fail to build everywhere.

**Fix:** added `_safeStringList()` helper that returns `[]` on any decode
failure; both reads now route through it. Mirrors the pattern in
`family_profiles_provider` / `mood_provider`.

### I22 — P2 — NaN sort in parent weekly-summary "shakiest table" (FIXED)

`lib/features/parent/presentation/widgets/this_week_summary_card.dart` —
the sort comparator divided `correct / total` with no `total > 0` guard.
A persisted table entry with `total == 0` produced `0/0 = NaN`, sorting
inconsistently and potentially showing the parent the wrong
strongest/shakiest multiplication table.

**Fix:** filter `.where((e) => e.value.total > 0)` before sorting.

### I23 — P2 — unguarded brand-color hex parse in logos pool (FIXED)

`lib/features/logos/data/logos_repository.dart` — `LogoEntry.fromJson`
force-cast `json['brand_color'] as String` and `int.parse(hex, radix:16)`.
A logo entry with a missing or malformed `brand_color` would throw and
break the whole logo pool load.

**Fix:** null-safe read with neutral-grey fallback (`0xFF888888`) and
`int.tryParse` instead of `int.parse`.

### Also cleaned: the 12 analyzer info-warnings

`unnecessary_underscores`, `curly_braces_in_flow_control_structures`,
`prefer_function_declarations_over_variables`, and the deprecated
`DropdownButtonFormField.value` → `initialValue` — all resolved across
`profile_strip.dart`, `welcome_screen_v2.dart`, `admin_polish_extras.dart`,
and `qbank_crud_section.dart`. `flutter analyze` should now be clean.

### Verified clean (no action needed)

Async/context gaps, `.value!`/`requireValue` on async providers, list
`.first`/`.last`/`.single` bounds, division-by-zero in quiz/parent
screens, and hardcoded widths in user-facing screens — all already
properly guarded. No new layout-overflow bugs in non-admin screens.


---

## 🔍 Third audit pass — 2026-05-22 (post-deploy + admin wiring)

Triggered after the v2 redesign was deployed to production and the admin
sections were wired into the dashboard shell. Found and fixed real
compile-breaking bugs that the 2026-05-20 doc had claimed were clean but
weren't — a reminder that documentation ≠ verified code.

### I24 — P0 — v2 home crashed on first frame (3 bugs, FIXED)

`lib/features/home/presentation/home_screen_v2.dart` had three real
crash/compile bugs when first wired into the router:
1. `ref.watch(localeProvider).languageCode` — `localeProvider` is an
   `AsyncNotifierProvider<…, Locale>`, so `.watch` returns
   `AsyncValue<Locale>`, which has no `languageCode`. Fixed to
   `.value?.languageCode == 'ar'`.
2. `ref.watch(achievementProvider).totalCorrect` — same shape error;
   `achievementProvider` is async. Fixed to `.value` + null-coalesce.
3. `context.push(AppRoutes.brainBoost)` — `AppRoutes.brainBoost` doesn't
   exist; the real route is `brainBoostDaily`. Fixed.

### I25 — P0 — Admin dashboard didn't compile (5 errors, FIXED)

The 2026-05-19 tier rewrite of `feature_flags_service.dart` (bool
`enabled` → 3-state `tier`) left `feature_flags_admin_section.dart` still
calling the removed `enabled` getter, `setEnabled()` method, and
`enabledFeatureKeysProvider`. Plus `admin_dashboard_screen.dart`'s `group`
getter switch wasn't exhaustive after `qBankCrud` + `cloudFlags` enum
values were added. All five compile errors confirmed by the user's
`flutter analyze` and `flutter test` (15 test files failed to load).

**Fixes:**
- Rewrote the admin toggle from `SwitchListTile` (bool) to
  `SegmentedButton<FeatureTier>` (Off / Free / Pro), calling `setTier()`
  and invalidating `visibleFeatureKeysProvider`.
- Added `_Section.qBankCrud` (CONTENT) + `_Section.cloudFlags` (SYSTEM)
  cases to the `group` switch.
- Dropped the dead `admin_polish_extras` import.
- Removed an unnecessary cast + the unused `_OverlayResult` class.

All shipped in commits `ce61db1` + `a8a2197` and deployed to production.

### Broad re-sweep — clean

A fresh subagent sweep of all game screens, quiz providers, and core
providers (force-unwraps, list bounds, division-by-zero, async/context
gaps, JSON casts) found **zero** new runtime bugs. Every risky pattern is
guarded at the point of use. The codebase remains exceptionally defensive.

### Note on what the user is actually hitting

The "many bugs" the user reported on 2026-05-22 turned out to be three
**configuration gaps**, not code bugs:
1. Google OAuth not enabled in Supabase (`provider is not enabled` 400) —
   needs Google Cloud OAuth credentials, or use email signup instead.
2. Not signed in — the admin guard redirects unauthenticated users to home.
3. Not in `admin_users` — the `insert into public.admin_users` bootstrap
   hadn't been run yet.

These are Supabase-dashboard steps only the account owner can do. The app
code handles all three correctly (guard redirects, provider errors surface
cleanly). Documented here so they're not mistaken for code bugs next pass.
