import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/features/mental_math/mental_math_engine.dart';

void main() {
  group('generateMentalQuestion', () {
    test('easy band only uses + and −', () {
      final rng = math.Random(1);
      for (var i = 0; i < 50; i++) {
        final q = generateMentalQuestion(MentalMathBand.easy, rng: rng);
        expect([MentalOp.add, MentalOp.sub], contains(q.op));
      }
    });

    test('easy subtractions are non-negative', () {
      final rng = math.Random(2);
      for (var i = 0; i < 100; i++) {
        final q = generateMentalQuestion(MentalMathBand.easy, rng: rng);
        expect(q.answer, greaterThanOrEqualTo(0));
      }
    });

    test('medium band includes ×, never ÷', () {
      final rng = math.Random(3);
      final ops = <MentalOp>{};
      for (var i = 0; i < 60; i++) {
        ops.add(generateMentalQuestion(MentalMathBand.medium, rng: rng).op);
      }
      expect(ops, contains(MentalOp.mul));
      expect(ops, isNot(contains(MentalOp.div)));
    });

    test('hard band can produce all four operations', () {
      final rng = math.Random(4);
      final ops = <MentalOp>{};
      for (var i = 0; i < 200; i++) {
        ops.add(generateMentalQuestion(MentalMathBand.hard, rng: rng).op);
      }
      expect(ops.length, 4);
    });

    test('hard divisions always produce whole-number answers', () {
      final rng = math.Random(5);
      var divs = 0;
      for (var i = 0; i < 200; i++) {
        final q = generateMentalQuestion(MentalMathBand.hard, rng: rng);
        if (q.op == MentalOp.div) {
          divs++;
          expect(q.a % q.b, 0,
              reason: 'division ${q.a}/${q.b} should be whole, got ${q.a / q.b}');
          expect(q.a ~/ q.b, q.answer);
        }
      }
      expect(divs, greaterThan(0));
    });

    test('answers always match the operation', () {
      final rng = math.Random(6);
      for (final band in MentalMathBand.values) {
        for (var i = 0; i < 60; i++) {
          final q = generateMentalQuestion(band, rng: rng);
          final expected = switch (q.op) {
            MentalOp.add => q.a + q.b,
            MentalOp.sub => q.a - q.b,
            MentalOp.mul => q.a * q.b,
            MentalOp.div => q.a ~/ q.b,
          };
          expect(q.answer, expected);
        }
      }
    });

    test('prompt format includes operands and symbol', () {
      const q = MentalQuestion(a: 7, b: 5, op: MentalOp.mul, answer: 35);
      expect(q.prompt, contains('7'));
      expect(q.prompt, contains('5'));
      expect(q.prompt, contains('×'));
    });
  });

  group('generateMentalOptions', () {
    test('returns exactly 4 unique positive options including answer', () {
      final rng = math.Random(7);
      for (var i = 0; i < 30; i++) {
        final q = generateMentalQuestion(MentalMathBand.medium, rng: rng);
        final opts = generateMentalOptions(q, rng: rng);
        expect(opts.length, 4);
        expect(opts.toSet().length, 4);
        expect(opts.every((o) => o > 0), isTrue);
        expect(opts, contains(q.answer));
      }
    });
  });
}
