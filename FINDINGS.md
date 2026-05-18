# Aziz Academy — Audit Findings

Generated: 2026-05-18 by the audit session.
Severity legend: P0 = drop everything · P1 = this week · P2 = this month · P3 = nice-to-have.

---

## 🚨 P0 — Data-loss risk (read this first)

**The repo is six weeks behind the on-disk reality.**

- Last commit on `master`: `40593c6 2026-04-20 — feat: add Madrasati section...`
- Today: 2026-05-18
- Tracked .dart files in `lib/`: **73** (1.36 MB)
- On-disk .dart files in `lib/`: **342** (4.01 MB)
- **269 .dart files (≈2.65 MB) exist only on your hard drive.** 91% of feature folders (121 of 133) have never been committed.

The "pre-audit-2026-05-18" tag I created points at the April 20 commit — not at your current working state. **If this disk failed today, ~6 weeks of work (every change since April 20, including v1.1.x, Madrasati polish, Brain Boost, the Plus tier, the account hub) would be gone.** The repo has a GitHub remote (`origin → SFAHHAD/aziz-academy.git`) but the latest pushed branch is the same April 20 state.

### Immediate mitigation (in order)

1. **Clear the stuck git index lock** (blocking all my writes too):
   ```powershell
   Remove-Item "C:\Users\sfahh\Desktop\Project\Aziz Academy\.git\index.lock"
   ```
   After closing any IDE / git client that might be holding it.

2. **Make a single "checkpoint" commit of everything**, even if it's messy. This is a snapshot, not a clean history:
   ```bash
   git add -A
   git commit -m "checkpoint: pre-audit working tree 2026-05-18"
   git tag working-tree-2026-05-18
   git push origin chore/audit-cleanup
   git push origin working-tree-2026-05-18
   ```
   This guarantees recovery. Triaging into clean commits can happen afterward.

3. **Set up an offsite backup beyond GitHub.** A 7zip of the working tree to OneDrive / Dropbox / external SSD. This belongs to next 24 hours, not next sprint.

4. Only AFTER 1–3 above, proceed with the cleanup work below.

---

## 🐛 P0 — Runtime bug: missing asset declaration

**`assets/data/tajweed_basics.json` is not declared in `pubspec.yaml`.**

- File exists on disk (142 lines).
- Referenced at `lib/features/tajweed/tajweed_basics_screen.dart:42`:
  ```dart
  await rootBundle.loadString('assets/data/tajweed_basics.json');
  ```
- Routed at `lib/core/router/app_router.dart:1002-1003`.
- Listed in `lib/features/home/activity_catalog.dart:1465`.
- Not in `pubspec.yaml` flutter.assets list.

**Result:** any user who taps the Tajweed Basics tile gets a `FlutterError: Unable to load asset: "assets/data/tajweed_basics.json"`. Confirmed by checking which assets are declared (270 OK) vs which exist on disk (271 in `assets/data/`).

### Fix
Add this line to `pubspec.yaml` under `flutter.assets`, alphabetically:
```yaml
    - assets/data/tajweed_basics.json
```
Run `flutter pub get` and the screen will load.

**Better long-term fix:** AUDIT_PLAN.md §8.1 — replace the hand-maintained list of ~257 individual asset paths with a single `assets/data/` directory entry. Flutter bundles the whole folder; you can never forget a file again.

---

## ⚠️ P1 — Dead feature folder

**`lib/features/tangram/` is empty.**

- Created May 5; contains zero `.dart` files.
- Not referenced anywhere in code, router, catalog, or assets.
- 132 other feature folders are wired up correctly.

**Fix:** delete the folder. If you want to keep "tangram" on the roadmap, leave a single-line `// TODO: implement tangram puzzle` in a stub `tangram_screen.dart` so the placeholder is visible in code review.

---

## ⚠️ P1 — Tofu-box risk in tajweed content

**Two instances of U+2192 (RIGHTWARDS ARROW) in `assets/data/tajweed_basics.json` are not in any bundled font.**

- `tajweed_basics.json:136` and `:137`:
  ```
  "example_ar": "الرَّحْمَٰنِ → الرَّحْمَٰن",
  "example_translit": "Ar-rahmaani → Ar-rahmaan",
  ```
- `scripts/audit_font_coverage.py` flagged this with: `[warn] U+02192 count=2 RIGHTWARDS ARROW`.
- Cairo, Amiri, NotoColorEmoji (your three bundled fonts) do not cover this glyph.
- On a device without a system fallback for math symbols, this renders as a ☐ tofu box. Common on stripped-down Android Go devices.

