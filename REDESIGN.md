# Aziz Academy — Redesign brief (2026-05-19)

Goal: turn the current "wall of 130 tiles" into a calm, kid-and-teenager-friendly experience that surfaces a few great choices, shows the user as the protagonist (avatar + streak + level), and reads as a pro product on landing.

This brief defines the IA + visual hierarchy. Implementation files are listed at the bottom.

---

## 1. Information architecture — what changes

### Before (today)
- Home greets with a wall of 130 tiles + 4 daily cards + 3 banners + a search bar + 5 category chips.
- Cognitive load = high. Decision fatigue.
- Users hit a small number of tiles repeatedly; the rest is noise.

### After
**Home is 4 surfaces, in this order:**

1. **Profile strip** — avatar + name + level + streak. Sets the user as the protagonist.
2. **Today's mission** — single hero card (carries existing Daily Challenge / Today's Mission / Brain Boost / Verse logic, but ONE card at a time, rotating).
3. **5 Hero categories** — Learn, Play, Islamic, Brain, More. Each opens its own sub-page with the full list.
4. **Pinned for you** — 3 small tiles the user has played recently, plus a "search all activities" button.

That's it on screen at first glance. Below the fold: the rotating "Did you know?" + footer links. Result: 8-10 visible things, not 140.

Each hero category becomes its own **CategoryPage** that holds the existing activity grid — but scoped. The big 130-tile grid moves there.

### Pro tier

A `feature_flags.tier` column lets the admin mark a section as `free` (everyone) or `pro` (paying parents). The `FeatureGate` widget hides tiles whose section is `tier=pro` for non-pro users, and shows a single "Unlock with Aziz Academy Plus" upsell tile instead.

Default seeding (suggested — admin can change later):
- **Free:** Capitals, Flags, Maps, Math, Sciences, Quran (short surahs), Athkar, Asma-ul-Husna, Daily Challenge, IQ (limited), 50% of Brain Boost packs
- **Pro:** Madrasati (full curriculum), full Brain Boost, Tajweed Basics, Hadith Quiz, Multiplayer/Versus, Parent Dashboard advanced reports, ad-free guarantee

This isn't policy yet — it's a tunable, you decide later via the admin toggle.

---

## 2. Visual hierarchy + design tokens

### Brand colors (unchanged — they already work)
- Primary navy: `#1B2A6B` → `AppColors.primary`
- Gold accent: `#C9A84C` → `AppColors.accent`
- Background: deep navy gradient → `AppColors.background`

### New typographic scale (kid-friendly = bigger, breathier)
| Token | Size | Weight | Use |
|---|---|---|---|
| `display` | 32 | 800 | Hero card title, welcome screen title |
| `headlineL` | 24 | 700 | Profile name, section header |
| `headlineM` | 18 | 600 | Card title, mission title |
| `body` | 15 | 400 | Description, fun fact |
| `meta` | 12 | 500 | Streak count, "12 questions", chip text |
| `micro` | 10 | 600 | Status badges (NEW, PRO, LIVE) |

Use Cairo for AR, Nunito for EN (already configured). Line height ≥ 1.35.

### Spacing — 8-pt grid
- Component padding: 16
- Section gap: 24
- Card radius: 16
- Tile gap: 12

