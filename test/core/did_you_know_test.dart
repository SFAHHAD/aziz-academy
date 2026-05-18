import 'package:aziz_academy/core/logic/did_you_know.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DidYouKnow', () {
    test('seed pool is non-empty and bilingual', () {
      expect(kDidYouKnow, isNotEmpty);
      for (final f in kDidYouKnow) {
        expect(f.en.trim(), isNotEmpty, reason: 'fact missing English');
        expect(f.ar.trim(), isNotEmpty, reason: 'fact missing Arabic');
        expect(f.emoji.trim(), isNotEmpty, reason: 'fact missing emoji');
      }
    });

    test('factForToday is stable within the same day', () {
      final d = DateTime(2026, 5, 8);
      expect(factForToday(d).en, factForToday(d).en);
      expect(factForToday(d).ar, factForToday(d).ar);
    });

    test('factForToday rotates across consecutive days', () {
      final picks = <String>{};
      for (var day = 1; day <= 14; day++) {
        picks.add(factForToday(DateTime(2026, 5, day)).en);
      }
      // 14 consecutive days should produce at least 5 distinct facts —
      // confirms the seed actually rotates.
      expect(picks.length, greaterThanOrEqualTo(5));
    });

    test('English copy contains no obvious Arabic letters and vice-versa', () {
      final arabicLetters = RegExp(r'[؀-ۿ]');
      final latinLetters = RegExp(r'[A-Za-z]');
      for (final f in kDidYouKnow) {
        expect(arabicLetters.hasMatch(f.en), isFalse,
            reason: 'English fact contains Arabic: "${f.en}"');
        expect(latinLetters.hasMatch(f.ar), isFalse,
            reason: 'Arabic fact contains Latin: "${f.ar}"');
      }
    });
  });
}
