# Audit Execution Progress — 2026-05-18

This file tracks what was actually executed against `AUDIT_PLAN.md` in
session 2026-05-18, what is queued for the next session, and what is
blocked.

Pre-audit safety tag: `pre-audit-2026-05-18`
Working branch: `chore/audit-cleanup`

---

## Done in this session

### Phase 0 — Safety net ✅
- Tag `pre-audit-2026-05-18` created at last commit on `master`.
- Branch `chore/audit-cleanup` checked out.
- Git remote confirmed (`origin → https://github.com/SFAHHAD/aziz-academy.git`).
- Identity confirmed (`SFAHHAD` / `SFAHHAD@users.noreply.github.com`).

### Phase 1.3 — `.gitignore` ✅
Appended (and verified active) patterns for:
- `/temp_*.mp3` / `.wav` / `.m4a` / `.mp4`
- `/AzizAcademy_WebBuild*.zip`
- Root scratch text files: `/analyze.txt`, `/analyze_output.txt`, `/build.txt`, `/build_log.txt`, `/emoji_scan.txt`, `/machine_analyze.txt`, `/machine_analyze_utf8.txt`, `/router_paths.txt`, `/sitemap_paths.txt`, `/New Text Document.txt`
- `/lighthouse-report.html` / `.json`
- `/.flutter-test-results/`

These now take effect for any **new** files matching the pattern. Existing
**tracked** files (e.g. `AzizAcademy_WebBuild.zip`, `build.txt`,
`build_log.txt`, `analyze.txt`, `analyze_output.txt`,
`machine_analyze.txt`, `machine_analyze_utf8.txt`) still appear because
git keeps tracking files it already knows about — `git rm --cached` is
needed to drop them. **Blocked by index.lock** — see "Blocked" below.

### Phase 1.4 — Move untracked scratch notes ✅
- Created `docs/notes/`.
- Renamed and moved (filesystem, no git involved since they were
  untracked):
  - `Imprtant.txt` → `docs/notes/important.md` (typo fixed)
  - `Points.txt` → `docs/notes/points.md`
  - `Reply.txt` → `docs/notes/reply.md`
  - `Research.txt` → `docs/notes/research.md`

### Phase 2.5 — `docs/ARCHITECTURE.md` ✅
Written. Covers: layering, startup sequence, services, state mgmt,
routing, l10n, assets, persistence model, Supabase backend, hidden
surfaces, CI/CD, where-to-look-first table, glossary, and the top three
architectural debts. ~250 lines.

### Phase 3.4 — Stricter lint scaffold ✅
- Created `analysis_options.proposed.yaml` at the repo root. Includes a
  staged rollout plan and comments — do **NOT** swap it in wholesale.
  Migration is one lint at a time per the file's header.

### Phase 6.4 — Version consistency in CI ✅
- Edited `.github/workflows/flutter_ci.yml` to add a "Version consistency"
  step that runs `python3 scripts/audit_version_consistency.py` after
  `flutter pub get` and before `flutter analyze`. The audit script
  already existed and explains its rationale in its docstring.

### Surprise wins (discovered, no action needed)
The `docs/` folder already contains several documents that the
AUDIT_PLAN.md called out as "to write". They exist and were last
reviewed 2026-05-02:
- `docs/PRIVACY.md`
- `docs/AI_SAFETY.md`
- `docs/APP_STORE_COMPLIANCE.md`
- `docs/ACCESSIBILITY_AUDIT.md`
- `docs/LOCALIZATION.md`
- `docs/CURRICULUM_MAPPING.md` (last reviewed 2026-05-13)
- `docs/IOS_RELEASE_NO_MAC.md`
- `docs/github_actions_secrets_checklist.txt`

Recommended next step: have a real auditor (or yourself) refresh
PRIVACY / AI_SAFETY / APP_STORE_COMPLIANCE / ACCESSIBILITY_AUDIT /
LOCALIZATION since they're 2 weeks old and the app shipped 1.1.113 in
the meantime.

