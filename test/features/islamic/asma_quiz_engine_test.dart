import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/features/asma_ul_husna/asma_quiz_engine.dart';

AsmaName _n(int i, String cat, {String? en}) => AsmaName(
  n: i,
  nameAr: 'اسم$i',
  tr: 'Name$i',
  en: en ?? 'Meaning $i',
  enAr: 'معنى $i',
  category: cat,
);

void main() {
  group('asmaStarsFor', () {
    test('returns 0 for empty round', () {
      expect(asmaStarsFor(0, 0), 0);
      expect(asmaStarsFor(5, 0), 0);
    });
    test('full score gives 3 stars', () {
      expect(asmaStarsFor(10, 10), 3);
    });
    test('zero score gives 0 stars', () {
      expect(asmaStarsFor(0, 10), 0);
    });
    test('partial score buckets — 50% rounds to 2 stars', () {
      expect(asmaStarsFor(5, 10), 2);
    });
    test('70% rounds to 2 stars', () {
      // 0.7 * 3 = 2.1 → round → 2
      expect(asmaStarsFor(7, 10), 2);
    });
    test('83% rounds to 2 stars, 84% rounds to 3', () {
      // 0.833 * 3 = 2.5 → round → 3 in Dart (banker's? no, half-away)
      expect(asmaStarsFor(5, 6), 3);
    });
    test('clamps even with absurd inputs', () {
      expect(asmaStarsFor(100, 10), 3);
      expect(asmaStarsFor(-5, 10), 0);
    });
  });

  group('buildAsmaOptions', () {
    test('returns 4 options including the correct answer', () {
      final pool = [for (var i = 0; i < 20; i++) _n(i, 'mercy')];
      final correct = pool.first;
      final opts = buildAsmaOptions(correct, pool, rng: math.Random(1));
      expect(opts.length, 4);
      expect(opts.any((o) => o.n == correct.n), isTrue);
    });

    test('no duplicate names among options', () {
      final pool = [for (var i = 0; i < 20; i++) _n(i, 'mercy')];
      final opts = buildAsmaOptions(pool.first, pool, rng: math.Random(2));
      final ids = opts.map((o) => o.n).toSet();
      expect(ids.length, opts.length);
    });

    test('prefers same-category distractors when available', () {
      final pool = [
        _n(0, 'mercy'), // correct
        _n(1, 'mercy'),
        _n(2, 'mercy'),
        _n(3, 'mercy'),
        // tons of other-category fillers
        for (var i = 10; i < 50; i++) _n(i, 'majesty'),
      ];
      final opts =
          buildAsmaOptions(pool.first, pool, rng: math.Random(42));
      final distractors = opts.where((o) => o.n != 0).toList();
      expect(distractors.length, 3);
      // With 3 same-category options available, all 3 distractors should
      // come from 'mercy'.
      expect(
        distractors.every((d) => d.category == 'mercy'),
        isTrue,
        reason: 'expected all same-category distractors, got '
            '${distractors.map((d) => d.category).toList()}',
      );
    });

    test('falls back to other-category when same-cat is too small', () {
      final pool = [
        _n(0, 'mercy'), // correct, no other mercy names
        for (var i = 10; i < 50; i++) _n(i, 'majesty'),
      ];
      final opts =
          buildAsmaOptions(pool.first, pool, rng: math.Random(7));
      expect(opts.length, 4);
      // 3 distractors must come from 'majesty' since mercy only has 1.
      final distractors = opts.where((o) => o.n != 0).toList();
      expect(distractors.every((d) => d.category == 'majesty'), isTrue);
    });

    test('skips distractors with identical English meaning', () {
      // Two names share the same en text. They should not both appear.
      final pool = [
        _n(0, 'mercy', en: 'The Merciful'), // correct
        _n(1, 'mercy', en: 'The Merciful'), // duplicate meaning — skip
        _n(2, 'mercy', en: 'The Compassionate'),
        _n(3, 'mercy', en: 'The Forgiver'),
        _n(4, 'mercy', en: 'The Kind'),
      ];
      final opts =
          buildAsmaOptions(pool.first, pool, rng: math.Random(9));
      final distractors = opts.where((o) => o.n != 0).toList();
      expect(
        distractors.any((d) => d.en == 'The Merciful'),
        isFalse,
        reason: 'distractor with same meaning as correct must be filtered',
      );
    });
  });

  group('buildAsmaQuestions', () {
    test('returns the requested number of questions', () {
      final pool = [
        for (var i = 0; i < 30; i++) _n(i, i.isEven ? 'mercy' : 'majesty'),
      ];
      final qs =
          buildAsmaQuestions(pool, roundSize: 10, rng: math.Random(1));
      expect(qs.length, 10);
      for (final q in qs) {
        expect(q.options.length, 4);
        expect(q.options.any((o) => o.n == q.name.n), isTrue);
      }
    });

    test('returns empty when pool is smaller than 4', () {
      final tiny = [_n(0, 'mercy'), _n(1, 'mercy'), _n(2, 'mercy')];
      expect(buildAsmaQuestions(tiny), isEmpty);
    });

    test('caps round size to pool size', () {
      final pool = [for (var i = 0; i < 6; i++) _n(i, 'mercy')];
      final qs =
          buildAsmaQuestions(pool, roundSize: 10, rng: math.Random(3));
      expect(qs.length, 6);
    });
  });

  group('AsmaName.fromJson', () {
    test('parses canonical pack shape', () {
      final n = AsmaName.fromJson({
        'n': 1,
        'name_ar': 'الرحمن',
        'name': 'Ar-Rahman',
        'en': 'The Most Merciful',
        'en_ar': 'الرحمن',
        'category': 'mercy',
      });
      expect(n.n, 1);
      expect(n.nameAr, 'الرحمن');
      expect(n.tr, 'Ar-Rahman');
      expect(n.en, 'The Most Merciful');
      expect(n.category, 'mercy');
    });

    test('tolerates missing optional fields', () {
      final n = AsmaName.fromJson({'n': 5});
      expect(n.n, 5);
      expect(n.nameAr, '');
      expect(n.en, '');
    });
  });
}
