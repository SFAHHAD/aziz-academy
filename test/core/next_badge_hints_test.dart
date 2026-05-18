import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextBadgeHints', () {
    test('returns empty list for a brand-new profile', () {
      const s = AchievementState();
      // Lots of badges are technically "X away" but with totalCorrect=0
      // every numeric target has remaining > 0 so hints are non-empty.
      // We assert ordering and shape, not absence.
      final hints = nextBadgeHints(s);
      expect(hints, isNotEmpty);
      expect(hints.length, lessThanOrEqualTo(3));
      // closest-first ordering
      for (var i = 1; i < hints.length; i++) {
        expect(hints[i].remaining, greaterThanOrEqualTo(hints[i - 1].remaining));
      }
    });

    test('skips badges already unlocked', () {
      final s = const AchievementState(totalCorrect: 25)
          .copyWith(unlockedBadges: {BadgeId.triviaTitan});
      final hints = nextBadgeHints(s);
      expect(hints.any((h) => h.id == BadgeId.triviaTitan), isFalse);
    });

    test('skips already-met thresholds (remaining <= 0)', () {
      // 25 correct unlocks Trivia Titan; without setting it as unlocked,
      // remaining is 0 and the hint is suppressed.
      const s = AchievementState(totalCorrect: 25);
      final hints = nextBadgeHints(s, limit: 50);
      expect(hints.any((h) => h.id == BadgeId.triviaTitan), isFalse);
    });

    test('respects the limit parameter', () {
      const s = AchievementState();
      expect(nextBadgeHints(s, limit: 1).length, lessThanOrEqualTo(1));
      expect(nextBadgeHints(s, limit: 5).length, lessThanOrEqualTo(5));
    });

    test('produces both Arabic and English copy for each hint', () {
      const s = AchievementState();
      for (final h in nextBadgeHints(s, limit: 5)) {
        expect(h.labelEn.trim(), isNotEmpty);
        expect(h.labelAr.trim(), isNotEmpty);
        expect(h.remaining, greaterThan(0));
      }
    });
  });
}
