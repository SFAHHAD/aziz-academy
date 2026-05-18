import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/core/quiz/multiple_choice_engine.dart';

class _T implements QuizItem {
  const _T(this.id, this.category);
  @override
  final String id;
  @override
  final String category;
}

void main() {
  group('quizStarsFor', () {
    test('zero total → zero stars', () {
      expect(quizStarsFor(0, 0), 0);
      expect(quizStarsFor(99, 0), 0);
    });
    test('full score → 3 stars', () {
      expect(quizStarsFor(10, 10), 3);
    });
    test('zero score → 0 stars', () {
      expect(quizStarsFor(0, 10), 0);
    });
    test('clamps absurd inputs', () {
      expect(quizStarsFor(-1, 10), 0);
      expect(quizStarsFor(100, 10), 3);
    });
    test('rounds 50% to 2 stars', () {
      expect(quizStarsFor(5, 10), 2);
    });
  });

  group('buildQuizOptions', () {
    test('returns 4 options including correct', () {
      final pool = [for (var i = 0; i < 20; i++) _T('$i', 'cat')];
      final opts = buildQuizOptions(pool.first, pool, rng: math.Random(1));
      expect(opts.length, 4);
      expect(opts.any((o) => o.id == pool.first.id), isTrue);
    });

    test('no duplicate ids', () {
      final pool = [for (var i = 0; i < 20; i++) _T('$i', 'cat')];
      final opts = buildQuizOptions(pool.first, pool, rng: math.Random(2));
      final ids = opts.map((o) => o.id).toSet();
      expect(ids.length, opts.length);
    });

    test('prefers same-category distractors', () {
      final pool = [
        const _T('A', 'mercy'),
        const _T('B', 'mercy'),
        const _T('C', 'mercy'),
        const _T('D', 'mercy'),
        for (var i = 10; i < 50; i++) _T('o$i', 'majesty'),
      ];
      final opts = buildQuizOptions(pool.first, pool, rng: math.Random(5));
      final distractors = opts.where((o) => o.id != 'A').toList();
      expect(distractors.length, 3);
      expect(distractors.every((d) => d.category == 'mercy'), isTrue);
    });

    test('falls back to other categories when same-cat is too small', () {
      final pool = [
        const _T('A', 'mercy'),
        for (var i = 10; i < 50; i++) _T('o$i', 'majesty'),
      ];
      final opts = buildQuizOptions(pool.first, pool, rng: math.Random(7));
      expect(opts.length, 4);
      final distractors = opts.where((o) => o.id != 'A').toList();
      expect(distractors.every((d) => d.category == 'majesty'), isTrue);
    });
  });

  group('buildQuizRound', () {
    test('returns N questions, each with 4 options', () {
      final pool = [
        for (var i = 0; i < 30; i++) _T('$i', i.isEven ? 'a' : 'b'),
      ];
      final qs = buildQuizRound(pool, roundSize: 10, rng: math.Random(1));
      expect(qs.length, 10);
      for (final q in qs) {
        expect(q.options.length, 4);
        expect(q.options.any((o) => o.id == q.name.id), isTrue);
      }
    });

    test('empty when pool < 4', () {
      expect(buildQuizRound([const _T('a', 'x')]), isEmpty);
      expect(
        buildQuizRound([
          const _T('a', 'x'),
          const _T('b', 'x'),
          const _T('c', 'x'),
        ]),
        isEmpty,
      );
    });

    test('caps round size to pool size', () {
      final pool = [for (var i = 0; i < 6; i++) _T('$i', 'cat')];
      final qs = buildQuizRound(pool, roundSize: 10, rng: math.Random(2));
      expect(qs.length, 6);
    });
  });
}
