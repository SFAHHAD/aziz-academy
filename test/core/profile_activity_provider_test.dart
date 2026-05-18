import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/family_profiles_provider.dart';
import 'package:aziz_academy/core/providers/profile_activity_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('activityDayKey', () {
    test('zero-pads month and day', () {
      expect(activityDayKey(DateTime(2026, 1, 5)), '2026-01-05');
      expect(activityDayKey(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });

  group('applyActivityPing', () {
    final day1 = DateTime(2026, 5, 16, 9);
    final day2 = DateTime(2026, 5, 17, 9);
    final day4 = DateTime(2026, 5, 19, 9);

    test('first ping starts a streak of 1 and sets member-since', () {
      final a = applyActivityPing(const ProfileActivity(), day1);
      expect(a.streak, 1);
      expect(a.bestStreak, 1);
      expect(a.daysActive, 1);
      expect(a.totalSessions, 1);
      expect(a.sessionsToday, 1);
      expect(a.lastActiveDate, '2026-05-16');
      expect(a.memberSince, '2026-05-16');
      expect(a.recentDays, ['2026-05-16']);
    });

    test('second ping same day only bumps session counters', () {
      var a = applyActivityPing(const ProfileActivity(), day1);
      a = applyActivityPing(a, day1.add(const Duration(hours: 2)));
      expect(a.streak, 1);
      expect(a.daysActive, 1);
      expect(a.sessionsToday, 2);
      expect(a.totalSessions, 2);
      expect(a.recentDays, ['2026-05-16']);
    });

    test('consecutive day extends the streak', () {
      var a = applyActivityPing(const ProfileActivity(), day1);
      a = applyActivityPing(a, day2);
      expect(a.streak, 2);
      expect(a.bestStreak, 2);
      expect(a.daysActive, 2);
      expect(a.sessionsToday, 1);
      expect(a.recentDays, ['2026-05-16', '2026-05-17']);
    });

    test('a gap resets the streak but keeps the best', () {
      var a = applyActivityPing(const ProfileActivity(), day1);
      a = applyActivityPing(a, day2); // streak 2
      a = applyActivityPing(a, day4); // gap → reset to 1
      expect(a.streak, 1);
      expect(a.bestStreak, 2);
      expect(a.daysActive, 3);
      expect(a.memberSince, '2026-05-16');
    });

    test('recentDays keeps only the last 14 distinct days', () {
      var a = const ProfileActivity();
      for (var i = 0; i < 20; i++) {
        a = applyActivityPing(a, DateTime(2026, 1, 1).add(Duration(days: i)));
      }
      expect(a.recentDays, hasLength(14));
      expect(a.daysActive, 20);
      expect(a.streak, 20);
      expect(a.recentDays.last, '2026-01-20');
      expect(a.recentDays.first, '2026-01-07');
    });
  });

  group('profileActivityProvider', () {
    test('records activity for the active slot', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(familyProfilesProvider.future);
      await c.read(profileActivityProvider.future);

      await c
          .read(profileActivityProvider.notifier)
          .recordActivity(now: DateTime(2026, 5, 16, 10));
      final a = c.read(profileActivityProvider).value!;
      expect(a.totalSessions, 1);
      expect(a.streak, 1);
      expect(a.hasData, isTrue);
    });

    test('separate slots track activity independently', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(familyProfilesProvider.future);
      await c.read(profileActivityProvider.future);
      final family = c.read(familyProfilesProvider.notifier);

      // Slot 0 records two days.
      await c
          .read(profileActivityProvider.notifier)
          .recordActivity(now: DateTime(2026, 5, 16, 10));
      await c
          .read(profileActivityProvider.notifier)
          .recordActivity(now: DateTime(2026, 5, 17, 10));

      // Add and switch to a second slot — its activity starts fresh.
      await family.addSlot(name: 'Sibling');
      final newId = c.read(familyProfilesProvider).value!.slots.last.id;
      await family.switchTo(newId);
      await c.read(profileActivityProvider.future);
      final fresh = c.read(profileActivityProvider).value!;
      expect(fresh.totalSessions, 0);
      expect(fresh.hasData, isFalse);

      // Switch back — slot 0's data is intact.
      await family.switchTo(0);
      await c.read(profileActivityProvider.future);
      final slot0 = c.read(profileActivityProvider).value!;
      expect(slot0.daysActive, 2);
      expect(slot0.streak, 2);
    });
  });
}