---

## Blocked — needs Saud (or unattended Windows access)

### Git index lock is stuck
`/.git/index.lock` (zero bytes, ~18 minutes old at first detection,
still present now). The sandbox cannot remove it (`Operation not
permitted`). Every git **write** is blocked: `git rm`, `git mv`,
`git add`, `git commit`. Reads still work.

**How to clear (on your Windows machine):**

1. Close anything that might be holding the repo:
   - Android Studio / IntelliJ (the repo has `.idea/`)
   - VS Code
   - GitHub Desktop / Sourcetree / Fork / lazygit
   - Any open terminal sitting inside the repo
2. Delete the lock file:
   ```powershell
   Remove-Item "C:\Users\sfahh\Desktop\Project\Aziz Academy\.git\index.lock"
   ```
   or:
   ```cmd
   del "C:\Users\sfahh\Desktop\Project\Aziz Academy\.git\index.lock"
   ```
3. Verify `git status` works:
   ```cmd
   cd "C:\Users\sfahh\Desktop\Project\Aziz Academy"
   git status
   ```

Once cleared, ping me and I'll execute the queued git operations below.

### Two zero-byte files I couldn't delete
`New Text Document.txt` and `router_paths.txt` — sandbox returned
"Operation not permitted" on `rm`. Same Windows-side process is
probably holding them. Once the index lock issue is fixed these will
likely delete fine too. Both are gitignored already so they don't
contaminate git anyway.

---

## Queued — execute as soon as the lock is cleared

These are all single commands. I would run them as one cleanup commit
each, on `chore/audit-cleanup`.

### Q1. Untrack the clutter files (commit message:
"chore: untrack accidental web-build zip and analyzer dumps")
```bash
git rm AzizAcademy_WebBuild.zip
git rm build.txt build_log.txt
git rm analyze.txt analyze_output.txt
git rm machine_analyze.txt machine_analyze_utf8.txt
```
The pre-audit tag preserves all of these in history. The 16 MB
`AzizAcademy_WebBuild.zip` is the biggest single win.

### Q2. Move the authoring .py scripts (commit:
"chore: move root authoring scripts into scripts/authoring/")
```bash
mkdir -p scripts/authoring
git mv crop_v2.py            scripts/authoring/
git mv download_audio.py     scripts/authoring/
git mv extract_logo.py       scripts/authoring/
git mv fetch_logos.py        scripts/authoring/
git mv fill_missing_capitals.py scripts/authoring/
git mv fix_flags.py          scripts/authoring/
git mv fix_fun_facts.py      scripts/authoring/
git mv generate_capitals.py  scripts/authoring/
git mv generate_logos.py     scripts/authoring/
git mv generate_sciences.py  scripts/authoring/
```
Update `CONTRIBUTING.md` line 31 in the same commit:

Before:
> Python helpers in the repo root (`generate_*.py`, `download_audio.py`, etc.) are for content maintenance; they are not required for `flutter run`.

After:
> Python helpers live under `scripts/authoring/` (`generate_*.py`, `download_audio.py`, etc.) and are for content maintenance; they are not required for `flutter run`.

### Q3. Archive `Aziz Academy.md` (commit:
"docs: archive original v0.x README as docs/HISTORY.md")
```bash
git mv "Aziz Academy.md" docs/HISTORY.md
```
Then prepend this header to `docs/HISTORY.md`:

```markdown
> **Archived 2026-05-18.** This was the original v0.x README describing
> 8 modules. The current README (`/README.md`) is the source of truth
> and describes 130+ modules in v1.1.113. Kept here for historical
> context.
```

### Q4. Commit the docs / scaffolds we wrote today (commit:
"docs: add AUDIT_PLAN, AUDIT_PROGRESS, ARCHITECTURE, lint scaffold")
```bash
git add .gitignore                            # gitignore additions
git add AUDIT_PLAN.md AUDIT_PROGRESS.md
git add docs/ARCHITECTURE.md
git add docs/notes/                            # 4 new scratch notes
git add analysis_options.proposed.yaml
git add .github/workflows/flutter_ci.yml       # version-consistency step
```

