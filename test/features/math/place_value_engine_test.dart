import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/features/place_value/place_value_engine.dart';

void main() {
  group('generatePvQuestion', () {
    test('always produces a two-digit number (10..99)', () {
      final rng = math.Random(1);
      for (var i = 0; i < 200; i++) {
        final q = generatePvQuestion(
          i.isEven ? PvMode.blocksToNumber : PvMode.numberToBlocks,
          rng: rng,
        );
        expect(q.number, greaterThanOrEqualTo(10));
        expect(q.number, lessThanOrEqualTo(99));
        expect(q.tens, q.number ~/ 10);
        expect(q.ones, q.number % 10);
      }
    });

    test('blocksToNumber answer matches the number', () {
      final rng = math.Random(2);
      for (var i = 0; i < 60; i++) {
        final q = generatePvQuestion(PvMode.blocksToNumber, rng: rng);
        expect(q.answer, q.number);
      }
    });

    test('numberToBlocks answer matches the digit asked for', () {
      final rng = math.Random(3);
      for (var i = 0; i < 200; i++) {
        final q = generatePvQuestion(PvMode.numberToBlocks, rng: rng);
        expect(q.answer, q.askTens ? q.tens : q.ones);
      }
    });
  });

  group('generatePvQuestion with weights', () {
    test('omitting weights preserves uniform sampling (back-compat)', () {
      final rng = math.Random(42);
      final counts = <int, int>{};
      for (var i = 0; i < 400; i++) {
        final q = generatePvQuestion(PvMode.blocksToNumber, rng: rng);
        counts[q.number] = (counts[q.number] ?? 0) + 1;
      }
      // 90 candidates, 400 draws → average ~4.4 per value, max should
      // stay well below the "biased" threshold.
      final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
      expect(maxCount, lessThan(20));
      expect(counts.keys.length, greaterThan(50));
    });

    test('high weight biases sampling toward the weighted number', () {
      final rng = math.Random(99);
      final weights = {37: 10};
      var hits37 = 0;
      const trials = 600;
      for (var i = 0; i < trials; i++) {
        final q = generatePvQuestion(
          PvMode.blocksToNumber,
          rng: rng,
          weights: weights,
        );
        if (q.number == 37) hits37++;
      }
      // Uniform would yield ~6.7 (600/90). Weighted should be ≥3×.
      expect(hits37, greaterThan(20));
    });

    test('weights only affect number — tens/ones still decompose correctly',
        () {
      final rng = math.Random(7);
      final weights = {25: 5, 88: 5};
      for (var i = 0; i < 100; i++) {
        final q = generatePvQuestion(
          PvMode.blocksToNumber,
          rng: rng,
          weights: weights,
        );
        expect(q.tens, q.number ~/ 10);
        expect(q.ones, q.number % 10);
        expect(q.number, greaterThanOrEqualTo(10));
        expect(q.number, lessThanOrEqualTo(99));
      }
    });
  });

  group('generatePvOptions', () {
    test('returns 4 unique options including the answer', () {
      final rng = math.Random(4);
      for (var i = 0; i < 60; i++) {
        final q = generatePvQuestion(
          i.isEven ? PvMode.blocksToNumber : PvMode.numberToBlocks,
          rng: rng,
        );
        final opts = generatePvOptions(q, rng: rng);
        expect(opts.length, 4);
        expect(opts.toSet().length, 4);
        expect(opts, contains(q.answer));
      }
    });

    test('digit-mode options stay in 0..9', () {
      final rng = math.Random(5);
      for (var i = 0; i < 60; i++) {
        final q = generatePvQuestion(PvMode.numberToBlocks, rng: rng);
        final opts = generatePvOptions(q, rng: rng);
        for (final o in opts) {
          expect(o, greaterThanOrEqualTo(0));
          expect(o, lessThanOrEqualTo(9));
        }
      }
    });
  });
}
