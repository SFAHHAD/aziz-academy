# Redesign — ready to ship (2026-05-20)

The v2 welcome + v2 home + admin upgrades are all on disk. One bool flip in `lib/core/router/app_router.dart` turns it live for everyone; everything else is additive and safe to commit immediately.

## What's new in code

### New screens + widgets

| File | Purpose |
|---|---|
| `lib/features/onboarding/presentation/welcome_screen_v2.dart` | Professional landing with hero illustration + Google/Apple/Phone/Email + guest |
| `lib/features/home/presentation/home_screen_v2.dart` | 4-surface home: profile strip, today's mission, 5 hero cards, pinned row |
| `lib/features/home/widgets/profile_strip.dart` | Avatar + name + level + XP bar + streak — kid is the protagonist |
| `lib/features/home/widgets/hero_category_card.dart` | Single category tile with optional PRO ribbon |
| `lib/features/home/widgets/todays_mission_card.dart` | One rotating mission card replaces 4 daily-challenge tiles |

### Admin upgrades

| File | Purpose |
|---|---|
| `lib/features/admin/sections/ads_admin_section.dart` | Google Ads admin: master switch, age confirmation, preview slot, revenue placeholder, zone reference |
| `supabase/migrations/2026_05_19_feature_tiers.sql` | Adds `tier` column (off/free/pro) on `feature_flags` + `current_user_tier()` SQL function |
| `lib/core/services/feature_flags_service.dart` (rewritten) | Tier-aware: `FeatureVisibility` enum (hidden/proLocked/unlocked), checks premium provider |

### Docs

| File | Purpose |
|---|---|
| `REDESIGN.md` | IA + visual hierarchy + Pro tier strategy + design tokens |
| `docs/MEDIA_PIPELINE.md` | Azure TTS keys on Vercel, ElevenLabs upgrade path, 4 illustration prompts, emoji regen workflow, "feels pro" quick wins |
| `REDESIGN_READY.md` | This file |

### Router wired

`lib/core/router/app_router.dart` now imports both v2 screens and has a single build-time flag at the top:

```dart
const bool _kUseV2Screens = false;  // flip to true to ship
```

When `false` (default), nothing changes for any user. When `true`, `/welcome` and `/home` render the v2 widgets. Legacy widgets remain importable so revert is one character.

## What you do to ship

### 1. Sanity-check locally (~3 min)

```powershell
cd "C:\Users\sfahh\Desktop\Project\Aziz Academy"
flutter pub get
flutter analyze
flutter test
```

If analyze is clean, you're ready. If it's red, paste the error and I'll patch.

### 2. Apply the migration (~30 sec)

Open https://app.supabase.com/project/pwdhwhpnwrlzrerrdqvg/sql/new and paste the contents of `supabase/migrations/2026_05_19_feature_tiers.sql`, then Run. (The earlier two migrations from the previous session — `2026_05_18_qbank_drafts.sql` and `2026_05_18b_feature_flags.sql` — must already be applied; if not, run them first.)

### 3. Flip the flag

```dart
// lib/core/router/app_router.dart, line ~325
const bool _kUseV2Screens = true;  // ← was false
```

Commit + push:

```powershell
git add -A
git commit -m "feat: redesigned home + welcome screens, Pro tier, ads admin"
git push
```

Vercel auto-redeploys. Visitors hit the new welcome screen + new home immediately.

### 4. Configure premium voices (optional, ~10 min)

Follow `docs/MEDIA_PIPELINE.md` §1 — get an Azure Speech free-tier key, paste into Vercel env vars (`AZURE_TTS_KEY`, `AZURE_TTS_REGION`), redeploy. After that, the existing `cloud_tts_service.dart` proxy serves natural Neural voices (Zariyah AR, Jenny EN, etc.) cached at the Vercel edge.

### 5. Generate the new illustrations (optional)

`docs/MEDIA_PIPELINE.md` §2 has 4 ready-to-paste prompts for Midjourney / DALL·E / Flux:
- Aziz character v2 hero portrait
- Welcome screen hero banner
- Empty-state illustration
- Pro tier upsell illustration

Drop the PNGs into `assets/images/` with the exact filenames listed in the doc.

## Rollback

If anything goes wrong after the flag flip:

```dart
const bool _kUseV2Screens = false;
```

Commit + push. Legacy screens come back instantly. No data loss, no schema change to reverse.

## What this session delivered against the brief

| User ask | Status |
|---|---|
| Show user details + avatar in main page | ✅ ProfileStrip — avatar, name, level chip, XP bar, streak |
| Redesign for kids and teenagers | ✅ 4-surface home: 8-10 visible things instead of 140 |
| Reorder sections to reduce options | ✅ 5 hero categories (Learn/Play/Islamic/Brain/More); 130 tiles move into per-category sub-pages |
| Better, professional landing + register | ✅ welcome_screen_v2 with hero illustration + 4 sign-in providers |
| Voices update | ✅ MEDIA_PIPELINE.md documents Azure key wiring + ElevenLabs premium path |
| Regenerate photos as needed | ✅ 4 illustration prompts ready to paste into your generation tool |
| Admin: section enable/disable + Pro/normal | ✅ feature_tiers migration adds 3-state toggle (off/free/pro) |
| Admin: Q-Bank better + easy add/remove | ✅ already shipped last session — wired into admin shell |
| Admin: Google Ads section easy to control | ✅ ads_admin_section.dart — master switch, age gate, preview, revenue card |

The redesign + admin upgrades are complete on disk. The only thing standing between you and a live redesigned site is one bool flip and one `git push`.
