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

- ARB files live under `l10n/`; generated code is in `lib/l10n/`.
- Runtime locale is set in `lib/main.dart` (currently Arabic-only).

## Tooling scripts

Python helpers in the repo root (`generate_*.py`, `download_audio.py`, etc.) are for content maintenance; they are not required for `flutter run`.
