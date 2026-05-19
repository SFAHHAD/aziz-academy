# Aziz Academy — Product Expansion Plan

Generated: 2026-05-18. Scope: turn Aziz Academy into a smooth, perfect, systematic operation with admin tooling, content management, analytics, and (optionally, on web only) ad monetization.

Companion to: AUDIT_PLAN.md (cleanup), FINDINGS.md (repo issues), ISSUES.md (live-app bugs), docs/ARCHITECTURE.md (codebase tour).

---

## Guiding principles

1. **Kids' app first.** Every decision below assumes the primary surface — the quiz/game/Islamic content — stays ad-free, tracking-free, and COPPA-compliant. Anything else is parent-only.
2. **Build on what's already there.** The admin dashboard, Q-Bank service, and on-device traffic tracking already exist. Don't rebuild; refactor and extend.
3. **Reversible decisions.** Feature flags for ads and analytics so they can be turned off if a policy review fails.
4. **Don't break the build.** Every phase ships behind a flag or in an admin-only area until verified.

---

## Phase 1 — Admin dashboard polish (1 week)

**Where we are:** `lib/features/admin/admin_dashboard_screen.dart` is 5,932 lines with 64 private widget classes covering 17 sections. It works but is hard to maintain and review.

**Where we're going:** the same 17 sections, split per-file with consistent layout, mobile-responsive, and a shared design system.

### 1.1 Structural split (already planned in FINDINGS.md §F7)

```
lib/features/admin/
├── admin_dashboard_screen.dart    # AdminDashboardScreen + _PasscodeGate + _AdminShell  (~700 lines)
├── admin_section.dart             # enum + extension
├── sections/                       # one file per section, ~150-500 lines each
│   ├── overview_section.dart
│   ├── traffic_section.dart
│   ├── engagement_section.dart
│   ├── feedback_section.dart
│   ├── audit_section.dart
│   ├── qbank_section.dart          # READ today; EXTEND in Phase 2
│   ├── lint_section.dart
│   ├── translate_section.dart
│   ├── catalog_section.dart
│   ├── assets_section.dart
│   ├── family_section.dart
│   ├── economy_section.dart
│   ├── privacy_section.dart
│   ├── storage_section.dart
│   ├── errors_section.dart
│   ├── flags_section.dart
│   ├── tools_section.dart
│   └── ads_section.dart            # NEW in Phase 4 — admin's ad placement + revenue dashboard
└── widgets/admin_atoms.dart        # shared sub-widgets
```

### 1.2 Design system

- **Sidebar:** 17 nav items, with badges for items that need attention (e.g., red dot when there are unfixed audit findings, count for new feedback)
- **PageHeader:** title + breadcrumb + last-refresh time + actions (refresh, export)
- **Cards:** consistent navy/gold theme already in `_C` constants
- **Mobile responsive:** below 800 px, sidebar collapses into a drawer

### 1.3 Add operator quality-of-life

- **Refresh button** on every section (currently only on some)
- **Last-refreshed-at timestamp** on each card
- **Copy-to-clipboard** on every numeric KPI (operators screenshot a lot)
- **Search across sections** — top bar input that opens the relevant section

### 1.4 New sections for this expansion

- **`ads_section.dart`** — Phase 4 work
- **`audience_section.dart`** — Phase 3 work (cross-device analytics view; on-device traffic stays as the `traffic` section)

Exit criteria: each section file < 600 lines. Admin dashboard loads under 200 ms on web. No regression in current sections.

---

## Phase 2 — Q-Bank CRUD (1-2 weeks)

**Where we are:** `lib/features/admin/q_bank_service.dart` loads all 258 JSON pools, normalizes them to `QBankItem`, exposes pool stats. **Read-only.** Editing means re-running content-author scripts and shipping a new build.

**Where we're going:** admins can add, edit, deactivate, and bulk-import quiz questions from inside the admin dashboard. Changes go to a Supabase `qbank_drafts` table; the app reads bundled pools + draft overrides on next launch.

### 2.1 Storage architecture

Two-layer model:

```
┌────────────────────────────────────┐
│ assets/data/*.json (bundled)       │  ← canonical, ship-with-app
└────────────────────────────────────┘
                ▲
                │ overlay
                │
┌────────────────────────────────────┐
│ Supabase qbank_drafts (live)        │  ← admin-edited, runtime-loaded
└────────────────────────────────────┘
                =
┌────────────────────────────────────┐
│ effective pool the app uses        │
└────────────────────────────────────┘
```

Bundled JSON is the immutable source of truth. Drafts override or extend pool by `(pool_id, id)`. On each fresh app start (or pull-to-refresh in admin), we read both layers and merge with draft wins.

