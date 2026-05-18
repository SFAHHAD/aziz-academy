import 'package:flutter_test/flutter_test.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';

void main() {
  group('applyBadgeUnlocks', () {
    test('unlocks capitalsExplorer after first capitals completion', () {
      const s = AchievementState(capitalsCompleted: 1);
      final out = applyBadgeUnlocks(s);
      expect(out.unlockedBadges, contains(BadgeId.capitalsExplorer));
    });

    test('unlocks triviaTitan at 25 total correct', () {
      const s = AchievementState(totalCorrect: 25);
      final out = applyBadgeUnlocks(s);
      expect(out.unlockedBadges, contains(BadgeId.triviaTitan));
    });

    test('unlocks academyStar only when all other badges are present', () {
      const partial = AchievementState(
        unlockedBadges: {
          BadgeId.capitalsExplorer,
          BadgeId.capitalsExpert,
          BadgeId.mapMaster,
          BadgeId.logoDetective,
          BadgeId.logoHunter,
          BadgeId.triviaTitan,
          BadgeId.scienceGenius,
          BadgeId.mathChampion,
          BadgeId.perfectScholar,
        },
      );
      final out = applyBadgeUnlocks(partial);
      expect(out.unlockedBadges, contains(BadgeId.academyStar));
    });

    test('preserves streak fields (badge logic does not clear them)', () {
      const s = AchievementState(
        streakCount: 5,
        lastVisitDate: '2026-04-01',
        capitalsCompleted: 1,
      );
      final out = applyBadgeUnlocks(s);
      expect(out.streakCount, 5);
      expect(out.lastVisitDate, '2026-04-01');
    });
  });

  group('AchievementState.progress', () {
    test('clamps to 1.0', () {
      const s = AchievementState(totalCorrect: 500);
      expect(s.progress, 1.0);
    });
  });
}
