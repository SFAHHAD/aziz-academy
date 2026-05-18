// Regression guard: prevent FontStyle.italic from being reintroduced.
//
// We only ship Cairo-Regular and Amiri-Regular (no italic variants), and
// CanvasKit's FontFallbackManager will lock in a requestAnimationFrame loop
// when an italic glyph is requested for a font that doesn't have one (it
// keeps asking gstatic for Noto fallbacks that don't cover the chars either).
// This bug took down the Quran / Athkar / Dua / Tasbih / Vocab / Daily-verse
// screens until we removed every `fontStyle: FontStyle.italic` from lib/.
//
// If you genuinely need a slanted face, add an italic font variant to
// pubspec.yaml first, then update this guard.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/ contains no FontStyle.italic (causes CanvasKit font-fallback loop)',
      () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib/ directory missing');

    final offenders = <String>[];
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      final lines = content.split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('FontStyle.italic')) {
          offenders.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'FontStyle.italic found — this triggers CanvasKit font fallback loops.\n'
          'Use fontWeight + letterSpacing for emphasis instead.\n'
          'Offenders:\n${offenders.join('\n')}',
    );
  });
}
