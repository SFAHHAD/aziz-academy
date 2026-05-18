import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/features/daily_wisdom_quiz/daily_question_engine.dart';

DailyPoolItem _item(String id) => DailyPoolItem(
      id: id,
      promptEn: 'p_$id',
      promptAr: 'پ_$id',
      answerEn: 'a_$id',
      answerAr: 'ج_$id',
    );

List<DailyPoolItem> _pool(String prefix, int n) =>
    [for (var i = 0; i < n; i++) _item('${prefix}_$i')];

void main() {
  group('buildDailyQuestion', () {
    final hadith = _pool('h', 25);
    final asma = _pool('a', 99);
    final prophet = _pool('p', 25);

    test('returns 4 options including the correct answer', () {
      final q = buildDailyQuestion(
        date: DateTime(2026, 5, 12),
        hadith: hadith,
        asma: asma,
        prophet: prophet,
      );
      expect(q.options.length, 4);
      expect(q.options.any((o) => o.id == q.correct.id), isTrue);
    });

    test('same date produces same question (determinism)', () {
      final d = DateTime(2026, 5, 12);
      final q1 = buildDailyQuestion(
        date: d,
        hadith: hadith,
        asma: asma,
        prophet: prophet,
      );
      final q2 = buildDailyQuestion(
        date: d,
        hadith: hadith,
        asma: asma,
        prophet: prophet,
      );
      expect(q1.kind, q2.kind);
      expect(q1.correct.id, q2.correct.id);
      expect(
        q1.options.map((o) => o.id).toList(),
        q2.options.map((o) => o.id).toList(),
      );
    });

    test('different dates rotate kinds (over 3 consecutive days)', () {
      final base = DateTime(2026, 5, 12);
      final kinds = <DailyQuestionKind>{
        for (var i = 0; i < 6; i++)
          buildDailyQuestion(
            date: base.add(Duration(days: i)),
            hadith: hadith,
            asma: asma,
            prophet: prophet,
          ).kind,
      };
      // Across 6 days we must see all 3 kinds at least once.
      expect(kinds.length, 3);
    });

    test('no duplicate options', () {
      final q = buildDailyQuestion(
        date: DateTime(2026, 3, 15),
        hadith: hadith,
        asma: asma,
        prophet: prophet,
      );
      final ids = q.options.map((o) => o.id).toSet();
      expect(ids.length, q.options.length);
    });

    test('empty pool for that day still returns a result (no crash)', () {
      // Force the hadith day (deterministic for this date).
      final q = buildDailyQuestion(
        date: DateTime(2026, 5, 12),
        hadith: const [],
        asma: asma,
        prophet: prophet,
      );
      // If hadith pool is too small the engine returns a degenerate
      // result rather than throwing — caller renders ContentEmptyState.
      expect(q.options, isA<List<DailyPoolItem>>());
    });
  });

  group('isSameCalendarDay', () {
    test('matches same Y-M-D regardless of time', () {
      expect(
        isSameCalendarDay(
          DateTime(2026, 5, 12, 0, 0),
          DateTime(2026, 5, 12, 23, 59),
        ),
        isTrue,
      );
    });
    test('rejects different days', () {
      expect(
        isSameCalendarDay(
          DateTime(2026, 5, 12),
          DateTime(2026, 5, 13),
        ),
        isFalse,
      );
    });
  });

  group('isNextCalendarDay', () {
    test('+1 day is next', () {
      expect(
        isNextCalendarDay(DateTime(2026, 5, 12), DateTime(2026, 5, 13)),
        isTrue,
      );
    });
    test('same day is not next', () {
      expect(
        isNextCalendarDay(DateTime(2026, 5, 12), DateTime(2026, 5, 12)),
        isFalse,
      );
    });
    test('two-day gap is not next', () {
      expect(
        isNextCalendarDay(DateTime(2026, 5, 12), DateTime(2026, 5, 14)),
        isFalse,
      );
    });
    test('crosses month boundary', () {
      expect(
        isNextCalendarDay(DateTime(2026, 5, 31), DateTime(2026, 6, 1)),
        isTrue,
      );
    });
    test('crosses year boundary', () {
      expect(
        isNextCalendarDay(DateTime(2026, 12, 31), DateTime(2027, 1, 1)),
        isTrue,
      );
    });
  });
}
