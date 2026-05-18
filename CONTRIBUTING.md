# Contributing to Aziz Academy

## Code style

- Run `flutter analyze --fatal-infos --fatal-warnings` before opening a PR.
- Run `flutter test`.
- Match existing patterns in the feature folder you touch (`data` → `presentation` → `providers`).

## Achievements & badges

- Badge unlock rules live in `applyBadgeUnlocks` in `lib/core/providers/achievement_provider.dart` so they are unit-testable.
- After changing `BadgeId` or rules, update `test/core/apply_badge_unlocks_test.dart` and the trophy UI copy if needed.

## Daily streak

- `AchievementNotifier.recordDailyVisit()` runs when the home screen loads. It updates `streakCount` and `lastVisitDate` once per calendar day.

## Adding quiz data

1. Edit JSON under `assets/data/` (see existing files for shape).
2. Register the asset in `pubspec.yaml` if you add a new file.
3. Map JSON to `QuizQuestion` in the relevant `*_repository.dart`.

## Localisation

- ARB files live under `lib/l10n/` (`app_en.arb`, `app_ar.arb`); generated `app_localizations*.dart` is in the same folder — do not edit by hand.
- Pipeline config: `l10n.yaml` at the repo root.
- Runtime locale is bilingual AR/EN, persisted via `localeProvider`. AR is the default; EN is opt-in. Toggle in Settings.
- When adding a string, edit **both** `app_en.arb` and `app_ar.arb`; the keys must stay in lock-step (a CI check enforces parity).

## Tooling scripts

Content-maintenance Python helpers (`generate_*.py`, `download_audio.py`, `fix_*.py`, etc.) live under `scripts/authoring/`. They are for one-off content regeneration and are not required for `flutter run`.

Audit scripts live under `scripts/` (`audit_*.py`) and are wired into CI — they fail the build if version constants drift from `pubspec.yaml`, if fonts can't render bundled content, or if Islamic-audio inventory drops below 100%. Run them locally with `python3 scripts/audit_<name>.py`.

## Architecture

For a tour of the codebase layout (`core/`, `features/`, services, providers, routing, l10n, assets, Supabase), see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

For the active cleanup / refactor backlog, see [AUDIT_PLAN.md](AUDIT_PLAN.md) and [FINDINGS.md](FINDINGS.md).
