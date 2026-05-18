import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/mental_math_bests_provider.dart';
import 'package:aziz_academy/features/mental_math/mental_math_engine.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MentalMathBests (pure)', () {
    test('empty returns 0 for every band', () {
      for (final b in MentalMathBand.values) {
        expect(MentalMathBests.empty.bestFor(b), 0);
      }
    });

    test('withMax only updates when higher', () {
      var b = MentalMathBests.empty;
      b = b.withMax(MentalMathBand.easy, 12);
      expect(b.bestFor(MentalMathBand.easy), 12);
      b = b.withMax(MentalMathBand.easy, 5); // lower — ignored
      expect(b.bestFor(MentalMathBand.easy), 12);
      b = b.withMax(MentalMathBand.easy, 20);
      expect(b.bestFor(MentalMathBand.easy), 20);
    });

    test('bands are independent', () {
      var b = MentalMathBests.empty;
      b = b.withMax(MentalMathBand.easy, 30);
      b = b.withMax(MentalMathBand.medium, 18);
      expect(b.bestFor(MentalMathBand.easy), 30);
      expect(b.bestFor(MentalMathBand.medium), 18);
      expect(b.bestFor(MentalMathBand.hard), 0);
    });

    test('roundtrip JSON', () {
      var b = MentalMathBests.empty;
      b = b.withMax(MentalMathBand.medium, 22);
      final restored = MentalMathBests.fromJson(b.toJson());
      expect(restored.bestFor(MentalMathBand.medium), 22);
    });
  });

  group('MentalMathBestsNotifier', () {
    test('records and returns isPB flag correctly', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(mentalMathBestsProvider.future);
      final n = c.read(mentalMathBestsProvider.notifier);

      final pb1 = await n.recordScore(MentalMathBand.easy, 10);
      expect(pb1, isTrue);

      final pb2 = await n.recordScore(MentalMathBand.easy, 5);
      expect(pb2, isFalse);

      final pb3 = await n.recordScore(MentalMathBand.easy, 15);
      expect(pb3, isTrue);
      expect(c.read(mentalMathBestsProvider).value!.bestFor(MentalMathBand.easy),
          15);
    });

    test('persists across container rebuilds', () async {
      final c1 = ProviderContainer();
      await c1.read(mentalMathBestsProvider.future);
      await c1
          .read(mentalMathBestsProvider.notifier)
          .recordScore(MentalMathBand.hard, 25);
      c1.dispose();

      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      final s = await c2.read(mentalMathBestsProvider.future);
      expect(s.bestFor(MentalMathBand.hard), 25);
    });
  });
}
