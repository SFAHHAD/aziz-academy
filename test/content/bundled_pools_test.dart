// Static-content quality test. Reads every JSON file under assets/data/
// directly from disk (no Flutter runtime needed) and asserts:
//   - every pool parses
//   - every pool is a top-level array (the few non-arrays are special and
//     allowed via [_nonArrayPools])
//   - bilingual coverage is at the threshold expected after the audit
//     improvements (≥ 99% AR coverage across all questions)
//   - no duplicate IDs within a pool
//
// This catches drift the runtime audit would also catch, but at CI time
// rather than after deploy.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _primaryFallbacks = <List<String>>[
  ['question', 'question_ar'],
  ['country', 'country_ar'],
  ['prompt', 'prompt_ar'],
  ['text', 'text_ar'],
  ['brand', 'brand_ar'],
  ['title', 'title_ar'],
  ['name', 'name_ar'],
  ['word', 'word_ar'],
  ['passage', 'passage_ar'],
  ['region', 'region_ar'],
];
const _answerArKeys = [
  'correct_answer_ar',
  'capital_ar',
  'answer_ar',
  'brand_ar',
  'name_ar',
  'translation_ar',
  'ar',
  'passage_ar',
];

// maps.json is a structured-region container with English-only quiz_questions
// (3 entries today). Allow these as a known-shape, separately translated
// later. New pools can NOT join this list — they must ship bilingual.
const _knownEnglishOnlyPools = {'maps'};

String _str(Map m, String key) {
  final v = m[key];
  if (v is String) return v.trim();
  return '';
}

bool _isFullyBilingual(Map q) {
  String en = '';
  String ar = '';
  for (final pair in _primaryFallbacks) {
    final ev = _str(q, pair[0]);
    final av = _str(q, pair[1]);
    if (ev.isNotEmpty || av.isNotEmpty) {
      en = ev;
      ar = av;
      break;
    }
  }
  String ansAr = '';
  for (final k in _answerArKeys) {
    final v = _str(q, k);
    if (v.isNotEmpty) {
      ansAr = v;
      break;
    }
  }
  final hasOptions = q['options'] is List && (q['options'] as List).isNotEmpty;
  final hasArOptions =
      q['options_ar'] is List && (q['options_ar'] as List).isNotEmpty;
  return en.isNotEmpty &&
      ar.isNotEmpty &&
      ansAr.isNotEmpty &&
      (!hasOptions || hasArOptions);
}

void main() {
  final dir = Directory('assets/data');
  if (!dir.existsSync()) {
    fail('assets/data directory not found at ${dir.absolute.path}');
  }
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('every JSON pool parses', () {
    for (final f in files) {
      try {
        jsonDecode(f.readAsStringSync());
      } catch (e) {
        fail('${f.path} failed to parse: $e');
      }
    }
  });

  test('every pool is a top-level array', () {
    for (final f in files) {
      final root = jsonDecode(f.readAsStringSync());
      expect(root, isA<List>(),
          reason: '${f.path} root must be a JSON array');
    }
  });

  test('no duplicate IDs within any pool', () {
    final offenders = <String>[];
    for (final f in files) {
      final data = jsonDecode(f.readAsStringSync()) as List;
      final ids = <String>{};
      for (final item in data) {
        if (item is! Map) continue;
        final id = _str(item, 'id');
        if (id.isEmpty) continue;
        if (!ids.add(id)) {
          offenders.add('${f.path.split('/').last}: dup id "$id"');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'duplicate IDs: $offenders');
  });

  test('bilingual coverage ≥ 99.5% across all pools', () {
    var total = 0;
    var bilingual = 0;
    for (final f in files) {
      final data = jsonDecode(f.readAsStringSync()) as List;
      final poolId = f.uri.pathSegments.last
          .replaceAll(RegExp(r'\.json$'), '');
      if (_knownEnglishOnlyPools.contains(poolId)) continue;
      for (final item in data) {
        if (item is! Map) continue;
        total++;
        if (_isFullyBilingual(item)) bilingual++;
      }
    }
    final ratio = total == 0 ? 1.0 : bilingual / total;
    expect(ratio, greaterThanOrEqualTo(0.995),
        reason: 'Bilingual coverage dropped to '
            '${(ratio * 100).toStringAsFixed(2)}% '
            '($bilingual / $total).');
  });
}
