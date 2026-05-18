import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke-load every JSON quiz pack and assert structural invariants.
/// This duplicates the python validator at the Dart layer so the same
/// invariants can fail a Flutter test run if a pack regresses.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const bbPacks = [
    'assets/data/brain_boost.json',
    'assets/data/brain_boost_spatial.json',
    'assets/data/brain_boost_memory.json',
    'assets/data/brain_boost_patterns_extra.json',
    'assets/data/brain_boost_mental_math_extra.json',
    'assets/data/brain_boost_analogies_extra.json',
    'assets/data/brain_boost_logic_extra.json',
  ];
  const sciPacks = [
    'assets/data/sciences.json',
    'assets/data/sciences_l2.json',
    'assets/data/sciences_l3.json',
    'assets/data/sciences_l4.json',
  ];

  Future<List<dynamic>> load(String path) async {
    final s = await rootBundle.loadString(path);
    return jsonDecode(s) as List<dynamic>;
  }

  test('Brain Boost packs: schema + global ID uniqueness', () async {
    final seen = <String>{};
    for (final p in bbPacks) {
      final list = await load(p);
      for (final raw in list) {
        final m = raw as Map<String, dynamic>;
        expect(m['id'], isNotNull, reason: '$p missing id');
        final id = m['id'] as String;
        expect(seen.add(id), isTrue, reason: 'duplicate BB id $id');
        final opts = (m['options'] as List).cast<String>();
        expect(opts.length, 4, reason: '$id options must be 4');
        expect(opts.first, m['correct_answer'],
            reason: '$id options[0] != correct_answer');
        if (m['options_ar'] != null) {
          final oa = (m['options_ar'] as List).cast<String>();
          expect(oa.length, 4, reason: '$id options_ar must be 4');
          expect(oa.first, m['correct_answer_ar'],
              reason: '$id options_ar[0] != correct_answer_ar');
        }
      }
    }
  });

  test('Sciences packs: correct_answer in options', () async {
    final seen = <String>{};
    for (final p in sciPacks) {
      final list = await load(p);
      for (final raw in list) {
        final m = raw as Map<String, dynamic>;
        final id = m['id'] as String;
        expect(seen.add(id), isTrue,
            reason: 'duplicate sciences id $id');
        final opts = (m['options'] as List).cast<String>();
        expect(opts.length, 4);
        expect(opts.contains(m['correct_answer']), isTrue,
            reason: '$id correct_answer not in options');
      }
    }
  });
}
