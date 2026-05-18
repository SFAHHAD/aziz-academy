import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/features/number_bonds/number_bonds_engine.dart';

void main() {
  group('generateBondQuestion', () {
    test('bonds-to-10: shown + answer always equals 10', () {
      final rng = math.Random(1);
      for (var i = 0; i < 200; i++) {
        final q = generateBondQuestion(BondTarget.ten, rng: rng);
        expect(q.target, 10);
        expect(q.shown + q.answer, 10);
      }
    });

    test('bonds-to-20: shown + answer always equals 20', () {
      final rng = math.Random(2);
      for (var i = 0; i < 200; i++) {
        final q = generateBondQuestion(BondTarget.twenty, rng: rng);
        expect(q.target, 20);
        expect(q.shown + q.answer, 20);
      }
    });

    test('shown stays in 1..target-1 (no trivial 0/target answers)', () {
      final rng = math.Random(3);
      for (final t in BondTarget.values) {
        final tv = t == BondTarget.ten ? 10 : 20;
        for (var i = 0; i < 200; i++) {
          final q = generateBondQuestion(t, rng: rng);
          expect(q.shown, greaterThanOrEqualTo(1));
          expect(q.shown, lessThanOrEqualTo(tv - 1));
          expect(q.answer, greaterThanOrEqualTo(1));
          expect(q.answer, lessThanOrEqualTo(tv - 1));
        }
      }
    });
  });

  group('generateBondQuestion with weights', () {
    test('omitting weights preserves uniform sampling (back-compat)', () {
      final rng = math.Random(42);
      // Smoke check: 200 draws from bonds-to-10 should cover most
      // shown values without any single one dominating > 40% of the
      // pool.
      final counts = <int, int>{};
      for (var i = 0; i < 200; i++) {
        final q = generateBondQuestion(BondTarget.ten, rng: rng);
        counts[q.shown] = (counts[q.shown] ?? 0) + 1;
      }
      final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
      expect(maxCount, lessThan(80));
      expect(counts.keys.length, greaterThan(6));
    });

    test('high weight biases sampling toward the weighted shown value', () {
      final rng = math.Random(123);
      // shown=7 carries miss count 10 — should appear far more often.
      final weights = {7: 10};
      var hits7 = 0;
      const trials = 300;
      for (var i = 0; i < trials; i++) {
        final q = generateBondQuestion(
          BondTarget.ten,
          rng: rng,
          weights: weights,
        );
        if (q.shown == 7) hits7++;
      }
      // Uniform sampling would give ~33 (300/9). Weighted should be
      // dramatically higher — assert at least 2× uniform.
      expect(hits7, greaterThan(66));
    });

    test('weights only affect shown — answer + target still hold', () {
      final rng = math.Random(7);
      final weights = {5: 5};
      for (var i = 0; i < 100; i++) {
        final q = generateBondQuestion(
          BondTarget.twenty,
          rng: rng,
          weights: weights,
        );
        expect(q.target, 20);
        expect(q.shown + q.answer, 20);
      }
    });
  });

  group('generateBondOptions', () {
    test('returns 4 unique options including the correct answer', () {
      final rng = math.Random(4);
      for (var i = 0; i < 60; i++) {
        final q = generateBondQuestion(
          i.isEven ? BondTarget.ten : BondTarget.twenty,
          rng: rng,
        );
        final opts = generateBondOptions(q, rng: rng);
        expect(opts.length, 4);
        expect(opts.toSet().length, 4);
        expect(opts, contains(q.answer));
      }
    });

    test('options stay within [0, target]', () {
      final rng = math.Random(5);
      for (var i = 0; i < 60; i++) {
        final q = generateBondQuestion(BondTarget.twenty, rng: rng);
        final opts = generateBondOptions(q, rng: rng);
        for (final o in opts) {
          expect(o, greaterThanOrEqualTo(0));
          expect(o, lessThanOrEqualTo(q.target));
        }
      }
    });
  });
}
