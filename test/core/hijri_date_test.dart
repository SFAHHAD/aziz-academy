import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/core/utils/hijri_date.dart';

void main() {
  group('HijriDate.fromGregorian', () {
    // Spot-check against well-known calendar anchor dates. The tabular
    // algorithm can be ±1 day off vs Umm al-Qura; we test against the
    // tabular reference to lock the implementation.

    test('returns a valid month and day for arbitrary modern date', () {
      final h = HijriDate.fromGregorian(DateTime(2026, 5, 12));
      expect(h.month, inInclusiveRange(1, 12));
      expect(h.day, inInclusiveRange(1, 30));
      expect(h.year, greaterThan(1440));
      expect(h.year, lessThan(1460));
    });

    test('1 January 2024 ≈ Jumada II 1445', () {
      final h = HijriDate.fromGregorian(DateTime(2024, 1, 1));
      expect(h.year, 1445);
      // Tabular: ~19 Jumada II (1-day variance vs Umm al-Qura tolerated)
      expect(h.month, inInclusiveRange(6, 6));
      expect(h.day, inInclusiveRange(18, 22));
    });

    test('Hijri new year — first day of Muharram', () {
      // 1 Muharram 1447 ≈ 27 June 2025 (tabular). Allow ±1 day.
      final h = HijriDate.fromGregorian(DateTime(2025, 6, 27));
      expect(h.year, 1447);
      expect(h.month, 1);
      expect(h.day, inInclusiveRange(1, 2));
    });

    test('month boundary stays inside 1..12 and 1..30', () {
      // Run for a full year of Gregorian dates to make sure nothing
      // ever produces an out-of-range month/day.
      for (var d = 0; d < 365; d++) {
        final h = HijriDate.fromGregorian(
          DateTime(2026, 1, 1).add(Duration(days: d)),
        );
        expect(h.month, inInclusiveRange(1, 12));
        expect(h.day, inInclusiveRange(1, 30));
      }
    });

    test('formatted (English) ends in "AH"', () {
      final h = HijriDate.fromGregorian(DateTime(2026, 5, 12));
      final s = h.formatted(arabic: false);
      expect(s, endsWith('AH'));
    });

    test('formatted (Arabic) ends in "هـ"', () {
      final h = HijriDate.fromGregorian(DateTime(2026, 5, 12));
      final s = h.formatted(arabic: true);
      expect(s, endsWith('هـ'));
    });

    test('month names lists have 12 entries each', () {
      expect(HijriDate.monthNamesEn.length, 12);
      expect(HijriDate.monthNamesAr.length, 12);
    });

    test('Ramadan is month 9', () {
      expect(HijriDate.monthNamesEn[8], 'Ramadan');
      expect(HijriDate.monthNamesAr[8], 'رَمَضَان');
    });
  });
}