### Q5. Push the safety tag and the branch
```bash
git push origin pre-audit-2026-05-18
git push -u origin chore/audit-cleanup
```

---

## Not done yet — out of scope for this session

These need either tooling I don't have (Flutter SDK, Xcode, signed
keystores), credentials I shouldn't be touching (Supabase dashboard,
App Store Connect, Play Console), or judgment calls only Saud can
make:

- **Phase 0 step 4** — `flutter analyze` / `flutter test` / `flutter
  build web --release` baseline. No Flutter SDK available here.
  Suggested: run locally on `master` BEFORE merging
  `chore/audit-cleanup`.
- **Phase 1.5** — `flutter clean` to recover the 3.5 GB `build/`. Same.
- **Phase 1.6 / 1.7** — decide what to do with the 14 MB CDN log
  (`aziz-academy.com-...log`) and the ~80 MB of `temp_*.mp3` files.
  They're now gitignored, so they're invisible to git. Question is
  whether you want them on disk at all. I left them alone.
- **Phase 2.2 README accuracy** — fact-check requires running the
  app or hitting the live URL. Recommended: verify aziz-academy.com
  is up, count `id:` entries in `activity_catalog.dart` vs. the
  README's "131 entries" claim.
- **Phase 2.3 CHANGELOG triage** — judgment call. Keep, archive, or
  restructure. My recommendation: keep — your commit log and store
  release notes both look like they pull from it.
- **Phase 4 (security/privacy)** — requires Supabase dashboard
  access to verify RLS policies. The docs (`PRIVACY.md`,
  `AI_SAFETY.md`, `APP_STORE_COMPLIANCE.md`) exist; refresh them.
- **Phase 5 (tests)** — adding tests is parallelizable busywork
  measured in days, not minutes; out of scope for one session.
  Useful next step: run
  ```bash
  flutter test --coverage && genhtml coverage/lcov.info -o coverage/html
  ```
  and inspect which features are uncovered.
- **Phase 6.1 (consolidate CI)** — needs you to read both `ci.yml`
  and `flutter_ci.yml` and decide which is canonical. Most likely
  delete `ci.yml` if it's a stub.
- **Phase 7 (store readiness)** — entirely external. The plan and
  `docs/APP_STORE_COMPLIANCE.md` cover the checklist.
- **Phase 8 / 9 / 10** — implementation work, not auditable from a
  read-only audit pass. The plan in `AUDIT_PLAN.md` is the to-do
  list.

---

## Files I created / edited this session

- `AUDIT_PLAN.md`                              (new, ~600 lines)
- `AUDIT_PROGRESS.md`                          (this file)
- `docs/ARCHITECTURE.md`                       (new, ~250 lines)
- `docs/notes/important.md`                    (moved from `Imprtant.txt`)
- `docs/notes/points.md`                       (moved from `Points.txt`)
- `docs/notes/reply.md`                        (moved from `Reply.txt`)
- `docs/notes/research.md`                     (moved from `Research.txt`)
- `analysis_options.proposed.yaml`             (new scaffold, not active)
- `.gitignore`                                 (appended ~25 lines)
- `.github/workflows/flutter_ci.yml`           (added version-consistency step)

---

## Pre-flight before merging `chore/audit-cleanup` to `master`

```bash
# 1. Clear the lock (see "Blocked" above).
# 2. Run all queued commits Q1–Q4.
# 3. Verify the tree:
git status                                     # should be ~zero noise
ls *.txt 2>/dev/null                           # should be empty
ls *.py 2>/dev/null                            # should be empty
du -sh .                                       # should drop ~16 MB minimum after Q1
# 4. Sanity-check the build:
flutter pub get
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter build web --release
# 5. If all green:
git push -u origin chore/audit-cleanup
git push origin pre-audit-2026-05-18
# 6. Open PR, merge into master.
```
