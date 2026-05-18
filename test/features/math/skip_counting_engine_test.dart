import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/features/skip_counting/skip_counting_engine.dart';

void main() {
  group('stepFor', () {
    test('maps each mode to the correct step', () {
      expect(stepFor(SkipMode.twos), 2);
      expect(stepFor(SkipMode.fives), 5);
      expect(stepFor(SkipMode.tens), 10);
    });
  });

  group('generateSkipQuestion', () {
    test('sequence is six values stepping by stepFor(mode)', () {
      final rng = math.Random(1);
      for (final mode in SkipMode.values) {
        for (var i = 0; i < 60; i++) {
          final q = generateSkipQuestion(mode, rng: rng);
          expect(q.sequence.length, 6);
          for (var k = 1; k < q.sequence.length; k++) {
            expect(q.sequence[k] - q.sequence[k - 1], stepFor(mode));
          }
        }
      }
    });

    test('answer equals sequence[blankIndex]', () {
      final rng = math.Random(2);
      for (final mode in SkipMode.values) {
        for (var i = 0; i < 60; i++) {
          final q = generateSkipQuestion(mode, rng: rng);
          expect(q.answer, q.sequence[q.blankIndex]);
        }
      }
    });

    test('blankIndex is never first or last (context on both sides)', () {
      final rng = math.Random(3);
      for (var i = 0; i < 100; i++) {
        final q = generateSkipQuestion(SkipMode.twos, rng: rng);
        expect(q.blankIndex, greaterThanOrEqualTo(1));
        expect(q.blankIndex, lessThanOrEqualTo(4));
      }
    });

    test('sequence starts at a multiple of the step (canonical)', () {
      final rng = math.Random(4);
      for (final mode in SkipMode.values) {
        for (var i = 0; i < 50; i++) {
          final q = generateSkipQuestion(mode, rng: rng);
          expect(q.sequence.first % stepFor(mode), 0);
        }
      }
    });
  });

  group('generateSkipQuestion with weights', () {
    test('omitting weights preserves uniform sampling (back-compat)', () {
      final rng = math.Random(11);
      // 200 draws should produce many distinct answers; no single
      // answer should dominate.
      final answers = <int, int>{};
      for (var i = 0; i < 200; i++) {
        final q = generateSkipQuestion(SkipMode.twos, rng: rng);
        answers[q.answer] = (answers[q.answer] ?? 0) + 1;
      }
      expect(answers.keys.length, greaterThan(10));
      final maxCount = answers.values.reduce((a, b) => a > b ? a : b);
      expect(maxCount, lessThan(40));
    });

    test('weighted answer appears far more often when valid placement exists',
        () {
      final rng = math.Random(101);
      // 14 is a valid bonds-of-2 answer (multiple of 2, placeable in
      // sequence). Weight it heavily.
      final weights = {14: 10};
      var hits14 = 0;
      const trials = 400;
      for (var i = 0; i < trials; i++) {
        final q = generateSkipQuestion(
          SkipMode.twos,
          rng: rng,
          weights: weights,
        );
        if (q.answer == 14) hits14++;
      }
      // Uniform draws ≈ 400 / ~20 distinct answers ≈ 20 hits.
      // Weighted with 10-miss bias should produce significantly more.
      expect(hits14, greaterThan(60));
    });

    test('weights that violate step modulus fall back to uniform', () {
      final rng = math.Random(5);
      // 13 is not a multiple of 5 — cannot be placed in a by-5
      // sequence. The generator should fall back gracefully.
      final weights = {13: 10};
      for (var i = 0; i < 50; i++) {
        final q = generateSkipQuestion(
          SkipMode.fives,
          rng: rng,
          weights: weights,
        );
        expect(q.answer % 5, 0);
        expect(q.sequence.length, 6);
      }
    });

    test('sequence invariants hold under weighted sampling', () {
      final rng = math.Random(77);
      final weights = {20: 5, 30: 5};
      for (var i = 0; i < 60; i++) {
        final q = generateSkipQuestion(
          SkipMode.tens,
          rng: rng,
          weights: weights,
        );
        // Still a canonical sequence stepping by 10.
        for (var k = 1; k < q.sequence.length; k++) {
          expect(q.sequence[k] - q.sequence[k - 1], 10);
        }
        // Blank is in the middle.
        expect(q.blankIndex, greaterThanOrEqualTo(1));
        expect(q.blankIndex, lessThanOrEqualTo(4));
        // Answer matches sequence at blank.
        expect(q.answer, q.sequence[q.blankIndex]);
      }
    });
  });

  group('generateSkipOptions', () {
    test('returns 4 unique options including the answer', () {
      final rng = math.Random(5);
      for (final mode in SkipMode.values) {
        for (var i = 0; i < 40; i++) {
          final q = generateSkipQuestion(mode, rng: rng);
          final opts = generateSkipOptions(q, rng: rng);
          expect(opts.length, 4);
          expect(opts.toSet().length, 4);
          expect(opts, contains(q.answer));
        }
      }
    });
  });
}
