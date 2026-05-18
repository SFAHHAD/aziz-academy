# Changelog

All notable changes to Aziz Academy.

## 1.1.113 — 2026-05-17 — Restructure: one registration path, two identity hubs

### Why
Reviewing the fast Phase-1/2 feature run showed the app had sprawled:
five overlapping profile/account screens reachable from three separate
home entries, and a registration path a new family never saw —
onboarding went language → name → age → home as a guest, with sign-up
buried in an overflow menu. This release re-integrates that surface
instead of adding to it.

### Registration now appears on first launch
- Onboarding gains a fourth step — **the parent account step** — after
  the age band. A new family meets "create a free account / continue
  without one" on launch instead of discovering it in a menu later.
- The child profile is persisted *before* the account step, so if the
  parent signs in, the cloud seed captures the real name and age rather
  than empty defaults.
- The parental gate runs inside the email sheet — account creation stays
  a grown-up action.

### Two identity hubs, one home each
- **My Profile** (the child — ID card, edit, siblings) is reached from
  the home grid. Profile editing and family profiles live *inside* it,
  not as competing top-level tiles or menu entries.
- **Parent account** (sign-in, cloud backup, Plus) lives in the overflow
  menu. The home menu drops from three identity entries to one.
- Family Profiles is no longer a separate home-grid tile or menu item —
  it is a sub-page of the Profile hub, so a child has one clear "me".

### Added
- **Aziz Academy Plus** upgrade screen (`/plus`) and the entitlement
  layer (`premiumProvider`, server-write-only `entitlements` table).
  Checkout stays closed — the screen says so honestly — until a payment
  processor is wired.
- `test/features/restructure_smoke_test.dart` (3) — first-frame render
  checks for the rebuilt onboarding, the Account hub, and the Plus
  screen. These caught two real header overflows before release.

### Changed
- Email sign-up / sign-in is now one reusable sheet
  (`showEmailAuthSheet`), shared by onboarding and the Account screen,
  so registration is identical wherever a parent reaches it.
- The account surface is "Parent account" everywhere — screen header,
  signed-in card, and menu entry (was a mix of "Account" /
  "حساب الوالد"), making it clear it is a grown-up area.
- Edit Profile's header was "My Profile" — identical to the profile
  card's title; renamed to "Edit profile".

### Fixed
- Hub headers (Account, Plus, My Profile, Edit profile) overflowed
  horizontally when the title was long — the title `Text` now flexes and
  truncates instead of overflowing the row.
- The email sheet and the family add / edit sheets now scroll, so they
  no longer overflow when the on-screen keyboard is open on small
  phones.

### Tested
- Full suite: 423/423 (was 420, added 3).

### Not in this release
- **Subscriptions (Phase 3 payment)** — the Plus screen ships, but
  checkout stays closed until a payment processor is connected. No
  pricing model or processor is encoded in client code.

## 1.1.112 — 2026-05-17 — Phase 2: cloud backup & restore

### What landed
Cross-device progress via **cloud backup & restore**. A signed-in
parent can back up the device's full progress to their account and
restore it onto any other device.

### Added
- **`SyncService`** — snapshots the whole `SharedPreferences` store into
  one type-tagged JSON document and writes it to the RLS-locked
  `account_sync` table; `pull()` restores it. Because the snapshot is
  the entire store, every feature's data syncs with no per-provider
  wiring, and it stays correct as new features ship.
  - Device-local keys are never synced — the guest id stays per-device,
    and the Supabase auth-session keys are excluded so a restore can't
    corrupt the login.
  - Sync is **explicit** (Back up / Restore buttons) — no silent
    auto-push, so a fresh device can never clobber the cloud copy.
    Last-write-wins.
- **Account screen — Cloud backup card** (signed-in state): shows the
  last-backup time, "Back up now", and "Restore from cloud" (behind the
  parental gate, with a confirm dialog and a restart prompt).
- On first sign-in the cloud is **seeded only if empty** — safe, can
  never overwrite another device.

### Changed
- `ACCOUNTS_SETUP.md` rewritten for **Supabase** (it was a stale
  Firebase checklist after the v1.1.111 backend pivot). Now documents
  the exact Apple / Google OAuth provider setup — the only remaining
  owner task.

### Tested
- `test/core/sync_service_test.dart` (8) — key exclusion, type-tagged
  encode, full snapshot round-trip, and that a restore never reinstates
  a device-local key.
- Full suite: 414/414 (was 406, added 8).

### Cleanup
`flutter analyze` is clean — no dead code, no unused imports. The old
Account-screen preview widgets were removed in the v1.1.111 rewrite;
the only stale artifact left was the Firebase setup doc, now corrected.

### Phases 3 & 4 — deliberately not built
- **Phase 3 (monetization)** needs a pricing decision (what is free vs
  paid) and a payment account — Stripe keys, or App Store / Play
  Console IAP products. Both are owner-only; building an entitlement
  gate with no model and no processor would be dead speculative code.
- **Phase 4 (school / classroom)** is a separate B2B product (teacher
  accounts, class join codes, rosters, licensing) that needs its own
  scoping. It is not a one-pass "complete" item.

## 1.1.111 — 2026-05-17 — Phase 1b: real parent accounts (Supabase email auth)

### What landed
Working **parent accounts** — email sign-up / sign-in, backed by a real
Supabase project. Guest mode stays the default; an account is an opt-in
parent action behind the parental gate.

### Backend
- New Supabase project `aziz-academy` (Q8VISION org, eu-central-1, free
  tier). Chosen over Firebase because it could be provisioned directly
  — Firebase project creation needs the owner's Google console login.
- `account_sync` table — one `jsonb` document per account for the
  Phase 2 cloud sync of family profiles + per-kid progress. Full
  row-level security: an account can only ever touch its own row.
  `updated_at` trigger; function `search_path` pinned (advisor-clean).

### Added
- `supabase_flutter` dependency; `initSupabase()` in `main()` — never
  throws, so a backend outage leaves the app fully playable as a guest.
- **`AuthService`** — email sign-up / sign-in / sign-out, Supabase
  errors mapped to stable bilingual message keys. Email-confirmation
  flow handled (Supabase sends a confirm link; the UI routes the
  parent to sign in afterwards).
- **`authSessionProvider`** — reactive signed-in / guest state; emits a
  guest session when the backend SDK isn't initialised (keeps widget
  tests and offline starts correct).
- **Account screen is now functional** — email "Create account / sign
  in" behind the parental gate; a signed-in card with the account
  email + cloud-saved reassurance + sign-out; honest "(soon)" Apple /
  Google buttons that point parents to email until their OAuth step is
  done.
- `vercel.json` CSP extended to the Supabase origin; a matching check
  added to `validate_production_deploy.py`.

### Tested
- `test/core/auth_service_test.dart` (7) — email/password validation,
  `AuthResult` shapes, and that every `AuthService` call degrades
  safely (never throws) when the backend isn't initialised.
- Full suite: 406/406 (was 399, added 7).

### Still needs the owner (one step)
Apple and Google sign-in need OAuth credentials registered on your
Apple Developer + Google accounts, then pasted into Supabase Auth →
Providers. `ACCOUNTS_SETUP.md` has the steps. Email accounts work now
with no further setup. Phase 2 (cloud sync of progress) and Phase 3
(monetization) follow.

## 1.1.110 — 2026-05-16 — Account foundation (Phase 1a): official guest identity + parental gate

### The ask
Add account creation via Apple / Google, and a guest path with no
registration.

### Approach
Accounts are a multi-phase project, not a one-shot. Apple/Google
sign-in fundamentally needs a backend + OAuth app registration that
only the project owner can create in the Firebase/Apple/Google
consoles. So this release ships **Phase 1a — the foundation** — which
is complete and dependency-free; `ACCOUNTS_SETUP.md` documents the
external setup that unblocks Phase 1b (the real sign-in + sync).

Design decision: **the child never signs in — the parent does.** Kids
stay as local profiles (`familyProfilesProvider`) under the parent's
account. This keeps the app COPPA-safe and inside the App Store Kids
Category rules. The phone number originally requested was dropped — a
child's phone number is a COPPA/GDPR-K liability with no real benefit.

### Added
- **Official guest identity** — `accountProvider` mints a stable,
  random, on-device guest id (`G-XXXXXXXX`, unambiguous alphabet) on
  first launch and persists it. The app is fully usable as a guest;
  this id is the merge key a cloud account will later attach to, so a
  guest who signs in later keeps all their progress. No PII.
- **Parental gate** — `showParentalGate()` + a pure `ParentalChallenge`
  (two-digit multiplication). A deliberate adult barrier required
  before any account/external action — mandatory for the App Store
  Kids Category. Reused by Phase 1b sign-in and Phase 3 purchases.
- **Account hub screen** — new `/account` route. Shows the guest
  status + short id, explains what a cloud account adds (backup,
  cross-device sync, parental oversight), an honest **"coming soon"**
  preview of the Apple/Google parent sign-in (disabled buttons, not
  dead tap-targets), and a parental-gated "for grown-ups" sheet with
  the full guest id + privacy explainer. Reachable from the home
  overflow menu.
- **`ACCOUNTS_SETUP.md`** — the precise Firebase + Apple Services ID +
  Google OAuth checklist that unblocks Phase 1b, with a clear
  owner/state table.

### Tested
- `test/core/account_provider_test.dart` (9) — guest id format,
  uniqueness, persistence across reloads, honouring a stored id.
- `test/widgets/parental_gate_test.dart` (4) — challenge arithmetic,
  input validation, dialog pass/cancel flows.
- Full suite: 399/399 (was 386, added 13).

### Not yet (Phase 1b+, blocked on `ACCOUNTS_SETUP.md`)
Real Apple/Google sign-in, Firebase Auth, cloud sync, parental
oversight dashboard, monetization, and the separate school/classroom
B2B track.

## 1.1.109 — 2026-05-16 — Boy/Girl profile, official profile card & per-kid tracking

### The ask
Add a Male/Female option, a proper "official" profile, and per-user
activity tracking so the app can give each kid more tailored support.

### Why gender matters here
Arabic is a gendered language — second-person verbs, adjectives and
nouns all inflect. Greeting a girl as "يا مكتشف" / "بطل" reads as a
mistake. Knowing the kid is a boy or a girl lets the app address them
grammatically correctly.

### Added
- **Gender field** on the profile. `Gender` (`boy` / `girl` / unset)
  added to `ProfileState` and `ProfileSlot` with migration-safe JSON
  (`g` key, omitted when unset). Mirrored through the family-profiles
  provider to the legacy single-profile provider.
- **`GenderPicker`** (`lib/core/widgets/gender_picker.dart`) — a visual
  two-card 👦 / 👧 selector (no reading required for a 6-year-old).
  Wired into onboarding (the name step), the Edit Profile screen, and
  the family add/edit sheets. Re-tapping the selected card clears it,
  so gender is never forced.
- **`GenderedAr`** (`lib/core/l10n/gendered_ar.dart`) — resolves the
  correct Arabic address forms (`أحسنتَ`/`أحسنتِ`, `بطل`/`بطلة`,
  `مُكتشِف`/`مُكتشِفة`, …). Unset falls back to the conventional
  neutral spelling.
- **Per-profile activity tracking** — new `profileActivityProvider`
  scoped to the active family slot (unlike coins/XP/trophies which stay
  device-wide by design). Tracks day streak, best streak, days active,
  total sessions, member-since, and a 14-day calendar. Recorded once
  per app launch from the home screen. Pure `applyActivityPing` for
  testable streak/day-rollover logic.
- **Official Profile card** — new `/profile` route
  (`profile_card_screen.dart`): a passport-style ID card (avatar,
  gendered champion title, gender badge, age, member-since), the level
  bar, a 4-tile activity stat grid, the 14-day activity calendar, and
  a **personalised, gender-aware support message** that adapts to the
  kid's streak. Edit button → Edit Profile. The home overflow menu and
  the activity catalog now point here.

### Changed
- Home greeting uses the gendered explorer pet name — a girl with no
  saved name is greeted "يا مُكتشِفة", not "يا مُكتشِف".

### Tested
- `test/core/profile_gender_test.dart` (9), `gendered_ar_test.dart`
  (7), `profile_activity_provider_test.dart` (7) — gender
  normalization + JSON, gendered forms, streak/rollover, per-slot
  isolation.
- Full suite: 386/386 (was 363, added 23).

## 1.1.108 — 2026-05-14 — Real-audio plumbing for Hadith/Azkar/Names/Du'a/Tajweed

### The ask
The v1.1.96 real-audio-only policy left a roadmap gap: Quran already
plays real reciter audio via EveryAyah CDN, but Hadith, Azkar (morning +
evening), 99 Names of Allah, Du'as, and Tajweed examples still fell
back to AI TTS — which is muted by default, so the 🔊 buttons just
hid themselves. This release lays the entire engineering pipeline so
that as soon as real MP3 recordings are dropped in, those buttons
upgrade from "hidden" to "plays the real thing" with zero code changes
per screen.

### Added
- **`assets/audio/RECORDINGS_MANIFEST.md`** — 209-entry manifest doc
  that names every required MP3, its target path, the source text to
  recite, and the audio spec (mono 96–128 kbps, -16 LUFS). Acts as the
  single contract between the reciter and the build.
- **`IslamicAudioService`** (`lib/core/services/islamic_audio_service.dart`)
  — mirrors `QuranRecitationService` but plays bundled `AssetSource`
  MP3s. Honours sound toggle (not TTS toggle — real audio is not TTS),
  ducks BGM, races natural completion against explicit stop + 60s
  timeout, idempotent over rapid taps.
- **`RealAudioButton`** (`lib/core/widgets/real_audio_button.dart`) —
  the generalised 🔊. Order of operations: real MP3 if registered →
  TTS fallback if parent opted into AI voices → hidden otherwise.
  Caller passes `(category, id, arabicText)`; the widget decides.
- **`IslamicAudioRegistry`** (generated) — `Set<String>` of asset
  paths that are known to ship. `RealAudioButton.hasRecording` is a
  pure registry lookup, no async, no bundle probing.
- **`scripts/audit_islamic_audio.py`** — walks
  `assets/audio/{hadith,azkar,names,dua,tajweed}/`, cross-checks
  against the JSON content packs (and the in-file athkar constants),
  regenerates the registry, and prints a coverage report. Pass
  `--strict` for CI gating once coverage is supposed to be complete.

### Wired into 5 screens
Replaced `TtsSpeakerIcon` with `RealAudioButton` in:
- `lib/features/hadith/hadith_memorization_screen.dart` (25 ids)
- `lib/features/asma_ul_husna/asma_ul_husna_screen.dart` (99 ids)
- `lib/features/dua/dua_memorization_screen.dart` (60 ids)
- `lib/features/tajweed/tajweed_basics_screen.dart` (10 ids)
- `lib/features/athkar/athkar_screen.dart` (15 ids; `_AthkarList`
  now threads a `section` param so the card derives a stable
  `morning_NN` / `evening_NN` id from its position)

### Coverage today
- Registry: **0 / 209** clips bundled. Every button on these screens
  still gracefully hides (TTS is off by default) — but the next time
  the user drops MP3s into the correct subfolder and runs the audit,
  those buttons start playing real audio immediately.

### How to ship recordings
1. Drop `.mp3` files into `assets/audio/<category>/` per
   `RECORDINGS_MANIFEST.md`.
2. `python scripts/audit_islamic_audio.py`
3. `.\scripts\deploy_web.ps1 --prod`

## 1.1.107 — 2026-05-14 — Parent insights card

### Added
- **`MasteryInsightsCard`** in the parent dashboard Progress section.
  Reads the existing on-device `quizBestsProvider` and
  `quizMissesProvider` to show 7 rows (Bonds-10, Bonds-20,
  PV-Blocks, PV-Digit, Skip-2, Skip-5, Skip-10), each with:
  - Best score / 10 with progress bar
  - Mastery tier chip (Starting / Learning / Mastered, thresholds
    at ≥5 and ≥8)
  - "💪 N to practice" badge counting accumulated misses
  - Tap → opens that screen directly so the parent can hand the
    device to the kid for targeted practice
- Empty state when no early-elementary practice has happened yet,
  with a "your child has not started… data will appear here"
  explainer.
- Privacy reaffirmation in the card subtitle: "All data on this
  device — never uploaded."

### Closes the loop
Adaptive sampling tracks misses → kid sees more weak spots → app
shows parent which surfaces still need work → parent can route them
to that screen. Same zero-PII architecture; nothing new is
collected, just surfaced.

## 1.1.106 — 2026-05-14 — Adaptive Skip Counting (trilogy complete)

### Added
- **Weighted sequence generation in `generateSkipQuestion`** —
  optional `weights` param keyed by the missed `answer` value. The
  generator tries to place that answer inside a canonical 6-value
  sequence by picking a `blankIndex ∈ 1..4` and back-solving
  `start = answer − blankIndex × step`. Gracefully falls back to
  uniform sampling when the weighted answer can't be placed (e.g.
  weight on a non-multiple-of-step value).
- **Skip Counting screen** records wrong picks via
  `quizMissesProvider` with key
  `skip_counting:<mode>:<answer>` and feeds the weights back through
  the half-weighted next() flow.
- **"💪 Practicing numbers you find tricky"** banner shown when 3+
  misses accumulate on the active step mode. Bilingual.

### Tested
- 4 new tests in `skip_counting_engine_test.dart` cover back-compat,
  bias measurement (14 with weight 10 in by-2s appears ≥3× uniform
  rate), graceful fallback when weights violate the step modulus,
  and sequence invariants under weighted sampling.
- Full suite: 363/363.

### Trilogy complete
All three new tap-to-answer screens now learn from the kid's
mistakes:
- Number Bonds (v1.1.104)
- Place Value (v1.1.105)
- Skip Counting (this release)

Adaptive-difficulty rating in my own internal scorecard: 6 → 8.

## 1.1.105 — 2026-05-14 — Adaptive Place Value

### Added
- **Weighted sampling in `generatePvQuestion`** — optional `weights`
  param keyed by 2-digit number (10..99). Same shape as the bonds
  sampler: `baseWeight + misses × biasWeight`. Pure-uniform when
  omitted.
- **Place Value screen** records wrong picks via `quizMissesProvider`
  with key `place_value:<mode>:<number>` and reads the map back when
  generating the next question. Half-weighted sampling so the kid
  doesn't see the same tough number every round.
- **"💪 Practicing numbers you find tricky"** banner appears in the
  round header once the kid has 3+ recorded misses on the current
  mode. Bilingual.

### Tested
- 3 new tests in `place_value_engine_test.dart` cover back-compat,
  bias measurement (37 with weight 10 appears ≥3× uniform over 600
  trials), and digit-decomposition invariants under weighting.
- Full suite: 359/359.

### Adoption status
- Number Bonds — adaptive (v1.1.104)
- Place Value — adaptive (this release)
- Skip Counting — deferred. The "weak signal" for skip counting is
  fuzzier (the kid struggles with specific `prev + step` mental
  jumps, not a clean per-key bucket), so this needs a different
  miss-key design before it ships.

## 1.1.104 — 2026-05-13 — Mastery-aware Number Bonds

### Added
- **`quizMissesProvider`** — on-device, SharedPreferences-backed
  miss tracker keyed `<screen>:<mode>:<shown>`. Capped at 8 per key
  so a single ancient blunder can't dominate the weighted sampler.
- **Weighted sampling in `generateBondQuestion`** — optional
  `weights` param; each `shown` candidate gets
  `baseWeight + misses × biasWeight`. Pure-uniform when no weights
  passed (back-compat for tests + untracked callers).
- **Number Bonds screen** now records wrong picks and reads the
  miss map back. Half of next-question draws use weighted sampling,
  half stay uniform — so the kid practices weak spots without
  feeling like the app is harping on one bond forever.
- **"💪 Practicing the bonds you find tricky"** banner appears in the
  round header once the kid has accumulated 3+ recorded misses on
  the current target. Bilingual.

### Tested
- 3 new tests in `number_bonds_engine_test.dart` cover back-compat,
  weighted-bias measurement (high-weight shown value appears ≥2×
  uniform rate over 300 trials), and the invariant that weights
  only affect `shown` while `shown + answer = target` still holds.
- Full suite: 356/356.

### Pattern, not just one screen
The provider + weight-handling pattern is reusable. Place Value
(`<key>:<mode>:<number>`) and Skip Counting (`<key>:<mode>:<step>`)
are the next adopters in a future release.

## 1.1.103 — 2026-05-13 — GCC-context word problems

### Added
- **20 bilingual word problems** in Kuwait/Gulf settings: souq dates,
  KD/fils money, machboos & luqaimat, diwaniya guests, pearl diving,
  palm trees, masjid iftar tables, Eid timing, prayer-time gaps.
  Across addition, subtraction, multiplication, division, time,
  money. Wired into `general_quiz_repository` alongside the existing
  60 generic problems. Closes the documented "math word problems
  lean abstract" curriculum gap.

## 1.1.102 — 2026-05-13 — For-Schools landing page

### Added
- **`/for-schools`** — bilingual landing page targeting Kuwait + GCC
  schools. Hero, value grid, what-students/teachers-get sections,
  privacy callout, copy-email CTA. Reached from the parent dashboard
  via a "🏫 For schools" button. Indexable (sitemap priority 0.9).
- This is the revenue lane we lead with: no kid subscription, no ad
  injection, no behavioural tracking. Schools pay, the privacy
  promise stays intact.

## 1.1.101 — 2026-05-13 — Teach, don't just quiz

A teacher's pass on the three new tap-to-answer screens. Functional
correctness wasn't enough: when a kid picked the wrong option the
screen just turned red and waited. Now it teaches.

### Added
- **Teaching hint banner** on wrong answers. Each engine grew a
  `*TeachingHint` function that returns a bilingual mini-lesson tied
  to the current question:
  - **Number Bonds** — frames the bond as both addition and
    subtraction so the kid sees the inverse: `10 − 7 = 3.  7 + 3 = 10.`
  - **Place Value** — decomposes the number into `tens × 10 + ones`
    explicitly: `7 tens + 8 ones = 70 + 8 = 78.` Mode-aware: digit
    questions point at the specific place.
  - **Skip Counting** — uses the left neighbour to show the
    step-by-step rule: `8 + 2 = 10. Keep adding 2.`
  The hint appears under the question in a soft amber "💡 Learn:"
  banner, animates in/out via `AnimatedSize` + `AnimatedSwitcher`,
  and clears on the next question or a correct pick.
- **Reading Zone expansion** — 6 new bilingual passages in two
  previously-absent themes:
  - Geography (Kuwait pearling history, GCC neighbours)
  - Values / character stories (kindness toward neighbours,
    honesty over an extra coin in change)
  - Sciences (the camel's desert adaptations, photosynthesis)
  Total Reading Zone: 33 → **39 passages** with 3 comprehension
  questions each. CURRICULUM_MAPPING.md note corrected — the
  "only 3 passages" line had been stale since v1.1.83.

### Tested
- `test/features/math/teaching_hints_test.dart` — 7 tests covering
  bilingual hint output, digit-place targeting, sequence neighbour
  logic.
- Full suite: 353/353 (was 346, added 7).

### Why this release exists
Educational apps that punish a wrong answer with red-and-retry are
just gates. Apps that turn the wrong answer into a tiny lesson
*teach*. This is the difference between Aziz Academy as a
quiz-trainer and Aziz Academy as something parents will actually
recommend to other parents.

## 1.1.100 — 2026-05-13 — Splash version label fix

### Fixed
- Splash screen showed **v1.0.0** at the bottom — a stale hardcoded
  literal that had drifted since the v1.0 build and was missed by the
  version-consistency audit. It now reads the current version
  (`v1.1.100`) from a `_kAppVersion` constant.
- `scripts/audit_version_consistency.py` extended to track
  `lib/features/home/splash_screen.dart` so the splash literal can
  never drift again. The audit now covers three user-visible version
  surfaces (splash, about, admin) instead of two.

## 1.1.99 — 2026-05-13 — UI/UX polish for early-elementary rounds

A senior UI/UX pass on the three new tap-to-answer screens (Number
Bonds, Place Value, Skip Counting). The screens were functionally
correct in v1.1.97 but missed the small reinforcement loops that
educational apps need.

### Added
- **Personal-best tracking** via a new `quizBestsProvider`
  (AsyncNotifier-backed SharedPreferences). Keyed per
  `<screen>:<mode>` so Number Bonds (ten/twenty), Place Value
  (blocks/digit), and Skip Counting (twos/fives/tens) all persist
  independently. The picker shows "Best: N/10" once a record exists;
  the result panel shows either **🌟 New best!** or **Previous best:
  N/10** so the kid always has a target.
- **`RoundProgressBar`** — slim 6px animated bar at the top of every
  round so kids can see how much is left. Reusable widget.
- **`QuizOptionTile`** — reusable answer tile with three visual
  states (neutral / correct / wrong). Correct picks flash green +
  scale 1.06× with a glow shadow; wrong picks turn red. Wrapped in
  `Semantics(button: true)` for screen readers and disabled while a
  correct pick is "settling" so kids can't double-tap.
- **Correct-answer beat** — when the kid picks correctly the screen
  now holds for ~320ms before advancing instead of jumping
  immediately. Tiny but meaningful: kids actually see the green
  flash and feel the "I got it!" beat. Honours
  `MediaQuery.disableAnimations` for accessibility.
- **`RoundResultPanel`** with varied praise (4 phrases per locale,
  seeded by score so the same kid sees a stable phrase per round
  but variety across rounds) and a **confetti burst** on perfect
  10/10 rounds (28 particles, gravity-curve animation, suppressed
  under reduced-motion).

### Tested
- `test/core/quiz_bests_provider_test.dart` — 5 tests cover empty
  start, new-best capture, lower-score no-overwrite, key
  independence across screens/modes, and persistence across
  ProviderContainer disposals.
- All 5 new-screens smoke tests still pass.
- Full suite: 346/346.

### Notes
- The result-panel + tile + progress-bar widgets live under
  `lib/core/widgets/` so future quiz-style screens get the same UX
  for free.

## 1.1.98 — 2026-05-13 — Polish & Audit Sweep

After shipping 1.1.97 (five new screens), this release does the polish
pass: every surface that quoted activity counts, surah counts, or the
old vercel.app URL is updated to reflect the new state. No new
features — just consistency.

### Updated
- **Meta tags + Open Graph** (`web/index.html`) — "more than 110 activities"
  → "more than 130 activities" (Arabic, English, OG, Twitter, noscript).
  JSON-LD `featureList` extended with English Alphabet + the four
  early-elementary math/geometry screens.
- **PWA manifest** (`web/manifest.json`) — description count refreshed
  to 130+ in both languages.
- **About screen** (in-app) — "120+ activities" → "130+ activities" in
  both locales. App version constant bumped.
- **Parent curriculum alignment screen** — added the five new screens
  (Number Bonds, Place Value, Skip Counting, Shapes Basics, English
  Alphabet) with proper grade bands. Short Surahs note updated to
  reflect the actual 15-surah pack (was stuck at 10 from v1.1.92).
- **Store listings** (`store/listing_en.md`, `store/listing_ar.md`) —
  "What's inside" lists now mention the new early-elementary surface
  and the Islamic suite (15 surahs + real-reciter audio). All
  privacy/about URLs flipped from `aziz-academy.vercel.app` to
  `aziz-academy.com` (the apex has been canonical since v1.1.89).
- **Release checklist** (`store/release_checklist.md`) — same URL fix.
- **README.md** — module table replaced with a category-summary table
  reflecting the actual 131-entry catalog. Tagline updated to mention
  the live URL.
- **DEPLOY.md** — production-routes smoke note updated 114 → 137 URLs.
- **CURRICULUM_MAPPING.md** — added rows for the five new screens;
  Last-reviewed date updated.
- **`sitemap_paths.txt`** — regenerated to match the live
  `web/sitemap.xml` (was 113 entries, now 137). A new helper
  `scripts/regenerate_sitemap_paths.py` keeps it in sync.

### Why this release exists
Tiny details add up to a sense of "this is a current, well-tended
product" vs. "this is somebody's old side project." The 1.1.97 deploy
was technically perfect but the marketing copy on the landing page
still claimed 110 activities — a kid's parent comparing listings would
notice. Worth the version bump.

## 1.1.97 — 2026-05-13 — Five New Learning Screens + Home Decomp

### Added — early-elementary learning surface
- **English Alphabet (`/english-alphabet`)** — 26 letters A-Z in a
  4-column grid. Tap a letter to see its phonetic name (in Arabic),
  an example word with emoji (Apple 🍎 Ball ⚽ Cat 🐱 …), and the Arabic
  translation. Mirrors the existing Arabic alphabet screen so a kid
  switching languages gets the same shape of practice.
- **Shapes Basics (`/shapes-basics`)** — 12 fundamental shapes drawn
  with `CustomPainter`: circle, square, rectangle, triangle, pentagon,
  hexagon, octagon, oval, diamond, star, heart, parallelogram. Each
  has a bilingual name, sides count, and a real-world example.
- **Number Bonds (`/number-bonds`)** — "Make 10" / "Make 20" mental
  math for ages 6-8. Pick a target, then 10 questions of the form
  `shown + ? = target`; tap-to-answer, no timer, wrong picks just
  shake red. Foundation for mental addition.
- **Place Value (`/place-value`)** — visualize tens-rods and
  ones-cubes for two-digit numbers. Two modes: "what number do the
  blocks show?" and "how many tens / ones in this number?". Bridges
  base-10 intuition to column arithmetic.
- **Skip Counting (`/skip-counting`)** — count by 2s, 5s, or 10s.
  Six numbers in a row with one blank, kid taps the missing value
  from four options. Pre-multiplication mental hook.

### Wired
- Five new routes in `AppRoutes` and `GoRoute` (all deferred-loaded
  so the initial bundle stays flat).
- Five new entries in `activity_catalog.dart`; English alphabet sits
  in Words, the four math screens sit in Math.
- `web/sitemap.xml` extended to 137 entries; pre-deploy
  `audit_sitemap_routes.py` agrees with the router.
- Pure-engine separation for the three quiz-style screens:
  `number_bonds_engine.dart`, `place_value_engine.dart`,
  `skip_counting_engine.dart` — same pattern as `mental_math_engine`
  and `fractions_engine`. Each ships property-based tests covering
  invariants and option-set shape.

### Tested
- Three new engine test files (16 tests total) covering bond/place
  value/skip counting invariants.
- One new widget smoke-test file (`new_screens_smoke_test.dart`) that
  pumps each of the five new screens in a `MaterialApp` and asserts
  they render their entry UI without throwing. Catches `AppTextStyles`
  typos and missing-provider regressions before deploy.
- Full suite: 341/341 passing.

### Refactor
- `SmartAppBar` + `CoinsStreakChip` + `PillIcon` lifted out of
  `home_screen.dart` into `lib/features/home/widgets/smart_app_bar.dart`.
  `home_screen.dart` drops from 2527 → 2280 lines. The overflow menu
  stays inlined because it threads through too many local navigation
  helpers — `SmartAppBar` now takes an `onOverflow` callback.

### Notes
- Real-audio policy from 1.1.96 is preserved — English alphabet's
  speak button hides itself when TTS is off, ready for real phonics
  audio when those MP3s ship.
- No state migration needed; the new screens are read-only practice
  with no persistence beyond what each round generates.

## 1.1.96 — 2026-05-13 — Real Audio Only

### Policy change
- **AI voices (TTS) are now off by default.** The kid only hears real
  reciter audio: Quran verses via the EveryAyah CDN (Mishary Alafasy
  and 5 alternates). Real recitations for Hadith / Azkar / 99 Names /
  Du'a / Tajweed examples are on the roadmap; until they ship the
  speak buttons on those screens are hidden, not just muted.

### Migration
- Existing installs that had `ttsEnabled = true` are flipped to `false`
  exactly once on next load via a `real_audio_only_migrated_v1` flag.
  A parent can re-enable AI voices anytime from the parent dashboard.

### Added
- **`TtsSpeakerIcon` widget** — reusable Consumer that renders the 🔊
  IconButton only when `ttsEnabled` is true, and returns
  `SizedBox.shrink()` otherwise. Replaces the inline
  `IconButton(...speakArabic...)` pattern in 9 screens.
- **Parent dashboard policy banner** — explains the new audio policy
  in both languages, with a clearer "AI voices (TTS)" toggle below.

### Changed
- Speak buttons on these screens now hide entirely when AI voices are
  off (no more dead taps). Full sweep — **20 screens** total:
    - Islamic content: `hadith_memorization`, `asma_ul_husna`,
      `prophet_stories`, `dua`, `athkar`, `tasbih`,
      `hadith_quiz`, `asma_ul_husna_quiz`, `tajweed_basics`,
      `five_pillars`, `six_articles`, and the shared
      `step_guide_screen` (Salah + Wudu).
    - Other: `vocab_flashcards`, `arabic_alphabet`, `maps_screen`,
      `capitals_quiz`, `iq_quiz`, `sciences_quiz`, `logos_screen`,
      `general_quiz_play`, `math_quiz`, `flags_quiz`,
      `learning_zone` (the "Read aloud" button on passages).
- TTS service `_isMuted` state was already wired to the settings
  toggle — when the migration flips `ttsEnabled` to false, all
  in-quiz feedback voices ("correct!", "try again") go silent
  automatically via the existing mute path. No source edits needed
  in those quiz screens.
- Downgraded `_HadithPromptCard` and `_RuleCard` (tajweed) from
  `ConsumerWidget` to `StatelessWidget` — they no longer need `ref`
  after the speak-button refactor.

### Tests
- `+9` test cases. Total: **320 passing**.
  - `real_audio_migration_test.dart` — 6 cases (new install default,
    legacy install flipped, persistence, parent re-enable wins,
    migration flag is one-shot).
  - `tts_speaker_icon_test.dart` — 3 cases (hidden when off, visible
    when on, hidden when text is empty).

## 1.1.95 — 2026-05-12 — Fractions, Parent Insights, Home Cleanup

### Added
- **Fractions Practice** (`/fractions-practice`) — visual fractions
  drill in two modes: Identify (a pie chart shows a shaded slice, pick
  the matching fraction) and Compare (which is bigger, 1/3 or 1/4?).
  10 questions per round, stars at the end. Custom `CustomPainter`
  for the pie visualization — no chart dependency.
- **"At a glance" parent card** (`ThisWeekSummaryCard`) — new section
  on the parent dashboard showing daily-quiz streak, best streak,
  surahs memorized, Islamic favorites, mental-math personal best,
  and tables touched. Plus two callouts: strongest table and the
  one needing the most practice. All reads from existing providers —
  no new persistence.

### Changed
- **More home_screen.dart decomposition** — extracted two more chunks:
  `_StarfieldBackground` (decorative painter) and `_DidYouKnowCard`
  (daily fact tile). home_screen.dart went 2,638 → **2,527 lines**.
  Together with v1.1.94's footer extraction, the file is down -210
  lines from where it was two sessions ago.

### Tests
- `+17` test cases. Total: **311 passing** (was 294 going in).
  - `fractions_engine_test.dart` — 14 cases (FractionVal math,
    star rubric, option uniqueness, proper-fraction invariants,
    comparator correctness).
  - `fractions_smoke_test.dart` — 2 cases (AR + EN at 375px).
  - `this_week_summary_card_test.dart` — 3 cases (empty state,
    strongest/shaky callouts with data, streak-only state).

### Removed
- `lib/features/word_scramble/word_scramble_engine.dart` and
  `assets/data/word_scramble.json` were created in this session but
  removed before commit — a Word Scramble screen already exists at
  `/word-scramble`, so duplicating it would be churn.

## 1.1.94 — 2026-05-12 — Math Practice + Hijri + Home Refactor

### Added
- **Times Tables Practice** (`/multiplication-practice`) — pick a table
  ×2..×12 (or mixed), run a 10-question round, see your accuracy per
  table. The picker surfaces "shaky tables" (any below 80%) so the kid
  can drill what they actually need. Per-table accuracy persists in
  shared_preferences.
- **Mental Math Sprint** (`/mental-math-sprint`) — three difficulty
  bands (Easy: + − to 20; Medium: + − × to 100; Hard: + − × ÷ with
  larger numbers, always-whole-number division). 60-second timed
  sprint. Personal best per band persists.
- **Hijri Converter** (`/hijri-converter`) — under Tools. Pick any
  Gregorian date with the system date picker, see the Hijri date.
  Uses the existing `core/utils/hijri_date.dart` (Kuwaiti tabular
  algorithm).
- **Hijri date display on Daily Wisdom Quiz** — small "🌙 NN month
  YYYY هـ" badge above the streak header so the kid sees both dates
  every time they play their daily question.

### Changed
- **Refactored `home_screen.dart`** — extracted the footer
  (mood check-in + daily verse + daily hadith + daily wisdom + Madrasati
  shortcut) into `lib/features/home/widgets/home_footer_stack.dart`
  as `HomeFooterStack`. home_screen.dart dropped from 2,737 → 2,638
  lines and home_screen no longer imports the daily-banner widgets
  directly.

### Tests
- `+37` test cases. Total: **294 passing** (was 257 going in).
  - `multiplication_progress_test.dart` — 9 cases (stats math,
    shakyTables ranking, JSON roundtrip, persistence).
  - `mental_math_engine_test.dart` — 7 cases (band rules, division
    always whole, prompt format).
  - `mental_math_bests_test.dart` — 5 cases (PB-only updates, band
    independence, persistence).
  - `hijri_date_test.dart` — 8 cases (algorithm spot-checks against
    known anchor dates, full-year range bounds, formatting).
  - `new_screens_smoke_test.dart` (math) — 6 cases (3 screens × AR/EN).

### Fixed
- Tile vertical overflow in the multiplication-practice picker on
  narrow Arabic phones. Reduced childAspectRatio from 1.1 → 0.85 so
  tile content sits comfortably regardless of locale.

## 1.1.93 — 2026-05-12 — Deep Linking, Tajweed, Daily Wisdom

### Added
- **Daily Wisdom Quiz** (`/daily-wisdom-quiz`) — one question per day,
  deterministically chosen from Hadith / 99 Names / Prophets based on the
  date so every family on the same day sees the same question. Tracks
  current streak, longest streak, lifetime correct/attempts. Streak
  continues through wrong answers (kindness > strict gamification) and
  only resets on a missed day. Featured tile on home.
- **Tajweed Basics** (`/tajweed-basics`) — 10 foundational rules
  (Madd, Ghunnah, Ikhfa, Idgham, Iqlab, Qalqalah, sun/moon lams, Idhar,
  Waqf) with Arabic example word + TTS + kid-friendly tip per rule.
- **5 new short surahs**: Al-Fil (105), Al-Qadr (97), At-Tin (95),
  Ad-Duha (93), Al-Inshirah (94). Total in `quran_short_surahs.json`
  jumps 10 → 15. All include Arabic with diacritics + English meaning
  + transliteration. Reciter audio works on all 5 (everyayah CDN).
- **Search deep linking** — when a result is tapped in Islamic Search,
  the receiving screen (`/hadith`, `/names-of-allah`, `/prophet-stories`,
  `/dua`) now opens with `?focusId=X`, scrolls the matching card into
  view after first paint, and flashes a brief border highlight on it.
  Closes the biggest UX gap from v1.1.92.
- **Quick-action chips on My Islamic Journey** — added Daily Wisdom +
  Tajweed alongside the existing Search / quiz shortcuts.

### Changed
- **Streak/highlight timers are dispose-safe** — focused screens use
  cancellable `Timer`s instead of bare `Future.delayed` so widget tear
  down doesn't leak pending callbacks (caught by widget tests).
- **About screen** activity count bumped: 110+ → 120+.

### Tests
- `+31` test cases. Total: **257 passing** (was 226 going in).
  - `multiple_choice_engine_test.dart` — 12 cases (was already there).
  - `daily_question_engine_test.dart` — 9 cases (determinism, kind
    rotation, calendar arithmetic).
  - `daily_quiz_streak_test.dart` — 10 cases (pure transition function +
    notifier persistence).
  - `focus_deep_link_test.dart` — 5 cases (all 4 screens render
    FocusHighlight when given a focusId; FocusHighlight reflects state).
  - `tajweed_and_daily_quiz_smoke_test.dart` — 4 cases (both screens at
    375px AR + EN).
  - Tajweed pack count assertion in `islamic_content_counts_test.dart`.

## 1.1.92 — 2026-05-12 — Islamic Quiz Suite + Search

### Added
- **Hadith Quiz** (`/hadith-quiz`) — 10-question MCQ over the 25-hadith
  pack. Shows the Arabic hadith text, asks for the English meaning, four
  options with same-category distractors (Manners, Faith, Family, …).
  Speak button on the prompt card.
- **Prophet Quiz** (`/prophet-quiz`) — 10-question MCQ over the 25
  prophets pack. Shows a lesson, asks which prophet it belongs to.
  Distractors cluster by era so contemporaneous prophets are the wrong
  answers (harder than random).
- **Islamic Search** (`/islamic-search`) — single-input cross-content
  search over Hadith + 99 Names + Prophet Stories + Duas. Bilingual
  case-insensitive substring match, results grouped by section with
  count, deep-links into source screens. Open with autofocused input.
- **Quick-action chips on My Islamic Journey** — Search, 99 Names Quiz,
  Hadith Quiz, Prophet Quiz buttons below the progress cards so kids
  discover the new content from the hub.

### Changed
- **Refactored Salah and Wudu step screens** into a shared
  `StepGuideScreen` widget (`lib/core/widgets/step_guide_screen.dart`).
  Both screens are now thin wrappers (~20 lines each, was ~300). Net
  -280 lines.
- **Extracted asma quiz logic** to `asma_quiz_engine.dart` and built a
  generic `multiple_choice_engine.dart` + `MCQuizScreen<T>` widget that
  powers the new quizzes. Adding a new MCQ quiz is now <100 lines of
  glue + a JSON pack.
- **Accessibility** — added missing `tooltip` strings on three TTS icon
  buttons (asma quiz, five pillars, six articles); wrapped step progress
  bars in a `Semantics(label: "Step X of N")` block so screen readers
  announce step progress instead of raw progress %.

### Tests
- `+70` test cases. Total: **226 passing**.
  - `asma_quiz_engine_test.dart` — 17 cases (distractor selection,
    stars rubric, edge cases).
  - `multiple_choice_engine_test.dart` — 12 cases for the generic
    engine that powers Hadith + Prophet quizzes.
  - `quran_progress_provider_test.dart` — 6 cases (toggle, persistence,
    corrupt-JSON resilience).
  - `cloud_tts_url_test.dart` — 8 cases for the cloud TTS URL builder
    (form encoding, cache-key stability).
  - `islamic_search_test.dart` — 13 cases (indexers, query, grouping).
  - `untested_screens_smoke_test.dart` + `new_quiz_and_search_smoke_test.dart`
    — 16 cases (Five Pillars, Six Articles, Salah, Wudu, Islamic
    Journey, Hadith Quiz, Prophet Quiz, Search at 375px in AR + EN).

### Fixed
- Header row overflow on the quiz screens at 375px — question counter
  is now `Flexible` with ellipsis and the English label is shortened
  to "Q N / M" to keep the score pill on the same line.

## 1.1.81 — 2026-05-06 — Wave 78

### Added
- **Famous Palaces of the World pack** (`famous_palaces_world.json`,
  prefix `plc_`) — 60 items spanning Buckingham, Versailles (Louis
  الرابع عشر, Hall of Mirrors), Topkapi, Forbidden City, Schönbrunn,
  Peterhof, Catherine (Amber Room), Winter (Hermitage), Doge's
  Palace Venice, Royal Palace of Madrid, Pena (Sintra), Caserta,
  Hampton Court (Henry الثامن), Dolmabahçe, Alhambra, Bahia
  (Marrakech), Dar al-Makhzen Fez, Qasr al-Hosn (Abu Dhabi), Qasr
  al-Watan (UAE Presidential), Bayan & Seif (Kuwait), Beiteddine
  (Lebanon), Al-Azem (Damascus), Mysore Palace, Taj Lake Palace
  Udaipur, Red Fort Delhi, City Palace Jaipur, Chowmahalla &
  Falaknuma (Hyderabad), Lahore Fort Sheesh Mahal, Noor Mahal
  (Bahawalpur), Gyeongbokgung & Changdeokgung (Seoul), Imperial
  Palace Tokyo, Grand Palace Bangkok, Phnom Penh Royal Palace,
  Chambord, Chenonceau, Linderhof, Neuschwanstein.
- **Famous Boxers pack** (`famous_boxers.json`, prefix `box_`) — 60
  items on Muhammad Ali (Rumble in the Jungle ١٩٧٤, Thrilla in Manila
  ١٩٧٥, Atlanta ١٩٩٦ flame), Frazier, Foreman, Sugar Ray Robinson
  (pound-for-pound GOAT), Sugar Ray Leonard, Durán (Hands of Stone),
  Hagler, Hearns, Mike Tyson (youngest heavyweight champ at ٢٠ in
  ١٩٨٦), Holyfield, Lewis, Mayweather Jr. (٥٠-٠), Pacquiao (٨ weight
  classes), De La Hoya, Hopkins, Roy Jones Jr., Klitschko brothers,
  Tyson Fury, Joshua, Wilder, Canelo, GGG, Naseem Hamed, Joe Louis,
  Marciano (٤٩-٠), Dempsey-Tunney Long Count ١٩٢٧, Jack Johnson (first
  black heavyweight champ ١٩٠٨), Henry Armstrong (٣ titles
  simultaneously), LaMotta (Raging Bull), Monzón, Chávez, Salvador
  Sánchez, Argüello, Eubank-Benn rivalry, Teófilo Stevenson (Cuba ٣x
  Olympic gold). Women: Laila Ali, Claressa Shields (٣x Olympic
  champion), Katie Taylor, Cecilia Brækhus, Amanda Serrano. WBC/WBA/
  IBF/WBO sanctioning bodies, Marquess of Queensberry rules.
- **Famous Game Consoles pack** (`famous_game_consoles.json`, prefix
  `gcn_`) — 60 items on Nintendo (NES/SNES/N٦٤/GameCube/Wii/Switch/
  Switch ٢, Game Boy line, DS/٣DS, Virtual Boy, Game & Watch ١٩٨٠),
  Sega (Master System, Genesis/Mega Drive, Saturn, Dreamcast,
  Game Gear), Sony (PS١-PS٥, PSP, PS Vita, best-selling PS٢ at
  ١٥٥M+), Microsoft (Xbox/Xbox ٣٦٠/One/Series X|S), Atari (٢٦٠٠
  VCS ١٩٧٧, ٥٢٠٠, ٧٨٠٠, Lynx, Jaguar), Magnavox Odyssey (first home
  console ١٩٧٢), Intellivision, ColecoVision, Neo Geo, ٣DO,
  PC Engine/TurboGrafx-١٦, Steam Deck (Valve ٢٠٢٢). Launch titles
  Halo: CE, Wii Sports, Astro's Playroom, Tetris (Game Boy bundle).
- **Color Mix mini-game** — 🎀 pill on home shelf. Color-theory
  educational quiz: show two source color circles + ?, pick the
  resulting mixed color from ٤ tinted buttons. ١١ classic mixes
  (red+yellow=orange, blue+yellow=green, red+blue=purple, red+white=
  pink, white+black=gray, etc.). 60s round, ٢🪙/٥🪙/١٠🪙 coin tiers
  at scores ٨/١٦/٢٤. Locale-aware Arabic color names.

## 1.1.80 — 2026-05-06 — Wave 77

### Added
- **Famous F1 Drivers pack** (`famous_f1_drivers.json`, prefix `f1d_`)
  — 60 items spanning Fangio (5x ١٩٥٠s), Clark, Stewart, Lauda
  (١٩٧٦ fire return), Senna (3x), Prost (4x), Mansell, Hill,
  Häkkinen, Schumacher (7x Ferrari era), Alonso, Räikkönen,
  Hamilton (7x Mercedes), Vettel (4x Red Bull), Rosberg, Verstappen
  (champion ٢٠٢١-٢٠٢٤), Leclerc, Norris, Piastri, Russell,
  Sainz Jr., Massa; teams Ferrari, McLaren, Williams, Mercedes,
  Red Bull, Lotus, Brabham, Tyrrell, Renault, Alpine, BAR; circuits
  Monaco, Silverstone, Spa, Monza, Suzuka, Interlagos, Imola,
  Bahrain, Jeddah, Abu Dhabi; technical eras (V١٠/V١٢, hybrid
  ٢٠١٤, halo ٢٠١٨).
- **Famous Chess Players pack** (`famous_chess_players.json`, prefix
  `chs_`) — 60 items on world champions Steinitz, Lasker, Capablanca,
  Alekhine, Botvinnik, Tal, Petrosian, Spassky, Fischer, Karpov,
  Kasparov (vs Deep Blue ١٩٩٦/٩٧), Kramnik, Anand, Carlsen, Ding
  Liren, Gukesh Dommaraju (youngest ever ٢٠٢٤). Top players Nakamura,
  Caruana, Aronian, So, Nepomniachtchi, Firouzja, Praggnanandhaa.
  Women: Menchik, Gaprindashvili, Polgár sisters (Judit highest-rated
  woman ever), Hou Yifan, Ju Wenjun. Historical Morphy, Staunton,
  Anderssen. Famous matches Fischer-Spassky ١٩٧٢ Reykjavík,
  Karpov-Kasparov ١٩٨٤-٨٥, Carlsen-Caruana ٢٠١٨, Ding-Gukesh ٢٠٢٤.
  Engines Stockfish, AlphaZero, Leela.
- **Famous Galaxies & Cosmic Objects pack** (`famous_galaxies_cosmic.json`,
  prefix `gxy_`) — 60 items on Milky Way, Andromeda M٣١, Triangulum
  M٣٣, Whirlpool M٥١, Sombrero M١٠٤, Cigar M٨٢, Pinwheel M١٠١,
  Centaurus A NGC ٥١٢٨, Black Eye M٦٤, Antennae galaxies, Magellanic
  Clouds (LMC + SMC), IC ١١٠١, Bullet Cluster, Stephan's Quintet,
  GN-z١١. Supernovae Crab (١٠٥٤), Tycho ١٥٧٢, Kepler ١٦٠٤, SN ١٩٨٧A.
  Quasars ٣C ٢٧٣, TON ٦١٨. Pulsars Crab Pulsar, PSR B١٩١٩+٢١ (Bell
  Burnell). Hubble Deep/Ultra-Deep Field, JWST Deep Field, AGN,
  Sagittarius A*, M٨٧ EHT image.
- **Bowling mini-game** — 🎳 pill on home shelf. Lane drawn via
  CustomPainter showing ١٠ pins in triangle formation; aim arrow
  oscillates left-right; tap "Roll!" to release. Aim accuracy
  determines pins knocked. Frame-based scoring across ١٠ frames
  with strikes (🎯 STRIKE!) and spares (✨ SPARE!). ٢🪙/٥🪙/١٠🪙
  coin tiers at scores ٦٠/١٠٠/١٥٠.

## 1.1.79 — 2026-05-06 — Wave 76

### Added
- **Famous Programming Languages pack** (`famous_programming_languages.json`,
  prefix `prg_`) — 60 items on C (Ritchie ١٩٧٢), C++ (Stroustrup
  ١٩٨٥), Java (Gosling ١٩٩٥), Python (van Rossum ١٩٩١), JavaScript
  (Eich ١٩٩٥), Ruby (Matsumoto ١٩٩٥), PHP (Lerdorf ١٩٩٥), Pascal
  (Wirth ١٩٧٠), BASIC (Kemeny & Kurtz ١٩٦٤), Fortran (Backus
  ١٩٥٧), COBOL (Hopper team ١٩٥٩), Lisp (McCarthy ١٩٥٨), Swift
  (Apple ٢٠١٤), Kotlin (JetBrains ٢٠١١), Go (Google ٢٠٠٩), Rust
  (Mozilla ٢٠١٠), TypeScript (Microsoft / Hejlsberg ٢٠١٢), C#
  (Hejlsberg ٢٠٠٠), Dart (Bak / Google ٢٠١١), Scala, Haskell,
  Erlang (Armstrong), Elixir (Valim), R, MATLAB, SQL, HTML/CSS,
  Lua, Objective-C, Ada (named after Ada Lovelace), and more.
- **Famous Children's TV Shows pack** (`famous_childrens_tv.json`,
  prefix `cts_`) — 60 items spanning Sesame Street (Big Bird,
  Cookie Monster, Elmo, Oscar, Bert/Ernie, Grover), Mr. Rogers,
  Reading Rainbow, Dora the Explorer, Blue's Clues, Teletubbies,
  Barney, The Wiggles, Power Rangers, Bluey, Peppa Pig, Paw Patrol,
  Daniel Tiger, Mickey Mouse Clubhouse, PJ Masks, Octonauts, Postman
  Pat, Bob the Builder, Thomas & Friends, Magic School Bus, Arabic
  classics Iftah Ya Simsim, Manahel, Spacetoon, MBC3, plus Doraemon,
  Pokémon, Hello Kitty/Sanrio.
- **Famous Pets in History pack** (`famous_pets_history.json`, prefix
  `pet_`) — 60 items on space animals (Laika, Belka & Strelka, Ham,
  Felicette, Albert II), war heroes (Cher Ami pigeon, Wojtek bear,
  Sgt. Stubby, Sgt. Reckless horse, Smoky), loyalty icons (Hachiko,
  Greyfriars Bobby, Bobi, Balto, Togo), historical pets (Cleopatra,
  Tutankhamun, Prophet Muhammad's cat Muezza, Newton's Diamond,
  Picasso's Lump, Frida Kahlo's Xolos, Dalí's Babou, Dickens' Grip,
  Poe's Catterina, Hemingway's polydactyls), modern presidential/royal
  (JFK's Pushinka, Obama's Bo & Sunny, Queen Elizabeth's corgis), and
  Gulf heritage (camel racing/hijin, Akhal-Teke, Saluki, falconry).
- **Hangman mini-game** — 🪢 pill on home shelf. Classic letter-guess
  word puzzle with bilingual word banks (٥٠+ EN words, ٥٠+ AR words).
  Locale-aware alphabet pad (٢٦ EN letters / ٣٦ AR letters). ٦
  misses per word. ٧٥-second round, ٢🪙/٥🪙/١٠🪙 coin tiers at
  scores ٣/٦/١٠.

## 1.1.78 — 2026-05-06 — Wave 75

### Added
- **Famous Tennis Players pack** (`famous_tennis_players.json`, prefix
  `tns_`) — 60 items spanning Federer/Nadal/Djokovic Big-3, Next-Gen
  Alcaraz/Sinner/Medvedev/Zverev/Tsitsipas, legends Sampras, Agassi,
  McEnroe, Connors, Borg, Lendl, Wilander, Edberg, Becker, Laver,
  Rosewall, women's icons Serena/Venus, Graf, Court, Navratilova,
  Evert, Goolagong, Hingis, Sharapova, Henin, Clijsters, modern WTA
  Halep, Osaka, Swiatek, Sabalenka, Pegula, Gauff, Rybakina, plus
  Davis Cup, BJK Cup, four Slams, ATP/WTA, Olympic gold concepts.
- **Famous Cartoons & Animated Films pack** (`famous_cartoons.json`,
  prefix `crt_`) — 60 items on Disney classics, Pixar, Studio
  Ghibli, Looney Tunes, Hanna-Barbera, Cartoon Network, Nickelodeon,
  DreamWorks, The Simpsons, Peanuts, Tintin, Asterix, Doraemon,
  Pokémon. All age-appropriate.
- **Famous Aircraft & Spacecraft pack** (`famous_aircraft_spacecraft.json`,
  prefix `acs_`) — 60 items on Wright Flyer, Concorde, Boeing
  ٧٤٧/٧٧٧/٧٨٧, Airbus A٣٨٠/A٣٥٠, Cessna ١٧٢, Sputnik ١, Vostok ١
  (Gagarin), Apollo ١١/١٣/١٧, Lunar Module, Soyuz, Mir, ISS, Hubble,
  JWST, Voyager ١/٢, Cassini, Curiosity, Perseverance, Ingenuity,
  SpaceX Falcon ٩/Heavy/Starship/Crew Dragon, Saturn V, Ariane ٥/٦.
- **Tell the Time mini-game** — 🕒 pill on home shelf. Analog clock
  with hour + minute hand drawn via CustomPainter; pick the matching
  digital time from 4 multiple-choice buttons. ٥-min granularity. 60s
  round, ٢🪙/٥🪙/١٠🪙 coin tiers at scores ٨/١٦/٢٤. Locale-aware
  Arabic-Indic digits in clock readings.

## 1.1.77 — 2026-05-06 — Wave 74

### Added
- **Famous Inventors & Inventions pack** (`famous_inventors.json`, prefix
  `inv_`) — 60 items spanning Edison, Tesla, Bell, Wright Brothers,
  Marie Curie, Newton, Gutenberg, da Vinci, Einstein, Franklin, Eli
  Whitney, Henry Ford, Karl Benz, Marconi, Steve Jobs, Tim Berners-Lee,
  Hedy Lamarr, Garrett Morgan, Stephanie Kwolek, George Washington
  Carver, plus Arab/Muslim Golden Age inventors Al-Khwarizmi,
  Al-Jazari, Ibn al-Haytham, Abbas Ibn Firnas. 22 easy / 24 medium /
  14 hard.
- **Famous Theme Parks & Roller Coasters pack** (`famous_theme_parks.json`,
  prefix `tpk_`) — 60 items spanning Disney parks worldwide
  (Disneyland, WDW, Paris, Tokyo, Shanghai, Hong Kong), Universal,
  Six Flags, Cedar Point, Tivoli Gardens, PortAventura, Ferrari World
  Abu Dhabi, IMG Worlds Dubai, Lotte World, Everland, Alton Towers,
  Legoland, plus iconic coasters Kingda Ka, Steel Vengeance, Formula
  Rossa, Top Thrill 2, Millennium Force.
- **Famous Video Games pack** (`famous_video_games.json`, prefix `vgm_`)
  — 60 items on Mario, Zelda, Pokémon, Minecraft, Tetris, Pac-Man,
  Sonic, Donkey Kong, Street Fighter, Final Fantasy, World of
  Warcraft, FIFA, Fortnite, Roblox, Among Us, Stardew Valley, Animal
  Crossing, Halo, The Sims, Angry Birds, Candy Crush. M-rated
  franchises referenced only by neutral facts (developer, year,
  genre name).
- **Speed Math mini-game** — 📐 pill on home shelf. Mental-arithmetic
  flashcards: ramp from +/− single-digit (early), to ×, to ÷ (after
  score ≥١٠). 4 multiple-choice answers, 60s round, ٢🪙/٥🪙/١٠🪙
  coin tiers at scores ١٠/٢٠/٣٢. Locale-aware (Arabic-Indic digits
  in expression and answer buttons).

## 1.1.76 — 2026-05-06 — Wave 73

### Added
- **Famous Painters & Paintings pack** (`famous_painters.json`)
  — 60 items on **Leonardo da Vinci (١٤٥٢–١٥١٩, Mona Lisa
  ~١٥٠٣–١٩, Last Supper ١٤٩٥–٩٨ Milan)**, **Mona Lisa at
  Louvre**, **stolen ١٩١١ by Vincenzo Peruggia, recovered
  ١٩١٣**, **Michelangelo (١٤٧٥–١٥٦٤, Sistine Chapel ceiling
  ١٥٠٨–١٢, Last Judgment ١٥٤١, David ١٥٠١–٠٤)**, **Raphael
  "School of Athens" ١٥٠٩–١١**, **Botticelli "Birth of
  Venus" ~١٤٨٥**, **Van Gogh (١٨٥٣–١٨٩٠, "Starry Night"
  ١٨٨٩, "Sunflowers", sold only ١ painting in life)**,
  **Picasso (١٨٨١–١٩٧٣, Cubism, "Guernica" ١٩٣٧)**,
  **Monet (١٨٤٠–١٩٢٦, "Impression, Sunrise" ١٨٧٢ named
  Impressionism, Water Lilies, Giverny)**, **Dalí "The
  Persistence of Memory" ١٩٣١ (melting clocks)**, **Magritte
  "The Treachery of Images"**, **Pollock drip painting**,
  **Warhol Pop Art (Campbell's Soup ١٩٦٢, Marilyn screen
  prints)**, **Lichtenstein "Whaam!"**, **Banksy "Girl with
  Balloon" shredded at auction ٢٠١٨**, **Frida Kahlo
  (١٩٠٧–١٩٥٤ self-portraits, married Diego Rivera)**,
  **Munch "The Scream" ١٨٩٣**, **Klimt "The Kiss"
  ١٩٠٧–٠٨**, **Hieronymus Bosch "Garden of Earthly
  Delights" ~١٥٠٠**, **Jan van Eyck "Arnolfini Portrait"
  ١٤٣٤ oil paint pioneer**, **Rembrandt "The Night Watch"
  ١٦٤٢**, **Vermeer "Girl with a Pearl Earring" ~١٦٦٥**,
  **Velázquez "Las Meninas" ١٦٥٦**, **Goya "The Third of
  May ١٨٠٨"**, **Delacroix "Liberty Leading the People"
  ١٨٣٠**, **Hokusai "The Great Wave off Kanagawa" ١٨٣١
  ukiyo-e**, **Hopper "Nighthawks" ١٩٤٢**, **Wood "American
  Gothic" ١٩٣٠**, **Salvator Mundi (attributed to Leonardo)
  $٤٥٠٫٣M ٢٠١٧ most expensive painting sold**.
- **Famous Astronauts & Cosmonauts pack**
  (`famous_astronauts.json`) — 60 items on **Yuri Gagarin
  first human in space Vostok 1 April ١٢ ١٩٦١ (~١٠٨ min
  orbit)**, **Neil Armstrong first man on Moon Apollo 11
  July ٢٠ ١٩٦٩ ("That's one small step for man, one giant
  leap for mankind")**, **Buzz Aldrin second on Moon
  ("Magnificent desolation")**, **Michael Collins orbited
  Moon while Armstrong + Aldrin landed**, **Apollo 11
  launched July ١٦ ١٩٦٩ from Kennedy Space Center**,
  **lunar module name: Eagle**, **١٢ humans walked on Moon
  (all American Apollo missions ١٩٦٩–١٩٧٢)**, **Eugene
  Cernan last man on Moon Apollo 17 Dec ١٩٧٢**, **Alan
  Shepard first American in space May ٥ ١٩٦١, hit golf
  ball on Moon Apollo 14**, **John Glenn first American
  to orbit Earth Feb ٢٠ ١٩٦٢; oldest in space ٧٧ STS-95
  ١٩٩٨**, **Valentina Tereshkova first woman in space
  Vostok 6 June ١٦ ١٩٦٣**, **Sally Ride first American
  woman in space STS-7 June ١٨ ١٩٨٣**, **Mae Jemison first
  African American woman in space STS-47 Sept ١٩٩٢**,
  **Christa McAuliffe (teacher, died Challenger Jan ٢٨
  ١٩٨٦)**, **Apollo 13 (April ١١–١٧ ١٩٧٠ "Houston, we have
  a problem")**, **Sultan bin Salman Al Saud first Arab +
  first Muslim astronaut June ١٩٨٥ Saudi Arabia**, **Hazza
  Al Mansouri first Emirati astronaut ISS Sept ٢٠١٩**,
  **Sultan AlNeyadi first Arab on long-duration ISS
  ٢٠٢٣**, **Rakesh Sharma first Indian Soyuz T-11 ١٩٨٤**,
  **Yang Liwei first Chinese in space Shenzhou 5 ٢٠٠٣**,
  **Dennis Tito first space tourist ISS April ٢٠٠١
  $٢٠M**, **William Shatner oldest in space ٩٠ Blue
  Origin Oct ٢٠٢١**, **NASA founded ١٩٥٨**, **ISS
  continuously occupied since Nov ٢ ٢٠٠٠**, **JWST
  launched Dec ٢٥ ٢٠٢١**, **Hubble launched April ٢٤
  ١٩٩٠**, **MBRSC UAE founded ٢٠٠٦**, **SpaceX founded
  ٢٠٠٢ Elon Musk**, **first crewed SpaceX Dragon: Bob
  Behnken + Doug Hurley May ٣٠ ٢٠٢٠**.
- **Famous Logos & Brand Origins pack** (`famous_logos.json`)
  — 60 items on **Apple logo (apple with bite, designed by
  Rob Janoff ١٩٧٧, rainbow stripes ١٩٧٧–٩٨)**, **Nike
  Swoosh (designed by Carolyn Davidson ١٩٧١ for $٣٥; Nike
  = Greek goddess of victory)**, **"Just Do It" slogan
  (١٩٨٨)**, **Adidas 3-stripes (Adi Dassler ١٩٤٩, brother
  Rudolf founded Puma)**, **Coca-Cola (١٨٨٦ John Pemberton
  Atlanta, distinctive Spencerian script designed by Frank
  Mason Robinson)**, **McDonald's Golden Arches (designed
  ١٩٦٢ by Jim Schindler; first franchise Ray Kroc ١٩٥٥)**,
  **Starbucks Siren (twin-tailed mermaid since ١٩٧١, Pike
  Place Seattle first store; named after Starbuck in
  "Moby-Dick")**, **Google (Brin + Page ١٩٩٨, name from
  "googol" ١٠^١٠٠)**, **Microsoft 4-color flag (since
  ١٩٩٢, redesigned ٢٠١٢, Gates + Allen founded ١٩٧٥)**,
  **Amazon arrow A→Z smile (since ٢٠٠٠, founded ١٩٩٤ by
  Jeff Bezos as "Cadabra")**, **Twitter bird "Larry"
  replaced by X ٢٠٢٣**, **Facebook (Zuckerberg ٢٠٠٤),
  Meta rebrand Oct ٢٨ ٢٠٢١**, **WhatsApp sold to Facebook
  ٢٠١٤ for $١٩B**, **YouTube founded ٢٠٠٥ (Chen + Hurley
  + Karim, "Me at the Zoo" first video)**, **Mercedes
  3-pointed star (١٩٠٩, land + sea + air)**, **Audi 4
  rings (١٩٣٢ Auto Union)**, **Lamborghini bull (١٩٦٣,
  Ferruccio's Taurus zodiac)**, **Ferrari prancing horse
  from WWI ace Francesco Baracca (١٩٢٣)**, **Olympic 5
  rings (١٩١٣ Pierre de Coubertin)**, **WWF panda (١٩٦١
  Sir Peter Scott)**, **Linux Tux penguin (١٩٩٦ Larry
  Ewing)**, **Android "Bugdroid" green robot (Irina Blok
  ٢٠٠٧)**, **MGM lion roar Leo since ١٩٢٤**, **Coca-Cola
  most-recognized brand worldwide**.
- **Anagram Solver mini-game** — locale-aware word puzzle:
  show scrambled letters of an English (~٨٠ words: BIRD,
  FISH, EAGLE, APPLE, HOUSE, CLOUD, etc.) or Arabic
  (~٦٠ words: كتاب، شجرة، تفاح، بيت، كرسي، إلخ.) word;
  tap letters in order to spell. Clear + Skip controls;
  ٦٠s round; coin tiers ٢🪙/٥🪙/١٠🪙 at scores ٨/١٦/٢٦.

### Cumulative
- 194 quiz packs (~١١٬٦٤٠ items), 73 mini-games on the home shelf.

## 1.1.75 — 2026-05-06 — Wave 72

### Added
- **Famous National Parks pack** (`famous_national_parks.json`)
  — 60 items on **Yellowstone (USA, est. March ١ ١٨٧٢,
  world's first national park, geysers, Old Faithful,
  Wyoming/Montana/Idaho)**, **Yosemite California (El
  Capitan + Half Dome)**, **Sequoia (General Sherman tree
  largest by volume on Earth, ~٨٤م, ~٢٬٥٠٠ years old)**,
  **Redwood (tallest trees ~١١٥م Hyperion)**, Grand Canyon,
  **Death Valley (Badwater −٨٦م lowest in N. America;
  hottest temp ٥٦٫٧°C ١٩١٣)**, **Denali Alaska (~٦٬١٩٠م,
  N. America's highest)**, Hawaii Volcanoes, **Banff +
  Jasper Canadian Rockies (Lake Louise, Moraine Lake)**,
  **Galápagos Ecuador (evolution)**, **Iguazu Argentina/
  Brazil (~٢٧٥ waterfalls)**, **Torres del Paine Patagonia**,
  **Serengeti Tanzania (Great Migration ~١٫٥M wildebeest)**,
  **Ngorongoro Crater Tanzania**, **Kruger South Africa
  (Big 5)**, **Maasai Mara Kenya**, **Volcanoes National
  Park Rwanda (gorillas, Dian Fossey)**, **Bwindi Impenetrable
  Uganda**, **Royal Chitwan Nepal (tigers + rhinos)**,
  **Sagarmatha Nepal (includes Mt Everest)**, **Komodo
  Indonesia (Komodo dragons)**, **Plitvice Lakes Croatia
  (~١٦ lakes)**, **Vatnajökull Iceland (Europe's largest
  national park)**, **Wadi Rum Jordan ("Valley of the
  Moon")**, **Saudi: Asir + Farasan Islands + AlUla**,
  **Sabah Al Ahmad Natural Reserve Kuwait**, **Kakadu
  Australia UNESCO**, **Uluru-Kata Tjuta Australia**,
  **Fiordland NZ (Milford Sound)**, **John Muir + Yosemite
  creation**, **Theodore Roosevelt "Conservation
  President" created ٥ NPs**, **National Park Service US
  ١٩١٦**, **most-visited park world: Great Smoky Mountains
  TN/NC**.
- **Famous Animals in History pack** (`famous_animals_history.json`)
  — 60 items on **Laika first animal in orbit (Soviet
  Sputnik 2 Nov ٣ ١٩٥٧)**, **Belka + Strelka first dogs to
  return safely from orbit (Sputnik 5 ١٩٦٠)**, **Ham first
  hominid in space (Mercury-Redstone 2 Jan ٣١ ١٩٦١)**,
  **Albert II first primate in space (V-2 rocket June ١٤
  ١٩٤٩)**, **Hachiko Akita dog Japan (waited ٩ years ٩
  months for deceased owner at Shibuya station ١٩٢٥–١٩٣٥;
  statue at Shibuya since ١٩٣٤)**, **Greyfriars Bobby
  Skye Terrier Edinburgh (sat on owner's grave ١٤ years
  ١٨٥٨–١٨٧٢)**, **Balto + Togo sled dogs (١٩٢٥ serum run
  to Nome Alaska, diphtheria; statue Central Park NYC)**,
  **Seabiscuit American thoroughbred (Depression-era
  hero ١٩٣٠s)**, **Secretariat Triple Crown winner ١٩٧٣
  (Belmont Stakes ٣١-length record)**, **Bucephalus
  (Alexander the Great's horse)**, **Marengo (Napoleon's
  horse)**, **Sergeant Stubby most decorated WWI dog
  (served ١٧ months Western Front)**, **Cher Ami carrier
  pigeon WWI ١٩١٨ (saved Lost Battalion, awarded Croix de
  Guerre)**, **Wojtek (Syrian brown bear, WWII Polish
  artillery soldier, Battle of Monte Cassino)**, **Jumbo
  P.T. Barnum elephant ("jumbo size" coined)**, **Lonesome
  George last Pinta Island tortoise (died ٢٠١٢, ~١٠٠
  years old)**, **Punxsutawney Phil groundhog Groundhog
  Day Feb ٢ since ١٨٨٧ Pennsylvania**, **Koko the Gorilla
  taught sign language (١٩٧١–٢٠١٨, ~١٬٠٠٠ signs)**,
  **Alex the African Grey parrot (Irene Pepperberg,
  learned ~١٠٠ words)**, **Lassie (collie, Lassie Come-
  Home ١٩٤٣)**, Rin Tin Tin German Shepherd Hollywood
  star, Toto Cairn Terrier (Wizard of Oz ١٩٣٩),
  Snoopy/Garfield/Mickey Mouse/Donald Duck/Bugs Bunny/
  Tom & Jerry/Scooby-Doo, **Black Beauty ١٨٧٧ novel
  (Anna Sewell)**, **Charlotte's Web (Wilbur the pig +
  Charlotte the spider)**, Bambi/101 Dalmatians/Lady and
  the Tramp, **Smokey Bear US Forest Service mascot ١٩٤٤
  ("Only You Can Prevent Forest Fires")**, **Aslan Narnia
  lion**, **Hedwig snowy owl Harry Potter**.
- **Famous Music Festivals & Concerts pack**
  (`famous_music_festivals.json`) — 60 age-appropriate
  items on **Woodstock (Aug ١٥–١٨ ١٩٦٩, Bethel NY,
  ~٤٠٠٬٠٠٠ attendees, "3 Days of Peace and Music")**,
  Woodstock performers (Hendrix, Janis Joplin, The Who,
  Joan Baez, Santana), **Hendrix played Star-Spangled
  Banner**, **Glastonbury (UK, Worthy Farm Somerset
  since ١٩٧٠, Michael Eavis founded, ~٢٠٠٬٠٠٠ attendees)**,
  **Coachella since ١٩٩٩**, **Lollapalooza since ٢٠٠٥
  (originally ١٩٩١ alt-rock tour by Perry Farrell)**,
  **Tomorrowland Belgium since ٢٠٠٥ (EDM)**, **SXSW
  Austin since ١٩٨٧ (music + film + tech)**, **Rock in
  Rio since ١٩٨٥ (~١٫٤M attendees largest)**, **MDLBeast
  Soundstorm Saudi Arabia since ٢٠١٩**, **Mawazine
  Festival Morocco**, **Eurovision Song Contest since
  ١٩٥٦ (ABBA won ١٩٧٤)**, **Live Aid (July ١٣ ١٩٨٥, Bob
  Geldof + Midge Ure organized for Ethiopian famine,
  simultaneous London Wembley + Philadelphia JFK, ~١٫٩
  billion TV viewers)**, **Live Aid Queen Freddie
  Mercury legendary performance**, **Concert for
  Bangladesh ١٩٧١ (George Harrison + Ravi Shankar, first
  major benefit concert)**, **Newport Folk Festival
  ١٩٥٩ (Bob Dylan went electric ١٩٦٥)**, **Newport Jazz
  Festival ١٩٥٤**, **Monterey Pop Festival ١٩٦٧
  (Hendrix burned guitar)**, **Knebworth UK (Oasis ١٩٩٦
  ~٢٥٠٬٠٠٠ over ٢ nights)**, **MTV VMAs since ١٩٨٤**,
  **Grammy Awards since ١٩٥٩**, **Brit Awards since
  ١٩٧٧**, **The Beatles last concert Candlestick Park
  Aug ٢٩ ١٩٦٦**, **The Beatles rooftop concert Apple
  Records Jan ٣٠ ١٩٦٩**, **Elvis Aloha from Hawaii ١٩٧٣
  (~١٫٥B viewers via satellite)**, **Taylor Swift Eras
  Tour ٢٠٢٣–٢٤ ($٢B+ highest-grossing tour ever)**.
- **Spot the Odd Color mini-game** — 3×3 grid of colored
  squares, all the same except one slightly different
  shade (HSL lightness shift); tap the odd cell. Difficulty
  grows: shade-difference shrinks as score grows
  (٠٫٢٠ → ٠٫٠٦). ٦٠s round; coin tiers ٢🪙/٥🪙/١٠🪙 at
  scores ١٢/٢٤/٤٠.

### Cumulative
- 191 quiz packs (~١١٬٤٦٠ items), 72 mini-games on the home shelf.

## 1.1.74 — 2026-05-06 — Wave 71

### Added
- **Famous Diamonds & Crown Jewels pack** (`famous_diamonds.json`)
  — 60 items on **Cullinan Diamond (largest gem-quality
  rough ever, ٣٬١٠٦ carats, found ١٩٠٥ South Africa, cut
  into ١٠٥ stones; Cullinan I "Star of Africa" in British
  Sovereign's Sceptre ٥٣٠٫٢ carats)**, **Cullinan II in
  Imperial State Crown UK**, **Hope Diamond ٤٥٫٥٢ carats
  blue "cursed" (Smithsonian since ١٩٥٨)**, **Koh-i-Noor
  ١٠٥٫٦ carats in Queen Mother's Crown (India/Pakistan/
  Iran/Afghanistan/UK contested)**, **Tiffany Yellow
  Diamond ١٢٨٫٥٤ carats (Audrey Hepburn wore for
  "Breakfast at Tiffany's" ١٩٦١)**, **Lesedi La Rona
  ١٬١٠٩ carats rough (Botswana ٢٠١٥ second-largest after
  Cullinan)**, **Pink Star ٥٩٫٦ carats sold $٧١٫٢M ٢٠١٧**,
  **Regent Diamond Louvre + Sancy Diamond Louvre**, **Crown
  Jewels housed at Tower of London**, **Russian Imperial
  Crown ١٧٦٢ (٤٬٩٣٦ diamonds + ٧٥ pearls)**, **Iranian
  Crown Jewels Daria-i-Noor pink ~١٨٢ carats**, **De Beers
  founded ١٨٨٨ Cecil Rhodes**, **"A diamond is forever"
  slogan ١٩٤٧ N.W. Ayer**, **diamonds form ~١٥٠–٢٠٠كم
  deep in mantle, brought up by kimberlite pipes**,
  **diamond Mohs ١٠ (hardest natural)**, **4 Cs: Cut +
  Color + Clarity + Carat**, **carat = ٢٠٠ mg**, **round
  brilliant cut Tolkowsky ١٩١٩ (٥٨ facets)**, **first
  synthetic diamond ١٩٥٤ GE**, **Argyle mine Australia
  closed ٢٠٢٠ (source of pink diamonds)**, **Kimberley
  Process ٢٠٠٣ (conflict-free certification)**, **diamond
  engagement ring tradition Maximilian I → Mary of Burgundy
  ١٤٧٧**, **Antwerp Belgium diamond center + Surat India
  cutting**, **Greek "adamas" = unconquerable (root of
  "adamant")**, **graphite vs diamond same element (carbon)
  different structure**.
- **Famous Theater Plays & Playwrights pack**
  (`famous_plays.json`) — 60 age-appropriate items on
  **Shakespeare (١٥٦٤–١٦١٦, ~٣٧ plays + ١٥٤ sonnets, born
  + died on April ٢٣ St. George's Day)**, **Globe Theatre
  London (built ١٥٩٩, burned ١٦١٣, modern reconstruction
  ١٩٩٧)**, **First Folio ١٦٢٣ (Heminge + Condell)**,
  Shakespeare tragedies (Hamlet, Macbeth, Othello, Romeo
  & Juliet, Julius Caesar), comedies (Midsummer Night's
  Dream, Twelfth Night, Tempest), histories (Henry V,
  Richard III), **"To be or not to be" (Hamlet)**, **"Et
  tu, Brute?"**, **Stratford-upon-Avon birthplace**,
  **Greek tragedy: Aeschylus + Sophocles ("Oedipus Rex")
  + Euripides**, **Greek comedy: Aristophanes**,
  **Theatre of Dionysus Athens**, **commedia dell'arte
  (Italian, ١٦th century, Harlequin/Pierrot/Columbina)**,
  **Molière (١٦٢٢–١٦٧٣ "Tartuffe", "The Misanthrope")**,
  **Henrik Ibsen "A Doll's House" ١٨٧٩**, **Anton Chekhov
  "The Cherry Orchard"**, **Oscar Wilde "The Importance
  of Being Earnest" ١٨٩٥**, **G.B. Shaw "Pygmalion" ١٩١٣
  → My Fair Lady (Nobel ١٩٢٥)**, **Eugene O'Neill (Nobel
  ١٩٣٦)**, **Tennessee Williams "A Streetcar Named
  Desire"**, **Arthur Miller "Death of a Salesman" ١٩٤٩
  + "The Crucible" ١٩٥٣**, **Lorraine Hansberry "A Raisin
  in the Sun" ١٩٥٩ (first Black-authored Broadway hit)**,
  **August Wilson Pittsburgh Cycle ١٠ plays**, **Samuel
  Beckett "Waiting for Godot" ١٩٥٣ (Theatre of the
  Absurd, Nobel ١٩٦٩)**, **Stanislavski Method acting**,
  **Kabuki Japan since ~١٦٠٣ Okuni**, **Noh masks**,
  **Peking opera China**, **"The Scottish Play" Macbeth
  superstition**, **"break a leg" good luck**.
- **Famous Dancers & Ballet History pack**
  (`famous_dancers_ballet.json`) — 60 items on **ballet
  originated Italian Renaissance, formalized France ١٧th
  century by Louis XIV (the "Sun King")**, **Royal Academy
  of Dance / Académie Royale de Danse founded ١٦٦١**,
  **pointe work invented Marie Taglioni (١٨٣٢ "La
  Sylphide")**, **5 basic ballet positions of feet**,
  **Petipa "Sleeping Beauty" ١٨٩٠ + "Nutcracker" ١٨٩٢ +
  "Swan Lake" ١٨٩٥ revival (with Tchaikovsky)**, **Tchaikovsky
  Swan Lake ١٨٧٧ + Sleeping Beauty ١٨٩٠ + Nutcracker
  ١٨٩٢**, **Ballets Russes (Diaghilev Paris ١٩٠٩–١٩٢٩)**,
  **Vaslav Nijinsky greatest male dancer of early ٢٠th c.
  + Stravinsky "Rite of Spring" ١٩١٣ riot at premiere**,
  **Anna Pavlova (١٨٨١–١٩٣١, "The Dying Swan", named
  meringue dessert)**, **Mikhail Baryshnikov (defected
  ١٩٧٤)**, **Rudolf Nureyev (defected ١٩٦١, "leap of the
  century")**, **Margot Fonteyn (English prima ballerina,
  partnered Nureyev)**, **George Balanchine (co-founded
  School of American Ballet ١٩٣٤ + NYCB ١٩٤٨)**, **Misty
  Copeland (first African-American female principal at
  ABT ٢٠١٥)**, **Bolshoi Ballet Moscow ١٧٧٦ + Mariinsky
  Ballet St. Petersburg ١٧٤٠ + Paris Opera Ballet oldest
  ١٦٦٩**, **Isadora Duncan "mother of modern dance"
  (barefoot, free movement)**, **Martha Graham (Graham
  technique, ١٨١ works)**, **Alvin Ailey "Revelations"
  ١٩٦٠**, **Fred Astaire + Ginger Rogers Hollywood
  musicals ١٩٣٠s**, **Gene Kelly "Singin' in the Rain"
  ١٩٥٢**, **Michael Jackson moonwalk ١٩٨٣ Motown ٢٥**,
  **breakdancing Olympics ٢٠٢٤ Paris (first time)**,
  **Argentine tango (Buenos Aires/Montevideo, ~١٨٨٠s)**,
  **Flamenco Spain Andalusia**, **Riverdance ١٩٩٤
  (Michael Flatley + Jean Butler)**, **Bharatanatyam
  Indian classical**, **whirling dervishes Sufi Mevlevi
  Konya**, **Dabke Levantine + Khaleeji Gulf**.
- **Shape Match mini-game** — visual matching game: target
  shape + color is shown, then a 3×3 grid of shapes
  (circle, square, triangle, star, heart, diamond) in 6
  colors; tap the cell that matches BOTH the target's
  shape and color. Custom-painted shapes. ٦٠s round; coin
  tiers ٢🪙/٥🪙/١٠🪙 at scores ١٢/٢٤/٤٠.

### Cumulative
- 188 quiz packs (~١١٬٢٨٠ items), 71 mini-games on the home shelf.

## 1.1.73 — 2026-05-06 — Wave 70

### Added
- **Famous Operas & Musicals pack** (`famous_operas_musicals.json`)
  — 60 items on **opera = sung drama (Italian "work"),
  originated Italy ~١٦٠٠**, **first opera Peri's "Dafne"
  ١٥٩٧**, **Monteverdi "L'Orfeo" ١٦٠٧ first masterpiece**,
  **Mozart "The Magic Flute" ١٧٩١ + "Don Giovanni" ١٧٨٧**,
  **Verdi "Aida" ١٨٧١ (Cairo for Suez Canal opening) +
  "La Traviata" ١٨٥٣**, **Puccini "La Bohème" ١٨٩٦ +
  "Madama Butterfly" ١٩٠٤ + "Turandot" "Nessun dorma"**,
  **Wagner "Ring Cycle" (4 operas, ~١٥ hours) + Bayreuth
  Festival Theatre ١٨٧٢–٧٦**, **Bizet "Carmen" ١٨٧٥**,
  **Rossini "Barber of Seville" ١٨١٦ + "William Tell"
  ١٨٢٩ (Lone Ranger theme)**, voice types (soprano/mezzo/
  alto/tenor/baritone/bass), **La Scala Milan ١٧٧٨ + Royal
  Opera House Covent Garden ١٨٥٨ + Met NYC ١٨٨٣ + Vienna
  State Opera ١٨٦٩ + Sydney Opera House ١٩٧٣**, **Three
  Tenors Pavarotti + Domingo + Carreras (١٩٩٠ World Cup
  Italy)**, Maria Callas, Andrea Bocelli, **Gilbert &
  Sullivan operettas ١٨٧٠s–٩٠s**, **Show Boat ١٩٢٧
  (Jerome Kern)**, **Oklahoma! ١٩٤٣ (Rodgers & Hammerstein)
  revolutionized integration of song + story**, **My Fair
  Lady ١٩٥٦**, **West Side Story ١٩٥٧ (Bernstein/Sondheim)**,
  **Sound of Music ١٩٥٩ stage / ١٩٦٥ film**, **Cats
  (Webber ١٩٨١) + Phantom of the Opera (Webber ١٩٨٦
  longest-running Broadway ٣٥ years until ٢٠٢٣)**, **Les
  Misérables ١٩٨٠ Paris / ١٩٨٥ London**, **The Lion King
  ١٩٩٧ stage (Julie Taymor, Tony Best Musical ١٩٩٨)**,
  **Wicked ٢٠٠٣ "Defying Gravity"**, **Mamma Mia! ١٩٩٩
  ABBA jukebox**, **Hamilton (Lin-Manuel Miranda ٢٠١٥
  hip-hop)**, **Tony Awards (since ١٩٤٧)**.
- **Famous Aquariums & Zoos pack** (`famous_aquariums_zoos.json`)
  — 60 items on **London Zoo ١٨٢٨ (world's oldest scientific
  zoo, ZSL Regent's Park)**, **Schönbrunn Vienna ١٧٥٢
  (oldest still-operating zoo)**, **Berlin Zoological
  Garden ١٨٤٤ (most species)**, **San Diego Zoo ١٩١٦
  (~٣٬٥٠٠ animals, ~٦٥٠ species)**, **Bronx Zoo NYC ١٨٩٩
  (largest US metro zoo)**, **Singapore Night Safari ١٩٩٤
  (first nocturnal zoo)**, **Henry Doorly Zoo Omaha
  (biggest zoo in world by area)**, **Beijing Zoo (giant
  pandas)**, **Tokyo Ueno Zoo ١٨٨٢ oldest in Japan**,
  **Edinburgh Zoo (only UK zoo with pandas Tian Tian +
  Yang Guang until ٢٠٢٣)**, **Disney's Animal Kingdom
  Orlando ١٩٩٨**, **Georgia Aquarium Atlanta ٢٠٠٥ (world's
  largest aquarium ~٣٨M liters, whale sharks)**, **Monterey
  Bay Aquarium ١٩٨٤ (Outer Bay tank, kelp forest)**,
  **Shedd Aquarium Chicago ١٩٣٠**, **Lisbon Oceanarium
  (Portugal, central tank)**, **Dubai Aquarium (in Dubai
  Mall, world's largest acrylic panel)**, **Okinawa
  Churaumi**, **Vancouver Aquarium**, **conservation
  breeding success: Arabian oryx (extinct in wild →
  reintroduced from zoo populations)**, **Père David's
  deer + Przewalski's horse + California condor**,
  **AZA + WAZA accreditation**, **Knut polar bear cub
  Berlin Zoo ٢٠٠٦**, **Tilikum orca SeaWorld (Blackfish
  ٢٠١٣ documentary)**, **first aquarium Regent's Park
  London ١٨٥٣**, **word "aquarium" coined by P.H. Gosse
  ١٨٥٤**.
- **Famous Fossils & Paleontology pack** (`famous_fossils.json`)
  — 60 items on **"Lucy" (Australopithecus afarensis ٣٫٢
  Mya, found ١٩٧٤ Hadar Ethiopia by Donald Johanson, ~٤٠٪
  complete skeleton, named after Beatles "Lucy in the Sky
  with Diamonds")**, **"Sue" T. rex ~٦٧ Mya, ~١٢٫٣م long,
  ~٩٠٪ complete, found ١٩٩٠ South Dakota by Sue
  Hendrickson; Field Museum Chicago since ٢٠٠٠**, **"Stan"
  T. rex sold $٣١٫٨M ٢٠٢٠**, dinosaur taxonomy (theropods/
  sauropods/ornithopods/ceratopsians/stegosaurids),
  **Argentinosaurus largest dinosaur (~٣٥–٤٠م, ~٧٥–١٠٠
  tons)**, **Compsognathus smallest (~٧٠سم)**,
  **Archaeopteryx ~١٥٠ Mya (transition fossil bird-
  dinosaur, Solnhofen Germany ١٨٦١)**, **Mary Anning
  (١٧٩٩–١٨٤٧, English fossil hunter, "She sells seashells",
  found ichthyosaur age ١٢ + plesiosaur ١٨٢٣ + pterosaur
  Lyme Regis)**, **Tiktaalik (~٣٧٥ Mya, fish-tetrapod
  transition, Ellesmere Island ٢٠٠٤ Neil Shubin)**,
  **Burgess Shale Canada (~٥٠٨ Mya, Cambrian explosion,
  Walcott ١٩٠٩)**, **Megalodon (~٣٫٦ Mya giant shark,
  ~١٨م)**, **Smilodon saber-toothed cat (~١٠٬٠٠٠ ya
  extinct)**, **woolly mammoth (~١٠٬٠٠٠ ya extinct, frozen
  Lyuba ٢٠٠٧ Siberia)**, **Ötzi the Iceman ٥٬٣٠٠ ya
  Copper Age mummy (Alps ١٩٩١)**, **K-Pg extinction ~٦٦
  Mya (Chicxulub asteroid)**, **Permian-Triassic extinction
  ~٢٥٢ Mya (~٩٦٪ marine species)**, **Coelacanth (living
  fossil, thought extinct ~٦٦ Mya, found alive ١٩٣٨ South
  Africa)**, **horseshoe crab (living fossil ~٤٥٠ Mya)**,
  **amber (fossilized resin, basis for Jurassic Park
  ١٩٩٣)**, **Richard Owen coined "Dinosauria" ١٨٤٢**,
  **Bone Wars Marsh vs Cope ١٨٧٠s–٩٠s (~١٣٦ species
  described)**, **Spinosaurus largest carnivorous dinosaur
  (~١٥م+, swam)**, **Wadi al-Hitan Egypt UNESCO whale
  fossils**, **Pakicetus (~٥٠ Mya whale ancestor with
  legs)**, **Toumai (oldest hominid ~٧ Mya Chad ٢٠٠٢)**,
  **Cradle of Humankind UNESCO South Africa**.
- **Tap the Greatest mini-game** — 4 cards each show a
  number or simple expression (٣+٤, ٧×٢, ٤٠-١٢, etc.);
  tap the card with the greatest value. ٦٠s round; coin
  tiers ٢🪙/٥🪙/١٠🪙 at scores ١٢/٢٤/٤٠.

### Cumulative
- 185 quiz packs (~١١٬١٠٠ items), 70 mini-games on the home shelf.

## 1.1.72 — 2026-05-06 — Wave 69

### Added
- **Famous Comets & Meteors pack** (`famous_comets.json`) —
  60 items on **Halley's Comet (Edmond Halley predicted
  return ١٧٥٨, every ~٧٦ years, last ١٩٨٦, next ٢٠٦١,
  spotted at Battle of Hastings ١٠٦٦ Bayeux Tapestry)**,
  **Hale-Bopp ١٩٩٥–٩٧ (visible to naked eye ١٨ months,
  brightest in 20th century)**, **Shoemaker-Levy 9 (broke
  into ٢١ fragments, hit Jupiter July ١٩٩٤)**, **NEOWISE
  ٢٠٢٠**, **Comet 67P/Churyumov-Gerasimenko (Rosetta probe
  + Philae lander ٢٠١٤)**, **Comet Tempel 1 (Deep Impact
  NASA July ٤ ٢٠٠٥)**, Stardust mission, **Tunguska event
  ١٩٠٨ Siberia (~١٢ megatons, flattened ٢٬٠٠٠ sq km)**,
  **Chelyabinsk meteor Feb ١٥ ٢٠١٣ Russia (airburst, ~٥٠٠
  kilotons, ~١٬٥٠٠ injured by glass)**, **Barringer/Meteor
  Crater Arizona (~٥٠٬٠٠٠ ya)**, **Vredefort crater South
  Africa (oldest + largest ~٢ billion ya, ~٣٠٠كم)**,
  **Chicxulub Yucatan ~٦٦Mya killed dinosaurs**, **Kuiper
  Belt + Oort Cloud**, **comet anatomy (nucleus + coma +
  ion blue tail + dust white tail; tails always point away
  from Sun)**, **meteoroid → meteor → meteorite**, **Perseids
  Aug ١٢–١٣ (Comet Swift-Tuttle), Geminids Dec ١٣–١٤ (٣٢٠٠
  Phaethon), Leonids Nov ١٧–١٨ (Tempel-Tuttle)**, **Hoba
  meteorite Namibia ~٦٠ tons largest known intact**,
  **NASA DART Sept ٢٦ ٢٠٢٢ nudged Dimorphos (planetary
  defense test)**, **OSIRIS-REx Bennu samples Sept ٢٤
  ٢٠٢٣**, **Hayabusa2 Ryugu ٢٠٢٠**, **Pluto demoted from
  planet ٢٠٠٦ (now dwarf planet)**, **Edmond Halley computed
  ٣ comets (١٤٥٦, ١٥٣١, ١٦٠٧, ١٦٨٢) were the same one and
  predicted return ١٧٥٨**.
- **Antarctic & Polar Explorers pack**
  (`antarctic_explorers.json`) — 60 items on **Roald
  Amundsen first to South Pole Dec ١٤ ١٩١١ (Norwegian, beat
  Scott by ~٥ weeks)**, **Robert Falcon Scott reached South
  Pole Jan ١٧ ١٩١٢ (٥ weeks after Amundsen, died on return
  March ١٩١٢)**, **Ernest Shackleton Endurance Expedition
  ١٩١٤–١٧, ship crushed in pack ice, all ٢٨ men survived;
  ١٬٣٠٠كم open-boat voyage to South Georgia, James Caird
  navigated by Frank Worsley with sextant**, **Endurance
  wreck found March ٢٠٢٢ (٣٬٠٠٠م deep, ١٠٧ years later,
  Weddell Sea)**, **James Cook crossed Antarctic Circle
  Jan ١٧ ١٧٧٣**, **Bellingshausen + Lazarev sighted
  Antarctic continent Jan ٢٧ ١٨٢٠ (Russian)**, **Belgium
  Antarctic Expedition ١٨٩٧–٩٩ first to overwinter
  (Belgica trapped in ice)**, **Borchgrevink first
  overwintered on continent ١٨٩٩**, **Apsley Cherry-Garrard
  "The Worst Journey in the World" Cape Crozier emperor
  penguin egg expedition**, **Robert Peary claimed first
  to North Pole April ٦ ١٩٠٩ (disputed)**, **Matthew
  Henson (African American) accompanied Peary**, **Roald
  Amundsen first verified North Pole reach by airship Norge
  ١٩٢٦**, **Lowest recorded temperature -٨٩٫٢°C Vostok July
  ٢١ ١٩٨٣**, **Antarctic Treaty signed Dec ١ ١٩٥٩ (in force
  ١٩٦١, ~٥٤ countries today)**, **No country owns Antarctica
  (science only continent)**, **Antarctica = 5th largest
  continent (~١٤M km²), ~٩٨٪ ice cover, coldest + driest
  + windiest**, **Antarctic ice ~٧٠٪ of world's fresh
  water**, **Lake Vostok subglacial lake under ٤كم of ice**,
  **Ozone hole detected ١٩٨٥ by Joe Farman BAS**, **Edmund
  Hillary led NZ side of British Trans-Antarctic Expedition
  ١٩٥٥–٥٨**, **Roald Amundsen Northwest Passage Gjøa
  ١٩٠٣–٠٦**.
- **Famous Statues & Monuments pack** (`famous_statues.json`)
  — 60 items on **Statue of Liberty NYC harbor (~٩٣م incl
  pedestal, gift from France ١٨٨٦, Bartholdi sculptor,
  Eiffel internal frame, dedicated Oct ٢٨ ١٨٨٦)**, **torch ٧
  spikes = ٧ continents/seas**, **"Give me your tired, your
  poor..." Emma Lazarus sonnet "The New Colossus" ١٨٨٣**,
  **Christ the Redeemer Rio de Janeiro (~٣٨م, completed
  ١٩٣١, Heitor da Silva Costa designer + Paul Landowski
  sculptor, ٧٠٠kg soapstone tiles, on Corcovado)**,
  **Statue of Unity Gujarat India (~١٨٢م, world's tallest
  statue, Sardar Vallabhbhai Patel ٢٠١٨)**, Spring Temple
  Buddha China (~١٢٨م 2nd tallest), **Easter Island Moai
  (~٨٨٧ statues)**, **Sphinx of Giza (~٧٣م long, ~٢٠م tall,
  4th dynasty Khafre ~٢٥٠٠ BCE, oldest known monumental
  sculpture)**, **Colossus of Rhodes (~٣٣م, ~٢٨٠ BCE, fell
  in earthquake ٢٢٦ BCE — one of 7 Wonders, Liberty inspired
  by it)**, **Mount Rushmore (Washington/Jefferson/T.
  Roosevelt/Lincoln, Gutzon Borglum ١٩٢٧–٤١ SD)**,
  **Statue of David (Michelangelo ١٥٠١–٠٤, Florence
  Galleria dell'Accademia, ٥٫١٧م Carrara marble)**,
  **Lincoln Memorial DC (Daniel Chester French ١٩٢٢, ٥٫٨م
  seated)**, **The Thinker (Le Penseur, Auguste Rodin
  ١٩٠٤)**, Venus de Milo Louvre ~١٣٠ BCE, Winged Victory
  of Samothrace Louvre ~١٩٠ BCE, **Charging Bull NYC Wall
  Street (Arturo Di Modica ١٩٨٩)**, **Fearless Girl NYC
  (Kristen Visbal ٢٠١٧)**, **Genghis Khan equestrian statue
  Mongolia (٤٠م ٢٠٠٨)**, **Olmec colossal heads Mexico
  (~١٥٠٠ BCE)**, **Terracotta Army Xi'an China (~٢١٠ BCE
  Qin Shi Huang, ~٨٬٠٠٠ figures, discovered ١٩٧٤)**,
  **Bamiyan Buddhas Afghanistan (destroyed by Taliban
  ٢٠٠١)**, **Trevi Fountain Rome (Pietro Bracci ١٧٦٢)**.
- **Tap the Letter mini-game** — 3×3 grid of random letters
  (English A-Z or Arabic ا-ي depending on locale); tap the
  letter that matches the target shown in the header pill.
  ٦٠s round; coin tiers ٢🪙/٥🪙/١٠🪙 at scores ١٢/٢٤/٤٠.

### Cumulative
- 182 quiz packs (~١٠٬٩٢٠ items), 69 mini-games on the home shelf.

## 1.1.71 — 2026-05-06 — Wave 68

### Added
- **Famous Magicians & Illusionists pack**
  (`famous_magicians.json`) — 60 items on **Houdini (Erik
  Weisz, ١٨٧٤–١٩٢٦, escapology king "Handcuff King", died
  Halloween ١٩٢٦, Chinese Water Torture Cell + Milk Can
  escapes, debunked spiritualists)**, **David Copperfield
  (b. ١٩٥٦, made Statue of Liberty disappear ١٩٨٣, walked
  through Great Wall ١٩٨٦)**, **David Blaine (b. ١٩٧٣
  endurance/street magic, buried alive ١٩٩٩, frozen ٢٠٠٠,
  ٤٤ days starvation ٢٠٠٣)**, **Penn & Teller (Las Vegas
  since ١٩٨٥)**, Criss Angel (Mindfreak), **Robert-Houdin
  (١٨٠٥–١٨٧١, "father of modern magic", inspired Houdini's
  name)**, Howard Thurston "King of Cards", **Chung Ling Soo
  (William Robinson, killed onstage by bullet catch ١٩١٨)**,
  **bullet catch most dangerous trick**, **cup and balls
  oldest known (ancient Egyptian Beni Hasan tomb ~٢٥٠٠
  BCE)**, **sawing a woman in half (P.T. Selbit ١٩٢١)**,
  **rabbit out of hat (Louis Comte ١٨١٤)**, **The Amazing
  Randi $١M paranormal challenge debunker**, **Magic Castle
  Hollywood ١٩٦٣ (Academy of Magical Arts)**, **Society of
  American Magicians ١٩٠٢ (Houdini was president)**,
  **magician's oath: never reveal secrets**, **magic words:
  Abracadabra (~٣rd century AD), Hocus Pocus (~١٦٣٢), Open
  Sesame (Aladdin/Ali Baba)**, Siegfried & Roy (white tigers),
  **Shin Lim AGT winner ٢٠١٨**, Mat Franco AGT winner
  ٢٠١٤, **first magic exposé book "Discoverie of Witchcraft"
  Reginald Scot ١٥٨٤**, **Davenport Brothers (١٨٦٤
  spiritualist mediums Houdini debunked)**, "Now You See Me"
  (٢٠١٣), "The Prestige" (٢٠٠٦ Nolan), "The Illusionist"
  (٢٠٠٦ Norton), Houdini's last word "Rosabelle, believe"
  code with wife Bess.
- **Famous Walls & Fortifications pack** (`famous_walls.json`)
  — 60 items on **Great Wall of China (~٢١٬١٩٦كم incl
  branches, ~٧th century BCE start, Ming dynasty rebuilt
  ١٣٦٨–١٦٤٤, NOT visible from moon despite myth)**, **Berlin
  Wall (Aug ١٣ ١٩٦١ → Nov ٩ ١٩٨٩, ~١٥٥كم, divided
  East/West Germany)**, **Hadrian's Wall (Roman Britain ١٢٢
  CE Emperor Hadrian, ~١١٧كم coast-to-coast)**, **Walls of
  Constantinople (Theodosius II ~٤١٣ CE, fell ١٤٥٣ to
  Ottomans)**, **Walls of Jericho (oldest known city walls
  ~١٠٬٠٠٠ BCE)**, **Walls of Babylon (Ishtar Gate)**,
  **Western Wall Jerusalem (last remnant of Second Temple
  ١st c. BCE)**, **Diyarbakır walls (Turkey, second
  longest after Great Wall)**, **Walls of Lugo (Spain, only
  intact Roman walls UNESCO)**, **Walls of Avila (Spain
  UNESCO ~٢٬٥٠٠م)**, **Vauban fortifications UNESCO (12
  sites) — bastion forts, ١٧th century France**, **Citadel
  of Aleppo, Citadel of Cairo (Saladin ١١٧٦)**, **Bahla
  Fort Oman (mud-brick, UNESCO)**, **Kremlin walls Moscow
  (red-brick, since ١٥th century)**, **Long Walls of Athens
  ٥th century BCE (to Piraeus)**, **Maginot Line (France
  WWI/WWII border defense, bypassed ١٩٤٠)**, **Atlantic
  Wall (Nazi WWII coastal defense, breached D-Day ١٩٤٤)**,
  **Sacsayhuamán (Inca, Cuzco, megalithic walls)**, castle
  parts (drawbridge/portcullis/machicolations/arrow slits/
  battlements/crenellations/curtain walls/bastions), Roman
  limes (frontier defenses).
- **Famous Hotels & Resorts pack** (`famous_hotels.json`)
  — 60 items on **Burj Al Arab Dubai ١٩٩٩ (sail-shaped,
  ٣٢١م, world's first "7-star" claim, helipad)**, **Marina
  Bay Sands Singapore ٢٠١٠ (3 towers + boat-shaped sky
  park, infinity pool)**, **Raffles Singapore ١٨٨٧ (Long
  Bar, Singapore Sling cocktail)**, **Ritz Paris ١٨٩٨
  (César Ritz, Coco Chanel lived ٣٠+ years)**, **Savoy
  London ١٨٨٩ (first hotel with electric lights + bathrooms
  in rooms)**, **Plaza Hotel NYC ١٩٠٧ ("Eloise at the
  Plaza", Home Alone 2)**, **Waldorf Astoria NYC ١٨٩٣
  (Park Avenue ١٩٣١)**, **Beverly Hills Hotel ١٩١٢ "Pink
  Palace"**, Chateau Marmont (Hollywood ١٩٢٩), **Hotel del
  Coronado San Diego ١٨٨٨ ("Some Like It Hot" ١٩٥٩)**,
  **Greenbrier Resort West Virginia (since ١٧٧٨)**,
  **Stanley Hotel Estes Park CO (inspired Stephen King's
  "The Shining")**, **Bellagio fountains since ١٩٩٨**,
  Caesars Palace ١٩٦٦, **Peninsula Hong Kong ١٩٢٨ "Grande
  Dame of the Far East"**, Burj Khalifa Armani Hotel,
  **Emirates Palace Abu Dhabi ٢٠٠٥ "8-star"**, **Ritz-
  Carlton Riyadh (housed ٢٠١٧ Saudi anti-corruption
  committee)**, **Conrad Hilton founded Hilton ١٩١٩**,
  **Holiday Inn founded ١٩٥٢ (Kemmons Wilson)**,
  **Marriott founded ١٩٥٧ (J. Willard Marriott)**,
  **Airbnb founded ٢٠٠٨ (Brian Chesky + Joe Gebbia)**,
  **Booking.com founded ١٩٩٦**, **Banff Springs Hotel
  ١٨٨٨ "Castle in the Rockies"**, **Chateau Frontenac
  Quebec ١٨٩٣ (most-photographed hotel)**, **Park Hyatt
  Tokyo ("Lost in Translation" ٢٠٠٣)**, **Ice hotel Sweden
  since ١٩٩٠ (rebuilt every year)**, capsule hotels Japan,
  **first purpose-built hotel: City Hotel NYC ١٧٩٤**.
- **Prime Tap mini-game** — 3×3 grid of random numbers
  (٢–٤٩); tap only the prime numbers (divisible by ١ and
  themselves only). Correct prime tap = +1; wrong tap
  blocks the cell. When all primes tapped, board refreshes;
  Skip button to redraw. ٦٠s round; coin tiers ٢🪙/٥🪙/١٠🪙
  at scores ١٢/٢٤/٤٠.

### Cumulative
- 179 quiz packs (~١٠٬٧٤٠ items), 68 mini-games on the home shelf.

## 1.1.70 — 2026-05-06 — Wave 67

### Added
- **Famous Foods of the World pack** (`famous_foods_world.json`)
  — 60 halal-friendly items on **Pizza Margherita named after
  Queen Margherita ١٨٨٩ Naples (red+white+green = Italian
  flag)**, pasta shapes, sushi, ramen, **Tacos Mexican**,
  **fried chicken (KFC, Colonel Sanders ١٩٥٢)**, **McDonald's
  founded ١٩٤٠ San Bernardino**, **croissant originated in
  Vienna ("kipferl"), brought to France**, **Mansaf Jordan
  national dish (lamb + yogurt + rice)**, **Kabsa Saudi
  national dish (rice + meat)**, **Machboos Kuwait/Bahrain
  rice dish**, Knafeh + Maamoul + Baklava, **Tagine Moroccan
  named after pot**, **Couscous UNESCO ٢٠٢٠ (Maghreb)**,
  Injera Ethiopian, Jollof West African, Biryani, Pad Thai,
  Tom Yum, Pho, Banh Mi, Dim sum, **Peking duck**, Bibimbap,
  **Kimchi UNESCO ٢٠١٣**, **Paella Valencia**, **Borscht
  UNESCO ٢٠٢٢ Ukraine**, **Sushi conveyor belt Japan ١٩٥٨**,
  **Restaurant invented ١٧٦٥ Paris (Boulanger)**, **Michelin
  Guide stars since ١٩٢٦ (3 stars highest)**, **Sandwich
  named after John Montagu, 4th Earl of Sandwich (١٧٦٢)**,
  **Coffee origin Yemen (~١٥-th century, Sufi monks)**,
  **Tea China (~٣٠٠٠ BCE legend)**, **saffron most
  expensive spice**, **Vanilla Mexico (only orchid that
  produces edible fruit)**, **Chocolate from cacao
  (Aztec/Maya "xocolatl")**.
- **Famous Roads & Routes pack** (`famous_roads_routes.json`)
  — 60 items on **Silk Road (Chang'an to Mediterranean
  ~٦٬٤٠٠كم, ١٣٠ BCE–١٤٥٣ CE)**, **Trans-Siberian Railway
  longest rail line ~٩٬٢٨٩كم**, **Pan-American Highway
  longest motorable ~٣٠٬٠٠٠كم (with Darién Gap break)**,
  **Route 66 USA ~٣٬٩٤٠كم since ١٩٢٦ "Mother Road"**,
  Autobahn Germany, **Via Appia (Appian Way Rome ٣١٢ BCE
  "Queen of Roads")**, **All roads lead to Rome (Roman
  roads ~٨٠٬٠٠٠كم)**, **Royal Road of Persia ~٢٬٧٠٠كم
  (Achaemenid courier system)**, **Inca Road / Qhapaq Ñan
  ~٤٠٬٠٠٠كم Andes UNESCO ٢٠١٤**, Camino de Santiago, Tea
  Horse Road, Frankincense Trail (Oman), **Trans-Saharan
  trade routes**, **silk worm secret smuggled out of China
  ~٥٥٢ CE Byzantine monks**, **Marco Polo journey (١٢٧١–
  ١٢٩٥)**, **Ibn Battuta travels (١٣٢٥–١٣٥٤, ~١١٧٬٠٠٠كم,
  longer than Marco Polo)**, **Genghis Khan's Yam postal
  relay across Mongol Empire**, **Hejaz Railway (Damascus-
  Medina, completed ١٩٠٨; T.E. Lawrence raids WWI)**,
  **Lincoln Highway USA ١٩١٣ first transcontinental road**,
  Karakoram Highway (China-Pakistan, "Eighth Wonder", up
  to ٤٬٦٩٣م), **Sheikh Jaber Causeway Kuwait ٣٦كم ٢٠١٩**,
  **King Fahd Causeway Saudi-Bahrain ٢٥كم ١٩٨٦**,
  **Eisenhower Interstate System (USA ١٩٥٦, ~٧٨٬٠٠٠كم)**,
  **first public motorway: Italy ١٩٢٤ (Milan-Varese)**,
  **driving on left ~٣٥٪ world (UK/Japan/Australia/India)**,
  **Sweden switched left → right Sept ٣ ١٩٦٧ ("Dagen H")**,
  **first traffic light London ١٨٦٨ gas, modern electric
  Detroit ١٩١٤**, asphalt invented Edgar Hooley ١٩٠٢ UK,
  Tarmacadam (McAdam ١٨٢٠), **Hyperloop concept (Musk
  ٢٠١٣)**, driverless cars Waymo + Tesla.
- **Famous Ships & Boats pack** (`famous_ships_boats.json`)
  — 60 items on **Titanic sank April ١٥ ١٩١٢ after iceberg
  (~١٬٥٠٠ died, "unsinkable" myth, discovered by Robert
  Ballard ١٩٨٥ ~٣٬٨٠٠م deep)**, **Mayflower (١٦٢٠ Pilgrims
  to Plymouth Rock)**, **Santa María/Pinta/Niña Columbus
  ١٤٩٢**, **HMS Beagle (Darwin's voyage ١٨٣١–٣٦)**, **HMS
  Endeavour (Cook ١٧٦٨–٧١, charted Australia + NZ east
  coast)**, **HMS Bounty (Mutiny on the Bounty ١٧٨٩
  Pitcairn)**, **HMS Victory (Nelson's flagship Trafalgar
  ١٨٠٥, oldest commissioned warship still afloat)**, **USS
  Constitution "Old Ironsides" ١٧٩٧**, **Vasa (Swedish
  ١٦٢٨, sank on maiden voyage, salvaged ١٩٦١, Stockholm
  museum)**, **Mary Rose (Henry VIII flagship ١٥٤٥,
  salvaged ١٩٨٢)**, **USS Nautilus first nuclear submarine
  ١٩٥٤**, **Allure of the Seas/Wonder of the Seas largest
  cruise ships (~٣٦٠م, ~٦٬٠٠٠ passengers)**, **Ever Given
  blocked Suez Canal March ٢٣–٢٩ ٢٠٢١**, **container
  shipping: Malcolm McLean ١٩٥٦ SS Ideal-X**, **Zheng He's
  treasure ships ~١٤٠٠s, ~١٢٠م, ٧ voyages ١٤٠٥–١٤٣٣ (~٣٠٠
  ships, ~٢٨٬٠٠٠ men)**, **dhow (Arabic Indian Ocean,
  lateen sail)**, Polynesian voyaging Hokule'a ١٩٧٦
  revival, **Ferdinand Magellan circumnavigation ١٥١٩–٢٢
  (died Philippines, Elcano completed)**, **Vasco da Gama
  Portuguese to India ١٤٩٨**, **HMS Challenger expedition
  ١٨٧٢–٧٦ (oceanography)**, **Kon-Tiki raft Heyerdahl
  ١٩٤٧**, **Liberty ships WWII (~٢٬٧١٠ built rapidly by US
  ١٩٤١–٤٥)**, knots = nautical miles per hour, latitude +
  longitude (chronometer Harrison ١٧٥٩), Plimsoll line.
- **Even or Odd mini-game** — a number flashes (range
  grows with score, up to ~٩٩٩); tap **EVEN** or **ODD**.
  ٦٠s round; coin tiers ٢🪙/٥🪙/١٠🪙 at scores ١٠/٢٠/٣٥.

### Cumulative
- 176 quiz packs (~١٠٬٥٦٠ items), 67 mini-games on the home shelf.

## 1.1.69 — 2026-05-06 — Wave 66

### Added
- **Movies & Cinema History pack** (`movies_cinema_history.json`)
  — 60 kid-appropriate items on **Lumière brothers first
  public film screening Dec ٢٨ ١٨٩٥ Paris**, **Edison
  Kinetoscope ١٨٩١**, **Méliès "A Trip to the Moon" ١٩٠٢**,
  **The Jazz Singer ١٩٢٧ first "talkie"**, **Snow White
  and the Seven Dwarfs ١٩٣٧ first full-length animated
  feature (Disney)**, **Disney founded ١٩٢٣; Mickey Mouse
  "Steamboat Willie" Nov ١٨ ١٩٢٨**, **Wizard of Oz ١٩٣٩
  Technicolor**, **Citizen Kane ١٩٤١**, **Star Wars: A
  New Hope ١٩٧٧ (Lucas)**, **E.T. ١٩٨٢ (Spielberg)**, Back
  to the Future ١٩٨٥, **Toy Story ١٩٩٥ first fully CGI
  feature (Pixar)**, **Pixar founded ١٩٨٦, merged Disney
  ٢٠٠٦ ($٧٫٤B)**, Pixar films (Bug's Life/Monsters Inc/
  Finding Nemo/Incredibles/Ratatouille/WALL-E/Up/Inside
  Out/Coco/Soul), **Frozen ٢٠١٣**, Frozen 2 ٢٠١٩,
  **Avatar ٢٠٠٩ first $٢٫٧B (Cameron)**, Titanic ١٩٩٧,
  Avengers: Endgame ٢٠١٩, Jurassic Park ١٩٩٣, **Studio
  Ghibli ١٩٨٥ (Miyazaki)**, **Spirited Away ٢٠٠١ first
  non-English Best Animated Feature Oscar**, My Neighbor
  Totoro ١٩٨٨, **Shrek ٢٠٠١ (DreamWorks)**, Despicable Me
  ٢٠١٠ (Illumination), **Harry Potter and the Sorcerer's
  Stone ٢٠٠١**, **LOTR trilogy ٢٠٠١–٢٠٠٣ (Peter
  Jackson)**, Hollywood sign ١٩٢٣ (originally
  "Hollywoodland"), **Bollywood (largest film output)**,
  Cannes Film Festival ١٩٤٦, **Venice Film Festival ١٩٣٢
  oldest**, Sundance ١٩٧٨, **Cairo Film Festival ١٩٧٦
  oldest in Arab world**, **Academy Awards / Oscars ١٩٢٩**,
  **Parasite ٢٠٢٠ first non-English Best Picture (Bong
  Joon-ho Korean)**, **John Williams composer (Star Wars,
  Indiana Jones, Jaws, ET, Harry Potter, Jurassic Park)**,
  **Hans Zimmer (Lion King, Inception, Interstellar, Dune)**.
- **Famous Photographers pack** (`famous_photographers.json`)
  — 60 items on **Niépce first surviving photo "View from
  the Window at Le Gras" ١٨٢٦/١٨٢٧ (~٨ hour exposure)**,
  **Daguerre Daguerreotype ١٨٣٩**, **Talbot calotype
  ١٨٣٩**, **Eastman Kodak ١٨٨٨ "You press the button, we
  do the rest"**, **first color photo Maxwell ١٨٦١
  (tartan ribbon, three-color)**, Autochrome Lumière ١٩٠٧,
  Kodachrome ١٩٣٥, **Polaroid Land instant ١٩٤٨**, **first
  digital camera Steve Sasson at Kodak ١٩٧٥**, first
  commercial DSLR Nikon D1 ١٩٩٩, **Mathew Brady American
  Civil War**, **Ansel Adams (١٩٠٢–١٩٨٤) Yosemite Half
  Dome + Moonrise over Hernandez ١٩٤١ + Zone System**,
  **Dorothea Lange "Migrant Mother" ١٩٣٦ Great Depression
  FSA**, **Cartier-Bresson "decisive moment" + Magnum
  Photos co-founder ١٩٤٧**, **Robert Capa Falling Soldier
  Spanish Civil War ١٩٣٦ + D-Day Normandy ١٩٤٤**, **Steve
  McCurry "Afghan Girl" Sharbat Gula National Geographic
  June ١٩٨٥**, **Yousuf Karsh Winston Churchill ١٩٤١
  portrait**, Robert Frank "The Americans" ١٩٥٨,
  **Eadweard Muybridge horse motion ١٨٧٨ "Sallie Gardner
  at a Gallop"**, **Margaret Bourke-White first female
  war photographer Life magazine ١٩٣٦**, **Andreas Gursky
  "Rhein II" $٤٫٣M ٢٠١١ record-priced photo**, **Earthrise
  by William Anders Apollo 8 Christmas Eve ١٩٦٨**, **Blue
  Marble Apollo 17 Dec ٧ ١٩٧٢**, **Iwo Jima flag-raising
  Joe Rosenthal Feb ٢٣ ١٩٤٥**, **V-J Day Times Square
  kiss Eisenstaedt Aug ١٤ ١٩٤٥**, **camera obscura
  ancient (Mozi ٥-th c. BCE; Ibn al-Haytham wrote on it
  ~١٠٢١ CE)**, **Ibn al-Haytham (Alhazen) "Book of
  Optics" ~١٠٢١ CE**, **first selfie Robert Cornelius
  ١٨٣٩**, **Magnum Photos co-op founded ١٩٤٧
  (Cartier-Bresson + Capa + Rodger + Seymour)**, **JWST
  ٢٠٢٢ first images**, **Photoshop launched ١٩٩٠**,
  Instagram ٢٠١٠ (Systrom + Krieger), aperture/shutter/ISO
  triangle, rule of thirds, golden hour.
- **Famous Beaches pack** (`famous_beaches.json`) — 60
  items on **Bondi Beach Sydney**, **Copacabana Rio
  ~٤كم**, Ipanema "Girl from Ipanema", **Waikiki Honolulu
  surfing**, **Pipeline Oahu big-wave surfing**, Maldives
  atolls, Bora Bora, **Maya Bay (Phi Phi Thailand "The
  Beach" film ٢٠٠٠)**, **Whitehaven Whitsundays Australia
  (٩٨٪ silica sand)**, **Glass Beach Fort Bragg California
  (sea-tumbled glass)**, **Pink Sand Bahamas Harbour
  Island (foraminifera)**, **Black Sand Iceland
  Reynisfjara, Hawaii Punaluʻu, Santorini**, Anse Source
  d'Argent (Seychelles, granite boulders), Praia da
  Marinha (Algarve), **Navagio Shipwreck Beach Zakynthos
  Greece**, Cinque Terre Italy, **Santorini Oia sunset**,
  Phuket Thailand, Halong Bay Vietnam UNESCO ~١٬٦٠٠
  limestone karsts, Cape Town beaches (Boulders Beach
  penguins), Zanzibar, Mauritius, Caribbean (Seven Mile
  Cayman, Negril Jamaica), Cancún + Tulum Mexico, Miami
  South Beach, California (Venice/Santa Monica/Malibu),
  **Outer Banks NC (Wright brothers Kitty Hawk ١٩٠٣)**,
  **Nazaré Portugal world's biggest waves (~٢٦م record
  ٢٠١٧ Rodrigo Koxa)**, **surfing originated Polynesia /
  Hawaii (~١٢-th century)**, **Saudi Red Sea coast (Jeddah
  Corniche, NEOM)**, **Kuwait Marina Crescent + Marina
  Beach**, Dubai Jumeirah Beach + JBR, Galapagos beaches
  (sea lions/marine iguanas), **tides caused by moon
  (and sun) — spring + neap**, **2004 Indian Ocean
  tsunami Boxing Day**, **2011 Tōhoku tsunami Japan**,
  Twelve Apostles Australia.
- **Fraction Match mini-game** — visual fraction recognition:
  a custom-painted pie chart shows N/M shaded slices
  (1/2, 1/3, 2/3, 1/4, 3/4, 1/5–4/5, 1/6, 5/6, 1/8, 3/8,
  5/8, 7/8); pick the matching fraction from 4 buttons.
  ٦٠s round; coin tiers ٢🪙/٥🪙/١٠🪙 at scores ٨/١٦/٢٦.

### Cumulative
- 173 quiz packs (~١٠٬٣٨٠ items), 66 mini-games on the home shelf.

## 1.1.68 — 2026-05-06 — Wave 65

### Added
- **Snakes of the World pack** (`snakes_world.json`) — 60
  kid-friendly items on **~٤٬٠٠٠ snake species**, all
  reptiles + cold-blooded + carnivorous, **no eyelids
  (transparent scales) + no ears (sense vibrations through
  jawbone)**, **forked tongue + Jacobson's organ on roof of
  mouth**, **most snakes NOT venomous (~٦٠٠ venomous)**,
  **Reticulated Python longest ~٦م+ Asia**, **Green
  Anaconda heaviest ~٢٥٠kg Amazon**, **Barbados threadsnake
  smallest ~١٠سم**, **King Cobra longest venomous ~٥٫٥م
  (eats other snakes)**, **Inland Taipan most venomous
  land snake (Australia)**, **Black Mamba fastest ~٢٠km/h
  (Africa)**, boa constrictor (Americas, kills by
  squeezing), sea snakes, **cobras (uraeus pharaoh symbol)**,
  vipers heat-pitted, rattlesnakes (rattle of keratin
  segments), coral snake "red on yellow kill a fellow",
  **sidewinder rattlesnake (sideways motion on sand)**,
  hognose plays dead, **flying snakes (glide between trees,
  SE Asia)**, spitting cobras, **snakes evolved from
  lizards ~١٥٠Mya**, **Titanoboa fossil ~١٣م ~٥٨Mya**,
  **St. Patrick "drove snakes from Ireland" (Ireland never
  had snakes due to ice age)**, snakes in mythology
  (Medusa, Caduceus, Naga, ouroboros), antivenom Calmette
  + Phisalix ١٨٩٤, snake charmers (cobras don't hear music,
  follow flute movement), Indiana Jones snake fear, "Snakes
  on a Plane" ٢٠٠٦.
- **Spiders & Arachnids pack** (`spiders_arachnids.json`) —
  60 kid-friendly items on **arachnids = ٨ legs + ٢ body
  parts + exoskeleton + NO antennae or wings**, **spiders
  are arachnids NOT insects**, ~٥٠٬٠٠٠ spider species,
  **silk stronger than steel by weight, stretchier than
  rubber**, ٧ silk types (dragline + spiral capture +
  attachment), spider eyes usually ٨, **book lungs +
  tracheae for breathing**, **Goliath birdeater largest by
  mass ~١٧٥g (S. America)**, **Giant huntsman largest
  leg-span ~٣٠سم Laos ٢٠٠١**, **Patu digua smallest
  ~٠٫٣٧مم Colombia**, **black widow red hourglass**,
  brown recluse, Sydney funnel-web (antivenom ١٩٨١),
  tarantulas, **trapdoor spider camouflaged trapdoor**,
  wolf spider carries babies on back, **jumping spider
  (Salticidae, big eyes, jumps several times own length)**,
  **peacock spider (colorful courtship dance)**, crab
  spider in flowers, web types (orb/funnel/sheet/tangle),
  **Charlotte's Web (E.B. White ١٩٥٢, Araneus cavaticus)**,
  **diving bell spider (only spider that lives entirely
  underwater, Europe)**, **harvestmen (Opiliones) =
  arachnid but NOT spider (no silk + no venom)**,
  **scorpions glow under UV light**, deathstalker scorpion
  (Middle East/N. Africa), mites + ticks (Lyme disease),
  camel spiders / sun spiders, **spiders predate dinosaurs
  (~٣٠٠+ Mya)**, tarantulas live ٢٥+ years, **Spider-Man
  (Marvel ١٩٦٢)**, Aragog (Harry Potter), Anansi (West
  African folklore trickster spider), **Arachne Greek myth
  (turned into spider by Athena, root of "arachnid")**,
  arachnophobia, web silk used for crosshairs in WWII gun
  sights.
- **Famous Caves of the World pack** (`famous_caves_world.json`)
  — 60 items on **Lascaux Cave (France, paintings ~١٧٬٠٠٠
  ya, discovered ١٩٤٠ by ٤ boys)**, **Altamira (Spain
  ceiling bison ~٣٦٬٠٠٠ ya)**, **Chauvet (oldest figurative
  art ~٣٢٬٠٠٠–٣٦٬٠٠٠ ya)**, **Mammoth Cave (Kentucky USA,
  longest cave system ~٦٧٥كم)**, **Carlsbad Caverns (NM USA,
  Bat Cave colony)**, **Krubera-Voronya / Veryovkina
  deepest known ~٢٬٢١٢م Georgia/Abkhazia**, **Son Doong
  Cave (Vietnam, largest cave passage by volume, ٢٠٠٩) —
  contains its own jungle + clouds**, **Crystal Cave
  Naica Mexico (selenite up to ١٢م)**, **Glowworm Caves
  Waitomo NZ (bioluminescent fungus gnats)**, **Cave of
  Hira / Jabal al-Nour (Mecca, Prophet Muhammad ﷺ first
  revelation ~٦١٠ CE)**, **Cave of Thawr (Mecca, Prophet
  ﷺ + Abu Bakr Hijrah ٦٢٢ CE; spider's web + dove's nest
  miracle)**, **Cave of Ashab al-Kahf / Seven Sleepers
  (Surah al-Kahf, slept ٣٠٩ years)**, **Qumran Caves (Dead
  Sea Scrolls, ١٩٤٧)**, Catacombs of Paris (~٦M remains),
  **Wieliczka Salt Mine (Poland)**, **Ajanta Caves
  (India, Buddhist ٢nd c. BCE — ٦th c. CE)**, Mogao Caves
  (Dunhuang Silk Road), Cappadocia underground cities
  (Derinkuyu/Kaymakli), Petra Treasury, **stalactites hang
  from ceiling vs stalagmites grow from floor (column when
  they meet)**, cave types (solution/lava tubes/sea/ice/
  glacier), **Olm (Slovenia cave salamander ~١٠٠yrs
  longest-lived amphibian)**, **Tham Luang cave rescue
  Thailand ٢٠١٨ (١٢ boys + soccer coach trapped ١٨ days)**,
  **cave bears Pleistocene Ursus spelaeus extinct ~٢٤٬٠٠٠
  ya**, Fingal's Cave Scotland (basalt columns,
  Mendelssohn "Hebrides Overture" inspired), Blue Grotto
  Capri, cenotes Yucatan (Mayan sacred).
- **Roman Numerals mini-game** — convert a Roman numeral
  (I/V/X/L/C/D/M up to ~CL) to an Arabic number, picking
  from 4 options. Range expands as score grows; ٦٠s round;
  coin tiers ٢🪙/٥🪙/١٠🪙 at scores ٨/١٦/٢٦.

### Cumulative
- 170 quiz packs (~١٠٬٢٠٠ items), 65 mini-games on the home shelf.

## 1.1.67 — 2026-05-06 — Wave 64

### Added
- **UNESCO World Heritage Sites pack**
  (`unesco_heritage_sites.json`) — 60 items on **UNESCO World
  Heritage Convention ١٩٧٢**, **first ١٢ inscriptions ١٩٧٨**,
  **~١٬٢٠٠+ sites in ~١٧٠+ countries**, categories
  (Cultural/Natural/Mixed/In Danger), **Italy + China most
  sites (~٥٨ each)**, Pyramids of Giza, **Great Wall of
  China**, **Taj Mahal (Mughal Shah Jahan ١٦٤٨)**, **Machu
  Picchu (Hiram Bingham ١٩١١)**, **Petra "Rose City"
  (Nabataean)**, **Stonehenge (~٣٠٠٠ BCE)**, **Acropolis
  Athens**, **Colosseum Rome (٨٠ CE)**, Vatican City,
  **Angkor Wat (Cambodia ١٢-th century, largest religious
  monument)**, Borobudur (Java Buddhist ٩-th century),
  Galápagos (Ecuador, evolution), **Great Barrier Reef
  (Australia, GBR UNESCO ١٩٨١)**, **Yellowstone (first US
  national park ١٨٧٢)**, Sydney Opera House (١٩٧٣ Utzon),
  **Madā'in Sāliḥ / Hegra (first Saudi WH ٢٠٠٨)**, **Diriyah
  Saudi (At-Turaif District ٢٠١٠)**, Historic Jeddah ٢٠١٤,
  Hima Cultural Area ٢٠٢١, Uruq Bani Ma'arid ٢٠٢٣,
  **L'Anse aux Meadows (only accepted Norse settlement in
  N. America)**, **New 7 Wonders of the World vote ٢٠٠٧
  (Great Wall + Petra + Christ Redeemer + Machu Picchu +
  Chichén Itzá + Colosseum + Taj Mahal)**, sites in danger
  (Palmyra, Old Aleppo, Sana'a Old City).
- **Penguins of the World (Deep) pack**
  (`penguins_world_deep.json`) — 60 items on **١٨ living
  penguin species**, **all in Southern Hemisphere except
  Galápagos Penguin (lives at equator)**, **NO penguins at
  North Pole / Arctic**, **Emperor Penguin largest ~١٫٢م ~٣٠kg
  (Antarctica only, dives ~٥٠٠م+, holds breath ~٢٠ min)**,
  **Emperor breeds in Antarctic winter, males incubate egg
  on feet ~٦٥ days while females hunt**, **Gentoo Penguin
  fastest swimmer ~٣٦ km/h**, **Macaroni Penguin yellow
  crest (named after ١٨-th century English fashion)**,
  Rockhopper, **Yellow-eyed Penguin NZ rarest**, **Little
  Blue (Fairy) Penguin smallest ~٣٣سم**, **African Penguin
  / Jackass (braying call)**, **Galápagos Penguin only at
  equator**, **flightless birds (lost flight ~٦٠ Mya)**,
  flippers = wings (fly through water), counter-shading,
  tobogganing on belly, **huddle ~٣٧°C inside vs -٥٠°C
  outside**, salt gland filters seawater, **densest
  feathers of any bird (~٧٠/in²)**, lifespan ~١٥–٣٠yrs,
  pebble courtship, **Linux mascot Tux ١٩٩٦ Larry Ewing**,
  Pittsburgh Penguins NHL, predators (leopard seals + orcas
  in water; skuas + sheathbills on land), **giant fossil
  penguins ~٢م tall (Kumimanu) ~٦٠Mya**, **Antarctica =
  desert (low precipitation)**, **Roald Amundsen first to
  South Pole Dec ١٤ ١٩١١**, Antarctic Treaty ١٩٥٩.
- **Coral Reefs of the World pack** (`coral_reefs_world.json`)
  — 60 items on **coral = animals (cnidarians, related to
  jellyfish + anemones), NOT plants or rocks**, calcium
  carbonate skeleton, **symbiotic zooxanthellae algae give
  color + food via photosynthesis**, **coral bleaching: warm
  water expels zooxanthellae, coral turns white, can die**,
  **reefs cover ~٠٫١٪ of ocean but home to ~٢٥٪ of marine
  species ("rainforests of the sea")**, **Great Barrier
  Reef largest (~٢٬٣٠٠كم, visible from space)**, Belize
  Barrier Reef + "Blue Hole" ١٢٤م, **Coral Triangle most
  biodiverse marine area**, Maldives atolls, Florida Keys,
  reef types (fringing/barrier/atoll), **Darwin's atoll
  theory ١٨٤٢**, reef fish (clownfish/parrotfish/Moorish
  idol/lionfish/blue tang), **Crown-of-thorns starfish eats
  coral**, **Coral spawning synchronized once a year on full
  moon**, water ٢٣–٢٩°C, **ocean acidification harms coral
  skeletons**, ٢٠١٦/٢٠١٧/٢٠٢٠ mass bleaching events GBR,
  reef restoration nurseries, **Jacques Cousteau (١٩١٠–١٩٩٧)
  + Aqua-Lung ١٩٤٣**, Sylvia Earle "Her Deepness", **modern
  Scleractinia corals ~٢٤٠Mya**, **reefs protect coastlines
  from storms (~$٩B/year wave protection)**, "Finding Nemo"
  ٢٠٠٣, "Finding Dory" ٢٠١٦.
- **Asteroid Dodge mini-game** — top-down arcade dodge:
  drag ship 🚀 left/right at the bottom to avoid falling
  asteroids ☄️; ٦٠s round (or until hit); each asteroid
  passed = +1 point; coin tiers ٢🪙/٥🪙/١٠🪙 at scores
  ١٥/٣٠/٥٠.

### Cumulative
- 167 quiz packs (~١٠٬٠٢٠ items), 64 mini-games on the home shelf.
- **Crossed 10,000 quiz items milestone.**

## 1.1.66 — 2026-05-06 — Wave 63

### Added
- **Frogs & Amphibians pack** (`frogs_amphibians.json`) — 60
  items on **~٨٬٠٠٠ amphibian species (class Amphibia "double
  life")**, three orders (Anura frogs/toads ~٧٬٠٠٠, Caudata
  salamanders ~٧٠٠, Gymnophiona caecilians ~٢٠٠), tadpole
  metamorphosis (egg → tadpole gills+tail → froglet → adult
  lungs), frogs vs toads (smooth wet vs warty dry skin),
  **Goliath frog Africa largest ~٣٢سم**, **Paedophryne PNG
  smallest vertebrate ~٧٫٧مم**, **poison dart frogs (golden
  poison frog deadliest)**, glass frog transparent belly,
  **wood frog freezes solid in winter (Alaska)**, red-eyed
  tree frog Costa Rica, bullfrog "jug-o-rum" call, **cane
  toad invasive Australia ١٩٣٥**, **axolotl Mexico (neoteny
  + regeneration of limbs/heart/spine)**, olm cave salamander
  Slovenia (blind), Surinam toad eggs in back skin, **Darwin's
  frog male carries young in vocal sac**, caecilians legless
  underground, **frogs predate dinosaurs (~٢٥٠Mya)**,
  amphibians evolved from lobe-finned fish (~٣٧٠Mya, Tiktaalik
  + Ichthyostega), **chytrid fungus Bd decimating amphibians
  since ١٩٩٠s (~٤٠٪ threatened)**, frog calls, amplexus,
  spawn (frogspawn floats vs toad strings), frogs blink to
  swallow food, **cutaneous breathing (some frogs have NO
  lungs)**, Wallace's flying frog Borneo, coqui Puerto Rico,
  Kermit the Frog (Henson ١٩٥٥).
- **Comic Book Heroes pack** (`comic_book_heroes.json`) — 60
  kid-friendly items on **Superman Action Comics #١ June ١٩٣٨
  (Siegel + Shuster, Clark Kent, Daily Planet, Krypton)**,
  **Batman Detective Comics #٢٧ May ١٩٣٩ (Kane + Finger,
  Bruce Wayne, Gotham, no powers)**, **Wonder Woman ١٩٤١
  (Marston, Themyscira, Lasso of Truth)**, **Captain America
  ١٩٤١ (Simon + Kirby)**, **Spider-Man Amazing Fantasy #١٥
  Aug ١٩٦٢ (Lee + Ditko, Peter Parker Queens NY)**, **Iron
  Man ١٩٦٣ (Stark)**, **Hulk ١٩٦٢ (Banner gamma rays)**,
  Thor ١٩٦٢ Asgardian Mjolnir, X-Men ١٩٦٣, **Wolverine ١٩٧٤
  (Hulk #١٨١)**, Fantastic Four ١٩٦١, **Black Panther ١٩٦٦
  (Wakanda T'Challa)**, Avengers ١٩٦٣ comic, Justice League
  DC ١٩٦٠, MCU **Iron Man ٢٠٠٨ launched MCU**, **Disney
  bought Marvel ٢٠٠٩ for $٤B**, **Avengers: Endgame ٢٠١٩
  highest-grossing ~$٢٫٨B**, Stan Lee + Jack Kirby + Steve
  Ditko, **Ms. Marvel Kamala Khan first Muslim Marvel
  headliner**, Miles Morales Spider-Man, **The 99 (Naif
  Al-Mutawa ٢٠٠٦ Kuwaiti Islamic-inspired heroes)**, Tintin
  Hergé ١٩٢٩, Asterix ١٩٥٩, **Naruto ١٩٩٧, One Piece ١٩٩٧
  (longest-running)**, Dragon Ball Toriyama ١٩٨٤, Pokemon
  Tajiri ١٩٩٦, Sailor Moon ١٩٩٢, **Astro Boy Tezuka ١٩٥٢**,
  Comic-Con SD since ١٩٧٠, Calvin and Hobbes (Watterson
  ١٩٨٥–١٩٩٥), Garfield ١٩٧٨, **Peanuts (Schulz ١٩٥٠–٢٠٠٠)**,
  Watchmen ١٩٨٦–٨٧.
- **Cold War & Famous Spies pack** (`cold_war_spies.json`) —
  60 age-appropriate items on **Cold War ~١٩٤٧–١٩٩١ (US vs
  USSR)**, **Iron Curtain (Churchill ١٩٤٦)**, Marshall Plan
  ١٩٤٨ ($١٣B), **NATO ١٩٤٩ vs Warsaw Pact ١٩٥٥**, **Berlin
  Wall built ١٩٦١, fell Nov ٩ ١٩٨٩**, Berlin Airlift
  ١٩٤٨–٤٩, **Sputnik 1 Oct ٤ ١٩٥٧ (started space race)**,
  Gagarin first human in space April ١٢ ١٩٦١, **Apollo 11
  July ٢٠ ١٩٦٩ (US won space race)**, **Cuban Missile Crisis
  Oct ١٩٦٢ (١٣ days, closest to nuclear war)**, **U-٢ spy
  plane shot down ١٩٦٠ (Powers)**, Korean War ١٩٥٠–٥٣,
  Vietnam War ١٩٥٥–٧٥, **"Tear down this wall" Reagan
  ١٩٨٧ Brandenburg Gate**, **Gorbachev ١٩٨٥–٩١ glasnost +
  perestroika, dissolved USSR ١٩٩١**, Reagan US president
  ١٩٨١–٨٩, **Kennedy "Ich bin ein Berliner" ١٩٦٣**, Bay of
  Pigs April ١٩٦١, **CIA founded ١٩٤٧, KGB ١٩٥٤–٩١, MI6 +
  MI5, NSA, Mossad**, **Mata Hari (executed ١٩١٧)**,
  **Cambridge Five (Burgess/Maclean/Philby/Blunt/Cairncross)**,
  **Aldrich Ames CIA mole exposed ١٩٩٤**, Robert Hanssen FBI
  mole ٢٠٠١, Rosenbergs executed ١٩٥٣, **Velvet Revolution
  ١٩٨٩ Czechoslovakia**, Solidarity Poland Walesa, **Fall of
  USSR Dec ٢٥ ١٩٩١**, **MAD (Mutually Assured Destruction)**,
  Stasi East German secret police, Olympics boycotts (Moscow
  ١٩٨٠ + LA ١٩٨٤), SDI "Star Wars" Reagan ١٩٨٣, **James
  Bond (Fleming "Casino Royale" ١٩٥٣); Connery first film
  "Dr. No" ١٩٦٢**, **George Smiley (le Carré ١٩٧٤)**, Yeltsin
  first Russian president.
- **Greater Than mini-game** — compare two sides (numbers or
  simple math expressions like ٣+٤ vs ٨ or ٧×٢ vs ١٥) and
  pick the correct sign <, =, >; ٦٠s round; coin tiers
  ٢🪙/٥🪙/١٠🪙 at scores ٨/١٦/٢٨.

### Cumulative
- 164 quiz packs (~٩٬٨٤٠ items), 63 mini-games on the home shelf.

## 1.1.65 — 2026-05-06 — Wave 62

### Added
- **Birds of the World pack** (`birds_world.json`) — 60 items
  on **~١٠٬٠٠٠ bird species worldwide**, **ostrich largest
  + fastest on land ~٧٠km/h**, kiwi (NZ flightless huge eggs),
  **Emperor Penguin largest penguin (~١٫٢م, dives ~٥٠٠م)**,
  **Bee Hummingbird smallest bird (~٥سم Cuba)**, hummingbirds
  only birds that fly backwards, **Peregrine Falcon fastest
  bird (dive ~٣٩٠km/h)**, **Common Swift longest non-stop
  flight (٠ landing for ١٠ months)**, **Bar-tailed Godwit
  longest non-stop migration ~١٣٬٥٠٠كم**, **Arctic Tern
  longest annual migration ~٧٠٬٠٠٠كم pole-to-pole**,
  Wandering Albatross sleeps while flying, **Bald Eagle US
  national bird since ١٧٨٢ (NOT bald — white head feathers)**,
  Andean Condor largest flying bird wingspan ~٣٫٢م, owls
  ٢٧٠° head rotation + silent flight, **African Grey
  smartest parrot**, Kakapo NZ flightless parrot ~٢٥٠ left,
  crows + ravens tool users, **Darwin's finches (Galapagos)
  drove evolution theory**, **Birds descended from theropod
  dinosaurs (~١٥٠Mya); Archaeopteryx (~١٥٠Mya transition
  fossil)**, **Birds = only living dinosaurs**, hollow bones,
  flamingo pink from carotenoids, dodo extinct ~١٦٨١
  Mauritius, passenger pigeon extinct ١٩١٤, **Saudi/Gulf
  falconry UNESCO heritage**, Audubon "Birds of America"
  ١٨٢٧–٣٨, **chickens most common bird ~٣٣ billion alive**.
- **Classical Composers pack** (`classical_composers.json`)
  — 60 items on **Bach (Baroque ١٦٨٥–١٧٥٠, Brandenburg
  Concertos)**, **Handel ١٦٨٥–١٧٥٩ "Messiah" + "Hallelujah
  Chorus"**, **Vivaldi "The Four Seasons"**, **Mozart child
  prodigy at ٥, ~٦٠٠ works, "Eine kleine Nachtmusik",
  Magic Flute, Requiem (١٧٥٦–١٧٩١)**, **Beethoven ٩
  symphonies + Ninth "Ode to Joy" + Fifth Ta-Ta-Ta-DUM,
  deaf composing the Ninth, "Moonlight Sonata", "Für
  Elise" (١٧٧٠–١٨٢٧)**, Schubert "Ave Maria", **Haydn
  "Father of the Symphony" (١٠٤+ symphonies)**, Chopin
  piano works, **Tchaikovsky Swan Lake ١٨٧٧ + Nutcracker
  ١٨٩٢ + ١٨١٢ Overture**, Brahms "Lullaby", Wagner "Ride of
  the Valkyries", Verdi "Aida"/"La Traviata", Puccini "La
  Bohème", **Debussy "Clair de Lune"**, **Ravel "Boléro"
  ١٩٢٨**, **Stravinsky "The Rite of Spring" caused riot
  ١٩١٣ Paris**, **Prokofiev "Peter and the Wolf" ١٩٣٦
  (each animal = instrument)**, Grieg "In the Hall of the
  Mountain King", Dvořák "New World Symphony" ١٨٩٣, Rossini
  "William Tell Overture", **Mendelssohn "Wedding March"**,
  **Hildegard von Bingen earliest known female composer**,
  Gershwin "Rhapsody in Blue" ١٩٢٤, music periods (Baroque
  ١٦٠٠–١٧٥٠ / Classical ١٧٥٠–١٨٢٠ / Romantic ١٨٢٠–١٩١٠),
  treble + bass clefs, dynamics (p/f/pp/ff), tempo
  (largo/adagio/andante/allegro/presto), symphony +
  concerto + sonata + opera + quartet definitions,
  orchestra sections (strings/woodwinds/brass/percussion),
  Carnegie Hall ١٨٩١, La Scala Milan ١٧٧٨.
- **Aviation History pack** (`aviation_history.json`) — 60
  items on **Wright Brothers first powered flight Dec ١٧
  ١٩٠٣ Kitty Hawk NC (Orville pilot, ١٢sec, ٣٦م)**, **Flyer
  I made ٤ flights that day (longest ٥٩sec ٢٦٠م)**,
  **Montgolfier brothers hot-air balloon ١٧٨٣ (first manned
  flight Paris)**, Blanchard crossed English Channel by
  balloon ١٧٨٥, Otto Lilienthal glider pioneer ١٨٩٠s,
  **Blériot first flight across English Channel ١٩٠٩**,
  **Lindbergh first solo non-stop transatlantic ١٩٢٧
  (Spirit of St. Louis NY-Paris ٣٣٫٥hrs)**, **Earhart
  first woman solo Atlantic ١٩٣٢; disappeared ١٩٣٧**,
  **Bessie Coleman first African-American + Native American
  woman pilot license ١٩٢١**, WWI Red Baron (٨٠ victories),
  WWII Spitfire (Battle of Britain), Mustang P-51, B-17 +
  B-29, **Enola Gay dropped atomic bomb Hiroshima Aug ٦
  ١٩٤٥**, **Chuck Yeager first to break sound barrier Oct
  ١٤ ١٩٤٧ (Bell X-1)**, **Concorde Mach ٢٫٠٤ (~٢٬١٨٠km/h)
  ١٩٧٦–٢٠٠٣**, **Boeing 747 "Jumbo Jet" ١٩٦٩, "Queen of
  the Skies"**, **Airbus A380 largest commercial passenger
  plane (٥٥٥ seats, ٢٠٠٧–٢٠٢١)**, **SR-71 Blackbird Mach
  ٣٫٣+**, X-15 fastest manned aircraft Mach ٦٫٧, **Apollo
  11 lunar landing July ٢٠ ١٩٦٩ (Armstrong/Aldrin/
  Collins)**, **Yuri Gagarin first human in space April
  ١٢ ١٩٦١**, **Sputnik 1 first satellite Oct ٤ ١٩٥٧**,
  Space Shuttle ١٩٨١–٢٠١١, Hindenburg disaster May ٦ ١٩٣٧
  (hydrogen), de Havilland Comet first jetliner ١٩٥٢,
  **black box (orange, David Warren ١٩٥٣)**, jet engine
  Whittle UK + von Ohain Germany, **four forces of flight:
  lift/weight/thrust/drag**, Sikorsky helicopter ١٩٣٩,
  da Vinci helical air screw sketch ~١٤٨٠, **Saudia (SV)
  founded ١٩٤٥**, Emirates ١٩٨٥, **DXB busiest international
  airport for international passengers**, ATL busiest
  overall, Boeing Everett factory largest building by
  volume in world.
- **Pattern Next mini-game** — given a 4-number sequence
  (arithmetic, geometric, squares, fibonacci-like, doubling
  ×3, descending), pick the next number from 4 options;
  ٦٠s round; coin tiers ٢🪙/٥🪙/١٠🪙 at scores ٨/١٦/٢٦.

### Cumulative
- 161 quiz packs (~٩٬٦٦٠ items), 62 mini-games on the home shelf.

## 1.1.64 — 2026-05-06 — Wave 61

### Added
- **Mythological Creatures pack** (`mythological_creatures.json`)
  — 60 items on **Phoenix (Egyptian Bennu, Greek phoenix,
  Persian Simurgh)**, dragons (Western fire-breathing vs
  Eastern serpentine bringer of luck/rain), unicorn, **Pegasus
  (winged horse, born from Medusa's blood)**, **centaur (Chiron
  the wise teacher)**, **Minotaur (Crete labyrinth, Theseus
  killed)**, **Sphinx (Greek riddles vs Egyptian Giza)**,
  mermaid (Andersen "Little Mermaid" ١٨٣٧), Cyclops Polyphemus,
  **Cerberus (٣-headed Underworld dog)**, Hydra (Heracles 2nd
  labor), Medusa (Gorgon), griffin, hippogriff, chimera,
  Anubis, Bastet, Horus, **Roc (Persian/Arabian giant bird,
  ١٠٠١ Nights)**, **Jinn (made of smokeless fire, in Quran)**,
  **Buraq (winged steed in Isra & Mi'raj)**, **Anqa Arabian
  phoenix**, Chinese Long dragon (٥ toes imperial),
  Qilin (Chinese unicorn), Fenghuang (Chinese phoenix), four
  Chinese symbols (Bai Hu/Zhu Que/Qing Long/Xuan Wu), **Japanese
  Kappa/Tengu/Kitsune/Tanuki**, **Norse Fenrir/Jörmungandr/
  Sleipnir/Valkyries/Mjölnir/Loki**, Indian Naga/Garuda/Hanuman/
  Ganesha, **vampire (Stoker "Dracula" ١٨٩٧)**, Frankenstein
  (Shelley ١٨١٨), Headless Horseman (Irving ١٨٢٠ "Sleepy
  Hollow"), Loch Ness, Yeti, Bigfoot, Kraken, Leviathan,
  Behemoth, banshee, leprechaun, troll, ogre, **Aladdin's
  genie (١٠٠١ Nights)**, Trojan Horse, Atlas, Pandora's Box,
  Achilles' heel, Charybdis & Scylla.
- **Automobile History pack** (`automobile_history.json`) —
  60 items on **Karl Benz Patent-Motorwagen ١٨٨٦ (3 wheels)**,
  **Bertha Benz first long-distance trip ١٨٨٨ (~١٠٦كم)**,
  **Henry Ford Model T ١٩٠٨–١٩٢٧ (١٥ million made, "Tin
  Lizzie")**, **Ford moving assembly line ١٩١٣ cut Model T
  production from ١٢٫٥hrs to ٩٣ min**, "any color so long as
  it's black", **Cugnot steam carriage ١٧٦٩ (first self-
  propelled vehicle)**, Daimler & Maybach Reitwagen ١٨٨٥
  (first motorcycle), Rolls-Royce ١٩٠٤, **BMW ١٩١٦ logo from
  Bavarian flag (NOT propeller)**, **VW Beetle (Porsche ١٩٣٨,
  ٢١+ million made)**, Toyota (Kiichiro Toyoda ١٩٣٧), Honda
  (Soichiro Honda ١٩٤٨ motorcycles first), Lamborghini
  (Ferruccio ١٩٦٣ after Ferrari dispute), Ferrari (Enzo ١٩٣٩,
  prancing horse from WWI ace Baracca), Porsche 911 since
  ١٩٦٣, **Bugatti Veyron Super Sport ٤٣١km/h ٢٠١٠**,
  **ThrustSSC ١٬٢٢٨km/h ١٩٩٧ land speed record**, Toyota Prius
  hybrid ١٩٩٧, Tesla Roadster ٢٠٠٨ / Model S ٢٠١٢, **first
  electric cars predate gasoline ١٨٣٠s**, **first gas station
  ١٨٨٨ Wiesloch Germany**, **Volvo 3-point seatbelt ١٩٥٩
  Nils Bohlin (open patent)**, **first airbag Mercedes
  S-Class ١٩٨١**, ABS production ١٩٧٨ Mercedes, **cruise
  control Ralph Teetor ١٩٤٨ (he was blind)**, Le Mans 24h
  since ١٩٢٣, Indy 500 since ١٩١١, F1 since ١٩٥٠, NASCAR
  ١٩٤٨, Diesel ١٨٩٣, **first Saudi female driver legally
  ٢٠١٨**, VIN standardized ١٩٨١ (١٧ chars), avg car ~٣٠٬٠٠٠
  parts.
- **Famous Museums of the World pack** (`famous_museums_world.json`)
  — 60 items on **Louvre most-visited (Mona Lisa, Venus de
  Milo, Winged Victory, I.M. Pei pyramid ١٩٨٩)**, **British
  Museum ١٧٥٣ (Rosetta Stone, Parthenon Marbles)**, **The Met
  NYC ١٨٧٠ (Temple of Dendur)**, **MoMA NYC ١٩٢٩ (Van Gogh
  Starry Night)**, **Vatican Museums (Sistine Chapel by
  Michelangelo ١٥٠٨–١٥١٢, Last Judgment ١٥٤١)**, **Uffizi
  Florence (Botticelli's Birth of Venus, Primavera)**,
  **Accademia Florence (Michelangelo's David)**, **Hermitage
  St. Petersburg (Catherine the Great ١٧٦٤, 2nd largest art
  museum)**, **Prado Madrid (Velázquez, Goya, El Greco)**,
  **Reina Sofía Madrid (Picasso's Guernica)**, **Rijksmuseum
  (Rembrandt's Night Watch)**, Van Gogh Museum Amsterdam,
  Pergamon Berlin (Ishtar Gate), **Egyptian Museum Cairo
  (Tutankhamun's mask, ١٩٠٢)**, **Grand Egyptian Museum
  Giza opened ٢٠٢٤–٢٠٢٥**, **Museum of Islamic Art Doha
  (I.M. Pei ٢٠٠٨)**, **Louvre Abu Dhabi ٢٠١٧ (Jean Nouvel)**,
  Tate Modern (former power station), **Smithsonian
  Washington (٢١ museums + zoo, free, founded ١٨٤٦)**,
  **National Air & Space (Wright Flyer, Apollo 11, Spirit of
  St. Louis)**, AMNH NYC (T. rex Sue cast), Field Museum
  Chicago (T. rex Sue actual), **Forbidden City Beijing (١٫٨٦M
  objects)**, Topkapi Istanbul (Ottoman ١٤٦٥–١٨٥٦), Hagia
  Sophia (museum until ٢٠٢٠), **Madame Tussauds wax ١٨٣٥**,
  Guggenheim Bilbao ١٩٩٧ Frank Gehry, Anne Frank House
  Amsterdam, Picasso Museum Barcelona, **Capitoline Rome
  ١٤٧١ first public museum**, **Ashmolean Oxford ١٦٨٣ first
  university museum**, curator/conservator/archivist roles.
- **Find the Twin mini-game** — visual scanning grid puzzle:
  4×4 grid of emojis where exactly two are duplicates; tap
  both to score. ٦٠s round; coin tiers ٢🪙/٥🪙/١٠🪙 at
  scores ٨/١٦/٢٦.

### Cumulative
- 158 quiz packs (~٩٬٤٨٠ items), 61 mini-games on the home shelf.

## 1.1.63 — 2026-05-06 — Wave 60

### Added
- **Famous Castles of the World pack** (`famous_castles_world.json`)
  — 60 items on **Neuschwanstein (King Ludwig II ١٨٦٩, Disney
  inspiration)**, Tower of London (William the Conqueror,
  Crown Jewels, ravens), **Windsor Castle oldest occupied
  ١٠٧٠ (Queen Elizabeth's home)**, **Versailles (Louis XIV,
  Hall of Mirrors, ~٧٠٠ rooms)**, Bran Castle "Dracula's
  Castle" Romania, **Prague Castle largest ancient castle**,
  **Malbork largest castle by area (Teutonic Order, Poland)**,
  **Krak des Chevaliers (Crusader, Syria)**, **Alhambra
  (Granada Moorish Nasrid ١٢٣٨)**, Carcassonne walled city,
  Mont Saint-Michel, Château de Chambord (double-helix
  staircase), **Himeji "White Heron" UNESCO Japan**,
  **Forbidden City Beijing (Ming/Qing ١٤٠٦–١٤٢٠)**, Potala
  Palace Tibet, **Red Fort Delhi (Shah Jahan ١٦٤٨)**,
  **Topkapi Palace (Ottoman ١٤٦٥–١٨٥٦)**, Hearst Castle,
  Biltmore Estate (Vanderbilt, largest US private home),
  **Cinderella Castle Disney World**, castle parts (keep,
  bailey, motte, drawbridge, portcullis, moat, battlements,
  crenellations, arrow slits, donjon, gatehouse, barbican),
  Norman motte-and-bailey post-١٠٦٦, trebuchet vs catapult
  vs ballista, Constantinople siege ١٤٥٣.
- **Currency & Money History pack** (`currency_money_history.json`)
  — 60 items on **barter predates money**, **cowrie shells
  used for thousands of years**, **first coins Lydia ~٦٠٠ BCE
  (Croesus, electrum)**, **first paper money Tang China
  ~٧–٩th c.**, **Marco Polo described Chinese paper
  money**, Greek drachma, Roman denarius, **Islamic gold
  dinar + silver dirham (Caliph Abd al-Malik ٦٩٧ CE)**,
  florin Florence ١٢٥٢, ducat Venice ١٢٨٤, **pound sterling
  £ (~٧٧٥ CE; symbol from L libra)**, **US dollar adopted
  ١٧٩٢**, US bills (Washington/Lincoln/Hamilton/Jackson/
  Grant/Franklin), **euro launched ١٩٩٩ electronic / ٢٠٠٢
  notes**, yen "circle" ١٨٧١, **Kuwaiti dinar highest valued
  circulated currency**, Bahraini dinar 2nd, **Bretton
  Woods ١٩٤٤ → Nixon shock ١٩٧١**, hyperinflation Weimar
  ١٩٢٣, Zimbabwe ٢٠٠٨ (١٠٠ trillion ZWD note), **largest
  ever: ١٠٠ quintillion pengő Hungary ١٩٤٦**, **Bitcoin
  (Satoshi Nakamoto whitepaper ٢٠٠٨, genesis block Jan
  ٢٠٠٩) + Pizza Day May ٢٢ ٢٠١٠ (١٠٬٠٠٠ BTC for ٢ pizzas)**,
  ATM ١٩٦٧ Barclays, credit cards (Diners ١٩٥٠, Visa
  ١٩٥٨, MasterCard ١٩٦٦), Federal Reserve ١٩١٣, **Bank of
  England ١٦٩٤ oldest central bank still active**, **USD
  ~٨٨٪ of forex / reserve currency since ١٩٤٤**, Fort Knox,
  banknote security (watermark/hologram/security thread/
  microprinting/color-shifting ink), **rarest US coin: ١٩٣٣
  Double Eagle ($١٨٫٩M sale ٢٠٢١)**, KD ≈ ٣٫٢٧ USD.
- **Famous Skyscrapers pack** (`famous_skyscrapers.json`) —
  60 items on **Burj Khalifa Dubai ٢٠١٠ (٨٢٨م, ١٦٣ floors,
  tallest in world)**, **Merdeka 118 Kuala Lumpur ٢٠٢٣
  (٦٧٨٫٩م, 2nd)**, **Shanghai Tower ٢٠١٥ (٦٣٢م, 3rd)**,
  **Makkah Royal Clock Tower (Abraj Al-Bait Saudi Arabia ٢٠١٢
  ٦٠١م, largest clock face in world)**, Lotte World Tower
  Seoul, **One World Trade Center NYC ٢٠١٤ (٥٤١٫٣م, height
  symbolic ١٧٧٦ feet)**, **Taipei 101 ٢٠٠٤ (٥٠٨م) tuned mass
  damper ٦٦٠-ton sphere**, **Empire State ١٩٣١ (٣٨١م + ٦٢م
  antenna, was tallest ٤٠ years)**, **Chrysler Building
  ١٩٣٠ (art deco, ٣١٩م)**, **Willis/Sears Tower Chicago ١٩٧٣
  (٤٤٢م)**, **Petronas Twin Towers ١٩٩٨ (٤٥٢م) was tallest
  until Taipei 101**, **CN Tower Toronto ١٩٧٦ (٥٥٣م) was
  tallest free-standing**, **Tokyo Skytree ٢٠١٢ (٦٣٤م,
  tallest tower)**, The Shard London ٢٠١٢ (Renzo Piano),
  Burj Al Arab Dubai ١٩٩٩ (٣٢١م sail-shaped), **Capital
  Gate Abu Dhabi (leaning tower ١٨°)**, **Home Insurance
  Building Chicago ١٨٨٥ often called first skyscraper**,
  **"skyscraper" coined ١٨٨٠s Chicago**, Bessemer steel +
  **Otis safety elevator ١٨٥٤** enabled tall buildings,
  Fazlur Khan tube structural system, supertalls vs
  megatalls (٣٠٠م vs ٦٠٠م), WTC twins were tallest ١٩٧٢–٣,
  destroyed ٩/١١/٢٠٠١, Empire State lightning ~٢٥× per year.
- **Stroop Color Match mini-game** (also "Ink Color") —
  classic Stroop interference test: a color word (RED, BLUE,
  GREEN, YELLOW, PURPLE) appears in a different ink color;
  tap the INK color, not the word's meaning. ٦٠s round; coin
  tiers ٢🪙/٥🪙/١٠🪙 at scores ٨/١٦/٢٨.

### Cumulative
- 155 quiz packs (~٩٬٣٠٠ items), 60 mini-games on the home shelf.

## 1.1.62 — 2026-05-06 — Wave 59

### Added
- **Big Cats of the World pack** (`big_cats_world.json`) — 60
  items on **tiger largest cat (Siberian/Amur up to ~٣٠٠kg)**,
  6 tiger subspecies (Bengal, Indochinese, South China,
  Sumatran, Siberian, Malayan), unique stripes like
  fingerprints, **lion (Panthera leo) only social cat with
  prides**, **Asiatic lions in Gir India ~٦٠٠ left**,
  **lion roar audible ٨كم away**, jaguar strongest jaw +
  rosettes-with-spots (Americas), leopard rosettes-without-
  spots + tree-cacher, snow leopard "ghost of mountains"
  Himalayas, **cheetah ~١١٠–١٢٠ km/h fastest land animal,
  ٠–١٠٠ in ٣s, NOT a roaring big cat**, cheetah black tear
  marks reduce sun glare, puma/cougar/mountain-lion same
  animal, lynx + caracal + serval + ocelot + clouded leopard,
  **black panther = melanistic leopard or jaguar (NOT a
  species)**, **white tiger = leucistic Bengal (rare gene)**,
  **Smilodon saber-tooth extinct ~١٠٬٠٠٠ya**, Panthera genus
  (lion, tiger, jaguar, leopard, snow leopard) defined by
  hyoid bone + roaring, lion pride structure, **cubs born
  blind**, tigers excellent swimmers, cheetahs hunt by speed
  not stealth, **Project Tiger India ١٩٧٣**, "Lion King"
  ١٩٩٤ Pride Rock, **"Born Free" Elsa ١٩٦٦**, Cecil killed
  ٢٠١٥, Iberian lynx most endangered cat, retractable claws
  (cheetah only semi-retractable), tapetum lucidum reflective
  layer.
- **Schulte Table mini-game** — tap numbers in order from ١
  on a grid that grows from ٣×٣ → ٤×٤ → ٥×٥ as you complete
  each board; ٦٠s round; coin tiers ٢🪙/٥🪙/١٠🪙 at
  ٣/٦/١٠ boards cleared. Trains visual-scanning attention.

### Notes
- This wave is half-sized (1 pack instead of 3) because the
  content-authoring quota hit a daily limit mid-wave. Wave
  60 will resume the regular 3-pack cadence after the reset.

### Cumulative
- 152 quiz packs (~٩٬١٢٠ items), 59 mini-games on the home shelf.

## 1.1.61 — 2026-05-06 — Wave 58

### Added
- **Famous Bridges of the World pack** (`famous_bridges_world.json`)
  — 60 items on **Brooklyn Bridge ١٨٨٣ (Roebling family)**,
  **Golden Gate ١٩٣٧ (International Orange)**, **Tower Bridge
  ١٨٩٤ (bascule, often confused with London Bridge)**,
  **Sydney Harbour ١٩٣٢ "The Coathanger"**, **Akashi-Kaikyō
  longest suspension main span ١٬٩٩١م (Japan ١٩٩٨)**,
  **Millau Viaduct tallest ٣٤٣م (France ٢٠٠٤)**, **Danyang–
  Kunshan Grand Bridge longest ever ١٦٥كم (China rail)**,
  **HK-Zhuhai-Macau ~٥٥كم longest sea crossing ٢٠١٨**,
  **Sheikh Jaber Causeway ٣٦كم Kuwait ٢٠١٩**, Iron Bridge
  Shropshire ١٧٧٩ (first major iron bridge), **Tacoma Narrows
  collapse ١٩٤٠ "Galloping Gertie"**, Stari Most rebuilt
  ٢٠٠٤, Forth Bridge cantilever ١٨٩٠, Vasco da Gama longest
  in Europe ~١٢٫٣كم, types (beam/arch/truss/cantilever/
  suspension/cable-stayed/bascule/swing), Pont du Gard
  Roman aqueduct, Ponte Vecchio, **Pittsburgh "City of
  Bridges" ٤٤٦+ bridges**, Falkirk Wheel boat lift ٢٠٠٢,
  Magdeburg water bridge.
- **Robots & AI History pack** (`robots_ai_history.json`) —
  60 items on **word "robot" Karel Čapek "R.U.R." ١٩٢٠
  (Czech "robota" = forced labor)**, **Asimov's Three Laws
  ١٩٤٢**, **Turing Test ١٩٥٠**, **Dartmouth ١٩٥٦ (McCarthy
  coined "AI")**, **ELIZA chatbot Weizenbaum ١٩٦٦**, Shakey
  Stanford ١٩٦٦–٧٢, **Unimate first industrial robot
  GM ١٩٦١**, ASIMO ٢٠٠٠, **Sophia (Hanson Robotics) Saudi
  citizenship ٢٠١٧**, Boston Dynamics Atlas/Spot/BigDog,
  Roomba ٢٠٠٢, Mars rovers (Sojourner ١٩٩٧ → Perseverance
  ٢٠٢١, Ingenuity helicopter ٢٠٢١), **Deep Blue beat
  Kasparov ١٩٩٧**, **AlphaGo beat Lee Sedol ٢٠١٦ (٤–١)**,
  AlphaZero ٢٠١٧, Watson Jeopardy ٢٠١١, **ChatGPT
  ٢٠٢٢**, GPT-3 ٢٠٢٠ / GPT-4 ٢٠٢٣, DALL·E ٢٠٢١, **al-Jazari
  ١٢-th century programmable humanoid drum band**, da
  Vinci's mechanical knight ~١٤٩٥, Hero of Alexandria
  automata, Karakuri puppets, **WALL-E (٢٠٠٨)**, R2-D2 &
  C-3PO (Star Wars ١٩٧٧), **da Vinci surgical robot
  FDA ٢٠٠٠**, Geoffrey Hinton "Godfather of AI" Turing
  Award ٢٠١٨ (with Bengio & LeCun), AI winters.
- **Insects of the World pack** (`insects_world.json`) — 60
  items on **insect anatomy (٦ legs, ٣ body parts,
  exoskeleton, compound eyes)**, **arachnids (8 legs) are
  NOT insects**, **~١٠ quintillion insects on Earth**,
  **Coleoptera (beetles) largest order ~٤٠٠٬٠٠٠ species**,
  **honeybees pollinate ١/٣ of food crops + waggle dance
  (von Frisch Nobel ١٩٧٣)**, queen lays ٢٬٠٠٠ eggs/day,
  **Monarch migration ~٤٬٨٠٠كم Mexico–Canada**, Atlas moth
  wingspan ~٢٥سم, Hercules beetle lifts ~٨٥٠× weight,
  **Meganeura prehistoric dragonfly ~٧٠سم wingspan**,
  dragonflies catch ~٩٥٪ of prey, **periodical Magicicada
  ١٧-year cycle**, fireflies bioluminescence, **mosquito
  deadliest animal ~٧٢٥٬٠٠٠ deaths/year**, female mosquitoes
  bite, **cockroaches ~٣٠٠ Mya old, survive ١ week
  headless**, ladybugs eat aphids, locust swarms cover
  ١٬٠٠٠كم², silkworms (Bombyx mori) silk discovered China
  ~٢٧٠٠ BCE, lac/cochineal dyes, ant farming aphids
  (mutualism), bombardier beetle boiling spray, **bees visit
  ~٢ million flowers per pound of honey**.
- **Sum Hunt mini-game** — pick two cells in a 4×4 grid of
  digits ١–٩ that add up to the target (٥–١٨); each correct
  pair refreshes the cells with new random digits and a new
  target; ٦٠s round; coin tiers ٢🪙/٥🪙/١٠🪙 at ٨/١٦/٣٠.

### Cumulative
- 151 quiz packs (~٩٬٠٦٠ items), 58 mini-games on the home shelf.

## 1.1.60 — 2026-05-06 — Wave 57

### Added
- **Famous Volcanoes (Deep) pack** (`famous_volcanoes_deep.json`)
  — 60 items on **Vesuvius/Pompeii ٧٩ CE (Pliny the Younger
  account)**, **Krakatoa ١٨٨٣ — sound heard ٤٬٨٠٠km away**,
  **Tambora ١٨١٥ → "Year Without a Summer" ١٨١٦, VEI ٧
  largest in recorded history**, **Mount St. Helens ١٩٨٠
  lateral blast**, **Pinatubo ١٩٩١ climate cooling**,
  **Eyjafjallajökull ٢٠١٠ grounded EU flights**, Fuji (last
  erupted ١٧٠٧), **Kīlauea most active**, **Mauna Loa largest
  by volume**, Stromboli "Lighthouse of the Mediterranean",
  **Etna Europe's most active**, **Mount Pelée ١٩٠٢
  destroyed Saint-Pierre**, Nyiragongo lava lake,
  **Yellowstone supervolcano**, **Toba ~٧٤٬٠٠٠ya bottleneck**,
  **Olympus Mons ~٢٥km tall on Mars (largest in solar
  system)**, types (shield/strato/cinder/dome/super), lava
  pahoehoe vs aa, pyroclastic flow, lahar, tephra, **Ring of
  Fire ~٧٥٪ of active volcanoes**, **VEI scale ٠–٨**,
  Surtsey ١٩٦٣ new island, Erebus southernmost active.
- **Periodic Table Basics pack** (`periodic_table_basics.json`)
  — 60 items on **Mendeleev ١٨٦٩ predicted unknown elements**,
  **Moseley ١٩١٣ reorganized by atomic number**,
  **١١٨ confirmed elements / ٧ periods / ١٨ groups**, H first
  & most abundant in universe, He ٢ noble gas, **C ٦ basis
  of life (diamonds & graphite)**, O ٨ ~٢١٪ atmosphere,
  N ~٧٨٪ atmosphere, **Fe ٢٦ Earth's core & hemoglobin**,
  Au/Ag/Cu currency metals, **Hg only liquid metal at room
  temp**, **Br only liquid nonmetal**, alkali Na/K react with
  water, halogens Cl/F, noble gases Ne/Ar/Kr (signs),
  **Al most abundant metal in crust**, Si semiconductors,
  Curies discovered radium ١٨٩٨, **H₂O & NaCl**, atom =
  protons + neutrons + electrons, metals/nonmetals/metalloids,
  lanthanides + actinides, **Tennessine ٢٠١٠ / Oganesson
  ٢٠٠٢**, Latin symbols (Au=aurum, Pb=plumbum, Fe=ferrum,
  Hg=hydrargyrum, K=kalium, Na=natrium, W=wolfram), **Seaborg
  only person with element named while alive**, Lavoisier
  named oxygen, Cavendish discovered hydrogen ١٧٦٦, water
  boils ١٠٠°م / freezes ٠°م, **aluminum once more valuable
  than gold (١٨٥٠s)**.
- **Sharks of the World (Deep) pack** (`sharks_world_deep.json`)
  — 60 items on **whale shark largest fish ~١٢–١٨م
  (filter feeder)**, basking shark 2nd largest filter feeder,
  **great white ~٦م apex predator (Jaws ١٩٧٥)**, tiger shark
  "garbage can of the sea", **bull shark tolerates fresh water
  (Lake Nicaragua, Amazon, Mississippi)**, hammerhead T-head
  + electroreception, **mako fastest ~٧٠km/h**, thresher
  whip-tail stunning, goblin shark protrusible jaws (living
  fossil), **megalodon extinct ~٣٫٦Mya, ~١٨م**, **Greenland
  shark longest-living vertebrate ~٢٥٠–٤٠٠yrs**, cookiecutter
  plug bites, wobbegong carpet, nurse, lemon, blacktip,
  whitetip reef, saw, frilled, **spined pygmy ~٢٢cm
  smallest**, **cartilage skeleton (no bone)**, multiple tooth
  rows replaced continuously (~٢٠٬٠٠٠ in lifetime), **ampullae
  of Lorenzini detect electric fields**, sharks predate
  dinosaurs (~٤٥٠Mya, predate trees), oviparous "mermaid's
  purses" + viviparous, **~١٠٠M sharks killed/year for fin
  trade**, ~١٠ fatal attacks/year globally, Eugenie Clark
  "shark lady", Palau first sanctuary ٢٠٠٩, Shark Week since
  ١٩٨٨, Mary Lee tracked great white.
- **Number Memory mini-game** — flash a digit sequence
  (3–9 digits, length grows with each correct answer), then
  recall in order on the numpad; ٦٠s round; coin tiers
  ٢🪙/٥🪙/١٠🪙 at scores ٥/١٠/١٨.

### Cumulative
- 148 quiz packs (~٨٬٨٨٠ items), 57 mini-games on the home shelf.

## 1.1.59 — 2026-05-06 — Wave 56

### Added
- **Whales & Dolphins (Deep) pack** (`whales_dolphins_deep.json`) —
  60 items on **blue whale (~٣٠m, ~١٩٠t — largest animal ever)**,
  **sperm whale's clicks ~٢٣٠dB & deepest dive ~٢٬٢٥٠m**, baleen vs
  toothed whales, **humpback songs (males during breeding) Roger
  Payne ١٩٧٠**, **bowhead longest-living mammal (~٢٠٠+yrs)**,
  **orca apex predator with matrilineal pods**, **bottlenose dolphin
  ~١٠٠٠ neocortex neurons & mirror self-recognition**, **dolphin
  echolocation via melon**, narwhal "tusk" is a tooth, beluga "sea
  canary", **whale fall ecosystems**, **cetaceans evolved from
  Pakicetus ~٥٠Mya**, IWC moratorium ١٩٨٢, ICR vs Sea Shepherd,
  Boto pink river dolphin, vaquita ~١٠ left, Free Willy/Keiko ١٩٩٣.
- **Famous Modern Athletes pack** (`famous_modern_athletes.json`) —
  60 items on **Messi 8 Ballons d'Or & 2022 World Cup**, **Ronaldo
  5 UCLs & all-time international goals**, **LeBron NBA all-time
  scorer (broke Kareem ٢٠٢٣)**, **MJ 6 NBA Finals 6-0**, **Brady 7
  Super Bowls**, **Serena 23 Slams (Open Era)**, **Federer 20**,
  **Nadal 22 (14 Roland-Garros)**, **Djokovic 24 Slams**, **Bolt
  100m 9.58 / 200m 19.19 (Berlin ٢٠٠٩)**, **Phelps 23 golds**,
  **Biles 4 GOAT vault & Yurchenko double pike**, **Hamilton 7 F1
  titles tied with Schumacher**, **Verstappen 2021/2/3/4 champ**,
  **Tiger 15 majors (Masters ١٩٩٧ youngest, ٢٠١٩ comeback)**,
  **Mahomes Super Bowl LVII MVP**, Mbappé hat-trick in 2022 final,
  Haaland Bundesliga & EPL goal records, Khabib 29-0, Mike Tyson
  youngest heavyweight champ ١٩٨٦, Ali "Rumble in the Jungle" ١٩٧٤.
- **Islamic Calendar Months pack** (`islamic_calendar_months.json`)
  — 60 items on **١٢ lunar months ~٣٥٤ days**, **Hijri begins from
  Prophet's hijra to Madina (٦٢٢ CE / ١ AH)**, **Caliph Umar
  established the calendar ١٧ AH**, the four sacred months (Dhul
  Qa'dah, Dhul Hijjah, Muharram, Rajab), **Muharram → Ashura ١٠th
  (Moses crossing the sea)**, **Rabi' al-Awwal → Mawlid ١٢th**,
  **Rajab → Isra & Mi'raj ٢٧th**, **Sha'ban → Laylat al-Bara'ah
  ١٥th**, **Ramadan → fasting + Laylat al-Qadr (last 10 odd nights,
  often ٢٧th) + revelation began (٦١٠ CE)**, **Shawwal → Eid al-Fitr
  ١st + 6 sunnah days**, **Dhul Qa'dah → travel/Hajj prep**, **Dhul
  Hijjah → Hajj (٨–١٣) + Eid al-Adha ١٠th + Day of Arafah ٩th**,
  why Ramadan moves ~١١ days earlier each Gregorian year.
- **Counting Stars mini-game** — flash-glance numerosity training
  (subitizing); 60-second round, stars flash 1–9 at random
  positions for ٤٥٠–٩٥٠ms (faster as streak grows), tap the digit;
  coin tiers ٢🪙/٥🪙/١٠🪙 at scores ٨/١٦/٣٠.

### Cumulative
- 145 quiz packs (~٨٬٧٠٠ items), 56 mini-games on the home shelf.

## 1.1.58 — 2026-05-06 — Wave 55

### Added
- **DNA & Genes Basics pack** (`dna_genes_basics.json`) — 60 items
  on **Watson & Crick double helix ١٩٥٣** with **Rosalind
  Franklin's Photo 51**, Miescher's nuclein ١٨٦٩, **A-T G-C base
  pairing**, **humans 46 chromosomes (23 pairs)**, **~٣B base
  pairs / ~20K genes (HGP completed ٢٠٠٣)**, **Mendel's pea-plant
  laws ١٨٦٥**, central dogma DNA→RNA→protein, **CRISPR-Cas9
  Doudna & Charpentier Nobel ٢٠٢٠**, PCR (Mullis ١٩٨٣), **DNA
  fingerprinting Jeffreys ١٩٨٤**, **mitosis vs meiosis**, **humans
  share ~٩٩٫٩٪ DNA, ~٥٠٪ with bananas**, twins, epigenetics, GMOs.
- **Plate Tectonics pack** (`plate_tectonics_deep.json`) — 60
  items on Earth's crust/mantle/core, **~15 tectonic plates float
  on the asthenosphere**, three boundary types (divergent →
  Mid-Atlantic Ridge & East African Rift; convergent → Himalayas
  & Andes & Marianas Trench ١١km; transform → San Andreas Fault),
  **Wegener's continental drift ١٩١٢ + Pangaea**, **theory accepted
  ١٩٦٠s after seafloor spreading + paleomagnetism**, fossil
  evidence (Mesosaurus across continents), Pacific Ring of Fire
  has ٧٥٪ of active volcanoes, P-waves vs S-waves, Richter & moment
  magnitude scales, **Everest still rises ~٥mm/year**, hot spots
  (Hawaii, Yellowstone), three rock types & cycle.
- **World Records pack** (`world_records_guinness.json`) — 60
  items on **Guinness founded ١٩٥٥** by Sir Hugh Beaver after a
  pub argument, **Everest ٨٬٨٤٩m**, **Mariana Trench Challenger
  Deep ١٠٬٩٣٥m**, hottest Furnace Creek ٥٦٫٧°C, coldest Vostok
  -٨٩٫٢°C, **Robert Wadlow ٢٫٧٢m tallest ever**, Jeanne Calment
  ١٢٢ years, **Bolt 9.58s ١٠٠m ٢٠٠٩**, **Phelps ٢٨ Olympic
  medals**, Blue whale largest animal, Peregrine Falcon ٣٨٩
  km/h, Greenland shark ~٤٠٠ years, **Burj Khalifa ٨٢٨m
  tallest**, **SR-71 Blackbird ٣٬٥٢٩ km/h fastest jet**, **Voyager
  1 farthest human-made object** (٢٤B+ km), **largest mosque
  Masjid al-Haram (٤M+ Hajj capacity)**.
- **Crossy Lane mini-game** (route `/crossy-lane`, 🐔 home pill)
  — frogger-lite. ٧×٩ grid. Cross alternating-direction car lanes
  to reach the top safe row for +1, then reset. Get hit = game
  over. Coin tiers: ٢🪙/٥🪙/١٠🪙 at scores ٥/١٢/٢٥. Tracks
  per-session high.

### Improved
- General-quiz extras pool now totals **142 packs (~٨٬٥٢٠ items)**.

## 1.1.57 — 2026-05-06 — Wave 54

### Added
- **Famous Modern Cities pack** (`famous_modern_cities.json`) — 60
  items spanning the GCC and the world: **Dubai (Burj Khalifa
  ٨٢٨m, Palm Jumeirah)**, **Abu Dhabi (Sheikh Zayed Mosque, Louvre
  ٢٠١٧)**, **Riyadh & NEOM**, **Doha (Museum of Islamic Art,
  2022 World Cup)**, **Kuwait City (Kuwait Towers ١٩٧٩)**, Tokyo
  (٣٧M metro), Seoul, Shanghai, **Singapore (Marina Bay Sands,
  Gardens by the Bay)**, **NYC (Liberty ١٨٨٦, Empire State ١٩٣١,
  Central Park)**, London (Big Ben, Tower Bridge, the Tube ١٨٦٣
  first underground), **Paris (Eiffel ٣٣٠m ١٨٨٩, Notre-Dame
  reopened ٢٠٢٤)**, Rome, **Istanbul on two continents**, Cairo,
  Mumbai, Delhi, Sydney (Opera House Utzon ١٩٧٣), Moscow, Mexico
  City, Rio (Christ the Redeemer ١٩٣١), Athens, **Jerusalem (Dome
  of the Rock & Al-Aqsa, Western Wall, Holy Sepulchre)**.
- **Famous Pirates pack** (`famous_pirates_real.json`) — 60 items
  educationally framed: **Blackbeard (Edward Teach ١٦٨٠-١٧١٨)**,
  **Captain Kidd hanged ١٧٠١**, **Bartholomew "Black Bart" Roberts
  ٤٠٠+ ships**, **Henry Morgan (privateer who became Lt. Governor
  of Jamaica)**, **Anne Bonny & Mary Read** female pirates,
  **Calico Jack designed Jolly Roger**, **Sam Bellamy's Whydah
  Gally wreck rediscovered ١٩٨٤**, **Sir Francis Drake circumnavigation
  ١٥٧٧-١٥٨٠**, **Barbary Corsairs (Hayreddin Barbarossa)**, **Ching
  Shih commanded ٧٠٬٠٠٠ pirates** (most successful in history),
  Pirate Code, Treasure Island ١٨٨٣ shaped modern pirate image,
  **walking the plank was Hollywood myth**, Strait of Malacca &
  Gulf of Aden modern piracy framing, Sept ١٩ Talk Like a Pirate
  Day.
- **Famous Modern Chefs pack** (`famous_modern_chefs.json`) — 60
  items led by **Marie-Antoine Carême father of haute cuisine**,
  **Auguste Escoffier (codified five mother sauces, brigade
  kitchen)**, **Julia Child brought French cooking to TV ١٩٦٣**,
  Gordon Ramsay, Jamie Oliver, **Anthony Bourdain food
  storyteller**, Massimo Bottura, **Ferran Adrià El Bulli
  molecular gastronomy**, **René Redzepi Noma foraging**, Heston
  Blumenthal, Yotam Ottolenghi, Marco Pierre White (3 Michelin at
  ٣٢ — Ramsay's mentor), **Wolfgang Puck**, **Alain Ducasse holds
  most Michelin stars ever (٢١ at peak)**, Thomas Keller, **Manal
  Al-Alem Arab TV legend**, world cuisines (French/Italian/
  Japanese/Chinese/Indian/Korean/Thai/Mexican/**Khaleeji kabsa &
  machboos & harees**), Michelin Guide history (since ١٩٠٠ tire
  guide, stars introduced ١٩٢٦), basic techniques, **mise en
  place**.
- **Higher or Lower mini-game** (route `/higher-lower`, 🎴 home
  pill) — classic card-prediction game. Look at the current card
  (2-13); guess if the next will be higher or lower; correct =
  +1 streak, wrong = game over. Tracks per-session best streak.
  Coin tiers: ٢🪙/٥🪙/١٠🪙 at streaks ٣/٥/٨.

### Improved
- General-quiz extras pool now totals **139 packs (~٨٬٣٤٠ items)**.

## 1.1.56 — 2026-05-06 — Wave 53

### Added
- **Black Holes & Cosmology pack** (`black_holes_cosmology.json`) —
  60 items led by **Schwarzschild's ١٩١٦ solution**, event horizons
  & singularity, three black hole types, **Sagittarius A*
  ~٤M solar masses**, **first BH image M87* by Event Horizon
  Telescope ١٠ Apr ٢٠١٩**, Sgr A* image ١٢ May ٢٠٢٢, **Hawking
  radiation ١٩٧٤**, **LIGO first gravitational wave detection
  ١٤ Sept ٢٠١٥** (Nobel ٢٠١٧), Big Bang ١٣٫٧٧B yr, **CMB Penzias
  & Wilson ١٩٦٤** (Nobel ١٩٧٨), **Hubble's expansion ١٩٢٩**, dark
  matter (٢٧٪) & dark energy (٦٨٪), Andromeda-Milky Way collision
  ~٤٫٥B yr, **JWST launched ٢٥ Dec ٢٠٢١**.
- **Stars & Stellar Evolution pack** (`stars_life_cycle.json`) —
  60 items: hydrogen→helium fusion at ١٥M °C cores, **molecular
  clouds & Pillars of Creation**, mass determines fate (red dwarfs
  trillions of years, Sun-like 10B, massive stars short and
  violent), **Sun-like → red giant → planetary nebula → white
  dwarf**, **massive → supernova → neutron star or black hole**,
  **Type Ia standard candles**, **Crab Nebula = SN ١٠٥٤** Chinese
  guest star, H-R diagram, **OBAFGKM spectral types**, famous
  stars (Polaris, Sirius, Betelgeuse, Rigel, Vega, Antares,
  Proxima Centauri ٤٫٢٤ ly), Pleiades & Hyades, **Henrietta
  Leavitt's Cepheid period-luminosity ١٩١٢**, Jocelyn Bell
  Burnell's pulsar discovery ١٩٦٧.
- **Constellations & Stories pack** (`constellations_stories.json`)
  — 60 items on the **88 official IAU constellations (since ١٩٢٢)**,
  Ptolemy's original 48, Greek myths (Andromeda, Perseus, Cassiopeia),
  asterisms (Big Dipper, Summer Triangle, Teapot), Orion, Ursa
  Major/Minor with Polaris, **Crux Southern Cross on Australia/NZ
  flags**, **most bright star names are Arabic** (Aldebaran, Altair,
  Vega, Rigel, Betelgeuse, Algol, Deneb, Fomalhaut), **al-Sufi's
  Book of Fixed Stars ٩٦٤**, Aboriginal Emu in the Sky, Chinese
  28 lunar mansions, Indian Nakshatras, **Earth's axial precession
  → Vega will be North Star in ~12,000 years**, planispheres,
  Stellarium app.
- **Stick Hero mini-game** (route `/stick-hero`, 🌉 home pill) —
  press-and-hold extends a stick from your platform; release to
  drop it. If the tip lands on the next platform, hero crosses
  for +1; over- or under-shoot, fall. Random gap distances and
  platform widths each round. Coin tiers: ٢🪙/٥🪙/١٠🪙 at scores
  ٣/٨/١٥. Tracks per-session high score.

### Improved
- General-quiz extras pool now totals **136 packs (~٨٬١٦٠ items)**.

## 1.1.55 — 2026-05-06 — Wave 52

### Added
- **Famous Disasters in History pack** (`famous_disasters_history.
  json`) — 60 items framed for kids on lessons learned: **Pompeii
  Vesuvius ٧٩ CE**, **Krakatoa ١٨٨٣ (loudest sound in modern
  history)**, **Mount St. Helens ١٩٨٠**, **١٩٠٦ San Francisco**,
  **Tangshan ١٩٧٦**, **Boxing Day Tsunami ٢٦ Dec ٢٠٠٤**,
  **Tōhoku ١١ Mar ٢٠١١ + Fukushima**, **Black Death ١٣٤٧-١٣٥٢**,
  **١٩١٨ Spanish Flu**, **Titanic sinking ١٥ Apr ١٩١٢**,
  **Hindenburg ٦ May ١٩٣٧** ended airship era, **Chernobyl ٢٦ Apr
  ١٩٨٦**, **Bhopal Dec ١٩٨٤**, **Apollo 13 successful failure ١٩٧٠**,
  **Captain Sully Hudson River landing ١٥ Jan ٢٠٠٩**, **Great Fire
  of London ١٦٦٦** (Wren rebuilt), Triangle Shirtwaist ١٩١١ → labor
  laws. Theme throughout: how we learn and prevent.
- **The Four Imams & Madhabs pack** (`the_imams_madhabs.json`) —
  60 items respectfully covering **Imam Abu Hanifa (٦٩٩-٧٦٧, Hanafi
  ٣٣٪ of Muslims, used qiyas/ra'y, died in prison)**, **Imam Malik
  (٧١١-٧٩٥, Imam Dar al-Hijra, Al-Muwatta, Maliki ١٥٪)**, **Imam
  al-Shafi'i (٧٦٧-٨٢٠, descendant of Hashim, founded Usul al-Fiqh
  with Al-Risala, Shafi'i ٢٨٪)**, **Imam Ahmad ibn Hanbal (٧٨٠-٨٥٥,
  ٣٠٬٠٠٠ hadiths in Musnad, stood firm during Mihna inquisition,
  Hanbali ٥٪)**. Hadith sciences: **Bukhari (٨١٠-٨٧٠, ٧٬٠٠٠+ from
  ٦٠٠٬٠٠٠ collected)**, **Muslim**, **Al-Kutub al-Sittah** (Tirmidhi,
  Abu Dawud, Nasa'i, Ibn Majah), classification (Sahih/Hasan/
  Da'if/Mawdu'), Mutawatir vs Ahad, Asma al-Rijal, Ilm al-Jarh
  wa al-Ta'dil, plus Nawawi, Ghazali (Ihya), Ibn Taymiyyah, Ibn
  Kathir.
- **Famous Authors for Kids pack** (`famous_authors_kids.json`) —
  60 items led by **Dr. Seuss (٤٤+ books, "Cat in the Hat" only
  ٢٣٦ unique words)**, **Roald Dahl (Charlie & Chocolate Factory,
  Matilda, BFG)**, **Eric Carle (Hungry Caterpillar ٥٠M+ copies,
  collage)**, **J.K. Rowling (Harry Potter ٥٠٠M+ books)**, Maurice
  Sendak, Lewis Carroll's Alice ١٨٦٥, Beatrix Potter (saved Lake
  District), Tolkien invented Elvish, C.S. Lewis Narnia, A.A.
  Milne Pooh, **E.B. White Charlotte's Web**, **Mo Willems (Pigeon,
  Elephant & Piggie)**, Astrid Lindgren Pippi, **Kamel Kilani —
  father of Arabic children's literature ٢٥٠+ books**, **Ibn
  Tufayl's Hayy Ibn Yaqzan ~١١٦٠** influenced Robinson Crusoe,
  Newbery & Caldecott Medals, **Sheikh Zayed Book Award**.
- **Lemonade Stand mini-game** (route `/lemonade-stand`, 🍋 home
  pill) — 7-day economic simulator. Each day: read weather forecast,
  set price ($0.10–$1.00) and cup count (0–60), open the stand.
  Demand model rewards sweet-spot pricing (~$0.40-0.60) and scales
  with weather (hot > sunny > cloudy > rainy). Cost $0.20/cup.
  Coin tiers: ٢🪙/٥🪙/١٠🪙 at final bank ≥ \$٨/\$١٥/\$٢٥.

### Improved
- General-quiz extras pool now totals **133 packs (~٧٬٩٨٠ items)**.

## 1.1.54 — 2026-05-06 — Wave 51

### Added
- **Mongolian Empire pack** (`mongolian_empire.json`) — 60 items
  led by **Genghis Khan (Temüjin, became Khan ١٢٠٦)** founding
  history's **largest contiguous land empire (~٢٤M km², ٢٢-٢٤٪ of
  world land)**, **Kublai Khan founded Yuan dynasty ١٢٧١** (Marco
  Polo's host ١٢٧١-١٢٩٥), conquest of Khwarazmian Empire & **Sack
  of Baghdad ١٢٥٨ ended Abbasid Caliphate**, four khanates
  (Yuan/Ilkhanate/Chagatai/Golden Horde), composite recurved bow,
  decimal army (arban → tumen), Yam postal system, **Pax Mongolica
  ١٢٥٠-١٣٥٠** Silk Road flourishing, Mongol religious tolerance,
  **Ghazan Khan converted to Islam ١٢٩٥**, Tamerlane (Timur)
  defeated Bayezid I ١٤٠٢, Mongolia's modern democracy ١٩٩٠,
  Naadam festival, ~١ in ٢٠٠ men carry Genghis's Y-chromosome.
- **Sahaba (Companions) pack** (`sahaba_companions.json`) — 60
  items respectfully covering the Companions of Prophet Muhammad
  ﷺ. **Khulafa al-Rashidun**: **Abu Bakr al-Siddiq (cave of Thawr,
  first Quran compilation)**, **Umar al-Faruq (Hijri calendar
  start, Diwan, expansion)**, **Uthman Dhul-Nurayn (Uthmanic
  Mushaf)**, **Ali (Lion of Allah)**. **Al-Asharah al-Mubasharun
  (Ten promised Paradise)**. **Mothers of Believers**: Khadijah
  first Muslim, Aisha narrator-scholar, Hafsa kept first Quran
  manuscript. **Family**: Fatima, Hasan & Husayn (Karbala ٦٨٠
  CE). **Famous Sahaba**: **Bilal first muezzin**, **Khalid ibn
  al-Walid Sword of Allah**, **Abu Hurayrah ٥٬٣٧٤ hadiths**,
  **Salman al-Farisi suggested trench at Khandaq**, Hamza martyr
  of Uhud, **Ja'far Dhul-Janahayn at Mu'tah**, Ansar/Muhajirun
  brotherhood. Battles: Badr ٢ AH, Uhud ٣ AH, Khandaq ٥ AH,
  Hudaybiyya ٦ AH, Conquest of Mecca ٨ AH, Farewell Pilgrimage
  ١٠ AH.
- **Famous Detectives in Literature pack** (`famous_detectives_lit.
  json`) — 60 items led by **Sherlock Holmes (Conan Doyle, Baker
  Street ٢٢١B, "A Study in Scarlet" ١٨٨٧)**, **Edgar Allan Poe's
  C. Auguste Dupin started detective fiction ١٨٤١**, **Hercule
  Poirot & Miss Marple (Christie, ٢ billion+ books — most ever)**,
  Father Brown (Chesterton), Lord Peter Wimsey, Inspector Morse,
  **Nancy Drew ١٩٣٠**, **Hardy Boys ١٩٢٧**, **Encyclopedia Brown**,
  **Detective Conan/Case Closed (Aoyama, Japanese kid manga)**,
  Inspector Maigret, Nero Wolfe, **Cadfael (medieval Welsh monk)**,
  Investigation methods, forensic science (fingerprints ١٨٩٢
  Argentina, **Alec Jeffreys' DNA fingerprinting ١٩٨٤**), genre
  tropes (locked room, red herring, plot twist).
- **Balloon Pop mini-game** (route `/balloon-pop`, 🎈 home pill) —
  rising-target tap game. Balloons drift up from the bottom; tap
  to pop (+1) but bombs cost a life. Missing a balloon (it floats
  off-screen) costs a life too. ٣ lives. Spawn rate 750ms,
  speed ramps. Coin tiers: ٢🪙/٥🪙/١٠🪙 at scores ١٥/٣٥/٧٠.

### Improved
- General-quiz extras pool now totals **130 packs (~٧٬٨٠٠ items)**.

## 1.1.53 — 2026-05-06 — Wave 50 🎉

### Added
- **Mughal Empire pack** (`mughal_empire.json`) — 60 items led by
  **Babur (descendant of Timur + Genghis Khan)** founding empire
  at **Panipat ١٥٢٦**, Humayun, **Akbar the Great** (Fatehpur Sikri,
  Nine Jewels, Din-i-Ilahi), Jahangir & Nur Jahan, **Shah Jahan
  built Taj Mahal ١٦٣٢-١٦٥٣ for Mumtaz Mahal**, Red Fort & Jama
  Masjid Delhi, Peacock Throne, Aurangzeb (empire's greatest
  extent ٤M km²), **Bahadur Shah Zafar last emperor — Indian
  Rebellion ١٨٥٧** ended Mughal rule. Architecture: Char Bagh,
  pietra dura inlay, Humayun's Tomb (Taj precursor UNESCO ١٩٩٣),
  Lahore Fort, Shalimar Gardens, Badshahi Mosque ١٦٧٣. Culture:
  Persian court, **Urdu emerged from camps**, miniature painting,
  Tansen ragas, Mughlai cuisine.
- **Computer Pioneers pack** (`computer_pioneers.json`) — 60 items:
  **Babbage Analytical Engine**, **Ada Lovelace first programmer
  ١٨٤٢-١٨٤٣**, **Turing Bombe + Universal Machine ١٩٣٦ + Turing
  Test ١٩٥٠**, **von Neumann architecture**, **Grace Hopper first
  compiler ١٩٥٢, COBOL, "debug" from literal moth ١٩٤٧**, Shannon
  information theory ١٩٤٨, Zuse Z3 first programmable ١٩٤١, ENIAC
  ١٩٤٥ + its 6 women original programmers, **Tim Berners-Lee
  invented WWW ١٩٨٩ at CERN**, Cerf & Kahn TCP/IP, Ritchie & Thompson
  Unix + C, Stroustrup C++, Gosling Java, van Rossum Python, Eich
  JavaScript in 10 days, Linus Torvalds Linux + Git, Knuth TAOCP,
  Dijkstra, Hoare quicksort, **Steve Jobs/Wozniak Apple**, **Gates/
  Allen Microsoft**, **Page/Brin Google ١٩٩٨**, Zuckerberg, Bezos,
  **Margaret Hamilton (Apollo + "software engineering")**, **Hedy
  Lamarr's frequency hopping (basis of Wi-Fi/Bluetooth)**, Hidden
  Figures (Katherine Johnson + Hopper + Frances Allen first woman
  Turing Award), Intel ٤٠٠٤ ١٩٧١.
- **Sound & Acoustics pack** (`sound_acoustics.json`) — 60 items
  on sound as longitudinal wave, **speed of sound ٣٤٣ m/s in air,
  ١٤٨٢ m/s in water, ٥٬٩٦٠ m/s in steel**, frequency/pitch/Hz
  (Heinrich Hertz), amplitude/decibels (log scale), human range
  ٢٠ Hz – ٢٠ kHz, infrasound (whales, earthquakes), ultrasound
  (bats echolocate, dolphins, medical imaging), **Doppler effect
  ١٨٤٢** (ambulance siren), Mach number & sonic booms, dB
  reference values, resonance, harmonics & overtones, A4 = ٤٤٠ Hz
  tuning, ear anatomy review, **Pythagoras discovered musical
  intervals ~٥٠٠ ق.م**, recording history (phonograph Edison ١٨٧٧
  → streaming), noise-cancellation by anti-phase, **Tacoma Narrows
  Bridge collapse ١٩٤٠ resonance**, anechoic chambers.
- **Match Three Gems mini-game** (route `/match-three`, 💎 home pill)
  — ٦×٦ match-3 swap puzzle. Tap two adjacent gems to swap; if a
  3+ line forms in row or column, gems pop and matter falls (with
  cascade combos). 75-second game. Coin tiers: ٢🪙/٥🪙/١٠🪙 at
  ٥٠/١٢٠/٢٥٠ score.

### Improved
- General-quiz extras pool now totals **127 packs (~٧٬٦٢٠ items)**.
- 50-wave milestone reached: **127 content packs, 50 mini-games**
  shipped across this autonomous run.

## 1.1.52 — 2026-05-06 — Wave 49

### Added
- **Ottoman Empire pack** (`ottoman_empire.json`) — 60 items led
  by **Osman I founded ١٢٩٩**, **Mehmed II "the Conqueror"
  captured Constantinople ٢٩ May ١٤٥٣ ending Byzantine Empire**
  (Orban's giant cannons, ٥٣-day siege, ships overland into
  Golden Horn at age ٢١), **Selim I added Egypt/Syria/Hejaz
  ١٥١٧ + Caliphate**, **Suleiman the Magnificent (Kanuni — golden
  age, codified law, ١٥٢٩ siege of Vienna)**, Mimar Sinan court
  architect, Battle of Lepanto ١٥٧١, abolition of Janissaries
  ١٨٢٦, Tanzimat reforms, Young Turks ١٩٠٨, **Atatürk founded
  Turkish Republic ٢٩ Oct ١٩٢٣**, Caliphate abolished ٣ Mar
  ١٩٢٤. Topkapı Palace, Hagia Sophia history, Devshirme,
  millet system, coffee culture spread to Vienna ١٦٨٣.
- **Mesoamerican & Andean Civilizations pack** (`mesoamerica_
  civilizations.json`) — 60 items: **Olmec colossal heads
  (mother culture)**, **Maya invented zero independently, Long
  Count calendar, ulama ball game, fully decipherable hieroglyphs,
  Tikal/Chichen Itza/Palenque/Copan**, Maya descendants ٦M+
  speakers today, **Aztec founded Tenochtitlán ١٣٢٥** (eagle on
  cactus = Mexican flag), chinampas floating gardens, **Cortés
  arrived ١٥١٩, Tenochtitlán fell ١٣ Aug ١٥٢١**, **Inca empire
  Andes: Cuzco capital, Quechua language, Pachacuti, Machu
  Picchu ~١٤٥٠ (rediscovered Bingham ١٩١١)**, **quipu knotted-
  cord records**, mortarless stonework, Qhapaq Ñan ٤٠٬٠٠٠ km
  road UNESCO, **Atahualpa captured by Pizarro ١٥٣٢, executed
  ١٥٣٣**.
- **Salah Prayer pack** (`salah_prayer.json`) — 60 items: **Salah
  is the 2nd Pillar**, **5 daily prayers (Fajr ٢, Dhuhr ٤, Asr
  ٤, Maghrib ٣, Isha ٤ = ١٧ rakat)**, Jumu'ah replaces Dhuhr
  Friday, Witr & Tarawih, Wudu steps from Surat al-Maida ٥:٦,
  Ghusl & Tayammum, **Qibla = Kaaba**, prayer postures (Qiyam,
  Ruku, Sujud on 7 limbs, Jalsa, Tashahhud, Salam), **Surah
  Al-Fatihah every rakat**, hadith on Salah being first
  questioned on Day of Judgment, **Bilal ibn Rabah رضي الله
  عنه first muezzin**, congregation reward 27×, Tashahhud,
  prayer times details, common surahs, sajdat as-sahw, prayer
  age guidance for children.
- **Cup Shuffle mini-game** (route `/cup-shuffle`, 🥤 home pill) —
  classic shell-game memory test. Watch which cup hides the ball,
  then track it through 3-10 swaps (more swaps each round, up to
  ٨ rounds). Tap the cup you think hides the ball. Coin tiers:
  ٢🪙/٥🪙/١٠🪙 at ٤/٦/٨ correct.

### Improved
- General-quiz extras pool now totals **124 packs (~٧٬٤٤٠ items)**.

## 1.1.51 — 2026-05-06 — Wave 48

### Added
- **Roman Empire pack** (`roman_empire.json`) — 60 items led by
  **Romulus & Remus founding myth ٧٥٣ ق.م**, Roman Republic →
  Empire, **Punic Wars (Hannibal crossing Alps with elephants
  ٢١٨ ق.م)**, **Julius Caesar (Rubicon ٤٩ ق.م, Ides of March)**,
  **Augustus first emperor ٢٧ ق.م**, Pax Romana, Trajan's empire
  at peak ٥M km², **Hadrian's Wall ١٢٢ CE**, Marcus Aurelius
  Stoic, **Constantine first Christian emperor ٣١٢ CE**, Empire
  splits ٣٩٥, **Fall of West ٤٧٦ CE**, Colosseum ٧٢-٨٠ CE,
  Pantheon dome, ٤٠٠٬٠٠٠ km Roman roads, aqueducts, Pompeii
  buried by Vesuvius ٧٩ CE.
- **Vikings & Norse pack** (`vikings_norse.json`) — 60 items on
  **Viking Age (٧٩٣ Lindisfarne raid – ١٠٦٦ Stamford Bridge)**,
  longships (clinker-built, dragon prows), sun stones for cloudy-
  day navigation, **Erik the Red founded Greenland ٩٨٢**, **Leif
  Eriksson first European in N. America Vinland ~١٠٠٠ CE
  (٤٩٢ years before Columbus)**, Battle of Hastings ١٠٦٦,
  **Normans = "Norsemen" → Normandy → William the Conqueror**,
  Norse mythology (Yggdrasil, Odin/Thor/Freya/Loki, Valkyries,
  Ragnarok), runes & Eddas, **Iceland's Althing ٩٣٠ CE = oldest
  parliament**, Volga trade route to Baghdad (Arab dirhams in
  Viking hoards), **"Rus" name → Russia**, Anglo-Saxon English
  loanwords (sky, knife, husband, window, law).
- **Hajj & Umrah pack** (`hajj_umrah.json`) — 60 items respectfully
  covering **Hajj as the 5th Pillar of Islam**, performed in
  Dhul-Hijjah (8-13), Pillars (Ihram + intent, Wuquf at Arafat,
  Tawaf al-Ifadah, Sa'i), Wajib acts (miqat ihram, Muzdalifah,
  stoning Jamarat, halq, farewell tawaf), **Tawaf — 7 counter-
  clockwise circumambulations from Hajar al-Aswad**, Maqam
  Ibrahim, **Sa'i between Safa & Marwah (Hajar searching for
  water)**, **Zamzam well ٤٬٠٠٠+ years old**, Day of Arafah =
  the day of Hajj, **Mount of Mercy & Farewell Sermon ١٠ AH**,
  Muzdalifah, Mina & three Jamarat, **Eid al-Adha ١٠ Dhul-Hijjah
  & udhiya** commemorating Ibrahim عليه السلام, three types of
  Hajj (Tamattu/Qiran/Ifrad), **Kaaba** built by Ibrahim & Ismail,
  **Kiswa** changed annually, Masjid al-Haram & Masjid al-Nabawi,
  Rawdah ash-Sharifah, Saudi crowd-management innovations, the
  largest annual gathering of humanity.
- **Hoop Shot mini-game** (route `/hoop-shot`, 🏀 home pill) —
  basketball free-throw with sweeping power meter. Tap when the
  red indicator is in the green zone (٤٢٪–٥٨٪) for a make.
  10 shots per game. Coin tiers: ٢🪙/٥🪙/١٠🪙 at ٣/٥/٨ makes.

### Improved
- General-quiz extras pool now totals **121 packs (~٧٬٢٦٠ items)**.

## 1.1.50 — 2026-05-06 — Wave 47

### Added
- **Iconic Trees of the World pack** (`iconic_trees_world.json`) —
  60 items led by **Olive (Olea europaea — mentioned ٧ times in
  Quran)**, **Date palm (Khaleeji symbol, ٣٠٠+ varieties)**,
  **Cedar of Lebanon (on flag, used by Phoenicians)**, **Sidr lote
  tree (Quran "Sidr al-Muntaha", sidr honey)**, Coast Redwood
  Hyperion ١١٥٫٧m tallest, Giant Sequoia General Sherman most
  massive, **Bristlecone Pine Methuselah ~٤٬٨٥٠+ years**, Pando
  aspen clone Utah ~٨٠٬٠٠٠ years, Baobab "tree of life", Banyan
  India national tree, Bodhi tree, Sakura, **Ginkgo "living
  fossil" survived Hiroshima ١٩٤٥**, Frankincense Boswellia (Oman/
  Yemen), Argan Morocco UNESCO, Acacia tortilis savanna, Tamarind,
  plus tree biology basics (xylem/phloem, dendrochronology rings,
  conifer vs broadleaf).
- **Anatomy & Senses pack** (`anatomy_senses.json`) — 60 items on
  the traditional 5 senses + proprioception/balance/thermoception
  (humans have ٩+ senses), eye anatomy (cornea/iris/lens/retina,
  cones vs rods, fovea, blind spot), **Ibn al-Haytham's Book of
  Optics ١٠١١-١٠٢١**, ear (٣ smallest bones hammer/anvil/stirrup,
  cochlea, semicircular canals), human hearing ٢٠ Hz – ٢٠ kHz,
  ٤٠٠+ olfactory receptors, **5 tastes including umami (Ikeda
  ١٩٠٨)**, skin as largest organ, vestibular system & dizziness,
  animal sensory adaptations (bats echolocation, dogs ٤٠×human
  smell, eagles ٤-٨×human sight, snakes pit organs).
- **Toys & Games History pack** (`toys_history.json`) — 60 items
  on yo-yo (Greece ٢٥٠٠ ق.م), Chinese kites ٢٠٠ ق.م, **Teddy bear
  named after Theodore Roosevelt ١٩٠٢**, **Lego (Christiansen
  ١٩٤٩, "leg godt" = play well)**, **Barbie (Ruth Handler ١٩٥٩
  named after Barbara)**, Slinky accidental invention ١٩٤٥,
  Play-Doh originally wallpaper cleaner, Crayola ١٩٠٣, **Rubik's
  Cube ١٩٧٤**, Mr. Potato Head first toy advertised on TV ١٩٥٢,
  **Tamagotchi Bandai ١٩٩٦**, **Tetris (Pajitnov USSR ١٩٨٤)**,
  **Pac-Man (Iwatani ١٩٨٠)**, console timeline (Atari ١٩٧٢ →
  Switch ٢٠١٧), **Minecraft (Notch ٢٠٠٩)**, ancient board games
  (Senet, Mancala, chess from India ٦th c., Go), Khaleeji
  Tab/Tib & Daama checkers traditions.
- **Beat Tap mini-game** (route `/beat-tap`, 🎵 home pill) — 4-lane
  rhythm tapper. Notes spawn every ٦٠٠ms and fall to a hit line
  at ٨٥٪ height; tap the matching color button when overlapping
  for +١ (close) or +٣ (perfect). 60-second song; spawn rate
  ramps. Coin tiers: ٢🪙/٥🪙/١٠🪙 at ٢٠/٥٠/١٠٠.

### Improved
- General-quiz extras pool now totals **118 packs (~٧٬٠٨٠ items)**.

## 1.1.49 — 2026-05-06 — Wave 46

### Added
- **Famous Architects pack** (`famous_architects.json`) — 60 items
  led by **Imhotep first named architect (Step Pyramid ٢٦٧٠ ق.م)**,
  **Mimar Sinan (Süleymaniye ١٥٥٧, Selimiye Edirne ٣٧٤ structures)**,
  Wren (St. Paul's), Brunelleschi (Florence Dome), Palladio,
  **Gaudí (Sagrada Família, Park Güell)**, **Frank Lloyd Wright
  (Fallingwater ١٩٣٥, Guggenheim NYC)**, **Le Corbusier**, Mies van
  der Rohe ("less is more"), Bauhaus, Sullivan ("form follows
  function"), **Gehry (Guggenheim Bilbao ١٩٩٧)**, **Zaha Hadid
  (first woman Pritzker ٢٠٠٤, Sheikh Zayed Bridge, Heydar Aliyev
  Center)**, **Norman Foster (Apple Park, Gherkin London)**, **Jean
  Nouvel (Louvre Abu Dhabi ٢٠١٧)**, Renzo Piano, Ando, I.M. Pei,
  **Hassan Fathy (Egyptian — vernacular architecture)**, **Diébédo
  Francis Kéré first African Pritzker ٢٠٢٢**, plus styles (Gothic
  → Brutalism) and the Pritzker Prize.
- **Birds of Prey pack** (`birds_of_prey.json`) — 60 items led by
  **Peregrine Falcon — fastest animal at ٣٨٩ km/h diving stoop**,
  **Saker Falcon (Mongolia national bird, prized in Khaleeji
  falconry)**, Bald & Golden Eagles, Philippine & Harpy Eagles,
  Red-tailed Hawk, Goshawk, **Falconry as UNESCO Intangible
  Heritage ٢٠١٠** (multinational including UAE/Saudi/Qatar/Kuwait/
  Mongolia), **Abu Dhabi Falcon Hospital**, owls (Great Horned,
  Snowy, Pharaoh Eagle-Owl), silent flight feathers, ٢٧٠° head
  rotation, Lammergeier "bone breaker", California Condor recovery,
  ospreys, **DDT crash & Rachel Carson Silent Spring ١٩٦٢**.
- **Magnets & Electromagnetism pack** (`magnets_electromagnetism.json`)
  — 60 items: lodestone & ancient Chinese compass ~٢٠٠ ق.م, Earth
  as giant magnet, **Ørsted current creates magnetic field ١٨٢٠**,
  Ampère, **Faraday electromagnetic induction ١٨٣١**, **Maxwell's
  equations ١٨٦٥** unify EM + light, **Hertz radio waves ١٨٨٧**,
  electric motor vs generator, transformer, MRI, **maglev trains
  Shanghai ٤٣٠ km/h**, AC vs DC (Edison vs Tesla), neodymium
  magnets, the **electromagnetic spectrum**, induction cooktops,
  Qi wireless charging, magnetosphere & aurora.
- **Tap Jump mini-game** (route `/tap-jump`, 🦘 home pill) —
  endless-runner with gravity. Tap anywhere to jump; obstacle
  speed ramps over time; collision = game over. Coin tiers:
  ٢🪙/٥🪙/١٠🪙 at scores ١٥/٣٥/٧٠. Tracks per-session high score.

### Improved
- General-quiz extras pool now totals **115 packs (~٦٬٩٠٠ items)**.

## 1.1.48 — 2026-05-06 — Wave 45

### Added
- **Renewable Energy pack** (`renewable_energy.json`) — 60 items
  on the seven main renewable sources (solar PV/thermal, wind,
  hydro, geothermal, biomass, tidal/wave), Bell Labs silicon
  cell ١٩٥٤, **Mohammed bin Rashid Al Maktoum Solar Park Dubai**,
  Shams 1 Abu Dhabi, **NEOM & Saudi Vision 2030 renewables**,
  3-blade wind turbines & offshore farms, Three Gorges/Aswan
  hydropower, **Iceland geothermal heats ٩٠٪ of homes**,
  green hydrogen via electrolysis, **Paris Agreement ٢٠١٥**,
  net-zero by ٢٠٥٠, kW-h units, EV revolution (Tesla, Nissan
  Leaf, China largest EV market), batteries (Powerwall, grid-
  scale lithium), kid-actionable steps (lights, walk/bike,
  reuse, plant trees).
- **Famous Mountaineers pack** (`famous_mountaineers.json`) — 60
  items led by **Hillary & Tenzing Norgay first Everest summit
  ٢٩ May ١٩٥٣**, **K2 first ascent Compagnoni & Lacedelli ١٩٥٤**,
  **Reinhold Messner — first Everest no-O₂ ١٩٧٨, first all ١٤
  eight-thousanders**, **Junko Tabei first woman Everest ١٩٧٥**,
  **Kami Rita Sherpa most Everest summits**, Maurice Herzog
  Annapurna I ١٩٥٠ (first ٨٠٠٠m peak), heights of all ١٤
  eight-thousanders, **Seven Summits**, mountaineering equipment,
  the Death Zone above ٨٬٠٠٠m, Sherpa community, Honnold's free
  solo of El Capitan ٢٠١٧.
- **Chocolate History pack** (`chocolate_history.json`) — 60
  items on **Theobroma cacao** (food of the gods), **Olmec
  cultivated cacao ~١٥٠٠ ق.م**, **Maya xocolatl** with chili,
  **Aztecs used cacao as currency**, **Cortés brought it to
  Spain ١٥٢٠s**, **Van Houten cocoa press ١٨٢٨**, **Joseph
  Fry's first solid eating chocolate ١٨٤٧**, **Daniel Peter's
  milk chocolate ١٨٧٥** with Nestlé, Lindt's conching ١٨٧٩,
  Cadbury/Hershey/Mars/Toblerone/Ferrero/Patchi, Côte d'Ivoire
  & Ghana ٦٠٪+ of world cocoa, fair-trade & ethical sourcing,
  bean-to-bar movement, **theobromine toxic to dogs/cats** and
  why chocolate melts at body temp.
- **Penalty Shootout mini-game** (route `/penalty-shootout`, ⚽
  home pill) — best-of-٥ vs CPU then sudden-death. Pick a
  direction (left/center/right) when shooting; guess CPU's
  shot when keeping. Win ⇒ ٥🪙.

### Improved
- General-quiz extras pool now totals **112 packs (~٦٬٧٨٠ items)**.

## 1.1.47 — 2026-05-06 — Wave 44

### Added
- **Famous Castles pack** (`famous_castles.json`) — 60 items led by
  **Krak des Chevaliers** Crusader-era Syria, **Citadel of Saladin
  Cairo ١١٧٦**, **Alhambra Granada** (Court of the Lions),
  **Aleppo Citadel ٣٬٠٠٠+ years**, **Erbil Citadel ٦٬٠٠٠+ years
  UNESCO**, **Diriyah At-Turaif Saudi UNESCO ٢٠١٠**, **Masmak
  Riyadh ١٨٦٥**, **Bahrain Fort UNESCO**, Nakhal/Bahla/Jabrin
  Oman, Edinburgh atop volcanic rock, Tower of London ١٠٧٨,
  Carcassonne, Mont Saint-Michel, Chambord ٤٤٠ rooms, Neuschwanstein
  (Disney inspiration), Himeji "white heron" Japan, Forbidden City
  ٩٬٩٩٩ rooms, Topkapi Palace; plus castle anatomy (keep, bailey,
  motte, moat, drawbridge, portcullis, machicolations, arrow slits)
  and siege weaponry (trebuchet, battering ram).
- **Tea & Coffee History pack** (`tea_coffee_history.json`) — 60
  items: **Shennong tea legend ٢٧٣٧ ق.م**, Lu Yu's *Classic of Tea*
  ٧٦٠ CE, six tea types and processing, matcha & chanoyu (Sen no
  Rikyū), British afternoon tea (Anna ١٨٤٠), **Boston Tea Party
  ١٧٧٣**; **Coffea arabica from Ethiopia (Kaldi the goatherd)**,
  **first coffee houses in ١٤٥٠s Yemen with Sufi monks**, **Mocha
  Yemeni port = origin of "mocha"**, Mecca/Cairo/Damascus coffee
  houses, **Khaleeji qahwa with cardamom & saffron**, **Arabic
  coffee culture UNESCO Intangible Heritage**, Italian espresso
  (Gaggia ١٩٤٧), four wave coffee culture, Coffee Belt geography.
- **Spice Trade pack** (`spice_trade.json`) — 60 items on **black
  pepper "king of spices"**, true vs Cassia cinnamon, **cloves &
  nutmeg from Banda Islands monopoly**, **saffron — most expensive
  spice (١٥٠ flowers/gram)**, cardamom "queen of spices",
  **Vanilla planifolia** Aztec xocolatl, turmeric (curcumin),
  za'atar, baharat seven-spice, **Silk Road & medieval Muslim
  merchant dominance (Hadhrami, Omani sailors)**, **Vasco da Gama
  reached India ١٤٩٨**, **Treaty of Breda ١٦٦٧ — Banda Islands
  traded for Manhattan**, Ibn Sina's spice prescriptions, regional
  cuisines (Indian curry, Moroccan ras el hanout, Yemeni bahaarat).
- **Pig Dice mini-game** (route `/pig-dice`, 🐷 home pill) — classic
  press-your-luck dice game vs CPU. Roll d٦; rolling a ١ ends your
  turn with no bank. Hold to bank turn-total to score. First to ٥٠
  wins. CPU strategy: hold at ٢٠+ or when winning. Coin reward:
  ٥🪙 per win.

### Improved
- General-quiz extras pool now totals **109 packs (~٦٬٦٠٠ items)**.

## 1.1.46 — 2026-05-06 — Wave 43

### Added
- **Famous Universities pack** (`famous_universities.json`) — 60
  items, **led by Qarawiyyin (Fatima al-Fihri ٨٥٩ — UNESCO/Guinness:
  oldest continuously operating university)**, **Al-Azhar Cairo
  ٩٧٠**, Nizamiyya Baghdad ١٠٦٥, **Bologna ١٠٨٨ (oldest in Europe)**,
  Oxford ١٠٩٦, Cambridge ١٢٠٩, Sorbonne, Harvard ١٦٣٦, Yale ١٧٠١,
  MIT, Stanford, ETH Zurich (Einstein), Heidelberg ١٣٨٦, Tokyo ١٨٧٧,
  Peking ١٨٩٨, **Kuwait University ١٩٦٦**, **King Saud ١٩٥٧**,
  AUB ١٨٦٦, Cairo University ١٩٠٨, NYUAD/HBKU, plus academic
  vocabulary (bachelor/master/PhD, dean, Latin honors, regalia).
- **Currencies & Money History pack** (`currencies_history.json`)
  — 60 items: cowrie shells, **Lydia first metal coins ~٦٠٠ ق.م**,
  **Tang dynasty paper money ٦٠٠s CE**, **Caliph Abd al-Malik
  standardized gold dinar (٤٫٢٥g) and silver dirham ٦٩٧ CE**, Bayt
  al-Mal treasury, Spanish "pieces of eight" → $ symbol, Bank of
  England ١٦٩٤, Bretton Woods ١٩٤٤ → Nixon shock ١٩٧١, **Euro
  launch ١٩٩٩/٢٠٠٢ (٢٠ countries)**, **Kuwaiti Dinar most valuable
  currency**, GCC pegs (SAR ٣٫٧٥ to USD), Bitcoin ٢٠٠٩ (Satoshi
  Nakamoto), banknote security features, **zakat on cash above
  nisab**, and **prohibition of riba in Islam**.
- **Famous Stadiums pack** (`famous_stadiums.json`) — 60 items
  on Wembley arch ٢٠٠٧, **Camp Nou (Europe's largest)**, Bernabéu,
  Old Trafford, **Maracanã ١٩٥٠ World Cup**, Soccer City ٢٠١٠ WC,
  **Lusail/Al Bayt/Education City Qatar 2022**, **Sheikh Jaber
  Stadium Kuwait**, Bird's Nest Beijing 2008, Allianz Arena
  color-changing facade, MCG, Lord's "home of cricket", Eden Gardens,
  Wimbledon (grass), Roland Garros (clay), Arthur Ashe, Rod Laver,
  ancient Stadium of Olympia, the Roman Colosseum's engineering,
  F1 circuits (Monaco, Silverstone, Bahrain, Yas Marina, Jeddah).
- **Stack Builder mini-game** (route `/stack-builder`, 🏗️ home pill)
  — physics tap-stack. A horizontal block oscillates above; tap to
  drop on the block below; misalignment trims the overhang. Block
  shrinks each round and oscillation speed ramps. Game ends when
  remaining width <٠٫٥٪. Coin tiers: ٢🪙/٥🪙/١٠🪙 at ١٠/٢٠/٤٠ blocks
  stacked.

### Improved
- General-quiz extras pool now totals **106 packs (~٦٬٤٢٠ items)**.

## 1.1.45 — 2026-05-06 — Wave 42

### Added
- **Famous Libraries pack** (`famous_libraries.json`) — 60 items led
  by **Library of Alexandria (Ptolemy I ~٣٠٠ ق.م)**, **Bayt al-Hikma
  Baghdad (al-Ma'mun)**, **Library of Cordoba (٤٠٠٬٠٠٠ books)**,
  Ashurbanipal's Nineveh tablets, modern Bibliotheca Alexandrina
  ٢٠٠٢, Vatican Apostolic, British Library, Library of Congress,
  **Qarawiyyin (Fatima al-Fihri ٨٥٩ — oldest continuously operating)**,
  Trinity College & Book of Kells, Bodleian, Sankoré Timbuktu
  ٣٠٠٬٠٠٠+ manuscripts, Kuwait National Library, **Dewey Decimal
  ١٨٧٦**, Gutenberg's printing press ١٤٤٠ → mass libraries, papyrus
  vs codex, Internet Archive Wayback Machine.
- **Beekeeping & Pollinators pack** (`beekeeping_pollinators.json`)
  — 60 items on honeybee anatomy, three castes (queen/worker/drone),
  **Karl von Frisch waggle dance Nobel ١٩٧٣**, royal jelly, hexagonal
  honeycomb (most efficient packing), nectar→honey process,
  Langstroth hive ١٨٥٢, sidr & manuka honey, **Surat An-Nahl
  (Quran 16) on bees & honey as healing**, varroa mite & colony
  collapse, **١/٣ of food crops depend on pollinators**, butterflies/
  hummingbirds/bats/moths as alternative pollinators, neonicotinoid
  threats, kid-actionable conservation.
- **Classical Composers pack** (`classical_composers.json`) — 60
  items led by **Bach (١٦٨٥–١٧٥٠ Brandenburg, fugues)**, **Mozart
  (١٧٥٦–١٧٩١ child prodigy, Eine kleine Nachtmusik, Magic Flute,
  ٤١ symphonies)**, **Beethoven (١٧٧٠–١٨٢٧, ٩ symphonies, Ode to
  Joy = EU anthem, deafness)**, Vivaldi Four Seasons, Handel's
  Messiah ١٧٤١, Haydn "Father of the Symphony" ١٠٤ symphonies,
  Schubert ٦٠٠+ Lieder, Chopin nocturnes, Tchaikovsky (Swan Lake,
  Nutcracker, 1812 Overture), Dvořák New World, Grieg Peer Gynt,
  Debussy Clair de lune, Ravel Boléro, Stravinsky Rite of Spring
  riot ١٩١٣, **Prokofiev Peter and the Wolf**, Copland, John Williams
  film scores, the four periods (Baroque/Classical/Romantic/Modern)
  and orchestra families.
- **Sokoban mini-game** (route `/sokoban`, 📦 home pill) — 5 hand-
  designed puzzles. Push (never pull) boxes onto targets; arrow
  controls; restart/skip-when-solved. Coin reward = (level+1)×٢🪙
  per solve, plus ١٠🪙 bonus on completing all ٥ levels.

### Improved
- General-quiz extras pool now totals **103 packs (~٦٬٢٤٠ items)**.

## 1.1.44 — 2026-05-06 — Wave 41

### Added
- **Famous Lighthouses pack** (`famous_lighthouses.json`) — 60 items
  led by **Lighthouse of Alexandria (Pharos)** — Wonder of the
  Ancient World, ١٠٠+m, built ٢٨٠–٢٤٧ ق.م by Sostratus, lost to
  earthquakes; **Tower of Hercules** Spain (only ancient Roman
  lighthouse still in service); Boston Light ١٧١٦, Cape Hatteras,
  Eddystone, Bell Rock (Stevenson ١٨١١), Skerryvore, Île Vierge,
  **Augustin-Jean Fresnel lens ١٨٢٣** revolutionized optics, parts
  (lantern room/gallery/watch room), keepers, automation, daymark
  paint patterns, fog horns, GPS replacing some, the Stevenson
  family of lighthouse engineers (R.L. Stevenson author related),
  Phare du Créac'h most powerful in Europe.
- **Egyptian Pharaohs pack** (`egyptian_pharaohs.json`) — 60 items
  on Narmer/Menes uniting Egypt ٣١٠٠ ق.م, **Djoser/Imhotep Step
  Pyramid Saqqara ٢٦٧٠ ق.م** (world's oldest stone monument),
  **Khufu Great Pyramid ٢٥٦٠ ق.م** ١٤٦٫٧m, Khafre + Sphinx,
  Hatshepsut female pharaoh + expedition to Punt, **Thutmose III
  "Napoleon of Egypt" ١٧ campaigns**, Akhenaten + Nefertiti's
  Aten reform Amarna ١٣٥٣ ق.م, **Tutankhamun — tomb discovered
  by Howard Carter ١٩٢٢, golden mask**, **Ramses II "the Great"
  Abu Simbel + ٦٦-year reign**, Cleopatra VII last pharaoh ٣٠ ق.م,
  Rosetta Stone deciphered by Champollion ١٨٢٢, mummification &
  Anubis, the Pschent (red Lower + white Upper Egypt double crown).
- **Fairy Tales of the World pack** (`fairy_tales_world.json`) — 60
  items led by **One Thousand and One Nights / ألف ليلة وليلة**
  (Scheherazade & Shahryar, Sindbad's seven voyages, Aladdin's lamp,
  Ali Baba & "Open sesame!"); Aesop's fables (Tortoise & Hare,
  Boy Who Cried Wolf, Lion & Mouse, Wind & Sun); Brothers Grimm
  (Cinderella, Snow White, Hansel & Gretel, Rapunzel, Red Riding
  Hood, Rumpelstiltskin); Charles Perrault (Puss in Boots);
  Hans Christian Andersen (Ugly Duckling, Little Mermaid, Emperor's
  New Clothes, Princess and the Pea, Thumbelina); Russian (Baba
  Yaga, Firebird); Japanese (Momotaro, Issun-bōshi, Urashima Taro);
  Chinese (Mulan, Cowherd & Weaver Girl); plus archetypes/morals
  and oral-vs-written tradition.
- **Fruit Catcher mini-game** (route `/fruit-catcher`, 🍎 home pill)
  — falling-emoji catcher with ٣ lives. Tap left/right or drag
  basket horizontally; catch fruit (+١) and dodge bombs/onions/
  chilies (−life). Spawn cadence ٧٠٠ms, fall-speed ramps from
  ٠٫٠٠٥ to ٠٫٠١٨ over time. Coin tiers: ٢🪙/٥🪙/١٠🪙 at scores
  ٢٠/٥٠/١٠٠.

### Improved
- General-quiz extras pool now totals **100 packs (~٦٬٠٦٠ items)** —
  centennial pack milestone reached.

## 1.1.43 — 2026-05-06 — Wave 40

### Added
- **Polar Regions pack** (`polar_regions.json`) — 60 items contrasting
  Arctic (ocean ringed by land, polar bears) and Antarctic (continent
  ringed by ocean, penguins): **Roald Amundsen first to South Pole
  ١٤ Dec ١٩١١**, Shackleton's Endurance, Inuit life (igloos, kayaks,
  dog sleds), Sami of Lapland, all six penguin species, narwhal &
  beluga, krill base of Antarctic food chain, **Vostok ‑٨٩٫٢ °C
  coldest ever**, **Antarctic Treaty ١٩٥٩** (peaceful science only),
  ice cores, aurora borealis/australis, ozone hole & Montreal Protocol
  ١٩٨٧, melting permafrost, Northwest/Northeast Passages.
- **Gemstones & Minerals pack** (`gemstones_minerals.json`) — 60
  items on **Mohs hardness ١-١٠** (talc → diamond), four precious
  stones, ruby & sapphire both corundum (Al₂O₃, color from impurities),
  emerald = green beryl, kimberlite pipes, **Cullinan Diamond ٣١٠٦
  ct ١٩٠٥**, opal play-of-color, pearls form in oysters, jade in
  Chinese culture, lapis lazuli on Tutankhamun's mask, amber as
  fossil resin, pyrite "fool's gold", graphite vs diamond same
  carbon different structure, **carat (gem ٢٠٠ mg) vs karat (gold
  purity)**, igneous/sedimentary/metamorphic rock cycle.
- **World Festivals pack** (`world_festivals.json`) — 60 items
  led by Islamic celebrations: **Eid al-Fitr (zakat al-fitr,
  eidiyya, salat al-eid)**, **Eid al-Adha (udhiya, Hajj-aligned,
  ٣ days)**, **Ramadan (Suhoor, Iftar, Laylat al-Qadr, ٢٩-٣٠
  days)**, Hijri New Year ١ Muharram, **Kuwait National & Liberation
  Days ٢٥-٢٦ Feb**, UAE/Saudi national days; then world cultures —
  Diwali, Holi, Lunar New Year (zodiac, red envelopes), Songkran,
  Hanami, Day of the Dead, Carnival/Mardi Gras, **Persian Nowruz
  (Spring Equinox)**, Independence Days (USA Jul ٤, Egypt Jul ٢٣,
  Pakistan Aug ١٤, India Aug ١٥), Earth Day, harvest festivals
  (Pongal, Onam, Mid-Autumn mooncakes).
- **Bubble Pop mini-game** (route `/bubble-pop`, 🫧 home pill) —
  ٨×٨ four-color same-game grid. Tap any group of ٢+ adjacent
  same-color bubbles to pop them; gravity collapses columns;
  empty columns shift left. Score = n×(n−1) per group. Coin tiers:
  ٢🪙/٥🪙/١٠🪙 at scores ٤٠/١٠٠/٢٠٠.

### Improved
- General-quiz extras pool now totals **97 packs (~٥٬٨٨٠ items)**.

## 1.1.42 — 2026-05-05 — Wave 39

### Added
- **Famous Mosques pack** (`famous_mosques.json`) — 60 items on
  **Masjid al-Haram (Mecca, Kaaba)**, **Masjid al-Nabawi (Medina,
  green dome)**, **Al-Aqsa & Dome of the Rock (Jerusalem ٦٩١ CE)**,
  Umayyad Damascus ٧٠٥, Hagia Sophia, Sinan masterworks (Süleymaniye
  ١٥٥٧, Selimiye Edirne), Cordoba Mezquita ٧٨٤, Sheikh Zayed Grand
  Mosque ٢٠٠٧ (largest hand-knotted carpet), Hassan II Casablanca
  ١٩٩٣ (٢١٠m minaret), Al-Azhar ٩٧٠, Ibn Tulun ٨٧٩, **Qarawiyyin
  Fez ٨٥٩ (Fatima al-Fihri founded the world's oldest university)**,
  Djinguereber Mali ١٣٢٧, Djenné mud-brick, Putra & Crystal mosques
  Malaysia, **Quba — first mosque in Islam**, Mosque of the Two
  Qiblahs, Grand Mosque Kuwait ٢٠١٣, plus core mosque architecture
  vocab (mihrab, minbar, qibla, minaret, dome, calligraphy).
- **Marine Biology pack** (`marine_biology.json`) — 60 items on
  ocean zones (intertidal → hadal), plankton, ocean food chain,
  shark species (whale shark filter feeder ١٢-١٨m), blue whale
  ٣٠m largest animal ever, dolphins & echolocation, octopus 3 hearts
  & color change, jellyfish (no brain), starfish regrowth, corals
  & zooxanthellae symbiosis, **Great Barrier Reef**, sea turtles,
  bioluminescence, anglerfish, mangroves, tide pools, moon-driven
  tides, ocean currents (Gulf Stream), coral bleaching, microplastic
  pollution, and Cousteau's marine conservation legacy.
- **Ancient Greece pack** (`ancient_greece.json`) — 60 items on
  Athens & Sparta, **democracy invented by Cleisthenes ٥٠٨ ق.م**,
  Pericles & Parthenon ٤٤٧–٤٣٢ ق.م, Athena, Persian Wars (Marathon
  ٤٩٠/Thermopylae ٤٨٠/Salamis), **Alexander the Great ٣٥٦–٣٢٣ ق.م**,
  Socrates/Plato/Aristotle, Pythagoras, Euclid, Archimedes, Herodotus
  "father of history", Homer's Iliad & Odyssey, Olympic Games origin
  ٧٧٦ ق.م, three architectural orders (Doric/Ionic/Corinthian), the
  twelve Olympians on Mount Olympus, Trojan Horse, Hippocratic Oath
  and **Eratosthenes measured Earth's circumference ٢٤٠ ق.م**.
- **Tetris-lite mini-game** (route `/tetris-lite`, 🧊 home pill) —
  ٨×١٤ board, all ٧ tetrominoes (I/O/T/S/Z/L/J), tick-driven
  falling that speeds up every ٥ lines (level cap by interval),
  classic ٤٠/١٠٠/٣٠٠/١٢٠٠ Nintendo line-clear scoring × level,
  rotate/move/soft-drop/hard-drop controls. Coin tiers: ٢🪙/٥🪙/١٠🪙
  at ٥/١٠/٢٠ lines.

### Improved
- General-quiz extras pool now totals **94 packs (~٥٬٧٠٠ items)**.

## 1.1.41 — 2026-05-05 — Wave 38

### Added
- **Internet History pack** (`internet_history.json`) — 60 items:
  ARPANET ١٩٦٩ first message, packet switching (Baran, Davies),
  TCP/IP (Cerf, Kahn ١٩٧٤), **Tim Berners-Lee invents the World
  Wide Web ١٩٨٩ at CERN** (info.cern.ch first website ١٩٩١),
  HTTP/HTML/URL, browsers (Mosaic, Netscape, Chrome ٢٠٠٨), search
  engines (AltaVista, Yahoo!, Google ١٩٩٨), Ray Tomlinson email
  @ ١٩٧١, Charles Kao fiber Nobel ٢٠٠٩, modems & dial-up, Wi-Fi,
  3G→4G→5G eras, IoT and online safety basics.
- **Modern Inventions pack** (`modern_inventions.json`) — 60 items
  on Edison & Swan light bulb ١٨٧٩, Bell telephone ١٨٧٦, Marconi
  radio, Lumière brothers cinema ١٨٩٥, Karl Benz auto ١٨٨٦, Wright
  brothers ١٩٠٣, Spencer microwave ١٩٤٥, de Mestral Velcro, Carlson
  photocopier, Land Polaroid, Fleming penicillin ١٩٢٨, Kilby/Noyce
  IC, Intel ٤٠٠٤ ١٩٧١, Apple I ١٩٧٦/IBM PC ١٩٨١/iPhone ٢٠٠٧, Hull
  3D printing SLA ١٩٨٣, Whittingham/Goodenough/Yoshino lithium-ion
  Nobel ٢٠١٩, Carrier AC ١٩٠٢, Bakelite ١٩٠٧.
- **Economics Basics pack** (`economics_basics.json`) — 60 items
  on currency, supply & demand, scarcity, opportunity cost, needs
  vs wants, budgeting, simple interest, inflation/recession, taxes,
  imports & exports, money history (cowries → coins → paper), **Ibn
  Khaldun Muqaddimah**, **zakat ٢٫٥٪ as Islamic principle**, halal
  trade ethics, **Yunus & Grameen microfinance Nobel ٢٠٠٦**,
  entrepreneurship, profit/loss, GCC currencies (KWD, SAR, AED) and
  the goods-vs-services distinction.
- **Dots and Boxes vs CPU mini-game** (route `/dots-boxes`, 🟦 home
  pill) — ٤×٤ box grid (٥×٥ dots). Tap a line; closing the 4th
  side claims the box and grants another move. CPU AI uses a
  three-tier heuristic: (١) close any 3-sided box, (٢) avoid
  leaving a 2-sided box that gives the player a free chain,
  (٣) random fallback. Coin reward by margin: ≥٨ → ١٠🪙, ≥٤ → ٥🪙,
  win → ٢🪙.

### Improved
- General-quiz extras pool now totals **91 packs (~٥٬٥٢٠ items)**.

## 1.1.40 — 2026-05-05 — Wave 37

### Added
- **Wildlife Conservation pack** (`wildlife_conservation.json`) — 60
  items: endangered species (giant panda, vaquita, kakapo, Iberian
  lynx, Amur leopard), CITES & IUCN red list categories, success
  stories (American bison, bald eagle, **Arabian oryx reintroduction**,
  mountain gorillas), national parks (Yellowstone ١٨٧٢ first ever,
  Serengeti, Galápagos), Jane Goodall, Dian Fossey, David Attenborough,
  keystone species (sea otter & kelp, wolves & Yellowstone), invasives
  (cane toad, lionfish), pollinator decline, coral bleaching, Amazon
  deforestation, kid-actionable conservation tips.
- **Simple Machines pack** (`simple_machines.json`) — 60 items on the
  six classical simple machines (lever, wheel & axle, pulley, inclined
  plane, wedge, screw), Archimedes' lever quote, three classes of
  levers with everyday examples, mechanical advantage, friction, gears
  (spur/bevel/worm), block & tackle, hand tools, kitchen tools as
  hidden machines, **Archimedes' screw water pump**, Stone→Iron Age
  tool history and Work = F·d at kid level.
- **Music Genres pack** (`music_genres.json`) — 60 items spanning
  world genres (jazz, blues, rock, pop, hip-hop, country, folk, EDM,
  reggae, R&B, K-pop), **Arabic genres (طرب, مقام, دبكة, خليجي,
  عتابا, موشحات)**, regional traditions (Andalusi, Persian, Indian
  classical, Japanese, Aboriginal didgeridoo), genre-defining
  instruments (oud, qanun, ney, sitar, koto, bagpipes, sax),
  origins (jazz New Orleans ١٩٠٠s, hip-hop Bronx ١٩٧٠s, reggae
  Jamaica), classical greats (Mozart, Beethoven, Bach, Vivaldi),
  music theory basics (chord, melody, rhythm, tempo) and recording
  evolution (vinyl→cassette→CD→streaming).
- **Battleship vs CPU mini-game** (route `/battleship`, 🚢 home pill)
  — ٦×٦ grid, ٣ ships (٣/٢/٢ cells). Player vs CPU turn-based.
  CPU uses hunt-mode greedy targeting after a hit (queues the four
  orthogonal neighbors). Coin reward by miss-count: ≤٨ misses → ١٠🪙,
  ≤١٦ → ٥🪙, otherwise ٢🪙.

### Improved
- General-quiz extras pool now totals **88 packs (~٥٬٣٤٠ items)**.

## 1.1.39 — 2026-05-05 — Wave 36

### Added
- **Trains & Railways pack** (`trains_railways.json`) — 60 items
  on locomotive history (Stephenson's Rocket ١٨٢٩), steam→diesel→
  electric→maglev evolution, gauges (standard ١٤٣٥ mm), iconic lines
  (Trans-Siberian, Orient Express, Shinkansen, TGV, Eurostar), tunnels
  (Channel Tunnel ٥٠٫٤٥ km, Gotthard ٥٧٫١ km), railway components
  (locomotive, tender, signal, switch), subway/metro systems, monorail
  & cable cars, narrow gauge, freight types and rail safety.
- **Renaissance Art pack** (`renaissance_art.json`) — 60 items on
  da Vinci (Mona Lisa, Last Supper, sfumato), Michelangelo (David,
  Sistine ceiling ١٥٠٨–١٥١٢, Pietà), Raphael (School of Athens),
  Donatello, Botticelli (Birth of Venus), Brunelleschi (Florence Dome),
  Northern Renaissance (Dürer, Van Eyck), techniques (perspective,
  fresco, chiaroscuro, oil painting), Medici patronage, Florentine
  workshops and Italian city-states.
- **Submarines & Ocean Tech pack** (`submarines_ocean_tech.json`) — 60
  items on Cornelius Drebbel's first sub ١٦٢٠, Turtle ١٧٧٦, Nautilus,
  ballast tanks & Archimedes' principle, bathysphere & Trieste
  Mariana Trench ١٩٦٠, Alvin (Titanic ١٩٨٦), ROVs/AUVs, sonar &
  echolocation, Cousteau & the Aqua-Lung, periscopes, hydrothermal
  vents, deep-sea creatures (anglerfish, giant squid), submarine
  cables, tidal turbines and James Cameron's Deepsea Challenger ٢٠١٢.
- **Word Scramble mini-game** (route `/word-scramble`, 🪄 home pill) —
  ٧٥-second arcade word-builder. ٤٠-word bilingual lexicon, tap letters
  in order to spell, +٣s on solve, -٥s on skip; coin tiers ٢🪙/٥🪙/١٠🪙
  at scores ٥/١٢/٢٠.

### Improved
- General-quiz extras pool now totals **85 packs (~٥٬١٦٠ items)** with
  ID-deduped merge on load.

## 1.1.38 — 2026-05-05 — Wave 35

### Added
- **Bridges & Tunnels pack** (`bridges_tunnels.json`) — 60 items:
  bridge types (suspension/cable-stayed/arch/truss/cantilever),
  Akashi Kaikyō ١٬٩٩١م, **١٩١٥ Çanakkale ٢٬٠٢٣م current record**,
  Golden Gate ١٩٣٧, Brooklyn Bridge ١٨٨٣ Roebling, Tower Bridge,
  Sydney Harbour, Forth UNESCO, **Millau Viaduct ٣٤٣م taller than
  Eiffel**, Danyang–Kunshan ١٦٤٫٨ km longest bridge, **Sheikh Jaber
  Causeway Kuwait ٤٨٫٥ km ٢٠١٩**, **King Fahd Causeway ٢٥ km ١٩٨٦**,
  Sheikh Zayed Bridge Abu Dhabi (Zaha Hadid), Bosphorus, **Channel
  Tunnel ٥٠٫٤٥ km ١٩٩٤**, Gotthard Base ٥٧٫١ km longest rail tunnel,
  Lærdal ٢٤٫٥ km longest road tunnel, TBM, Tay collapse ١٨٧٩, Tacoma
  Narrows ١٩٤٠ aerodynamic flutter, Stari Most Mostar ١٥٦٧ Ottoman,
  Si-o-se-pol ٣٣ arches Isfahan, **As-Sirat** Islamic eschatology.
- **Treaties & Diplomacy pack** (`treaties_diplomacy.json`) — 60
  items: **Constitution of Madinah ٦٢٢ CE first written constitution
  in human history (Prophet Muhammad ﷺ)**, **Treaty of Hudaybiyya
  ٦ AH/٦٢٨ CE turning point**, Pact of Umar Jerusalem, Salahuddin
  capitulations ١١٨٧, **Treaty of Kadesh ١٢٥٩ ق.م earliest
  preserved peace treaty (copy at UN HQ)**, Magna Carta ١٢١٥, Peace
  of Westphalia ١٦٤٨, Treaty of Versailles ١٩١٩, **UN Charter ١٩٤٥**,
  UDHR ١٩٤٨, Geneva Conventions, NPT ١٩٦٨, Camp David ١٩٧٨, Egypt-
  Israel ١٩٧٩, Maastricht ١٩٩٢ → EU, Good Friday ١٩٩٨, Paris Climate
  ٢٠١٥, Abraham Accords ٢٠٢٠, **GCC ٢٥ May ١٩٨١**, **Arab League
  ١٩٤٥**, **OIC ١٩٦٩** ٥٧ states, Vienna Convention on Diplomatic
  Relations ١٩٦١, **honoring contracts Surah Al-Isra ١٧:٣٤**, sulh
  Surah An-Nisa ٤:١٢٨.
- **Sleep & Dreams pack** (`sleep_dreams.json`) — 60 items: REM
  discovered Aserinsky/Kleitman ١٩٥٣, ٤ sleep stages, ٩٠-minute
  cycle, glymphatic brain "garbage collection", melatonin/pineal
  gland, suprachiasmatic nucleus master clock, kids ٦-١٢ need ٩-١٢
  hours, Mendeleev periodic table dream ١٨٦٩, Kekulé benzene ring
  ١٨٦٥, Mary Shelley Frankenstein ١٨١٦, dolphins half-brain sleep,
  koalas ٢٢ hours, Surah An-Naba ٧٨:٩ "وجعلنا نومكم سباتًا",
  **Qaylulah** sunnah + NASA ٢٦-min nap research, sleep dua
  "بسم الله أموت وأحيا", right-side sunnah, **Ashab al-Kahf ٣٠٩
  years Surah Al-Kahf**, Yusuf A.S. dream interpretation.
- **Odd One Out mini-game** (`/odd-one-out`) — ٤٥-second visual
  search; tap the slightly-different tile in a grid that scales
  with score (٣×٣ → ٦×٦) and shrinks color difference. +٢🪙 ٥+,
  +٥🪙 ١٥+, +١٠🪙 ٣٠+. Surfaced as 🔍 home pill.

### Changed
- General Quiz pool now mixes 82 bilingual extras packs (~4,980+
  items before base set), home shows 35 mini-games.

## 1.1.37 — 2026-05-05 — Wave 34

### Added
- **Cars & Engineering pack** (`cars_engineering.json`) — 60 items:
  Karl Benz Patent-Motorwagen ١٨٨٦, Bertha Benz first long trip ٢٠٦
  km ١٨٨٨, Ford Model T ١٥M sold, Toyota Way kanban, ٤-stroke
  internal combustion (Diesel ١٨٩٢), James Watt ٧٤٦W = ١hp, Tesla
  Model S ٢٠١٢ revival, Goodenough lithium-ion Nobel ٢٠١٩, BYD
  overtook Tesla ٢٠٢٣, Toyota Prius ١٩٩٧ first hybrid, Mirai
  hydrogen, F١ since ١٩٥٠, Hamilton/Schumacher ٧× champs, **Bahrain
  GP ٢٠٠٤, Yas Marina, Saudi Arabia Jeddah ٢٠٢١**, Dakar in Saudi
  Arabia since ٢٠٢٠, Volvo ٣-point seatbelt ١٩٥٩, Bugatti Chiron SS
  >٤٩٠ km/h, Toyota Corolla ٥٠M+ best seller, **Saudi women legally
  allowed to drive ٢٠١٨**, دعاء السفر.
- **Languages of the World pack** (`languages_world.json`) — 60
  items: top ١٠ languages (Arabic ~٤٠٠M speakers in ٢٢+ countries),
  language families (Indo-European, Sino-Tibetan, Afroasiatic),
  **Modern Standard Arabic vs dialects (Khaleeji/Levantine/Maghrebi/
  Egyptian)**, ٢٨ letters RTL root system, Arabic loanwords (algebra,
  alcohol, sugar, magazine), endangered languages (one dies every
  ٢ weeks), Esperanto Zamenhof ١٨٨٧, Icelandic unchanged ١٬٠٠٠
  years, Hawaiian ١٣ letters, Khmer ٧٤ letters, Basque isolate,
  Silbo Gomero whistled UNESCO, click languages, Mezzofanti
  ٧٢-language polyglot, **Bayt al-Hikma Baghdad** translations,
  UN's ٦ official languages, **Sibawayh الكتاب ٧٦٠–٧٩٦ founder of
  Arabic grammar**, Tajweed.
- **Ancient India pack** (`ancient_india.json`) — 60 items: Indus
  Valley ٣٣٠٠ ق.م Harappa & Mohenjo-daro first urban sewers,
  Sanskrit, Mahabharata/Ramayana cultural literature, **Maurya
  Ashoka the Great ٢٦٨–٢٣٢ ق.م** Edicts & Lion Capital, Brahmagupta
  ٥٩٨–٦٦٨ formalized zero, Aryabhata π ≈ ٣٫١٤١٦, Nalanda University
  ٤٢٧–١١٩٧ ١٠٬٠٠٠ students, **Muhammad ibn al-Qasim ٧١١ CE Sindh**,
  Mahmud of Ghazni, **Delhi Sultanate ١٢٠٦–١٥٢٦**, Qutub Minar
  ٧٢٫٥م tallest brick minaret, Moinuddin Chishti Ajmer, **Mughal
  Empire ١٥٢٦–١٨٥٧**: Babur, Akbar Din-i Ilahi, **Shah Jahan Taj
  Mahal ١٦٣١–١٦٥٣ for Mumtaz Mahal**, Aurangzeb Fatawa Alamgiri,
  Red Fort, Tipu Sultan iron rockets, Gandhi/Iqbal/Jinnah/Azad,
  ١٩٤٧ Independence/Partition, Bangladesh ١٩٧١, Shah Waliullah of
  Delhi, **٦٥٠M+ Muslims** in subcontinent.
- **Tap Sequence mini-game** (`/tap-sequence`) — find numbers ١-٢٥
  scattered on a ٦×٦ grid, tap in order ASAP. Wrong tap +٢s
  penalty. +٢🪙 finish, +٥🪙 ≤ ٢٠s, +١٠🪙 ≤ ١٢s. Surfaced as 🆗 home
  pill.

### Changed
- General Quiz pool now mixes 79 bilingual extras packs (~4,800+
  items before base set), home shows 34 mini-games.

## 1.1.36 — 2026-05-05 — Wave 33

### Added
- **Forests & Biomes pack** (`forests_biomes.json`) — 60 items:
  major biomes (taiga ٢٩% world forest, rainforest, tundra, savannah,
  mangrove, Mediterranean), Amazon ٥٫٥M km² ٢٠% world oxygen,
  Yanomami people, Black Forest, Białowieża, Daintree ١٨٠M years,
  Hyperion ١١٦م tallest tree, Methuselah ٤٬٨٥٠ years, photosynthesis,
  tree rings, Yellowstone ١٨٧٢ first national park, **Saudi Green
  Initiative ١٠ billion trees**, **Hima system — early Islamic
  protected reserves ٧th c.**, sapling hadith.
- **Famous Battles pack** (`famous_battles.json`) — 60 items:
  Marathon ٤٩٠ ق.م, Thermopylae, Salamis, Cannae Hannibal envelopment,
  **Badr ٦٢٤ CE Surah Al-Anfal ٨**, Uhud, Khandaq with Salman
  al-Farsi RA, **Yarmuk ٦٣٦ Khalid ibn al-Walid RA "Saif Allah"**,
  al-Qadisiyyah Sa'd RA, **Hattin ١١٨٧ Salahuddin recaptured
  Jerusalem**, **Ain Jalut ١٢٦٠ Mamluks Qutuz/Baybars first major
  Mongol defeat**, Tours ٧٣٢ Charles Martel, Hastings ١٠٦٦, Mehmed
  II conquest of Constantinople ١٤٥٣, Lepanto, Vienna ١٦٨٣,
  Austerlitz/Trafalgar/Waterloo, Marne, Atatürk Gallipoli ١٩١٥,
  Britain ١٩٤٠, Midway, D-Day ١٩٤٤. Tactics: phalanx, flanking,
  pincer, combined arms.
- **Olympic Games pack** (`olympic_games.json`) — 60 items: ancient
  Olympia ٧٧٦ ق.م, banned ٣٩٣ CE, **Pierre de Coubertin revival
  Athens ١٨٩٦**, IOC ١٨٩٤, **Olympic rings (٥ continents)**, motto
  "Citius Altius Fortius — Communiter", torch since Berlin ١٩٣٦,
  Phelps ٢٣ golds, Bolt ١٠٠m WR ٩٫٥٨s, Comăneci first perfect ١٠
  ١٩٧٦, **Hicham El Guerrouj** Morocco, **Mutaz Barshim** Qatar high
  jump Tokyo ٢٠٢٠, **Hafnaoui** Tunisia ٤٠٠m gold Tokyo, **Ibtihaj
  Muhammad** first hijabi US Olympic medalist Rio ٢٠١٦, **Sarah
  Attar** Saudi first London ٢٠١٢, FIFA hijab approval ٢٠١٤,
  Paralympic Rome ١٩٦٠, Beijing ٢٠٢٢ first dual-host city, Brisbane
  ٢٠٣٢, hadith on strong believer.
- **Pegs Solitaire mini-game** (`/pegs`) — English ٣٣-hole cross
  pattern, jump pegs over neighbors to remove them. Goal: ١ peg in
  center. +٢🪙 finish ≤ ٣ pegs, +٥🪙 ≤ ٢, +١٠🪙 perfect ١-in-center.
  Surfaced as 🟡 home pill.

### Changed
- General Quiz pool now mixes 76 bilingual extras packs (~4,620+
  items before base set), home shows 33 mini-games.

## 1.1.35 — 2026-05-05 — Wave 32

### Added
- **African Civilizations pack** (`african_civilizations.json`) — 60
  items: **Mansa Musa** richest person ever, **Mali Empire**
  Timbuktu Sankore University ٢٥٬٠٠٠ students, Djinguereber Mosque
  ١٣٢٧, **Hijra to Abyssinia ٦١٥ CE — first Hijra**, Negus al-
  Najashi protected early Muslims, **Bilal ibn Rabah (RA)** first
  muezzin, Kingdom of Kush Nubian pyramids, Aksum, Carthage &
  Hannibal Alps elephants ٢١٨ ق.م, Songhai (Sonni Ali, Askia
  Muhammad), Ghana Empire trans-Saharan gold, Great Zimbabwe stone
  city, Walls of Benin ١٦٬٠٠٠ km, Shaka Zulu, Swahili Coast
  (Kilwa/Mombasa/Zanzibar), Ethiopia never colonized (Adwa ١٨٩٦),
  Ahmad Baba al-Timbukti library ١٬٦٠٠ books, Ishango Bone
  ٢٠٬٠٠٠ years.
- **Time & Clocks pack** (`time_clocks.json`) — 60 items: sundials,
  hourglasses, **Al-Jazari ١١٣٦–١٢٠٦ Father of Robotics — Elephant
  Clock ١٢٠٦** (cultural unity: India/China/Egypt/Greece), Castle
  Clock programmable, "Book of Knowledge of Ingenious Mechanical
  Devices", astrolabe, Su Song clock ١٠٨٨, **Huygens pendulum
  ١٦٥٦**, Harrison chronometer ١٧٦١, Cartier Santos ١٩٠٤,
  Seiko quartz Astron ١٩٦٩, **Cesium-١٣٣ atomic clock**
  ٩٬١٩٢٬٦٣١٬٧٧٠ oscillations = ١ second since ١٩٦٧, GPS relativity
  ٣٨ μs/day, GMT ١٨٨٤, **Hijri Calendar** ٣٥٤ days starting ٦٢٢
  CE, **Jalali Calendar (Omar Khayyam ١٠٧٩)** more accurate than
  Gregorian, **Surah Al-Asr "وَالْعَصْرِ"**, Hajj Dhul-Hijjah ٨–١٣.
- **Photography pack** (`photography.json`) — 60 items: **Ibn al-
  Haytham camera obscura ١٠٢١م** foundation of all photography,
  Niépce ١٨٢٧ first photo (٨ hr exposure), Daguerre ١٨٣٩, Talbot
  calotype, Maxwell first color ١٨٦١, Kodachrome ١٩٣٥, Eastman
  Kodak roll film ١٨٨٨, Ansel Adams, Cartier-Bresson decisive
  moment, Steve McCurry Afghan Girl ١٩٨٤, Lange Migrant Mother
  ١٩٣٦, Earthrise Apollo ٨ ١٩٦٨, Pale Blue Dot ١٩٩٠, exposure
  triangle (aperture/shutter/ISO), DSLR/mirrorless/phone, Sharp
  J-SH04 first camera phone ٢٠٠٠, computational photography,
  rule of thirds, golden hour, JPEG ١٩٩٢, Photoshop ١٩٩٠,
  deepfakes ethics.
- **Reversi mini-game** (`/reversi`) — ٨×٨ board vs CPU (greedy +
  corner heuristic + X-square avoidance), flip stones to capture.
  +٢🪙 first win, +٥🪙 win by ١٠+, +١٠🪙 win by ٢٠+. Surfaced as ⚫
  home pill.

### Changed
- General Quiz pool now mixes 73 bilingual extras packs (~4,440+
  items before base set), home shows 32 mini-games.

## 1.1.34 — 2026-05-05 — Wave 31

### Added
- **Medicine Pioneers pack** (`medicine_pioneers.json`) — 60 items:
  **Ibn Sina ٩٨٠–١٠٣٧ Canon of Medicine** used in Europe for ٦٠٠+
  years, **Al-Razi ٨٥٤–٩٢٥** smallpox vs measles & founder of
  pediatrics, **Al-Zahrawi ٩٣٦–١٠١٣** father of modern surgery
  with ٢٠٠ instruments, **Ibn al-Nafis ١٢١٣–١٢٨٨ pulmonary
  circulation ٣٠٠ years before Harvey**, Hippocrates, Galen,
  Vesalius ١٥٤٣, Harvey ١٦٢٨, **Jenner smallpox vaccine ١٧٩٦**
  (smallpox eradicated ١٩٨٠), Pasteur germ theory & rabies vaccine
  ١٨٨٥, Lister ١٨٦٧, Koch TB ١٨٨٢, Fleming penicillin ١٩٢٨ Nobel
  ١٩٤٥, Salk polio ١٩٥٥, Banting & Best insulin ١٩٢٢, Barnard
  first heart transplant ١٩٦٧, Tu Youyou artemisinin Nobel ٢٠١٥,
  Karikó & Weissman mRNA Nobel ٢٠٢٣, Röntgen X-ray ١٨٩٥, MRI/CT,
  Semmelweis hand-washing ١٨٤٧, **Tibb Nabawi** (honey Surah
  An-Nahl ٦٩, black seed habbat al-sawda), Bimaristan first
  hospitals with wards.
- **Ancient China pack** (`ancient_china.json`) — 60 items:
  dynasties Shang→Qing, Qin Shi Huang first emperor & Great Wall
  start, **Four Great Inventions** (Cai Lun paper ١٠٥ CE, Bi Sheng
  movable type ١٠٤٠s, gunpowder Tang ٩th c., compass Song),
  Great Wall ٢١٬٠٠٠ km, Forbidden City ٩٬٩٩٩ rooms ١٤٠٦–١٤٢٠,
  Terracotta Army discovered ١٩٧٤ ٨٬٠٠٠+ warriors, Confucius
  ٥٥١–٤٧٩ ق.م, Sun Tzu Art of War, Laozi/Daoism, silk/tea/porcelain,
  Zhang Heng earthquake detector ١٣٢ CE, Su Song mechanical clock
  ١٠٨٨, Wu Zetian only female emperor ٦٩٠–٧٠٥, Crab Nebula
  supernova ١٠٥٤, **hadith "اطلبوا العلم ولو في الصين"**, Battle of
  Talas ٧٥١ paper transfer to Muslim world, **Hui Muslims** Beijing
  Niujie Mosque ٩٩٦.
- **Famous Mathematicians pack** (`famous_mathematicians.json`) —
  60 items: **Al-Khwarizmi ٧٨٠–٨٥٠** algebra/algorithm etymology,
  Al-Biruni Earth radius ٦٬٣٣٩ km, **Omar Khayyam** Jalali calendar
  more accurate than Gregorian, Thabit ibn Qurra amicable numbers,
  Sharaf al-Din al-Tusi cubic equations, Pythagoras (Plimpton ٣٢٢
  Babylonian priority), Euclid Elements, Archimedes "Eureka",
  Aryabhata zero & decimal place, Brahmagupta zero arithmetic,
  Fibonacci sequence (learned in North Africa), Newton/Leibniz
  calculus, Leibniz binary, Euler e ≈ ٢٫٧١٨ & "most beautiful
  equation" e^(iπ)+١=٠, Gauss 1-100=٥٬٠٥٠, Riemann hypothesis,
  Kovalevskaya first woman PhD math, Hilbert ٢٣ problems, Ramanujan
  ٣٬٩٠٠ identities, Noether (symmetries↔conservation), Wiles
  Fermat's Last Theorem ١٩٩٤ after ٣٥٠ years, **sifr صفر → zero/
  cipher**.
- **Math Sprint mini-game** (`/math-sprint`) — ٦٠-second timed
  arithmetic (+/-/×) with 4-choice answers. +٢🪙 first ١٠ correct,
  +٥🪙 ٢٠+, +١٠🪙 ٣٥+. Surfaced as ➕ home pill.

### Changed
- General Quiz pool now mixes 70 bilingual extras packs (~4,260+
  items before base set), home shows 31 mini-games.

## 1.1.33 — 2026-05-05 — Wave 30

### Added
- **Ancient Mesopotamia pack** (`ancient_mesopotamia.json`) — 60
  items: Tigris دجلة & Euphrates الفرات, **Sumerians** first
  civilization (cuneiform, ziggurats, wheel ٣٥٠٠ ق.م, base-٦٠ →
  why we have ٦٠ minutes & ٣٦٠°), **Sargon of Akkad** first empire
  ٢٣٣٤ ق.م, **Hammurabi ١٧٩٢ ق.م** ٢٨٢-law code, **Nebuchadnezzar
  II Hanging Gardens** Ishtar Gate, Assyrian Nineveh & **Library of
  Ashurbanipal ٣٠٬٠٠٠ tablets**, Plimpton ٣٢٢ Pythagoras-before-
  Pythagoras, Royal Game of Ur, **Ibrahim A.S. born in Ur**,
  **Yunus A.S. sent to Nineveh**, Iraq → Bayt al-Hikma continuum.
- **Deserts of the World pack** (`deserts_world.json`) — 60 items:
  Antarctica largest desert, **Sahara** ٩٫٢ M km² ١١ countries
  (was green ٥٬٠٠٠ ya), **Empty Quarter / الربع الخالي ٦٥٠٬٠٠٠
  km² dunes ٢٥٠م** Wilfred Thesiger ١٩٤٠s, An-Nafud, Ad-Dahna,
  Wahiba Sands, Gobi, Taklamakan, Lut ٧٠٫٧°C ٢٠٠٥, Death Valley
  ٥٦٫٧°C ١٩١٣, Atacama, Namib oldest, polar deserts, camel triple
  eyelids ١٠٠L in ١٠ minutes, Arabian oryx, fennec, jerboa الجربوع,
  Bedouin tents بيت الشعر, falconry, oases Al-Ahsa/Siwa/Liwa,
  **Hagar & Zamzam** in Bakka, **Hijra ٦٢٢ CE**.
- **Aviation History pack** (`aviation_history.json`) — 60 items:
  **Abbas Ibn Firnas ٨١٠–٨٨٧ glide flight Cordoba ٨٧٥** (٦٠٠+ years
  before Leonardo), Hezârfen Çelebi ١٦٣٢ Bosporus, Montgolfier
  ١٧٨٣, Hindenburg ١٩٣٧, **Wright brothers Kitty Hawk ١٩٠٣-١٢-١٧**,
  Lindbergh ١٩٢٧, Earhart, Bessie Coleman ١٩٢١, Red Baron, Spitfire,
  Whittle/Ohain jet engine, Concorde Mach ٢٫٠٤, ٧٤٧/A٣٨٠, **Yeager
  Bell X-١ Mach ١ ١٩٤٧**, Sikorsky helicopter ١٩٣٩, **Kuwait
  Airways ١٩٥٤**, Emirates, Saudia, drones, eVTOL future, Surah
  Al-Mulk ٦٧:١٩ & An-Nahl ١٦:٧٩ on flight.
- **Maze Runner mini-game** (`/maze-runner`) — recursive-backtracker
  procedural maze (٩×٩/١١×١١/١٥×١٥), swipe or arrow-tap. +٢🪙 first
  solve, +٥🪙 ≤ ٤٠ moves, +١٠🪙 ≤ ٢٥ moves. Surfaced as 🌀 home pill.

### Changed
- General Quiz pool now mixes 67 bilingual extras packs (~4,080+
  items before base set), home shows 30 mini-games.

## 1.1.32 — 2026-05-05 — Wave 29

### Added
- **Calligraphy & Writing Systems pack** (`calligraphy_writing.json`)
  — 60 items: Arabic styles (الكوفي/النسخ/الثلث/الديواني/الرقعة/
  المغربي/النستعليق), **Ibn Muqla ٨٨٦–٩٤٠ proportional script**,
  Ibn al-Bawwab, Yaqut al-Mustaʿsimi, Hafiz Osman, Arabic alphabet
  ٢٨ letters, Abu al-Aswad i'jam dots, al-Khalil harakat, Battle of
  Talas ٧٥١ paper, world scripts (cuneiform, hieroglyphs, Phoenician,
  Hangul ١٤٤٣, Cyrillic, Devanagari), Rosetta Stone Champollion
  ١٨٢٢, Braille ١٨٢٤, Morse, emoji ١٩٩٩, Unicode/QR, **first word
  «اقرأ» Surah Al-Alaq ٩٦**, Dome of the Rock Kufi ٦٩١م, Alhambra,
  Hagia Sophia, Kiswah.
- **Mountains & Peaks pack** (`mountains_peaks.json`) — 60 items:
  Seven Summits (Everest ٨٨٤٩م → Carstensz), K2/Kangchenjunga, the
  ١٤ ٨٬٠٠٠m peaks, Hillary & Tenzing Norgay ١٩٥٣-٠٥-٢٩, Junko
  Tabei ١٩٧٥, Messner, Himalaya/Andes/Rockies/Alps/Atlas/Hijaz/Hajar/
  Zagros, **Hira (cave of revelation), Uhud "Uhud loves us" hadith,
  Arafat (Hajj), Sinai (Jabal Musa)**, Olympus, Fuji, Mauna Kea
  (tallest from base ١٠٬٢١٠م), altitude sickness >٢٬٥٠٠م, Death
  Zone >٨٬٠٠٠م, **Surah An-Naba "جعلنا الجبال أوتادًا" pegs verse,
  Al-Judi Hud Surah** (Nuh's ark resting place).
- **Codes & Ciphers pack** (`codes_ciphers.json`) — 60 items: Caesar
  shift ٣ ٥٠ ق.م, Atbash, Scytale, frequency analysis, **Al-Kindi
  ٨٠١–٨٧٣ founder of cryptanalysis at Bayt al-Hikma**, Vigenère
  ١٥٨٦, Babbage/Kasiski cracks, **Enigma**: Rejewski ١٩٣٢, Turing
  Bombe at Bletchley Park (war shortened ٢ years), Navajo Code
  Talkers, public-key (Diffie-Hellman ١٩٧٦, RSA ١٩٧٧), HTTPS
  padlock, end-to-end encryption (WhatsApp/Signal), Zimmermann
  telegram ١٩١٧, Voynich, Linear B Ventris ١٩٥٢, Turing test ١٩٥٠,
  steganography, DNA codons, **علم المعمى والمستعجم** Arab cipher
  tradition, password & phishing safety.
- **Brick Breaker mini-game** (`/brick-breaker`) — drag paddle,
  bounce ball, clear ٥×٧ brick wall in ٣ lives. +٢🪙 first clear,
  +٥🪙 no-loss clear, +١٠🪙 sub-٦٠s clear. Surfaced as 🧱 home pill.

### Changed
- General Quiz pool now mixes 64 bilingual extras packs (~3,900+
  items before base set), home shows 29 mini-games.

## 1.1.31 — 2026-05-05 — Wave 28

### Added
- **Maritime Exploration pack** (`maritime_exploration.json`) — 60
  items: **Ibn Battuta** ١٢٠٬٠٠٠ km in ٢٩ years (Tangier ١٣٠٤–١٣٦٨,
  Rihla), **Zheng He** ٧ voyages ١٤٠٥–١٤٣٣ treasure ships ١٣٧م,
  **Ahmed Ibn Majid** "Lion of the Sea" piloted Vasco da Gama
  ١٤٩٨, Vasco da Gama, Columbus framed as "encountered the Americas"
  ١٤٩٢, Magellan/Elcano ١٥١٩–١٥٢٢, Vikings/Leif Erikson ~١٠٠٠ CE,
  Phoenicians, Arab dhows & monsoons, Captain Cook, Polar
  (Amundsen ١٩١١, Shackleton), Cousteau & Cameron Mariana ٢٠١٢,
  ship tech (caravel, astrolabe, Harrison chronometer ١٧٦١), Kuwait
  pearl-diving heritage, Surah An-Nahl ١٦ on ships at sea.
- **Telescopes & Discoveries pack** (`telescopes_discoveries.json`)
  — 60 items: refractor vs reflector, Galileo Sidereus Nuncius
  ١٦١٠ (Jupiter ٤ moons + Venus phases + sunspots), Lippershey
  ١٦٠٨, Newton reflector ١٦٦٨, Hubble launched ١٩٩٠ (Pillars of
  Creation), JWST ٢٠٢١-١٢-٢٥ ٦٫٥م gold mirror at L٢, Saturn rings
  Huygens ١٦٥٥, Uranus Herschel ١٧٨١, Pluto Tombaugh ١٩٣٠, Hubble's
  law ١٩٢٩, Arecibo, FAST ٥٠٠م, Event Horizon Telescope M٨٧* ٢٠١٩
  + Sgr A* ٢٠٢٢, **Muslim Golden Age**: al-Battani, al-Sufi Book
  of Fixed Stars ٩٦٤, Ulugh Beg Samarkand ١٤٢٤, al-Tusi Maragheh
  ١٢٥٩, Surah At-Tariq.
- **Money & Trade History pack** (`money_trade_history.json`) — 60
  items: barter (cowries, salt-salary), Lydia Croesus ٦٠٠ ق.م
  electrum coins, Greek drachma, Roman denarius, Chinese jiaozi
  ١١th c., **Caliph Abd al-Malik ibn Marwan ٦٩٧م/٧٧هـ Islamic
  dinar (٤٫٢٥g) and dirham (٢٫٩٧٥g) "لا إله إلا الله" inscription**,
  Hanseatic League, Medici, Marco Polo, Silk Road, spice trade,
  **Kuwait pearl diving** until ١٩٣٠s, Bretton Woods ١٩٤٤, Nixon
  shock ١٩٧١, Bank of England ١٦٩٤, Fed ١٩١٣, Weimar/Zimbabwe
  hyperinflation, NYSE ١٧٩٢, Bitcoin ٢٠٠٩, Kuwaiti dinar ١٩٦١,
  zakat ٢٫٥%, riba prohibited Surah Al-Baqarah ٢٧٥, Bait al-Mal.
- **Code Breaker / Mastermind mini-game** (`/mastermind`) — guess
  a secret 4-color code in ١٠ tries, ٦-color palette, green/gold
  feedback pegs (right slot vs right color only). +٢🪙 first solve,
  +٥🪙 ≤ ٦ tries, +١٠🪙 ≤ ٤ tries. Surfaced as 🎯 home pill.

### Changed
- General Quiz pool now mixes 61 bilingual extras packs (~3,720+
  items before base set), home shows 28 mini-games.

## 1.1.30 — 2026-05-05 — Wave 27

### Added
- **Ancient Egypt pack** (`ancient_egypt.json`) — 60 items: pyramids
  (Khufu ٢٥٦٠ ق.م ١٤٦م, Sphinx, Saqqara Step Pyramid Djoser ٢٦٧٠
  ق.م), pharaohs (Tutankhamun KV٦٢ Howard Carter ١٩٢٢, Ramses II,
  Hatshepsut, Akhenaten, Cleopatra VII ٣٠ ق.م), Rosetta Stone
  ١٧٩٩→Champollion ١٨٢٢, hieroglyphs/papyrus, mummification ٧٠ days
  & canopic jars, ancient mythology (framed culturally), Karnak/
  Luxor/Abu Simbel, calendar ٣٦٥-day, Quran context — Yusuf A.S.,
  Musa A.S. & Firaun, modern Egypt ٩٥% Muslim Arab.
- **Volcanoes & Earthquakes pack** (`volcanoes_earthquakes.json`) —
  60 items: ٧ tectonic plates, Wegener ١٩١٢, Earth layers (inner core
  ٥٧٠٠°C), volcano types (shield/strato/cinder/caldera), Vesuvius
  ٧٩ CE, Krakatoa ١٨٨٣, St Helens ١٩٨٠, Tambora ١٨١٥, Tonga ٢٠٢٢,
  P/S waves & Richter, Tōhoku ٢٠١١ ٩٫٠, Türkiye-Syria ٢٠٢٣ ٧٫٨,
  Ring of Fire, Drop-Cover-Hold safety, Lehmann inner-core ١٩٣٦,
  geothermal (Iceland/Kenya), **Surah Az-Zalzalah ٩٩**.
- **Microbes & Cells pack** (`microbes_cells.json`) — 60 items: cells
  (prokaryote vs eukaryote, organelles), Hooke ١٦٦٥, Leeuwenhoek
  ١٦٧٠s, Pasteur germ theory ١٨٦٠s, bacteria shapes & friendly vs
  harmful, viruses (smallpox eradicated ١٩٨٠), fungi (Fleming
  penicillin ١٩٢٨ Nobel ١٩٤٥), gut microbiome ٣٩ trillion, hygiene
  (٢٠ second handwashing, soap breaks lipid membrane), DNA Watson/
  Crick/Franklin ١٩٥٣, Salk polio ١٩٥٥, Jenner smallpox ١٧٩٦,
  **النظافة من الإيمان**, sneezing sunnah, wudu cleanliness.
- **Pong vs CPU mini-game** (`/pong`) — first to ٧, drag bottom
  paddle, ball speeds up after each rally hit. +٢🪙 first win, +٥🪙
  shutout. Surfaced as 🏓 home pill.

### Changed
- General Quiz pool now mixes 58 bilingual extras packs (~3,540+
  items before base set), home shows 27 mini-games.

## 1.1.29 — 2026-05-05 — Wave 26

### Added
- **Optical Illusions & Vision pack** (`optical_illusions_vision.json`)
  — 60 items: eye anatomy (rods/cones, fovea, blind spot), how vision
  works, classic illusions (Müller-Lyer, Hermann grid, Ebbinghaus,
  Kanizsa, Necker, Ponzo), color perception (RGB cones, afterimages),
  depth & 3D, **Ibn al-Haytham (الحسن بن الهيثم) Book of Optics
  ١٠٢١م**, Hubel & Wiesel Nobel ١٩٨١, optical phenomena (mirages,
  rainbows, halos), eye care (٢٠-٢٠-٢٠ rule), Surah An-Nur ٢٤
  light & vision metaphor.
- **Insects & Bugs pack** (`insects_bugs.json`) — 60 items: insect
  anatomy (٦ legs, exoskeleton), insects vs arachnids, bees (waggle
  dance, hive roles), ants (colonies, pheromones), butterfly
  metamorphosis (monarch ٣٢٠٠ km), beetles, dragonflies, hygiene
  around mosquitoes/flies, beneficial insects, **Surah An-Naml ٢٧
  ant story** with Sulaiman A.S., **Surah An-Nahl ١٦ ٦٨-٦٩ honey as
  healing**, entomologists Maria Sibylla Merian (١٧٠٥) and Fabre,
  camouflage adaptations.
- **Female Scholars & Pioneers pack** (`female_scholars_pioneers.json`)
  — 60 items: Khadija (RA), Aisha (RA) ٢٢١٠+ hadiths, Fatimah al-Fihri
  founded Al-Qarawiyyin Fes ٨٥٩م, Sutayta al-Mahamali (١٠th c.
  mathematician), Lubna of Córdoba, Mariam al-Asturlabi, Hypatia,
  Marie Curie (٢ Nobels), Ada Lovelace ١٨٤٣, Grace Hopper, Hedy
  Lamarr (Wi-Fi precursor patent ١٩٤٢), Rosalind Franklin Photo ٥١,
  Katherine Johnson NASA, Maryam Mirzakhani Fields ٢٠١٤, Tu Youyou
  ٢٠١٥, Wangari Maathai, Malala ٢٠١٤, Stephanie Kwolek (Kevlar
  ١٩٦٥), Sameera Moussa.
- **Tower of Hanoi mini-game** (`/hanoi`) — drag disks across ٣ pegs
  toward the goal column without ever placing larger on smaller. ٣/
  ٤/٥/٦ disk modes via choice chips. Optimal-move counter (٢^n - ١).
  +٢🪙 first 3-disk solve, +٥🪙 4-disk, +١٠🪙 5-disk. Surfaced as 🗼
  home pill.

### Changed
- General Quiz pool now mixes 55 bilingual extras packs (~3,360+
  items before base set), home shows 26 mini-games.

## 1.1.28 — 2026-05-05 — Wave 25

### Added
- **Modern Tech Basics pack** (`modern_tech_basics.json`) — 60 items:
  internet plumbing (URL/HTTP/DNS, IP, packets), browsers, search engines,
  cloud computing, smartphones (CPU, battery, GPS, NFC), Wi-Fi vs cellular,
  USB-C, Bluetooth, smart home, wearables, e-payments, Kuwait digital
  services (Sahel, MyID, KNET), digital citizenship, and tech literacy.
- **Human Brain pack** (`human_brain.json`) — 60 items: neuroanatomy
  (cerebrum, cerebellum, brain stem), lobes & function (frontal/parietal/
  temporal/occipital), neurons & synapses, neurotransmitters at kid level
  (dopamine, serotonin), memory (short-term/long-term/working), sleep &
  brain health, learning & neuroplasticity, famous neuroscientists
  (Cajal Nobel ١٩٠٦, Ibn al-Haytham vision/perception), brain myths
  busted (10% myth), and habits that grow the brain.
- **Climate Change for Kids pack** (`climate_change_kids.json`) — 60
  items: greenhouse gases (CO٢, methane), climate vs weather, fossil
  fuels, renewable energy (solar, wind, hydro, geothermal), carbon
  footprint, deforestation & reforestation, polar ice & sea levels,
  extreme weather links, COP meetings, IPCC, Kuwait climate (heat waves
  ٥٠°C+ summers), kid actions (recycle, reduce, reuse), and famous
  voices (Wangari Maathai, Greta Thunberg, David Attenborough).
- **Simon Says mini-game** (`/simon-says`) — watch a sequence of 4
  colored pads light up, then tap them back in order. Sequence grows
  by ١ each round. Earn +٢🪙 at round ٥, +٥🪙 at round ٨, +١٠🪙 at
  round ١٢. Surfaced as 🟥 home pill.

### Changed
- General Quiz pool now mixes 52 bilingual extras packs (~3,180+ items
  before base set), reaching 25 mini-games on the home screen.

## 1.1.27 — 2026-05-05 — Wave 24

### Added
- **Entrepreneurship for Kids pack** (`entrepreneurship_kids.json`) — 60
  items: business basics (revenue/cost/profit), money basics, problem
  solving (MVP, customer feedback), famous founders (Jobs, Disney, Ford,
  Mary Kay, Oprah, Bezos garage, Khalifa bin Zayed), marketing, **money
  & Islam** (kasb halal, no riba, zakat ٢٫٥%, As-Sadiq Al-Amin honest
  trade, contracts Surah Al-Ma'idah ٥), saving & investing (compound
  growth at age-level, diversification), soft skills, and real kid
  founders (Mikaila Ulmer, Moziah Bridges, Maya Penn).
- **Maps & Cartography pack** (`maps_cartography.json`) — 60 items:
  map basics (compass rose, latitude/longitude, prime meridian),
  projections (Mercator, Peters), GPS (٢٤+ satellites, ٤ for fix),
  famous historical maps (Babylonian Imago Mundi ٦th BCE, Al-Idrisi's
  Tabula Rogeriana ١١٥٤, Mercator ١٥٦٩, Beck Tube map ١٩٣٣), navigation
  (qibla compass, sextant, dead reckoning), continents/oceans, exonym
  vs endonym (Al-Quds/Jerusalem), reading coordinates (Mecca, Kuwait
  City), modern tech (OpenStreetMap, what3words, drone mapping).
- **Robotics & AI for Kids pack** (`robotics_ai_kids.json`) — 60 items:
  robot anatomy (sensors/brain/actuators), famous robots (Curiosity,
  Perseverance + Ingenuity, ASIMO, Boston Dynamics), AI basics (narrow
  vs general, training data, supervised/unsupervised, neural networks),
  famous AI moments (Deep Blue ١٩٩٧, AlphaGo ٢٠١٦, ChatGPT era ٢٠٢٢),
  robot types, sensors & actuators, programming (Scratch, Python),
  ethics (bias in training data, deepfakes, AI for good), and **AI in
  Islam context** (verify religious info from AI, scholars' role
  unchanged, "ask the people of knowledge" Surah An-Nahl ١٦:٤٣).

### Added (mini-game)
- **Whack-a-Mole** (🦫 home pill, route `/whack-a-mole`) — 3×3 grid,
  ٤٥-second round. Moles 🦫 = +١, bombs 💣 = −٥. Pace increases as
  the timer runs down (٨٠٠ms → ٤٥٠ms intervals). +٢🪙 finish, +٥🪙
  score ≥ ٢٥.

### Content totals
- General Knowledge merge pipeline: 52 extras packs (3,120+ entries).
- 12 mini-games now: Tic-Tac-Toe, Memory Match, Sudoku, Snake, Connect
  Four, Crossword, 2048, Lights Out, 15-Puzzle, Reaction Time, Color
  Match, Whack-a-Mole.
- All bilingual invariants verified by `scripts/validate_quiz_packs.py`.

## 1.1.26 — 2026-05-05 — Wave 23

### Added
- **Emotional Intelligence pack** (`emotional_intelligence.json`) — 60
  items: naming emotions, recognizing triggers (HALT, body signals),
  self-regulation (4-7-8 breathing, anger hadith "if angry sit/lie
  down"), empathy, social skills, friendships (perfume-seller hadith),
  family dynamics (ihsan to parents Al-Isra ١٧:٢٣), mental health
  awareness (you're not alone, feelings can change, tell a trusted
  adult). Every item framed to leave the kid feeling capable.
- **Inventions of Antiquity pack** (`inventions_antiquity.json`) — 60
  items: Stone Age & early tools (fire control ٧٩٠٬٠٠٠ years ago),
  Mesopotamian (wheel ٣٥٠٠ BCE, cuneiform), Egyptian (papyrus, ٣٦٥-day
  calendar), Indus Valley (urban grid, drainage at Mohenjo-Daro),
  Ancient China (paper Cai Lun, gunpowder, compass, silk, abacus),
  Ancient Greece (Archimedes' screw, Antikythera mechanism), Roman
  engineering (concrete lasted ٢٠٠٠ years, aqueducts, hypocaust),
  pre-Columbian Americas (Maya zero, Aztec aqueducts, Inca terraces),
  Africa (Nubian pyramids, Aksum stelae). Companion to existing
  famous_inventions pack.
- **Quran Sciences pack** (`quran_sciences.json`) — 60 items: 12
  tajweed rules (qalqalah, idgham, ikhfa, iqlab, izhar, makharij,
  ghunna, madd), Hifz tradition, surah counts (١١٤ surahs, ٦٬٢٣٦ ayat,
  longest Al-Baqarah ٢٨٦, shortest Al-Kawthar, longest ayah Ayat
  ad-Dayn ٢٨٢), revelation history (Hira, ٢٣ years), compilation
  (Abu Bakr → Uthman, ٧ ahruf, Hafs from Asim), famous reciters
  (Abdul Basit, Al-Husary, Al-Minshawi, Al-Afasy), the mushaf
  (sajdah ayat, ٦٠٤ pages standard Madinah print), practical etiquette.
  "Scholars discuss" hedges where appropriate.

### Added (mini-game)
- **Color Match (Stroop)** (🎨 home pill, route `/color-match`) —
  read the INK color, ignore the WORD. ٢٠ rounds, ٣s timer per round.
  Trains attention and inhibition. +٢🪙 finish, +٥🪙 score ≥ ١٧/٢٠.

### Content totals
- General Knowledge merge pipeline: 49 extras packs (2,940+ entries).
- 11 mini-games now: Tic-Tac-Toe, Memory Match, Sudoku, Snake, Connect
  Four, Crossword, 2048, Lights Out, 15-Puzzle, Reaction Time, Color
  Match.
- All bilingual invariants verified by `scripts/validate_quiz_packs.py`.

## 1.1.25 — 2026-05-05 — Wave 22

### Added
- **Cybersecurity for Kids pack** (`cybersecurity_kids.json`) — 60 items
  on online safety: strong passwords (≥ ١٢ chars), phishing red flags,
  privacy online (don't share school + phone + photos), stranger
  awareness, malware basics at age-level, Wi-Fi & networks, social
  media (most platforms ١٣+, "permanent posts"), devices & updates, and
  Islamic ethics online (speak good or silent, ٧٠٬٠٠٠ angels watching
  digital actions, ghibah extends to digital).
- **Clouds & Atmosphere pack** (`clouds_atmosphere.json`) — 60 items
  going deeper than weather pack: 5 atmospheric layers, 10 cloud types
  (cumulus/cirrus/stratus/cumulonimbus/lenticular/mammatus/fog), sky
  color (Rayleigh scattering), air composition (N₂ ٧٨%, O₂ ٢١%, Ar ١%),
  atmospheric pressure (sea level ١ atm = ١٠١٬٣٢٥ Pa), humidity & dew,
  wind & pressure systems (jet stream, monsoon), greenhouse effect
  (Earth without atmosphere -١٨°C, with +١٥°C), atmospheric phenomena
  (lightning ٣٠٬٠٠٠°C, sprites & elves, noctilucent clouds).
- **Famous Scientists Deep pack** (`famous_scientists_deep.json`) — 60
  biographical items: Classical era (Aristotle/Archimedes/Euclid/
  Eratosthenes/Ptolemy), 12 Islamic Golden Age figures (Al-Khwarizmi,
  Al-Biruni, Ibn Sina, Ibn al-Haytham, Al-Razi, Al-Zahrawi, Al-Battani,
  Ibn Khaldun, Al-Idrisi, Al-Jazari, Ibn al-Nafis pulmonary circulation,
  House of Wisdom), Renaissance to early modern (Galileo→Pascal),
  18th-19th century (Lavoisier→Curie family), 20th century with
  Rosalind Franklin properly credited for DNA, women scientists
  (Hypatia, Lovelace as first programmer, Katherine Johnson, Vera
  Rubin, Jane Goodall, Mae Jemison), and modern Arab/Muslim scientists
  (Abdus Salam Nobel ١٩٧٩, Ahmed Zewail Nobel ١٩٩٩, ElBaradei Peace
  ٢٠٠٥). Companions to existing famous_inventions pack.

### Added (mini-game)
- **Reaction Time** (⚡ home pill, route `/reaction-time`) — wait for
  green, then tap as fast as you can. ٥ rounds tracked; running list
  of times shown as pills. False starts (tap during red) reset the
  round. +٢🪙 finish, +٥🪙 average ≤ ٣٥٠ms.

### Content totals
- General Knowledge merge pipeline: 46 extras packs (2,760+ entries).
- 10 mini-games now: Tic-Tac-Toe, Memory Match, Sudoku, Snake, Connect
  Four, Crossword, 2048, Lights Out, 15-Puzzle, Reaction Time.
- All bilingual invariants verified by `scripts/validate_quiz_packs.py`.

## 1.1.24 — 2026-05-05 — Wave 21

### Added
- **First Aid Basics pack** (`first_aid_basics.json`) — 60 awareness-only
  items framed as "tell a trusted adult." Calling for help (Kuwait ١١٢,
  US 911, UK 999, Saudi 997), cuts & scrapes, burns (٠ ice / ٠ butter,
  cool water ١٠ minutes), choking/Heimlich (adult action), bleeding,
  bites & stings, RICE for sprains, allergic reactions, CPR awareness,
  mental/emotional first aid (panic breathing, hadith on visiting the
  sick — ٧٠٬٠٠٠ angels), home safety. Heimlich/CPR/EpiPen explicitly
  framed as "what trained adults do."
- **Rivers & Lakes pack** (`rivers_lakes.json`) — 60 items: famous
  rivers (Nile ٦٬٦٥٠ km, Amazon by volume, Yangtze, Yellow, Tigris &
  Euphrates), lake records (Caspian, Baikal ١٬٦٤٢m holding ٢٠% of
  freshwater, Dead Sea, Aral), river systems & deltas, Wadis & Arabian
  water (Wadi Hanifa, Wadi Al-Batin, qanat, falaj), lakes-by-type,
  rivers in history, conservation (Sunnah on not wasting water at a
  river), water in the Quran (Al-Anbiya ٢١:٣٠, Ar-Rahman ٥٥, Al-Kawthar
  ١٠٨, Al-Furqan ٢٥, Maryam, Hud).
- **Periodic Elements pack** (`periodic_elements.json`) — 60 items
  going deeper than chemistry_deep.json: elements 1–10 with symbols,
  common metals (Fe/Cu/Al/Au/Hg liquid metal), noble gases, halogens,
  alkali metals, discovery history (Marie Curie, Hennig Brand, helium
  on the sun), elements in the body (oxygen most by mass, calcium for
  bones, iodine for thyroid), cool facts (gallium melts in your hand
  ٢٩.٧٦°C, francium rarest, hydrogen most abundant in universe), table
  structure (groups, periods, lanthanides, actinides).

### Added (mini-game)
- **15-Puzzle** (🔢 home pill, route `/15-puzzle`) — 4×4 sliding-tile
  classic. Scrambled by 60 random valid moves so every puzzle is
  guaranteed solvable. Tiles glow gold when in their correct position.
  +٢🪙 solve, +٥🪙 in fewer than 100 moves.

### Content totals
- General Knowledge merge pipeline: 43 extras packs (2,580+ entries).
- 9 mini-games now: Tic-Tac-Toe, Memory Match, Sudoku, Snake, Connect
  Four, Crossword, 2048, Lights Out, 15-Puzzle.
- All bilingual invariants verified by `scripts/validate_quiz_packs.py`.

## 1.1.23 — 2026-05-05 — Wave 20

### Added
- **Architecture Marvels pack** (`architecture_marvels.json`) — 60 items
  across Ancient Wonders, Islamic Architecture (Haram/Nabawi/Dome of the
  Rock/Alhambra/Sheikh Zayed/Sultan Qaboos/Taj Mahal/Mezquita), Modern
  Skyscrapers (Burj Khalifa ٨٢٨م, Merdeka ١١٨), Bridges (incl. Sheikh
  Jaber Causeway Kuwait), Cathedrals & Temples, Engineering Feats
  (canals, dams, Channel Tunnel, ITER), Architectural Styles, Sustainable
  & Smart (LEED, Masdar City, NEOM).
- **Famous Experiments pack** (`famous_experiments.json`) — 60 items
  covering Galileo→Einstein in physics, Lavoisier→Mendeleev→Rutherford,
  Mendel/DNA/Pasteur/Fleming/Darwin/CRISPR, Pavlov & Skinner, Foucault
  to Hubble, scientific misconceptions corrected, and 8 items on the
  Muslim era (Ibn al-Haytham as Father of Optics, Al-Biruni's Earth
  radius ١٠١٨م, Al-Khwarizmi, Al-Razi distillation, Al-Zahrawi
  surgery, Ibn Sina, Banu Musa, Al-Jahiz precursor to natural selection).
- **Chess Fundamentals pack** (`chess_fundamentals.json`) — 60 items:
  pieces & movement, special rules (en passant, castling, 50-move,
  draws), algebraic notation, 10 tactics (fork/pin/skewer/discovered
  attack/decoy), openings overview, endgame basics, famous players
  (Carlsen, Kasparov, Hou Yifan, Ding, Fischer, Deep Blue ١٩٩٧), chess
  in Islamic culture (Al-Adli's 9th-century treatise, Persian→Arabic
  route الشطرنج).

### Changed
- **Adaptive Bloom-level ordering helper** — new
  `lib/core/utils/bloom_ordering.dart` exposes `orderByBloom(entries)`
  that scaffolds learners remember → understand → apply within a
  session. Items without scaffolding fall through to plain difficulty
  ordering. Foundation for future quiz flows.

### Added (mini-game)
- **Lights Out 5×5** (💡 home pill, route `/lights-out`) — toggle
  cells (self + orthogonal neighbours) to turn every light off.
  Solvable scrambles via 5–8 random presses. +٢🪙 solve, +٥🪙 if
  solved within scramble + 2 moves.

### Content totals
- General Knowledge merge pipeline: 40 extras packs (2,400+ entries).
- 8 mini-games now: Tic-Tac-Toe, Memory Match, Sudoku, Snake, Connect
  Four, Crossword, 2048, Lights Out.
- All bilingual invariants verified by `scripts/validate_quiz_packs.py`.

## 1.1.22 — 2026-05-05 — Wave 19

### Added
- **World Mythology pack** (`world_mythology.json`) — 60 bilingual items
  framed as cultural storytelling/literary heritage (NOT theology):
  Greek (Zeus, Heracles, Trojan horse, Pegasus, Medusa), Roman
  adaptations (Jupiter=Zeus), Norse (Mjolnir, Yggdrasil, Ragnarok),
  Egyptian (Ra, Anubis, Bastet, Thoth), Chinese & Japanese (Sun
  Wukong, Amaterasu, kami), Native American (Coyote, Thunderbird —
  presented respectfully), Mesopotamian (Gilgamesh, Marduk), pre-Islamic
  Arabian folklore (jinn-as-folk-tale, Antarah, Roc, Sindbad — explicitly
  flagged as folk tales, not religious teaching), comparative themes
  (flood myths, hero's journey, world-tree).
- **Oceanography pack** (`oceanography.json`) — 60 items: ocean
  geography (Pacific largest, Mariana ١١٬٠٣٤m, Arabian Sea), tides &
  waves, ocean zones (sunlight→hadal), marine life (blue whale ٣٠m
  ٢٠٠tons, jellyfish ٩٥% water, octopus 9 brains), coral reefs (Great
  Barrier Reef, ٢٥% of marine life, bleaching, zooxanthellae), currents
  & climate, pollution & conservation (الإسراف Sunnah), famous explorers
  (Cousteau, Cameron's ٢٠١٢ Mariana dive, Sylvia Earle), Quran on the
  sea (Ar-Rahman ٥٥, An-Nahl ١٦, Yunus, Ash-Shu'ara ٢٦, Fatir ٣٥).
- **Logic & Critical Thinking pack** (`logic_critical_thinking.json`) —
  60 items going deeper than the Brain Boost logic packs: formal
  reasoning (modus ponens/tollens, contrapositive), 8 common fallacies,
  truth tables, set theory & Venn diagrams, probability fundamentals
  (Gambler's fallacy), critical reading, source evaluation (with
  تَبَيَّنُوا principle), decision-making (pros/cons, sunk cost,
  الأناة hadith on patience). **First pack to ship the new schema
  scaffolding** — every item carries `objective` and `bloom_level`
  ('remember' / 'understand' / 'apply') for the future adaptive engine.
- **2048 mini-game** (🔟 home pill, route `/2048`) — 4×4 sliding tile
  puzzle. Swipe + arrow keys (web). Bilingual digits in tiles.
  +٢🪙 each ٢٥٦+ doubling, +٥🪙 first 1024, +١٠🪙 reaching 2048.

### Changed
- **`GeneralQuizEntry` schema extended** with optional `objective` and
  `bloomLevel` fields. Backwards-compatible — existing 33 packs continue
  to load unchanged. New packs may include them; the future adaptive
  engine will sort by Bloom level for spaced repetition.

### Content totals
- General Knowledge merge pipeline: 37 extras packs (2,220+ entries).
- 7 mini-games now: Tic-Tac-Toe, Memory Match, Sudoku, Snake, Connect
  Four, Crossword, 2048.
- All bilingual invariants verified by `scripts/validate_quiz_packs.py`.

## 1.1.21 — 2026-05-04 — Wave 18 (Store-Launch Foundation)

### Added
- **Body Anatomy pack** (`body_anatomy.json`) — 60 bilingual items across
  skeletal (٢٠٦ bones), muscular (٦٠٠ muscles), circulatory (٤ chambers,
  ٧٠ bpm), respiratory (٢٠٬٠٠٠ breaths/day), digestive (stomach pH ١-٢,
  small intestine ٦m), nervous (٨٦ billion neurons), senses, and Body
  Wonders (Surah At-Tin "best form" framing).
- **Kuwait Heritage pack** (`kuwait_heritage.json`) — 60 items: geography
  & symbols (capital, area ١٧٬٨١٨ km², flag, بلبل، الأرفج), history
  before 1961 (Bani Utub ١٧١٦, Sabah dynasty ١٧٥٢, Mubarak Al-Kabeer,
  pearl-diving era), independence & liberation (١٩٦١، ١٩٩٠، ١٩٩١),
  pearl-diving heritage (نهام، نوخذة، محمل), traditional foods
  (مجبوس، قبوط، هريس، چباب، قرص عقيلي), cultural heritage (الديوانية،
  بشت، قرقيعان، السدو UNESCO، الصقارة UNESCO), modern landmarks (أبراج
  الكويت ١٩٧٧، برج التحرير، Mubarakiya). Flagship local pack.
- **Sign Language pack** (`sign_language.json`) — 60 items covering ASL
  alphabet & common signs, Arabic Sign Language (ALECSO Unified ArSL),
  famous Deaf people (Helen Keller, Beethoven, Marlee Matlin, Nyle
  DiMarco), inclusion etiquette, Deaf culture (capital-D Deaf, deaf gain,
  Deaf President Now ١٩٨٨ Gallaudet), hearing anatomy. Frames deafness
  positively as Deaf gain, not loss.
- **Crossword 7×7 mini-game** (🧩 home pill, route `/crossword`) —
  pre-baked English 7×7 (Lion / Nile / Lamp / Star / Moon) and Arabic 5×5
  (قمر / روضة / واضح). Tap-to-select cell + on-screen keyboard with
  haptic feedback. +٢🪙 per word, +٥🪙 perfect grid.

### Changed (Wave 18 launch foundation)
- **Streak flame on coin pill** — home AppBar's coin pill now displays
  the live Brain Boost daily streak as `🪙 N · 🔥 Md`. Surfaces a
  retention signal pre-tap. Hidden when streak == 0.
- **Memoized General Knowledge pool** — new
  `lib/core/providers/general_quiz_pool_provider.dart` caches the 31-pack
  merged list at session scope. Eliminates the repeated `rootBundle.load`
  + decode + dedup walk on every entry into the General Knowledge flow.
- **Honorific helper** — new `lib/core/utils/honorifics.dart` centralizes
  prophet honorifics (`ﷺ` for Muhammad, `عليه السلام` for others,
  `عليهم السلام` for plurals) plus a standardized `quranCitation()`
  template. Lets future PRs normalize wording across all packs from one
  place.

### Audit notes (Multi-Agent Board Wave 18)
Items already present in the codebase that the audit critique
incorrectly listed as "missing":
- Privacy/About routes — present at `/privacy`, `/about`.
- "Reset all data" affordance — exists in Parent screen; wipes all
  SharedPreferences + resets coin/cosmetics/learner state.
- Onboarding screen — present at first-launch (language → name →
  age band → avatar).
- Lifeline economy — `LifelineCost` system already wires hint / 50-50 /
  skip purchases against the coin balance.
- Vercel cache headers — `vercel.json` already sets `max-age=31536000,
  immutable` for canvaskit/assets and `no-cache` for index.html.
- Haptics — `HapticFeedback.lightImpact` already wired on shop tiles.

### Content totals
- General Knowledge merge pipeline: 34 extras packs (2,040+ entries).
- 6 mini-games now: Tic-Tac-Toe, Memory Match, Sudoku, Snake, Connect
  Four, Crossword.
- All bilingual invariants verified by `scripts/validate_quiz_packs.py`.

### External (cannot ship from code alone)
The following Wave 18 P0/P1 items remain owned by you, the maintainer,
since they require assets I don't have or external submissions:
- Cairo-Bold.ttf + Tajawal-Regular.ttf font assets (drop into
  `assets/fonts/` and add to pubspec — pipeline already accepts them)
- Apple Privacy Nutrition Label JSON + Google Designed-for-Families form
- iOS/Android native shells (`flutter create --platforms=ios,android` on
  a Mac/Android Studio host) + 12-size app icons + splash assets
- Vendored offline tile pack (~12 MB, replaces `flutter_map` OSM fetch)
- Lottie thumbnail animations for the categorized home grid
- Lighthouse re-baseline run after this deploy

## 1.1.20 — 2026-05-04

### Added
- **Arabic Poetry & Literature pack** (`arabic_poetry_literature.json`) —
  60 bilingual items across pre-Islamic & Mu'allaqat (Imru' al-Qais,
  Antarah, Zuhayr, Ukaz market), famous Arab poets (Al-Mutanabbi, Hafiz
  Ibrahim, Ahmed Shawqi أمير الشعراء, Darwish, Qabbani, Abu Madi),
  poetic forms (qasidah, ghazal, rubaiyat, zajal, muwashshah, Al-Khalil's
  metres), famous books (One Thousand and One Nights, Kalila wa Dimna,
  Maqamat of Al-Hariri & Al-Hamadhani, Cairo trilogy, Tayyeb Saleh,
  Kanafani), Mahfouz Nobel ١٩٨٨م, folk tales (Antar, Juha, Sindbad,
  Hatim al-Tai), calligraphy/letters in poetry, children's lit (Kamel
  Kilani, Majallat Sindbad ١٩٥٢م).
- **Dinosaurs & Prehistoric pack** (`dinosaurs_prehistoric.json`) — 60
  items across famous dinosaurs (T. rex, Triceratops, Velociraptor,
  Stegosaurus, Spinosaurus largest carnivore), eras (Triassic/Jurassic/
  Cretaceous), diets, K-Pg extinction (Chicxulub asteroid in Yucatán,
  ٦٦ million years ago), fossils & paleontology (Sue, Lucy, Mary Anning),
  other prehistoric animals (mammoth, Smilodon, megalodon, Quetzalcoatlus),
  modern discoveries (feathered dinos, Spinosaurus aquatic clues), and
  Pangaea distributions.
- **Weather & Natural Phenomena pack** (`weather_natural_phenomena.json`)
  — 60 items: cloud types, storms (hurricane/typhoon/cyclone naming,
  haboob, shamal), lightning ٣٠٬٠٠٠°C with du'a for thunder & rain
  (Sunnah anchors), water cycle, climate zones (Empty Quarter), natural
  disasters, sky phenomena (rainbow, moon halo, aurora, mirage, sun
  pillars, sundogs), greenhouse effect, ozone, Quran on mountains as
  stakes (Surah An-Naba), planting hadith.
- **Connect Four mini-game** (🔴 home pill, route `/connect-four`) —
  7×6 board vs CPU. Easy random / Medium block-or-win + centre bias /
  Hard depth-4 minimax with alpha-beta. Tracks W/L/D. +٢🪙 win, +١🪙
  draw.

### Content totals
- General Knowledge merge pipeline: 31 extras packs (1,860+ entries).
- 5 mini-games now: Tic-Tac-Toe, Memory Match, Sudoku, Snake, Connect Four.
- All bilingual invariants verified by `scripts/validate_quiz_packs.py`.

## 1.1.19 — 2026-05-04

### Added
- **Cooking & Nutrition pack** (`cooking_nutrition.json`) — 60 bilingual
  items across 8 categories: food groups, cooking methods, kitchen tools,
  world cuisines (machboos Kuwait, kabsa Saudi, biryani, tagine), Halal &
  Tayyib (Bismillah, eating with right hand, no-waste hadith,
  "kul mimma yaleek"), nutrition science, food safety (٢٠-second handwash,
  ٤°C fridge), famous sweets (qatayef, baklava, halwa, dates, Arabic
  coffee).
- **Music & Instruments pack** (`music_instruments.json`) — 60 items:
  instrument families, specific instruments, Arabic & Middle-Eastern
  instruments (oud العود, qanun القانون, ney الناي, darbuka, riq, daf,
  mizmar), music theory (scales/tempo/beat/melody/chord/rest), composers
  (Mozart, Beethoven, Bach, Chopin), world music (sitar, koto, kalimba,
  didgeridoo, kora), voice ranges. Tilawah kept separate from music.
- **Quran Prophet Stories pack** (`quran_prophet_stories.json`) — 60
  items covering Adam, Nuh, Ibrahim, Yusuf, Musa, Isa, Sulayman, Yunus,
  Ayyub, Lut, and Saleh/Hud/Shu'ayb (عليهم السلام) — all sourced from
  Quran or authentic hadith with surah/ayah references in fun facts. No
  Israeliyyat. Complements existing sirah_prophets.json (Muhammad ﷺ).
- **Snake mini-game** (🐍 home pill, route `/snake`) — classic 15×15
  grid, eat 20 apples to win. Swipe gestures + on-screen D-pad + arrow
  keys (web). +١🪙 every 5 fruits, +٥🪙 perfect run.

### Content totals
- General Knowledge merge pipeline: 28 extras packs (1,680+ entries).
- 4 mini-games now: Tic-Tac-Toe, Memory Match, Sudoku, Snake.
- All bilingual invariants verified by `scripts/validate_quiz_packs.py`.

## 1.1.18 — 2026-05-04

### Added
- **World History pack** (`world_history.json`) — 60 bilingual items
  across 8 categories: Ancient Civilizations (Mesopotamia, Egypt, Indus,
  China, Maya), Greece & Rome (democracy, Olympics, Caesar), Medieval Era
  (knights, Vikings, Magna Carta), Renaissance & Exploration (Da Vinci,
  Gutenberg, Columbus, Magellan), Industrial Revolution (steam, telegraph),
  Modern Era (World Wars at age-appropriate level, moon landing, internet),
  Asian History (Great Wall, Genghis Khan, samurai, Mughal Empire), Africa
  & Americas (Mansa Musa, Aztec/Inca, Mali Empire).
- **Riddles & Puzzles pack** (`riddles_puzzles.json`) — 60 items: classic
  riddles, word play (palindromes/anagrams in both languages — Arabic uses
  language-specific tricks like المشترك اللفظي), logic riddles, math
  riddles, visual/spatial puzzles, animal & nature riddles. Per-language
  riddle pairing where wordplay required.
- **Plants & Botany pack** (`plants_botany.json`) — 60 items across plant
  parts, photosynthesis, trees (date palm/نخلة, sidr, baobab, redwood),
  flowers (jasmine/الياسمين, saffron, lotus, rafflesia), botanical fruits
  vs veggies, desert flora (ghaf/الغاف, succulents, cacti), carnivorous
  plants (Venus flytrap, sundew), and Plants & Islam (dates, fig+olive of
  Surat At-Tin, الحبة السوداء, miswak/Arak, Verse of Light olive, planting
  hadith).
- **Mini Sudoku 4×4** (🔢 home pill, route `/sudoku`) — fills 1–4 across
  rows, columns, and 2×2 boxes. 8–9 randomized clues per puzzle from a
  Latin-square solution permuted for variety. Conflict detection with red
  highlighting. Hint button reveals one cell. +٨🪙 perfect solve, +٣🪙
  if any hint was used.

### Content totals
- General Knowledge merge pipeline: 25 extras packs (1,500+ entries).
- All bilingual invariants verified by `scripts/validate_quiz_packs.py`.

## 1.1.17 — 2026-05-04

### Added
- **Chemistry Deep-Dive pack** (`chemistry_deep.json`) — 60 bilingual items
  across 9 categories: atoms & subatomic particles, periodic table groups,
  states of matter & phase changes, common compounds (H₂O/CO₂/NaCl/CH₄),
  chemical reactions, acids/bases & pH, organic chem basics, lab safety,
  Islamic-world chemists (Jabir ibn Hayyan as father of chemistry,
  Al-Razi's contributions to alchemy→chemistry).
- **Astronomy & Space pack** (`astronomy_space.json`) — 60 items across
  10 categories: solar system, stars & galaxies, moon phases, eclipses,
  constellations (incl. Arabic-named stars), space exploration, telescopes,
  black holes & nebulae, the Hubble/JWST, and Muslim astronomers
  (Al-Battani's solar year, Al-Sufi's Book of Fixed Stars, Ulugh Beg's
  observatory).
- **Famous Inventions pack** (`famous_inventions.json`) — 60 items across
  8 categories: ancient inventions, transportation, communication,
  medicine, everyday tools, computing, energy, and 17 entries dedicated
  to Islamic-world inventors (Al-Jazari's automata, Al-Zahrawi's surgical
  tools, Ibn al-Haytham's optics/camera obscura, Al-Khwarizmi's
  algorithms, Banu Musa brothers, coffee origin, the astrolabe).
- **Tic-Tac-Toe vs CPU mini-game** (❌ home pill, route `/tic-tac-toe`) —
  3 difficulties: Easy random, Medium block-or-win heuristic, Hard
  unbeatable minimax. Tracks W/L/D session counters. +٢🪙 per win,
  +١🪙 per draw.
- **Memory Match mini-game** (🃏 home pill, route `/memory-match`) —
  3×4 grid, 6 emoji pairs from a curated 18-emoji pool. Tap-to-flip with
  700ms peek-back on mismatch. Tracks moves and matches. +١🪙 per match,
  +٥🪙 perfect run bonus.

### Content totals
- General Knowledge merge pipeline: 22 extras packs (1,320+ entries).
- All bilingual invariants verified by `scripts/validate_quiz_packs.py`.

## 1.1.16 — 2026-05-04

### Added
- **Coding for Kids pack** (`coding_for_kids.json`) — 60 bilingual items
  across Algorithms, Scratch-style Blocks, Python (print/range/list/len),
  Web (HTML/CSS), Debugging, CS Concepts (binary, RAM, CPU, IP), kid-AI.
  References Al-Khwarizmi as "father of algorithms".
- **Art & Culture pack** (`art_culture.json`) — 60 items: color theory,
  mediums, famous artists (Da Vinci/Picasso/Van Gogh), Islamic art (girih,
  arabesque, Kufic/Naskh/Thuluth/Diwani/Ruq'a calligraphy), architecture
  (Alhambra, Taj Mahal, Hagia Sophia, Petra), instrument families (oud,
  qanun, tabla, ney), world cuisines & festivals.
- **Sports & Games pack** (`sports_games.json`) — 60 items: football
  (Qatar ٢٠٢٢), basketball, tennis (love/15/30/40), Olympics, chess,
  backgammon (طاولة), traditional games (kabaddi, falconry, camel
  racing), kid-safe esports, healthy play. No gambling content.
- **Word Search mini-game** (🔡 home pill, route `/word-search`) —
  pure-Dart 8×8 grid generator, 5 themed puzzles (Animals/Fruits/Body/
  Colors/Sky), tap-cells-then-commit, +٢🪙 per word, +٥🪙 perfect.



### Added
- **Financial Literacy pack** (`financial_literacy.json`) — 60 bilingual
  items across Money, Saving, Spending, Earning, Budget, Charity,
  Investing, Islamic Finance (Zakat 2.5%, sadaqah jariyah, riba
  principle, israaf, halal income).
- **Health & Body pack** (`health_body.json`) — 60 items: skeleton,
  muscles, organs, 5 senses, hygiene (20-second handwash, wudu/siwak
  fitra), nutrition + 8 cups water, sleep 9–11 hours, exercise 60 min,
  fever ٣٧٫٥°C, mental health basics, Sunnah anchors (third-stomach
  hadith, "strong believer" hadith).
- **Environment & Sustainability pack**
  (`environment_sustainability.json`) — 60 items across Recycling 3Rs,
  Energy renewable/non, Water cycle + conservation, Climate, Wildlife,
  Pollution, Stewardship/Khilafah (Prophet ﷺ's tree-planting hadith,
  Sa'd's wudu beside a river, cat-starvation hadith), Lifestyle.
- **Smart Quiz** (🎯 home pill, route `/smart-quiz`) — surfaces the
  weakest module from the rolling skill EMA in `learnerStateProvider`,
  ranks all 9 tracked modules from weakest to strongest, one-tap drill
  routes to that module's quiz.



### Added
- **Asma'ul Husna pack** (`asma_ul_husna.json`) — 60 bilingual items
  drilling 59 unique Names of Allah across 8 themes (Mercy, Power,
  Knowledge, Creation, Sustenance, Forgiveness, Glory, Beauty). Easy
  meaning-matches → hard theme-distinguishers (Ar-Rahman vs Ar-Raheem).
- **Hadith for Kids pack** (`hadith_kids.json`) — 60 authentic-only
  items from Bukhari/Muslim/Tirmidhi/Abu Dawud/Nasa'i/Ibn Majah (sahih +
  hasan grade). Famous narrations: actions-by-intentions, hadith of
  Jibril, seven-shaded-ones, "love for your brother," smiling-as-sadaqah.
- **Islamic History pack** (`islamic_history.json`) — 60 items across
  Rashidun, Umayyad, Abbasid, Andalusia, Ottoman, golden-age Science,
  Culture, Travel. Covers House of Wisdom, al-Qarawiyyin (859), Mehmed
  II's conquest of Constantinople (١٤٥٣), Saladin, Ibn Battuta, Mansa
  Musa, Mongol sack of Baghdad, fall of Granada.
- **Tasbih counter** (🧿 home pill, route `/tasbih`) — digital dhikr
  counter with target-progress ring, 5 phrase presets (سبحان الله /
  الحمد لله / الله أكبر / لا إله إلا الله / أستغفر الله), targets
  33/99/100/1000, lifetime total persistence, AR TTS playback.
- **Activity heatmap** on parent dashboard — 28-day GitHub-style grid
  (4×7) of daily Brain Boost completions, with active-day count.



### Added
- **Fiqh basics pack** (`fiqh_basics.json`) — 60 mainstream Sunni
  consensus items across Wudu, Salah, Fasting, Zakat, Hajj, Halal, Adab.
  Avoids madhab disputes. Auto-merged into General Knowledge.
- **Sirah of the Prophets pack** (`sirah_prophets.json`) — 60 bilingual
  items covering all 25 Qur'an-named prophets (Adam through Muhammad ﷺ),
  with kid-friendly hooks: Nuh's ark, Yunus's whale, Sulayman's ant,
  Ibrahim & the fire, Yusuf in the well, Maryam under the date-palm,
  Cave of Hira, Hijrah, Badr, Khandaq, Conquest, Farewell Hajj. Pure
  Qur'anic + sahih-hadith narratives only.
- **Dua memorization library** (🤲 home pill, route `/dua`) — 60 short
  authentic supplications from Hisn al-Muslim and Qur'anic duas, grouped
  by 9 occasions (Daily/Travel/Weather/Distress/Family/Knowledge/Mosque/
  Quran/Forgiveness). Each card shows full Arabic with diacritics +
  transliteration + English meaning + AR TTS playback.
- **Mood check-in** banner on home — 5-emoji daily picker (😄🙂😐😔😤),
  one-tap to record, last 60 picks persisted. No nags, no streaks.
- **Hijri date pill** in home top section — pure-Dart Umm al-Qura
  conversion already-built; surfaced visibly above the daily verse.



### Added
- **Arabic Grammar pack** (`arabic_grammar.json`) — 60 bilingual items
  across nouns/verbs/particles, إعراب basics (فاعل/مفعول/مبتدأ/خبر/حال),
  gender/number (مفرد/مثنى/جمع, جمع تكسير), tenses (ماضي/مضارع/أمر),
  pronouns متصلة ومنفصلة, definiteness (الـ / تنوين), Form II/VII/X verb
  patterns. Auto-merges into General Knowledge.
- **English Grammar pack** (`english_grammar.json`) — 60 bilingual items
  across parts of speech, articles a/an/the, tenses (simple + continuous
  + perfect), subject-verb agreement, irregular plurals (children/feet/
  mice/people), pronouns, comparatives/superlatives (incl. good→best,
  far→farther), apostrophes, capitalization, common confusions
  (their/there/they're, your/you're, its/it's, then/than).
- **Sciences L6** (`sciences_l6.json`) — 60-item advanced primer for
  ages 13–14 (difficulty 5). Biology (transcription/translation,
  homeostasis, neuron action potential), Chemistry (s/p orbitals, Le
  Chatelier, hydrogen bonding, functional groups), Physics (p=mv,
  projectile motion, simple harmonic motion, Snell, PV=nRT, total
  internal reflection), Earth/Space (Hubble redshift, Big Bang, dark
  matter, supernova types I/II, thermohaline currents). References
  Ibn al-Nafis, Ibn Sina, Jabir, Ibn al-Haytham, Al-Battani,
  Al-Khwarizmi. Sciences pool now **380 items**.
- **Sadaqah Jar** screen at `/sadaqah-jar` (🫙) — gentle visual habit
  tracker for charity-saving. Tap +1/+5/+10/+25 to fill an animated jar
  toward a settable goal. Pure on-device, no real money, no transfers.
- **Brain Boost weekly recap** widget on the parent dashboard — 7-day
  bar strip showing daily-challenge completion + streak count. Reads
  the existing `recentCompletions` history; no new persistence.

## 1.1.11 — 2026-05-03

### Added
- **+90 Brain Boost Memory** (`brain_boost_memory_extra2.json`) — sequence
  recall, anchor inclusion, reverse recall, position recall, grid pattern,
  story recall, double-step recall. Memory pool now **240 items**.
- **+90 Brain Boost Spatial** (`brain_boost_spatial_extra2.json`) —
  rotations, reflections, cube nets (incl. 11-distinct-nets fact), painted
  cubes (2³/3³/4³), paper-fold + hole punch, direction walks, shape
  composition, 3D-from-above, cube-cross-section-hexagon. Spatial pool now
  **240 items**.
- **+60 Brain Boost Mental Math** (`brain_boost_mental_math_extra3.json`)
  — speed arithmetic, 25/50/75% calculations, squares 11²/12², mixed-step
  `(٢٥+٥)×٣`, kg↔g and hour↔min conversions. Mental Math pool now **300**.
- **Vocab Flashcard study mode** at `/vocab-flashcards` — pulls from the
  60-item bilingual `vocabulary.json` pack, tap-to-flip cards with
  category badge, "Got it" / "Review again" decisions, AR TTS on flip.
- **Daily verse banner** on home — pure-Dart deterministic pick of one
  verse per day from `quran_short_surahs.json` (50 verses across 10
  surahs). Tap to open the full Quran screen, or 🔊 to hear the Arabic.



### Added
- **Sciences L5** (`sciences_l5.json`) — 60-item high-school primer tier
  for ages 12–14 across Biology (cell division, genetics + Punnett squares,
  central dogma, enzymes, immune system), Chemistry (balanced equations,
  mole concept, pH, periodic trends, bonding types), Physics (Newton's
  laws applied, V=IR, Faraday/Lenz, wave properties, E=mc²), and
  Earth/Space (plate tectonics, rock cycle, supernova, gravitational
  orbits). Naturally references Ibn Sina, Jabir ibn Hayyan, Ibn al-Haytham,
  Al-Khwarizmi. Sciences pool now 320 items.
- **+60 Brain Boost Logic** items (`brain_boost_logic_extra3.json`) —
  syllogisms, truth-tellers vs. liars, ordering puzzles, mislabeled-box
  riddle, Fibonacci/squares deductions. Logic pool now **300 items**.
- **+60 Brain Boost Patterns** items (`brain_boost_patterns_extra3.json`)
  — squares, cubes, primes, triangular, pronic, Mersenne 2ⁿ−1,
  letter+number combined (A1/B2/C3, Z26/Y25). Patterns pool now **300**.
- **Athkar (📿) screen** at `/athkar` — Morning + Evening tabs of
  canonical short adhkar from Hisn al-Muslim (Ayat al-Kursi, sayyid
  al-istighfar, sub-haan-Allah ×١٠٠, etc.). Per-line 🔊 TTS button +
  tap-counter that locks at the sunnah repeat count. No network.
- **Speed Reading (⚡) drill** at `/speed-reading` — flashes a passage
  one word at a time at 60/120/180/240 wpm, then asks one comprehension
  question. +1🪙 per correct answer.



### Added
- **Geography deep-dive** trivia pack (`geography.json`) — 60 bilingual items
  (20 easy / 20 medium / 20 hard) across 10 categories: Continents, Oceans,
  Currencies, Languages, Mountains, Climate, Rivers, Deserts, Islands, Lakes.
  Auto-merges into General Knowledge. Numeric facts spelled in Arabic words
  to satisfy the no-Latin-digit rule.
- **+20 Reading Zone passages** (`learning_zone_extra2.json`) — 20 new
  bilingual stories, 3 comprehension questions each, ~80–150 words. ≥4
  stories with Islamic-cultural anchoring (first fast / sadaqah / neighbour
  rights / shukr / ethical trade). Reading Zone now 40 passages total.
- **+60 Brain Boost Analogies** items (`brain_boost_analogies_extra3.json`)
  — country:capital, life-cycle, instrument:scientist, antonyms/synonyms,
  cause:effect, container:contents, etc. Analogies pool now **300 items**.
- **Curriculum alignment view** (`/parent/curriculum`) — parent-facing
  reference mapping every Aziz Academy module to school grade bands
  (KG–G6) and subject categories (Math, Science, Reading, Geography,
  Islamic Studies, Thinking Skills, Parent Tools). Each row taps through
  to the relevant module. Indicative — curricula vary by country.
- **Ramadan countdown pill** in home header — pure-Dart Hijri-date
  calculation. Shows "Ramadan day N" inside Ramadan, "N days to Ramadan"
  within 60 days, Eid al-Fitr / Eid al-Adha badges within their windows.
  No notifications, no permissions, no network.

## 1.1.8 — 2026-05-03

### Added
- **Arabic Alphabet trainer** (🔤 home pill, route `/alphabet`) — 28-letter
  grid; tap a letter to hear it via TTS, see an example word + meaning.
- **Prayer Times screen** (🕌 home pill, route `/prayer-times`) — pure-Dart
  astronomical solar math, Umm al-Qura method by default, 14 preset cities
  (Makkah, Madinah, Riyadh, Jeddah, Dammam, Cairo, Istanbul, Dubai, Doha,
  Kuwait, Manama, Karachi, London, NY). Banner: "approximate, always
  confirm with your local masjid."
- `lib/core/utils/prayer_times.dart` — pure-Dart `PrayerTimes.compute(...)`
  helper. No network, no platform plugins. ±2 minute typical accuracy.
- **+60 animals & nature** trivia pack (`animals_nature.json`) — animal
  sounds, habitat, diet, baby animals, body parts, plants, trees, birds,
  insects, sea life, reptiles, mammals. Auto-merges into General Knowledge.

## 1.1.7 — 2026-05-03

### Added
- **Times Tables drill** (✖️ home pill, route `/times-tables`) — pick a table
  1..12, run a 20-question speed drill. 1 coin per correct answer, +5 coin
  mastery bonus on a perfect run. No lives, no game-over — just fluency.
- **+5 short surahs** appended to the Quran pack: Al-Kawthar, Al-Asr,
  Al-Quraish, Al-Maun, Al-Kafirun. Pack now has 10 surahs / 50 verses /
  40 memorization questions.
- **+60 famous-landmarks** pack (`landmarks.json`) — Europe / Middle East /
  Asia / Americas / Africa / Oceania, with 14+ Islamic-world landmarks for
  cultural relevance. Auto-merged into General Knowledge.
- **+60 historical-figures** pack (`historical_figures.json`) — Inventors,
  Scientists, Explorers, Leaders, Writers, Islamic_Scholars (16+ Islamic
  scholars: Ibn Sina, Al-Khwarizmi, Ibn al-Haytham, Ibn Battuta, Salah
  ad-Din, Al-Razi, Ibn Khaldun, Al-Biruni, Jabir ibn Hayyan, etc.). Also
  auto-merges into General Knowledge.
- **`HijriDate`** pure-Dart Umm al-Qura tabular calculator + `HijriDatePill`
  widget at `lib/core/utils/hijri_date.dart`. Ready to drop into any
  screen header for a Hijri date stamp; no network, no platform code.

## 1.1.6 — 2026-05-03

### Added
- **Printable worksheet generator** — `/parent/worksheet`. Parent picks a
  topic, gets 10 randomized questions + answer key in a paper-style layout,
  shares as PNG via the system sheet (works on web, iOS, Android).
- **Compare siblings dashboard** — `/parent/family-compare`. Side-by-side
  cards for every family-profile slot (avatar, name, age, active flag) with
  a banner clarifying that coins/streak/sessions are shared on-device.
- **Avatar outfits shop** — six cosmetic outfits (👑 crown 200🪙, 🦸 cape
  150🪙, 🧙 wizard hat 150🪙, 🤓 glasses 80🪙, 🥇 medal 120🪙, 🚀 rocket pack
  250🪙). One-time purchase, equip on the active profile slot. Glyph
  rendered as a small badge over the avatar emoji on the compare view.
- `ProfileSlot.outfitId` — optional cosmetic accessory id, persisted with
  the family-profiles state. Backwards-compatible (null → no badge).
- `FamilyProfilesNotifier.replaceSlots(...)` for atomic multi-slot updates.

## 1.1.5 — 2026-05-03

### Added
- **Short Surahs screen** (`/quran`, 📖 home-pill) — Al-Fatihah, Al-Ikhlas,
  An-Nas, Al-Falaq, Al-Masad. 27 verses with canonical Hafs Arabic +
  diacritics, kid-friendly Sahih-International English meaning, Latin
  transliteration, and a per-verse 🔊 button that uses the device TTS.
  Source pack at `assets/data/quran_short_surahs.json`.
- `QuizQuestion.difficulty` field (defaults to 2) — capitals, sciences,
  logos, general_quiz repositories now propagate per-item difficulty
  through to the shared model.
- **Adaptive ordering wired** into capitals + sciences quiz providers
  (was IQ-only). Reorders the question pool so the band closest to the
  kid's EMA skill on that module lands first; gated by the existing
  `appSettings.adaptiveDifficulty` toggle.

## 1.1.4 — 2026-05-03

### Added
- **Treasure Room** — tap-a-chest coin loot loop with weighted reward tiers
  (10/15/20/30/50/80 coins; long-tail bias). Each chest costs 30 coins to
  open; "new chests" button resets after all three opened. Reachable from
  the home-screen 🎁 pill, route `/treasure`.
- **Widget gallery** dev screen at `/dev/gallery` (not surfaced in nav) —
  renders `CoinCountUpChip`, `Sparkline`, and color-token swatches in
  isolation for visual regression checks.
- `lib/core/utils/adaptive_order.dart` — generic skill-based ordering
  helper extracted from the IQ provider's `_adaptiveOrder`. Ready to wire
  into capitals/flags/math/sciences when their providers are refactored
  to expose per-question difficulty.

### Engineering
- `share_plus` 10.1 → **12.0** (major version). Refactored 8 callsites to
  the new `SharePlus.instance.share(ShareParams(...))` API; deprecation
  warnings for `Share.share`/`shareXFiles` are gone. Held back from 13.x
  because of a `win32` peer-dep conflict with `file_picker` 11.x.

## 1.1.3 — 2026-05-03

### Added
- Daily-login bonus dialog on first home-screen open of the day (10 coins
  baseline, 30 at day 3, 75 at day 7, 250 at day 30 + every 30 thereafter).
  Streak resets on a missed calendar day; pure on-device persistence.
- +60 bilingual math word problems (`math_word_problems.json`) — 20 easy /
  20 medium / 20 hard, mixed across +/-/×/÷, fractions, percentages, time,
  money, geometry, measurement
- +60 bilingual vocabulary items (`vocabulary.json`) — synonyms, antonyms,
  word meaning/roots, idioms, compound words, categories, spelling
- Both new packs auto-merge into `GeneralQuizRepository` with id-dedup, so
  they appear inside General Knowledge gameplay without a new screen
- Full app-icon matrix regenerated from `logo_final.png`: 15 iOS sizes,
  5 Android density buckets (legacy + adaptive foreground), web manifest
  variants + favicon. Adaptive icon background = brand `#0F2445`.
- `web/sitemap.xml` (16 URLs) + `web/robots.txt` for search-engine indexing
- `scripts/generate_icons.py` — reproducible icon-matrix generator from one
  master PNG

### Engineering
- Refactored `GeneralQuizRepository` to support an extras-merge pipeline
  (id-dedup, base + N extras like the IQ/LearningZone repositories already
  use)
- Validator now covers `math_word_problems.json` + `vocabulary.json`

## 1.1.2 — 2026-05-03

### Added
- +90 Brain Boost Spatial items (rotations, reflections, cube nets, painted
  cubes, paper-fold puzzles) → Spatial pool now 150
- +90 Brain Boost Memory items (sequence recall, anchor inclusion, reverse
  recall) → Memory pool now 150
- +10 bilingual Reading Zone passages (`learning_zone_extra.json`) with
  comprehension questions, id-deduped against the base pack
- +150 Spelling pack items (50 easy / 50 medium / 50 hard); spelling now has
  a typed `SpellingRepository` instead of mining other modules at runtime
- On-device-only stats CSV export from Parent Dashboard (no PII, parent shares
  via system share sheet)
- Inline `Sparkline` widget for per-module 14-day skill trend
- End-of-quiz coin reward chip — animated count-up, wired into all 7 quiz
  victory overlays (capitals/flags/logos/math/sciences/IQ/general)
- Streak Freeze ❄️ shop entry (50 coins, EN+AR copy)
- Streak Freeze auto-consumption when missing exactly one Brain Boost day
- Privacy policy expanded with explicit COPPA / GDPR-K / PDPL compliance
  statement, parent rights, and certificate-share clarification

### Engineering
- `flutter_map` 8.2 → 8.3, `go_router` 17.1 → 17.2, transitive bumps
- `gstatic.com` preconnect + DNS-prefetch in index.html (eats the TLS
  handshake before flutter_bootstrap.js requests CanvasKit)
- Lighthouse baseline refreshed against the warm-cache prod (the previous
  capture had an anomalous interactive_ms=351 from a partial run)

### Tooling
- Pre-commit hook (`.githooks/pre-commit`) gating commits on validator +
  `flutter analyze`
- `scripts/watch_packs.sh` for live-validating quiz JSON during authoring
- `store/release_checklist.md` — Android signed AAB, iOS archive, Web deploy

### Web
- Stripped redundant `main.dart.js` / `flutter.js` preloads (loader fetches
  them itself), kept manifest + Cairo font preload
- Added Permissions-Policy + referrer-policy headers in `index.html`

## 1.1.1 — 2026-05-03

### Added
- 60 deeper Sciences L4 items (cell organelles, DNA replication, periodic
  trends, balanced equations, Newton qualitative depth, electromagnetism,
  planet moons, light-years, plate boundaries, soil horizons, biomes)
- Skeleton loading state in Trophy Room
- `precacheHotImages` helper for splash → home transition
- Lighthouse + bundle-audit shell scripts

### Engineering
- First lighthouse pass on prod recorded as baseline
- Image precache wired through splash gesture (no extra latency)

## 1.1.0 — 2026-05-03

### Added
- First-launch onboarding flow (language → name+avatar → age band)
- Family Profiles — up to 4 sibling slots on one device
- Brain Boost: Champion Mode (12-question gauntlet), Daily Challenge with
  streak milestones (3/7/14/30), per-category drill-downs, Spatial + Memory
  reasoning categories, plus 720 hand-curated bilingual items across 6
  categories
- Boss Rush — 12 questions across 3 modules with perfect-run bonus
- Pass and Play — local 2-player versus mode
- Weekly Tournament — device-local family leaderboard
- Achievement Certificate — printable / shareable PNG
- Parent Dashboard upgrades: weekly digest, printable progress report,
  sound volume slider, adaptive-difficulty toggle, larger-text setting
- Madrasati Homework Helper — non-quiz study mode
- Streak Freeze inventory — skip-a-day insurance
- Hint provider — peek-and-strike one wrong option
- 6 new badges (Brain Boost trio + Dragon Slayer + Pass-Play Champion +
  Weekly Champion)
- Adaptive difficulty wiring — Brain Boost biases pool toward kid's EMA skill
- Sciences L2 + L3 packs (90 deeper items for ages 10-12)

### Changed
- IQ section renamed to Brain Boost; UI rebuilt with disclaimer and tour
- Sciences repository now merges L2 + L3 packs with id-dedup
- Achievement state widened with multiplayer / chained-mode stats

### Fixed
- Legacy sciences.json Arabic options/answers converted to Arabic-Indic digits
- share_plus 10.x Share API used (was on incompatible newer API)
- Multiple Brain Boost content fixes (marbles "بلية", verb/noun parallelism)

### Engineering
- JSON schema validator script (`scripts/validate_quiz_packs.py`)
- GitHub Actions CI: validate content + flutter analyze + test + build web
- Unit tests: weekly_tourney, family_profiles, brain_boost_daily, quiz packs
- App store listings (EN + AR), privacy URL, age rating

## 1.0.0+4 — 2026-04-XX
- Initial release with capitals, flags, logos, math, sciences, IQ, blitz,
  survival, daily challenge, shop, parent dashboard, leaderboard.
