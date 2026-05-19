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
