// Regression: the curated Islamic content packs are critical to the app's
// Islamic identity and easy to accidentally truncate. Asserts the expected
// row counts so a future cleanup that wipes a section blows up loudly.
//
// If you intentionally trim a pack, update the expectation here.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Islamic content packs — row counts', () {
    test('99 Names of Allah has all 99 entries', () {
      final f = File('assets/data/asma_ul_husna_memorization.json');
      final list = jsonDecode(f.readAsStringSync()) as List;
      expect(list.length, 99,
          reason: 'Asma Ul Husna must always be exactly 99 — '
              'the religious significance is the number itself.');
    });

    test('Prophet Stories covers the canonical 25 named prophets', () {
      final f = File('assets/data/prophet_stories.json');
      final list = jsonDecode(f.readAsStringSync()) as List;
      expect(list.length, 25,
          reason: 'There are 25 named prophets in the Quran. Anything '
              'less is incomplete; more breaks the canonical count.');
    });

    test('Hadith memorization pack has at least 25 entries', () {
      final f = File('assets/data/hadith_memorization.json');
      final list = jsonDecode(f.readAsStringSync()) as List;
      expect(list.length, greaterThanOrEqualTo(25),
          reason: 'Hadith memorization library was extended to 25 in '
              'v1.1.88; do not silently shrink it below that baseline.');
    });

    test('Dua memorization pack has at least 20 entries', () {
      final f = File('assets/data/dua_memorization.json');
      final list = jsonDecode(f.readAsStringSync()) as List;
      expect(list.length, greaterThanOrEqualTo(20),
          reason: 'Dua library should cover daily occasions broadly.');
    });

    test('Tajweed basics pack has at least 10 rules', () {
      final f = File('assets/data/tajweed_basics.json');
      final list = jsonDecode(f.readAsStringSync()) as List;
      expect(list.length, greaterThanOrEqualTo(10),
          reason: 'Tajweed basics pack should cover the foundational '
              '10 rules: Madd, Ghunnah, Ikhfa, Idgham, Iqlab, Qalqalah, '
              'sun/moon lams, Idhar, Waqf.');
    });

    test('Quran short surahs has at least 15 surahs', () {
      final f = File('assets/data/quran_short_surahs.json');
      final list = jsonDecode(f.readAsStringSync()) as List;
      expect(list.length, greaterThanOrEqualTo(15),
          reason: 'Short-surah pack drives Quran screen + Daily Verse '
              'banner. Truncating it would silently break those. '
              'Expanded from 10 → 15 in v1.1.93 with Fil/Qadr/Tin/Duha/'
              'Inshirah.');
    });
  });
}
