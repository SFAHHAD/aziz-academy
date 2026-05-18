import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/multiplication_progress_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MultiplicationStats (pure)', () {
    test('empty stats return null accuracy', () {
      expect(MultiplicationStats.empty.accuracyFor(5), isNull);
      expect(MultiplicationStats.empty.correctFor(5), 0);
    });

    test('withRound accumulates', () {
      var s = MultiplicationStats.empty;
      s = s.withRound(7, 8, 10);
      expect(s.correctFor(7), 8);
      expect(s.totalFor(7), 10);
      expect(s.accuracyFor(7), 0.8);

      s = s.withRound(7, 5, 10);
      expect(s.correctFor(7), 13);
      expect(s.totalFor(7), 20);
      expect(s.accuracyFor(7), 0.65);
    });

    test('shakyTables returns weakest-first below threshold', () {
      var s = MultiplicationStats.empty;
      s = s.withRound(2, 10, 10); // 100% — strong
      s = s.withRound(3, 9, 10); // 90%  — strong
      s = s.withRound(7, 5, 10); // 50%  — shaky
      s = s.withRound(8, 7, 10); // 70%  — shaky
      s = s.withRound(11, 6, 10); // 60% — shaky

      final shaky = s.shakyTables(threshold: 0.8);
      // 7, 11, 8 — sorted by ascending accuracy.
      expect(shaky, [7, 11, 8]);
    });

    test('shakyTables ignores untouched tables', () {
      var s = MultiplicationStats.empty;
      s = s.withRound(7, 5, 10);
      final shaky = s.shakyTables();
      expect(shaky, [7]); // Only the one that has data
    });

    test('roundtrip JSON', () {
      var s = MultiplicationStats.empty;
      s = s.withRound(3, 8, 10);
      s = s.withRound(9, 4, 10);
      final restored = MultiplicationStats.fromJson(s.toJson());
      expect(restored.correctFor(3), 8);
      expect(restored.totalFor(3), 10);
      expect(restored.correctFor(9), 4);
    });

    test('fromJson tolerates malformed entries', () {
      final restored = MultiplicationStats.fromJson({
        '5': {'c': 3, 't': 10},
        'not-a-number': {'c': 1, 't': 1}, // skipped
      });
      expect(restored.tables.length, 1);
      expect(restored.correctFor(5), 3);
    });
  });

  group('MultiplicationProgressNotifier', () {
    test('starts empty', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final s = await c.read(multiplicationProgressProvider.future);
      expect(s.tables, isEmpty);
    });

    test('recordRound persists across containers', () async {
      final c1 = ProviderContainer();
      await c1.read(multiplicationProgressProvider.future);
      await c1.read(multiplicationProgressProvider.notifier).recordRound(
            table: 6,
            correct: 7,
            total: 10,
          );
      c1.dispose();

      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      final s = await c2.read(multiplicationProgressProvider.future);
      expect(s.correctFor(6), 7);
      expect(s.totalFor(6), 10);
    });

    test('reset clears storage', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(multiplicationProgressProvider.future);
      final n = c.read(multiplicationProgressProvider.notifier);
      await n.recordRound(table: 4, correct: 5, total: 10);
      await n.reset();
      final s = c.read(multiplicationProgressProvider).value!;
      expect(s.tables, isEmpty);
    });
  });
}
