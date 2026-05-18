import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/daily_quiz_streak_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('applyDailyAnswer (pure)', () {
    test('first ever play starts streak at 1', () {
      final next = applyDailyAnswer(
        prev: DailyQuizStreak.empty,
        now: DateTime(2026, 5, 12, 9),
        correct: true,
      );
      expect(next.currentStreak, 1);
      expect(next.longestStreak, 1);
      expect(next.totalAttempts, 1);
      expect(next.totalCorrect, 1);
    });

    test('correct + wrong both count as a play', () {
      var s = applyDailyAnswer(
        prev: DailyQuizStreak.empty,
        now: DateTime(2026, 5, 12, 9),
        correct: true,
      );
      s = applyDailyAnswer(
        prev: s,
        now: DateTime(2026, 5, 13, 9),
        correct: false,
      );
      // Wrong answer: streak continues (kindness > strict gamification)
      // but totalCorrect doesn't bump.
      expect(s.currentStreak, 2);
      expect(s.totalAttempts, 2);
      expect(s.totalCorrect, 1);
    });

    test('consecutive days grow the streak', () {
      var s = DailyQuizStreak.empty;
      for (var i = 0; i < 5; i++) {
        s = applyDailyAnswer(
          prev: s,
          now: DateTime(2026, 5, 12 + i, 9),
          correct: true,
        );
      }
      expect(s.currentStreak, 5);
      expect(s.longestStreak, 5);
      expect(s.totalAttempts, 5);
    });

    test('a missed day resets streak to 1', () {
      var s = DailyQuizStreak.empty;
      s = applyDailyAnswer(
        prev: s,
        now: DateTime(2026, 5, 12, 9),
        correct: true,
      );
      s = applyDailyAnswer(
        prev: s,
        now: DateTime(2026, 5, 13, 9),
        correct: true,
      );
      // Skip the 14th. Play on the 15th — should reset.
      s = applyDailyAnswer(
        prev: s,
        now: DateTime(2026, 5, 15, 9),
        correct: true,
      );
      expect(s.currentStreak, 1);
      // Longest streak (2 from before the gap) is preserved.
      expect(s.longestStreak, 2);
    });

    test('replaying the same day is a no-op on totals', () {
      var s = applyDailyAnswer(
        prev: DailyQuizStreak.empty,
        now: DateTime(2026, 5, 12, 9),
        correct: true,
      );
      final repeat = applyDailyAnswer(
        prev: s,
        now: DateTime(2026, 5, 12, 18),
        correct: false,
      );
      expect(repeat.currentStreak, s.currentStreak);
      expect(repeat.totalAttempts, s.totalAttempts);
      expect(repeat.totalCorrect, s.totalCorrect);
    });

    test('longestStreak is monotonic', () {
      // Build up streak of 7, lose it, build streak of 3 — longest is 7.
      var s = DailyQuizStreak.empty;
      for (var i = 0; i < 7; i++) {
        s = applyDailyAnswer(
          prev: s,
          now: DateTime(2026, 5, 1 + i, 9),
          correct: true,
        );
      }
      // Two day gap, then 3 consecutive.
      s = applyDailyAnswer(
        prev: s,
        now: DateTime(2026, 5, 12, 9), // 3-day gap from May 8
        correct: true,
      );
      s = applyDailyAnswer(
        prev: s,
        now: DateTime(2026, 5, 13, 9),
        correct: true,
      );
      s = applyDailyAnswer(
        prev: s,
        now: DateTime(2026, 5, 14, 9),
        correct: true,
      );
      expect(s.currentStreak, 3);
      expect(s.longestStreak, 7);
    });
  });

  group('DailyQuizStreakNotifier', () {
    test('starts empty', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final s = await c.read(dailyQuizStreakProvider.future);
      expect(s.currentStreak, 0);
      expect(s.totalAttempts, 0);
    });

    test('recordAnswer bumps and persists', () async {
      final c = ProviderContainer();
      await c.read(dailyQuizStreakProvider.future);
      await c
          .read(dailyQuizStreakProvider.notifier)
          .recordAnswer(correct: true, now: DateTime(2026, 5, 12, 9));
      final s = c.read(dailyQuizStreakProvider).value!;
      expect(s.currentStreak, 1);
      expect(s.totalCorrect, 1);
      c.dispose();

      // Fresh container, same SharedPreferences → persistence check.
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      final s2 = await c2.read(dailyQuizStreakProvider.future);
      expect(s2.currentStreak, 1);
      expect(s2.totalCorrect, 1);
    });

    test('playedToday is true after recording today', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(dailyQuizStreakProvider.future);
      await c
          .read(dailyQuizStreakProvider.notifier)
          .recordAnswer(correct: true);
      final s = c.read(dailyQuizStreakProvider).value!;
      expect(s.playedToday, isTrue);
    });
  });
}
