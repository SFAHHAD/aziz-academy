import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/weekly_tourney_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('currentIsoWeek formats as YYYY-WW with two-digit week', () {
    final iso = currentIsoWeek(DateTime(2026, 1, 5));
    expect(iso, matches(RegExp(r'^\d{4}-\d{2}$')));
  });

  test('recordScore saves new entry for slot+week', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(weeklyTourneyProvider.future);
    await c.read(weeklyTourneyProvider.notifier).recordScore(
          slotId: 0,
          score: 7,
        );
    final s = c.read(weeklyTourneyProvider).value!;
    expect(s.entries, hasLength(1));
    expect(s.entries.first.score, 7);
    expect(s.entries.first.slotId, 0);
  });

  test('recordScore keeps higher of two scores for same slot+week',
      () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(weeklyTourneyProvider.future);
    final n = c.read(weeklyTourneyProvider.notifier);
    await n.recordScore(slotId: 0, score: 5);
    await n.recordScore(slotId: 0, score: 9);
    await n.recordScore(slotId: 0, score: 3);
    final s = c.read(weeklyTourneyProvider).value!;
    expect(s.entries, hasLength(1));
    expect(s.entries.first.score, 9);
  });

  test('recordScore separates entries by slot', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(weeklyTourneyProvider.future);
    final n = c.read(weeklyTourneyProvider.notifier);
    await n.recordScore(slotId: 0, score: 5);
    await n.recordScore(slotId: 1, score: 8);
    final s = c.read(weeklyTourneyProvider).value!;
    expect(s.entries, hasLength(2));
  });

  test('TourneyEntry json roundtrip', () {
    const e = TourneyEntry(slotId: 2, score: 8, iso: '2026-15');
    final j = e.toJson();
    final back = TourneyEntry.fromJson(j);
    expect(back.slotId, e.slotId);
    expect(back.score, e.score);
    expect(back.iso, e.iso);
  });
}
