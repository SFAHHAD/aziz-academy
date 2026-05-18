import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/features/number_bonds/number_bonds_engine.dart';
import 'package:aziz_academy/features/place_value/place_value_engine.dart';
import 'package:aziz_academy/features/skip_counting/skip_counting_engine.dart';

void main() {
  group('bondTeachingHint', () {
    test('English form includes both operations', () {
      const q = BondQuestion(target: 10, shown: 7, answer: 3);
      final h = bondTeachingHint(q, arabic: false);
      expect(h.en, contains('10 − 7 = 3'));
      expect(h.en, contains('7 + 3 = 10'));
    });

    test('Arabic form uses Arabic-Indic digits', () {
      const q = BondQuestion(target: 10, shown: 7, answer: 3);
      final h = bondTeachingHint(q, arabic: true);
      expect(h.ar, contains('١٠'));
      expect(h.ar, contains('٧'));
      expect(h.ar, contains('٣'));
    });
  });

  group('pvTeachingHint', () {
    test('blocksToNumber decomposes the number into tens+ones', () {
      const q = PvQuestion(
        mode: PvMode.blocksToNumber,
        number: 78,
        tens: 7,
        ones: 8,
        askTens: false,
        answer: 78,
      );
      final h = pvTeachingHint(q, arabic: false);
      expect(h.en, contains('7 tens'));
      expect(h.en, contains('8 ones'));
      expect(h.en, contains('70 + 8 = 78'));
    });

    test('digit mode (tens) explains the tens place', () {
      const q = PvQuestion(
        mode: PvMode.numberToBlocks,
        number: 78,
        tens: 7,
        ones: 8,
        askTens: true,
        answer: 7,
      );
      final h = pvTeachingHint(q, arabic: false);
      expect(h.en, contains('In 78'));
      expect(h.en, contains('tens place'));
      expect(h.en, contains('70'));
    });

    test('digit mode (ones) explains the ones place', () {
      const q = PvQuestion(
        mode: PvMode.numberToBlocks,
        number: 78,
        tens: 7,
        ones: 8,
        askTens: false,
        answer: 8,
      );
      final h = pvTeachingHint(q, arabic: false);
      expect(h.en, contains('In 78'));
      expect(h.en, contains('ones place'));
    });
  });

  group('skipTeachingHint', () {
    test('shows previous + step = answer', () {
      const q = SkipQuestion(
        mode: SkipMode.twos,
        sequence: [4, 6, 8, 10, 12, 14],
        blankIndex: 3,
        answer: 10,
      );
      final h = skipTeachingHint(q, arabic: false);
      expect(h.en, contains('8 + 2 = 10'));
    });

    test('Arabic form uses Arabic-Indic digits', () {
      const q = SkipQuestion(
        mode: SkipMode.fives,
        sequence: [5, 10, 15, 20, 25, 30],
        blankIndex: 3,
        answer: 20,
      );
      final h = skipTeachingHint(q, arabic: true);
      expect(h.ar, contains('١٥'));
      expect(h.ar, contains('٥'));
      expect(h.ar, contains('٢٠'));
    });
  });
}
