import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/core/services/cloud_tts_service.dart';

void main() {
  group('CloudTtsService.urlFor', () {
    test('English default voice', () {
      final url = CloudTtsService.urlFor(text: 'Hello', arabic: false);
      expect(url, startsWith('/api/speak?'));
      expect(url, contains('text=Hello'));
      expect(url, contains('lang=en'));
      expect(url, isNot(contains('gender=')));
    });

    test('Arabic default voice', () {
      final url = CloudTtsService.urlFor(text: 'بسم الله', arabic: true);
      expect(url, contains('lang=ar'));
      // Arabic chars must be percent-encoded so the URL is safe to feed
      // into a browser MediaElement / cache key.
      expect(url, isNot(contains('بسم')));
    });

    test('male voice adds gender=male', () {
      final url = CloudTtsService.urlFor(
        text: 'Salam',
        arabic: true,
        male: true,
      );
      expect(url, contains('gender=male'));
    });

    test('female (default) omits gender param so it stays cache-stable', () {
      final url = CloudTtsService.urlFor(
        text: 'Salam',
        arabic: true,
        male: false,
      );
      expect(url, isNot(contains('gender=')));
    });

    test('escapes spaces and special chars', () {
      final url = CloudTtsService.urlFor(
        text: 'hello world & friends',
        arabic: false,
      );
      // Spaces become '+' under x-www-form-urlencoded (what Dart's
      // Uri.encodeQueryComponent emits) — both '+' and '%20' are valid
      // query-string space encodings.
      expect(url, contains('hello+world'));
      // Ampersand must be encoded — otherwise it would split the query.
      expect(url, contains('%26'));
      // The raw unencoded sequence must not appear.
      expect(url, isNot(contains('hello world')));
    });

    test('escapes percent signs (no double-encoding hazard)', () {
      final url = CloudTtsService.urlFor(text: '50%', arabic: false);
      expect(url, contains('50%25'));
    });

    test('produces a stable URL for the same input (cache-key stability)', () {
      final a = CloudTtsService.urlFor(text: 'hi', arabic: false);
      final b = CloudTtsService.urlFor(text: 'hi', arabic: false);
      expect(a, b);
    });

    test('arabic vs english produce different URLs for same text', () {
      final ar = CloudTtsService.urlFor(text: 'salam', arabic: true);
      final en = CloudTtsService.urlFor(text: 'salam', arabic: false);
      expect(ar, isNot(en));
    });
  });
}