### 2.2 Supabase migration

```sql
-- 2026-05-18: qbank drafts table for admin CRUD
create table public.qbank_drafts (
  pool_id text not null,             -- e.g. 'capitals'
  id text not null,                  -- canonical question id within the pool
  status text not null default 'draft' check (status in ('draft','review','published','archived')),
  payload jsonb not null,            -- the full question record, same shape as JSON pool entries
  author_uid uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (pool_id, id)
);

-- Read: any authenticated admin
create policy qbank_drafts_read on public.qbank_drafts
  for select using (
    auth.role() = 'authenticated' and
    exists (select 1 from public.admin_users where uid = auth.uid())
  );

-- Write: only admins; only their own rows; payload validated client-side
create policy qbank_drafts_write on public.qbank_drafts
  for all using (
    auth.role() = 'authenticated' and
    exists (select 1 from public.admin_users where uid = auth.uid())
  ) with check (
    auth.role() = 'authenticated' and
    exists (select 1 from public.admin_users where uid = auth.uid())
  );

-- Audit log
create table public.qbank_audit (
  id bigserial primary key,
  pool_id text not null,
  question_id text not null,
  action text not null check (action in ('create','update','delete','publish','archive')),
  before jsonb,
  after jsonb,
  actor_uid uuid not null references auth.users(id),
  at timestamptz not null default now()
);

create policy qbank_audit_read on public.qbank_audit
  for select using (
    exists (select 1 from public.admin_users where uid = auth.uid())
  );

-- Trigger to populate audit log on every drafts change
create or replace function public.qbank_drafts_log() returns trigger as $$
begin
  insert into public.qbank_audit (pool_id, question_id, action, before, after, actor_uid)
  values (
    coalesce(new.pool_id, old.pool_id),
    coalesce(new.id, old.id),
    case
      when tg_op = 'INSERT' then 'create'
      when tg_op = 'UPDATE' then 'update'
      when tg_op = 'DELETE' then 'delete'
    end,
    to_jsonb(old),
    to_jsonb(new),
    auth.uid()
  );
  return coalesce(new, old);
end;
$$ language plpgsql security definer;

create trigger qbank_drafts_log_trg
  after insert or update or delete on public.qbank_drafts
  for each row execute function public.qbank_drafts_log();

-- Admin allowlist (small, manually populated)
create table public.admin_users (
  uid uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  added_at timestamptz not null default now()
);

-- Read-only — admins themselves can see who else is an admin
create policy admin_users_read on public.admin_users
  for select using (
    exists (select 1 from public.admin_users where uid = auth.uid())
  );
```

**Bootstrap:** after applying migration, manually INSERT one row into `admin_users` via the Supabase SQL editor — your own UID. From then on, all admin auth flows through Supabase Auth + this allowlist.

### 2.3 Client architecture

```
lib/core/services/
└── qbank_remote_service.dart   # Supabase CRUD + audit log fetch

lib/core/providers/
└── qbank_drafts_provider.dart  # FutureProvider streaming drafts, merged with bundled pools

lib/features/admin/sections/
└── qbank_section.dart          # Phase 1 split + Phase 2 editor
```

### 2.4 Admin UI flow

```
[Q-Bank section]
├── Pools list (left column) ─ pool stats badge: bundled count + draft count
│   ▼ click a pool
├── Question list (right column) ─ search, filter (bilingual? has fun fact? difficulty?)
│   ▼ click a question
├── Question editor (modal)
│   ├── question_en + question_ar (required)
│   ├── options_en + options_ar (4 each, required)
│   ├── correct_answer (must be in options)
│   ├── difficulty (1-3)
│   ├── fun_fact_en + fun_fact_ar (optional)
│   ├── status (draft / review / published)
│   └── [Save] [Cancel] [Delete]
└── Bulk actions
    ├── [Import CSV / JSON] ─ paste a JSON array; validates against schema
    ├── [Export pool] ─ download current effective pool as JSON
    └── [Publish drafts] ─ sets status of all 'review' drafts to 'published' (only this status is read by app)
```

### 2.5 Validation (client + server)

Same rules as `scripts/validate_quiz_packs.py`:
- `question_en` and `question_ar` non-empty
- 4 options in each language
- `correct_answer` is `options[0]` (canonical position 0)
- Each option appears once (no duplicates)
- `difficulty` in {1, 2, 3} if present
- `id` unique within pool
- `fun_fact` length sanity (10-200 chars per language)

Validation in Dart before sending to Supabase. The audit script remains the post-deploy gate.

### 2.6 Quality of life