### Tap targets
- Minimum 56×56 (kids' hands, dyslexia-friendly)
- Cards: 88-96 high
- Hero cards: 144+ high

---

## 3. Specific screens

### 3.1 Landing / welcome screen (pre-auth, pre-onboarding)

```
┌──────────────────────────────────────┐
│           ☆  (small star)            │
│                                      │
│            [Aziz illustration]       │
│              (big, centered)         │
│                                      │
│       أكاديمية عزيز                  │
│       Aziz Academy                   │
│                                      │
│    Learn, play, discover — together. │
│                                      │
│  ┌────────────────────────────────┐  │
│  │   Continue with Google         │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │   Continue with Apple          │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │   Continue with Phone          │  │
│  └────────────────────────────────┘  │
│  ─────────  or  ─────────            │
│  Use email · Continue as guest       │
│                                      │
│  By continuing you agree to the     │
│  Privacy Policy and Terms.           │
└──────────────────────────────────────┘
```

- "Continue as guest" goes straight to the kid surface; the parent can sign up later from settings.
- No parental gate before signup (per `docs/AUTH_AND_GATE.md`).
- Already mostly built — the auth picker is in `lib/features/account/presentation/multi_provider_auth_sheet.dart`. The welcome screen below wraps it.

### 3.2 Home (post-login)

```
┌──────────────────────────────────────────────┐
│ ╭──╮  Faisal · Level 4         🔥 6 · 240 XP │
│ │👤│  ✏  Edit                  ⚙  Settings   │
│ ╰──╯                                          │
├──────────────────────────────────────────────┤
│  Today's mission                              │
│  ┌──────────────────────────────────────────┐ │
│  │  🌟  Brain Boost                         │ │
│  │  Mental math · 5 quick questions          │ │
│  │  ▶  Start (2× XP today)                  │ │
│  └──────────────────────────────────────────┘ │
├──────────────────────────────────────────────┤
│  Explore                                      │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐         │
│  │  📚      │ │  🎮      │ │  🕌      │         │
│  │  Learn   │ │  Play    │ │ Islamic  │         │
│  └─────────┘ └─────────┘ └─────────┘         │
│  ┌─────────┐ ┌─────────┐                     │
│  │  🧠      │ │  ⋯       │                     │
│  │  Brain   │ │  More    │                     │
│  └─────────┘ └─────────┘                     │
├──────────────────────────────────────────────┤
│  Pinned                                       │
│  Capitals · Flags · Sciences   (▶ play)       │
│  🔍  Search all activities                    │
└──────────────────────────────────────────────┘
```

- Avatar uses `lib/features/profile` data; falls back to a colorful initial-circle if no photo.
- Streak (🔥 6) + XP (240) come from existing `achievementProvider`.
- The 5 hero category cards link to a new `CategoryPage(routeKey)` which renders the existing activity grid filtered to that category.
- "Pinned" reads from a new `recentlyPlayedProvider` (3 last opened activities).
- All of this fits a phone viewport without scrolling. Below-fold: "Did you know?" + footer.

### 3.3 Category page

The existing 130-tile grid moves here, but filtered. Top has a search bar. Below is the grid scoped to the category — and Pro tiles render with a gold ribbon + "Aziz Academy Plus" CTA if the user isn't subscribed.

### 3.4 Profile / user detail

Reached from the avatar tap. Shows:
- Big avatar (tap to change)
- Display name (tap to edit)
- Age band, gender
- Level / XP bar / streak
- Family Profiles (siblings) — swap account
- Achievements gallery
- Settings link

This already exists at `/profile`; the redesign is more spacing + bigger tap targets.

---

## 4. Admin dashboard upgrades

### 4.1 Section enable/disable + Pro tier (combined)

The existing **Feature flags (global)** section gets a 3-state toggle per row:

```
[Capitals]  EN AR  capitals     [ Off | Free | Pro ]
```

- `Off` → not visible to anyone
- `Free` → visible to everyone
- `Pro` → visible only to subscribed parents (Plus); shows upsell card to others

Schema change: replace `feature_flags.enabled BOOLEAN` with `feature_flags.tier TEXT` having values `off`, `free`, `pro`.

### 4.2 Q-Bank — already built, just visually polished

The CRUD section (`lib/features/admin/sections/qbank_crud_section.dart`) already supports:
- Pool picker
- Question list with search
- Editor dialog
- Publish/archive/delete

Add:
- **Quick-add** — a single-line "I want to add a question to: [pool ▼]" → opens editor pre-filled.
- **CSV import** — paste tab-separated `id\tquestion_en\tquestion_ar\to1\to2\to3\to4` → bulk validates → bulk inserts as drafts.
- **Pool health card** at top of each pool view: bilingual %, missing fun-facts count, last-updated, last-author.

### 4.3 Google Ads admin section — new

A new admin section that controls:
- **Master switch** — ads on parent screens ON/OFF (sets `appSettings.adsOnParentScreens`)
- **Per-zone enable** — toggle ads per parent zone (parent dashboard, settings, plus screen, account screen)
- **Revenue dashboard** — AdSense revenue YTD, eCPM, top placements (server-to-server fetch via AdSense API; until that's wired, shows "Configure AdSense API key in env" hint)
- **Policy reminder** — banner: "Ads NEVER appear on kid-facing screens. CI test `ads_policy_test.dart` enforces this."
- **Test ad button** — renders an AdSlot in a modal so the admin can verify the placement looks right without leaving the dashboard

---

## 5. Voices update

The existing `cloud_tts_service.dart` already proxies through `/api/speak.js` → Azure Neural TTS (Zariyah, Hamed for Arabic; Jenny, Guy for English). What's needed:

1. **Flip `cloudVoices` default to `true` on web** (per ISSUES.md I3 fix)
2. **Configure Azure key** on Vercel → env var `AZURE_TTS_KEY` and `AZURE_TTS_REGION` (one-time)
3. **Voice picker UI in parent settings** — let parent pick which voice their kid hears (already partially built in `tts_service.dart` voice resolution)
4. **Long-term: ElevenLabs voice cloning** for a kid-friendly Arabic narrator that's signature to the brand. ~$22/month for the starter plan. Use for the daily Did-you-know audio + recap voice; keep Azure for incidental speak buttons.

Voice options I'd recommend, in order:
- **Zariyah** (Azure, female, modern Saudi) — for default Arabic
- **Hamed** (Azure, male, Saudi) — when parent picks male
- **Jenny** (Azure, female, US English, warm) — for default English  
- **Aria** (Azure, female, US English, more expressive) — alternative
- **(Future) ElevenLabs branded voice** — premium tier

---

## 6. Implementation map — what files change

Implemented in this session:
- `lib/features/onboarding/presentation/welcome_screen_v2.dart` — new landing
- `lib/features/home/presentation/home_screen_v2.dart` — new home layout
- `lib/features/home/widgets/profile_strip.dart` — top user strip
- `lib/features/home/widgets/hero_category_card.dart` — 5 hero cards
- `lib/features/home/widgets/todays_mission_card.dart` — single rotating card
- `lib/features/home/widgets/pinned_row.dart` — recently played row
- `supabase/migrations/2026_05_19_feature_tiers.sql` — tier column on feature_flags
- `lib/features/admin/sections/ads_admin_section.dart` — new ads admin UI

Deferred (needs your input or external assets):
- New Aziz illustration for welcome screen (image generation)
- New emoji set if you don't like the existing ones
- AdSense API key for revenue dashboard
- Azure TTS key on Vercel
- ElevenLabs subscription (if you want the premium voice)

---

## 7. Sequencing this session

1. Migration: `feature_flags.tier` column (replaces `enabled` boolean)
2. Update `FeatureFlagsService` + `FeatureGate` to use tier
3. Update admin Feature Flags UI to 3-state toggle
4. Build `welcome_screen_v2.dart`
5. Build the profile strip + home v2 + 5 hero cards
6. Build `ads_admin_section.dart`
7. Add `recentlyPlayedProvider` for the Pinned row

Ship as `home_screen_v2.dart` (parallel to existing `home_screen.dart`) — flip the router when satisfied. Same with `welcome_screen_v2.dart`. Reduces blast radius.
