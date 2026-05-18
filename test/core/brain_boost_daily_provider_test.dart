import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/features/iq/providers/brain_boost_daily_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('streak milestones present at 3, 7, 14, 30', () {
    expect(kStreakMilestones[3], isNotNull);
    expect(kStreakMilestones[7], isNotNull);
    expect(kStreakMilestones[14], isNotNull);
    expect(kStreakMilestones[30], isNotNull);
  });

  test('initial state has zero streak and not completed today', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final s = await c.read(brainBoostDailyProvider.future);
    expect(s.streak, 0);
    expect(s.todayCompleted, isFalse);
    expect(s.recentCompletions, isEmpty);
  });

  test('markCompleted starts streak and is idempotent for the same day',
      () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(brainBoostDailyProvider.future);
    final n = c.read(brainBoostDailyProvider.notifier);
    await n.markCompleted();
    final s1 = c.read(brainBoostDailyProvider).value!;
    expect(s1.streak, 1);
    expect(s1.todayCompleted, isTrue);
    // Calling again same day must not change the streak.
    await n.markCompleted();
    expect(c.read(brainBoostDailyProvider).value!.streak, 1);
  });

  test('json roundtrip preserves streak + last completion', () {
    final s = const BrainBoostDailyState(
      streak: 5,
      lastCompletedYmd: '2026-04-01',
      recentCompletions: ['2026-04-01', '2026-03-31'],
    );
    final back = BrainBoostDailyState.fromJson(s.toJson());
    expect(back.streak, 5);
    expect(back.lastCompletedYmd, '2026-04-01');
    expect(back.recentCompletions.length, 2);
  });
}