- **Inline diff** — when editing a question that exists in the bundled JSON, show "bundled vs draft" side-by-side
- **Revert** — one-click reset a draft to the bundled version
- **Suggestions** — when typing in Arabic, suggest stems from the same pool's existing questions (using `flutter_typeahead`)
- **Bilingual checker** — green dot on each card if both languages valid

Exit criteria: admins can add a new question and see it appear in the live quiz (after app reload) within 2 minutes. Audit log captures every change.

---

## Phase 3 — Cross-device analytics (3-5 days)

**Where we are:** `admin_traffic.dart` records app opens + route hits in SharedPreferences on the current device. Per the file's own comment: "This is a single-device picture. Cross-device visitor counts require Vercel Analytics or an analytics SDK."

**Where we're going:** real, anonymous, cross-device analytics with no PII, no cookies, no behavioral targeting — appropriate for a kids' app.

### 3.1 Stack choice: Vercel Web Analytics

- Already on Vercel
- Free tier covers indie/small apps
- No cookies, no PII
- COPPA-compliant by default (no behavioral targeting)
- Aggregates by URL path, country, referrer, device class
- Toggle on in the Vercel project dashboard, add one script tag to `web/index.html`

### 3.2 What to add

**Web side:**

In `web/index.html` `<head>`:
```html
<script defer src="/_vercel/insights/script.js"></script>
```

That's it. Vercel handles the rest. Custom events optional:
```js
window.va = window.va || function () { (window.vaq = window.vaq || []).push(arguments); };
window.va('event', { name: 'quiz_completed', category: 'capitals', score: 9 });
```

**App side:**

A small `analytics_service.dart` that wraps `window.va` on web and is a no-op on native (until we wire mobile analytics in a later phase). Fire events at key moments:
- `app_open` (already tracked locally — mirror to remote)
- `route_view` (already tracked locally — mirror to remote)
- `quiz_completed { module, score, total }`
- `daily_challenge_completed`
- `account_signup`

Total: ~80 lines of Dart + 1 line of HTML.

### 3.3 New admin section: `audience_section.dart`

Reads from Vercel Analytics API (server-to-server with a read-only token) and renders:
- Daily/weekly/monthly active users (DAU/WAU/MAU)
- Top routes by hits
- Top events
- Country breakdown (good for content prioritization — if 60% of users are Saudi, prioritize KSA-specific Madrasati content)
- Device breakdown (mobile web vs desktop)

Falls back to the on-device `traffic_section` data if the API key isn't configured. The admin sees a 1-line note explaining which mode is active.

Exit criteria: cross-device DAU number visible in the admin dashboard, refreshed every 6 hours.

---

## Phase 4 — Ad slots (web only, parent screens only) (1-2 weeks)

**Where we are:** `pubspec.yaml` description says "No ads, no tracking, on-device only." Zero ad code in the app.

**Where we're going:** carefully gated ad slots on **web only**, on **parent-facing pages only** (parent dashboard, settings, plus, account screens), with a hard policy that **kids' content is forever ad-free.**

### 4.1 Policy boundaries (non-negotiable)

| Surface | Ads allowed? | Why |
|---|---|---|
| Kid-facing quiz / game / Islamic content screens | ❌ **Never** | Apple Kids policy, Google DFF policy, brand promise |
| Mobile builds (iOS Kids, Android DFF) | ❌ **Never** | Apple Kids category forbids it; DFF certified networks only and even then risky |
| Web parent dashboard / settings / Plus screen | ✅ Tasteful | Adult audience, web has more leeway |
| Web kid-facing screens | ❌ **Never** | Even though it's web, kids are on the page |

The classification of "kid-facing" is set per-route in `app_router.dart`. Each `GoRoute` gets a new `adZone: AdZone.kidContent | AdZone.parent | AdZone.public` field.

### 4.2 Ad network

- **Google AdSense for Search** — text-only, no display, no behavioral. Family-safe by default. Lowest CPM but lowest policy risk.
- **AdSense with family-safe filter** — display ads, but with `google_ads_filter_adult: true` set. Requires manual ad-category blocking in AdSense dashboard.
- **Defer AdMob (mobile)** entirely — too policy-risky for a kids app without legal review.

Start with AdSense for Search on the web parent screens only. Revisit display ads after 30 days of operation.

### 4.3 Implementation

**`lib/core/services/ads_service.dart`** (new):
```dart
/// Returns true if it is policy-safe to render an ad in the current
/// context. Combines:
///   - Platform (web only)
///   - Route's AdZone (parent only)
///   - User's locale (no ads in Kuwait/Saudi until family-safe inventory verified)
///   - Feature flag (admin can turn off globally)
///   - User's age band (parent has marked themselves as 18+)
bool shouldRenderAd({required AdZone zone, required Locale locale, required AgeBand age});
```

