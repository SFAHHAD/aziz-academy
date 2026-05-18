import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/features/fractions_practice/fractions_engine.dart';

void main() {
  group('FractionVal', () {
    test('value is numerator/denominator', () {
      expect(const FractionVal(1, 2).value, 0.5);
      expect(const FractionVal(3, 4).value, 0.75);
    });

    test('equality is structural', () {
      expect(const FractionVal(2, 3), const FractionVal(2, 3));
      expect(const FractionVal(2, 3), isNot(const FractionVal(1, 2)));
    });

    test('toString is "n/d"', () {
      expect(const FractionVal(3, 7).toString(), '3/7');
    });
  });

  group('fractionStarsFor', () {
    test('handles zero total', () {
      expect(fractionStarsFor(0, 0), 0);
    });
    test('full → 3 stars', () {
      expect(fractionStarsFor(10, 10), 3);
    });
    test('zero → 0 stars', () {
      expect(fractionStarsFor(0, 10), 0);
    });
    test('clamps absurd input', () {
      expect(fractionStarsFor(-1, 10), 0);
      expect(fractionStarsFor(99, 10), 3);
    });
  });

  group('generateIdentifyQuestion', () {
    test('returns 4 unique options including the correct value', () {
      final rng = math.Random(1);
      for (var i = 0; i < 50; i++) {
        final q = generateIdentifyQuestion(rng: rng);
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        expect(q.options, contains(q.correct));
      }
    });

    test('no distractor has the same numeric value as the correct answer', () {
      final rng = math.Random(2);
      for (var i = 0; i < 100; i++) {
        final q = generateIdentifyQuestion(rng: rng);
        final wrongs = q.options.where((o) => o != q.correct);
        for (final w in wrongs) {
          expect(w.value, isNot(q.correct.value),
              reason: 'option $w has same value as ${q.correct}');
        }
      }
    });

    test('fractions are always proper (numerator < denominator)', () {
      final rng = math.Random(3);
      for (var i = 0; i < 100; i++) {
        final q = generateIdentifyQuestion(rng: rng);
        for (final o in q.options) {
          expect(o.numerator, lessThan(o.denominator));
          expect(o.numerator, greaterThanOrEqualTo(1));
          expect(o.denominator, greaterThanOrEqualTo(2));
        }
      }
    });
  });

  group('generateCompareQuestion', () {
    test('left and right have different values', () {
      final rng = math.Random(4);
      for (var i = 0; i < 100; i++) {
        final q = generateCompareQuestion(rng: rng);
        expect(q.left.value, isNot(q.right.value));
      }
    });

    test('leftIsBigger flag matches the actual comparison', () {
      final rng = math.Random(5);
      for (var i = 0; i < 100; i++) {
        final q = generateCompareQuestion(rng: rng);
        expect(q.leftIsBigger, q.left.value > q.right.value);
      }
    });
  });
}