### Fix
Pick one (in order of preference):
1. Replace `→` with `←` (Arabic context, right-to-left, but Cairo doesn't cover that either — same problem).
2. Use ASCII `->` or `←` text equivalent — both fonts cover Latin punctuation.
3. Add a Material Icons inline `Icon(Icons.arrow_forward)` and split the string.
4. Add NotoSansSymbols to `assets/fonts/` and the font fallback chain.

Cheapest: option 2.

---

## ⚠️ P1 — `.gitignore` may have hidden meaningful files

The `.gitignore` additions I made in this session correctly catch the `temp_*.mp3` clutter, but they also now hide three files that were untracked-but-real-content:

| File | Size | What it is |
|------|------|------------|
| `emoji_scan.txt` | 32 KB | Output of an emoji audit run on 2026-05-09. Could be useful as a one-time report. |
| `sitemap_paths.txt` | 1.8 KB | Apparently driver for `scripts/audit_sitemap_routes.py` or its output. |
| `lighthouse-report.html` | 548 KB | Local Lighthouse run from 2026-05-03. |

**Decide:** if any of these has lasting value, move it into `docs/reports/` and remove the gitignore line. Otherwise leave the gitignore as-is.

---

## ✅ Clean bills of health

These were the worst-case scenarios I checked, and they passed:

### Localization parity
- 409 keys in `app_en.arb`, 409 keys in `app_ar.arb`. **Zero drift.**
- Zero empty AR strings.
- Zero AR strings that are still Latin-only (i.e., everything got translated).

### Version consistency
- `scripts/audit_version_consistency.py` passes: pubspec.yaml `1.1.113+118` matches all three hardcoded `_kAppVersion` constants in the source.

### Sitemap ↔ router parity
- 139 sitemap entries, 164 router paths. Sitemap is a subset of router (admin/dev routes are intentionally non-crawlable). Clean.

### Islamic audio inventory
- 209 / 209 clips bundled (100%). Hadith, azkar, names, dua, tajweed all complete.
- `lib/core/services/islamic_audio_registry.dart` regenerated by the audit script and is byte-identical to the committed version — registry is in sync.

### Supabase attack surface
- Only two tables hit by client code: `account_sync` and `entitlements`.
- No edge function invocations.
- No RPC calls.
- The client passes `user_id: uid` in the `account_sync` upsert; if RLS is set with `WITH CHECK (auth.uid() = user_id)`, this is safe.

### Asset integrity
- 270 / 270 assets declared in `pubspec.yaml` exist on disk.
- Only one direction of drift: the `tajweed_basics.json` listed under P0 above.

---

## 🔧 P2 — Architecture debts (concrete split plans)

These do not block shipping but every change near them is painful.

### A. `lib/core/data/madrasati_data.dart` — 8,829 lines

This is **pure data with no business logic** — just nested `SchoolStage` / `SchoolGrade` / `SchoolSubject` / `SchoolChapter` / `SchoolQuestion` constructor calls.

**Structure today:**
```
L1-7      imports + header comment
L8-5197   final madrasatiStages = [...]    (the top-level tree, references _kg1..._secondaryGrade12)
L5200-5392    final _kgGrade1 = SchoolGrade(...)
L5393-5584    final _kgGrade2 = ...
L5585-5868    final _primaryGrade1
L5869-6171    final _primaryGrade2
L6172-6466    final _primaryGrade3
L6467-6664    final _primaryGrade4
L6665-7008    final _primaryGrade5
L7009-7350    final _middleGrade6
L7351-7557    final _middleGrade7
L7558-7783    final _middleGrade8
L7784-8016    final _middleGrade9
L8017-8219    final _secondaryGrade10
L8220-8574    final _secondaryGrade11
L8575-8829    final _secondaryGrade12
```

**Recommended split:**
```
lib/core/data/madrasati/
  madrasati_stages.dart           # the top-level list, 200 lines
  kg/kg1.dart                     # 200 lines
  kg/kg2.dart                     # 200 lines
  primary/g1.dart .. g5.dart      # ~300 lines each
  middle/g6.dart .. g9.dart       # ~250 lines each
  secondary/g10.dart .. g12.dart  # ~250 lines each
```

Each grade file is a `final SchoolGrade gN = SchoolGrade(...)` plus its private question helpers. `madrasati_stages.dart` exports the list and re-exports the grades.

**Order of operations:**
1. Make the new files (copy from line ranges above).
2. Update `madrasati_data.dart` to re-export from the new files temporarily (compatibility shim).
3. Update every importer to point at `madrasati_stages.dart`.
4. Delete the shim. Done.

**Even better long-term:** move to `assets/data/madrasati/<grade>.json` (matches your other 200+ JSON content packs). Pros: hot-reload, non-coder authoring, easier to diff. Cons: lose const construction (small startup cost, easily worth it).

### B. `lib/features/admin/admin_dashboard_screen.dart` — 5,932 lines

Already has perfect natural seams: **64 private widget classes, each clearly a section.**

**Recommended split:**
```
lib/features/admin/
  admin_dashboard_screen.dart     # AdminDashboardScreen + _PasscodeGate + _AdminShell  (~700 lines)
  admin_section.dart              # enum _Section + extension (~170 lines)
  sections/
    overview_section.dart         # _OverviewSection                          (~150 lines)
    traffic_section.dart          # _TrafficSection                           (~240 lines)
    engagement_section.dart       # _EngagementSection + _EngRow + _ActivityRankingCard  (~470 lines)
    feedback_section.dart         # _FeedbackSection + _FeedbackRow           (~370 lines)
    audit_section.dart            # _AuditSection + _AuditRow                 (~260 lines)
    privacy_section.dart          # _PrivacySection                           (~260 lines)
    qbank_section.dart            # _QBankSection + _PoolCard + _QuestionMatches  (~320 lines)
    lint_section.dart             # _LintSection + _LintRow                   (~410 lines)
    translate_section.dart        # _TranslateSection                         (~320 lines)
    catalog_section.dart          # _CatalogSection                           (~200 lines)
    assets_section.dart           # _AssetsSection                            (~155 lines)
    family_section.dart           # _FamilySection                            (~110 lines)
    economy_section.dart          # _EconomySection                           (~90 lines)
    storage_section.dart          # _StorageSection + _PrefValue              (~165 lines)
    errors_section.dart           # _ErrorsSection + _ErrorRow                (~165 lines)
    flags_section.dart            # _FlagsSection                             (~105 lines)
    tools_section.dart            # _ToolsSection                             (~190 lines)
  widgets/
    admin_atoms.dart              # _Header2, _MutedText, _Card, _StatGrid, _HealthCard,
                                  # _Dot, _Tag, _Kv, _CountPill, _SearchRow, _ToggleChip,
                                  # _SkillTable, _SessionList, _ToolButton, _LoadingPanel,
                                  # _ErrorPanel, _MutedPanel, _AuditTrendStrip   (~900 lines)
```

Each section file is self-contained: imports + one widget class. The `widgets/admin_atoms.dart` holds the shared small widgets. The current `_C` color constants class (L135) goes to a top-level `_constants.dart`.

After the split, the dashboard screen file is ~700 lines (just the gate + shell). Every section file is under 500 lines. Total: ~5,900 lines spread across ~20 files. No behaviour change.

### C. `lib/core/router/app_router.dart` — 1,889 lines, 164 GoRoutes, 169 deferred imports

Tricky because `deferred as` imports cannot be lifted out of the file consuming them. The routes themselves CAN be grouped, but the deferred handles have to stay.

**Recommended split:**
```
lib/core/router/
  app_router.dart                 # GoRouter() declaration + redirect logic   (~200 lines)
  routes/
    _imports.dart                 # the 169 deferred-as imports                (~340 lines)
    home_routes.dart              # / and /splash and /home                    (~30 lines)
    quiz_routes.dart               # /capitals /flags /sciences /math /logos /maps  (~200 lines)
    brain_boost_routes.dart        # /iq, /brain-boost                         (~100 lines)
    action_routes.dart             # /snake /tetris-lite /bubble-pop ... ~50 routes  (~250 lines)
    versus_routes.dart             # /tic-tac-toe /connect-four /battleship ...  (~100 lines)
    islamic_routes.dart            # /quran /hadith /athkar /dua ...           (~200 lines)
    learning_routes.dart           # /madrasati /smart-quiz /daily-challenge   (~150 lines)
    profile_routes.dart            # /profile /family /trophy /account /plus   (~150 lines)
    legal_routes.dart              # /privacy /about /for-schools              (~50 lines)
    admin_routes.dart              # /x9k2-admin-portal /dev                   (~100 lines)
```

Each `routes/*.dart` file exports `List<GoRoute>` from a `<name>Routes` getter. `app_router.dart` does:
```dart
GoRouter(
  routes: [
    ...homeRoutes,
    ...quizRoutes,
    ...brainBoostRoutes,
    ...actionRoutes,
    ...versusRoutes,
    ...islamicRoutes,
    ...learningRoutes,
    ...profileRoutes,
    ...legalRoutes,
    ...adminRoutes,
  ],
  redirect: ...,
  errorBuilder: ...,
)
```

`_imports.dart` is the only file with the deferred-as machinery; all `routes/*.dart` files import from it.

---

## 📋 P2 — Audit-script automation

Your `scripts/audit_*.py` are excellent. CI integration recommended (AUDIT_PLAN.md §6.4 already added version-consistency to `flutter_ci.yml`):

```yaml
- name: Asset / content audits
  run: |
    python3 scripts/audit_font_coverage.py
    python3 scripts/audit_islamic_audio.py
    python3 scripts/audit_sitemap_routes.py
```

`audit_font_coverage.py` currently returns 0 even with the U+2192 warning (it's a "soft pass" path). Consider tightening: any uncovered glyph fails CI once tajweed_basics is fixed.

`audit_islamic_audio.py` has a **side effect** — it rewrites `lib/core/services/islamic_audio_registry.dart`. In CI this means a clean run will dirty the working tree (no-op if registry is up to date, but be aware). Wrap with `--check` mode that diffs instead of writes if you intend to gate CI on it.

---

## 📚 P3 — Stale docs (informational)

The `docs/` directory already contains review notes from 2026-05-02:

| File | Last reviewed | Lines |
|------|--------------|-------|
| `docs/PRIVACY.md` | 2026-05-02 | 89 |
| `docs/AI_SAFETY.md` | 2026-05-02 | 55 |
| `docs/APP_STORE_COMPLIANCE.md` | (not dated) | 46 |
| `docs/ACCESSIBILITY_AUDIT.md` | 2026-05-02 | 39 |
| `docs/LOCALIZATION.md` | 2026-05-02 | 66 |
| `docs/CURRICULUM_MAPPING.md` | 2026-05-13 | 67 |

The app shipped 1.1.113 (CHANGELOG: account hub, Plus tier, onboarding restructure) since May 2. These docs predate that work. They are **also all untracked**, so they're at risk per P0.

Recommended:
1. Get them under version control (P0 mitigation step 2).
2. Refresh each against the post-May-2 changes.
3. Add a "Last reviewed:" header to every doc and a CI check that fails any doc older than 90 days.

---

## 🧪 P3 — Testing posture (informational)

- 63 test files in `test/` covering 27 distinct categories.
- 121 feature folders have no `*_test.dart` mate.
- Coverage baseline not measured (requires `flutter test --coverage`, which I can't run here).
- AUDIT_PLAN.md §5 has the testing strategy.

Lowest-hanging fruit: add a one-line smoke test per feature:
```dart
testWidgets('${feature_name} renders', (tester) async {
  await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: FeatureScreen())));
  expect(find.byType(FeatureScreen), findsOneWidget);
});
```
121 of these = ~2 hours of mechanical work.

---

## 🧮 Summary table

| ID | Severity | Title | Estimate |
|----|----------|-------|----------|
| F1 | **P0** | 269 .dart files uncommitted; ~6 weeks of work has no remote backup | 30 min (checkpoint commit + push) |
| F2 | **P0** | `tajweed_basics.json` missing from pubspec — Tajweed screen throws at runtime | 1 line |
| F3 | P1 | Empty `lib/features/tangram/` folder — dead | 1 line `rmdir` |
| F4 | P1 | `→` in tajweed content has no font coverage | 1 string edit |
| F5 | P1 | New .gitignore hides 3 untracked content files | 3 decisions |
| F6 | P2 | `madrasati_data.dart` (8,829 lines) — split per grade | ~1 day |
| F7 | P2 | `admin_dashboard_screen.dart` (5,932 lines) — split per section | ~1 day |
| F8 | P2 | `app_router.dart` (1,889 lines) — split per area | ~½ day |
| F9 | P2 | Wire content audits into CI | 1 hour |
| F10 | P3 | Refresh stale docs in `docs/` | ~3 hours per doc |
| F11 | P3 | Add smoke tests for 121 untested features | ~2 hours mechanical |

---

## Recommended order of operations

1. **Right now** — clear `.git/index.lock`, make the checkpoint commit, push to remote, take an external backup. **F1**.
2. **Within 1 hour** — fix tajweed pubspec entry, delete tangram folder, fix the `→` in JSON. **F2 + F3 + F4**.
3. **This week** — decide on F5; wire audits into CI (F9); start the split work on whichever big file you change next.
4. **This sprint** — execute the AUDIT_PLAN.md phases starting with Phase 2 (docs), Phase 4 (security/privacy verification with Supabase dashboard), Phase 6 (CI consolidation).
5. **Ongoing** — splits (F6/F7/F8), tests (F11), doc refresh (F10).
