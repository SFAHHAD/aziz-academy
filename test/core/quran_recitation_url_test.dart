// Pure-function tests for the Quran recitation URL builder. The actual
// network call to everyayah.com is not exercised — we just verify the URL
// scheme is correct so a future refactor of `_surahNumByName` or the
// zero-pad logic can't silently break audio playback.

import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/core/services/quran_recitation_service.dart';

void main() {
  group('QuranRecitationService url builder', () {
    test('Al-Fatihah verse 1 returns canonical 001001 URL', () {
      final url = QuranRecitationService.urlFor(
        surahId: 'surah_al_fatihah',
        verseNumber: 1,
      );
      expect(url, isNotNull);
      expect(url!.endsWith('/Alafasy_128kbps/001001.mp3'), isTrue,
          reason: 'Expected 3-digit zero-padded surah + ayah; got $url');
    });

    test('Al-Ikhlas (#112) verse 4 returns 112004 URL', () {
      final url = QuranRecitationService.urlFor(
        surahId: 'surah_al_ikhlas',
        verseNumber: 4,
      );
      expect(url, isNotNull);
      expect(url!.endsWith('/Alafasy_128kbps/112004.mp3'), isTrue);
    });

    test('An-Nas (#114) verse 6 returns 114006 URL', () {
      final url = QuranRecitationService.urlFor(
        surahId: 'surah_an_nas',
        verseNumber: 6,
      );
      expect(url, isNotNull);
      expect(url!.endsWith('/Alafasy_128kbps/114006.mp3'), isTrue);
    });

    test('Reciter override changes the path segment', () {
      final url = QuranRecitationService.urlFor(
        surahId: 'surah_al_fatihah',
        verseNumber: 1,
        reciter: 'Husary_128kbps',
      );
      expect(url, isNotNull);
      expect(url!.contains('/Husary_128kbps/'), isTrue);
    });

    test('Unknown surah id returns null (caller falls back to TTS)', () {
      final url = QuranRecitationService.urlFor(
        surahId: 'surah_does_not_exist',
        verseNumber: 1,
      );
      expect(url, isNull);
    });

    test('surahNumberFor exposes the canonical 1..114 number', () {
      expect(QuranRecitationService.surahNumberFor('surah_al_fatihah'), 1);
      expect(QuranRecitationService.surahNumberFor('surah_al_ikhlas'), 112);
      expect(QuranRecitationService.surahNumberFor('surah_an_nas'), 114);
      expect(
          QuranRecitationService.surahNumberFor('surah_nonexistent'), isNull);
    });
  });

  group('Reciter catalog', () {
    test('default reciter is in the catalog', () {
      expect(kReciters.containsKey('Alafasy_128kbps'), isTrue,
          reason: 'AppSettings.preferredReciter defaults to '
              'Alafasy_128kbps; if it is not in kReciters the dropdown '
              'will not show the current selection.');
    });

    test('every reciter has both EN and AR display names', () {
      for (final entry in kReciters.entries) {
        expect(entry.value.en, isNotEmpty,
            reason: 'reciter ${entry.key} missing EN display name');
        expect(entry.value.ar, isNotEmpty,
            reason: 'reciter ${entry.key} missing AR display name');
      }
    });
  });
}