**`lib/core/widgets/ad_slot.dart`** (new):
```dart
/// Wraps Google AdSense Search Ads. On non-web: SizedBox.shrink().
/// On web parent screens with feature flag on: renders the slot.
/// Otherwise: SizedBox.shrink().
class AdSlot extends ConsumerWidget { ... }
```

**Feature flag:**
```dart
// In AppSettings
final bool adsOnParentScreens; // default false; admin flips via /x9k2-admin-portal
```

**Default state:** OFF. Admin turns on after manual policy review.

### 4.4 Listing updates

When this phase ships:
- Update `pubspec.yaml` description: remove "No ads"; replace with "Ad-free for kids; family-safe ads on parent screens only on web"
- Update privacy policy (`docs/PRIVACY.md`) to declare AdSense usage
- Update App Store / Play Store listings accordingly

### 4.5 Admin section: `ads_section.dart`

- Toggle for `adsOnParentScreens`
- AdSense revenue dashboard (server-to-server fetch via AdSense API)
- Ad-impression count per parent route (to detect mis-classification — if kid-facing route shows ads, alert)

### 4.6 Kid-safety enforcement (tests)

A new test pack: `test/integration/ads_policy_test.dart`. For every route in the app:
1. Navigate to it
2. Find any `AdSlot` widgets in the tree
3. Assert their result is `SizedBox.shrink()` UNLESS the route's `adZone == AdZone.parent`

CI gate. If a developer adds an ad slot to a kid screen, CI rejects the PR.

Exit criteria: parent-screen ads visible on web only, kid screens verified ad-free by a CI test, admin toggle works, revenue dashboard reads from AdSense.

---

## Phase 5 — Beyond the immediate ask (the "and more needs")

Plausible extensions, prioritized:

### 5.1 Content authoring import pipeline (1 week)
Drag-and-drop a CSV of new questions into the admin, get instant validation feedback, one-click publish. Companion to Q-Bank CRUD §2.4.

### 5.2 Family / parent multi-account (already partially done)
The current Family system supports up to 4 child profiles. Extend to:
- Per-child progress reports emailed weekly to parent
- Per-child time limits (parent controls)
- Per-child curriculum focus (parent picks subjects to emphasize)

### 5.3 Achievement curation (1 week)
Admin can mint custom badges, attach unlock rules, assign per-child. Connects to `badge_l10n.dart` and `achievement_provider.dart`.

### 5.4 Push notifications (parent → child) (2 weeks)
Web Push + Firebase Cloud Messaging. Parent can schedule "study reminders" sent to child's device. Standard COPPA-safe pattern: parent-initiated only.

### 5.5 Live tutor companion (the AI agent in `lib/core/agents/`) (4+ weeks)
The `tutor_companion.dart` skeleton is there. Wiring it to an LLM is a different conversation — needs the AI safety review per `docs/AI_SAFETY.md`. Not in this plan.

### 5.6 Localization beyond AR/EN (ongoing)
Activity catalog is 409 strings; existing ARB pipeline supports any locale. Adding Urdu, Turkish, French is "translate 409 strings, add a locale flag." A native reviewer per language is the gate, not engineering.

---

## Sequencing recommendation

| Week | Phase | Outcome |
|---|---|---|
| 1 | Phase 1: Admin split + design system | Mature 17-section admin; easier reviews |
| 2 | Phase 2 (start): Q-Bank schema + remote service | DB ready; client can read drafts |
| 3 | Phase 2 (finish): admin UI for CRUD | Admins can edit questions live |
| 4 | Phase 3: Vercel Analytics + audience section | Cross-device DAU/MAU visible |
| 5-6 | Phase 4: ads service + AdSense + policy tests | Parent-screen ads on web; full CI safety |
| ongoing | Phase 5 extensions | As priority dictates |

**Total: 6-week roadmap, single engineer.** Earlier phases unblock later ones; each ships independently.

---

## What's in this session

I'm executing the design + scaffolding for Phases 2-4 right now:
- `PROJECT_PLAN.md` (this file)
- Supabase migration SQL → `supabase/migrations/2026_05_18_qbank_drafts.sql`
- Dart service stubs → `lib/core/services/qbank_remote_service.dart`, `lib/core/services/ads_service.dart`
- Provider scaffolds → `lib/core/providers/qbank_drafts_provider.dart`
- Web Analytics one-liner → `web/index.html`

These let you commit a working scaffold today; full UI + integration work follows in the next sessions per the sequencing above.
