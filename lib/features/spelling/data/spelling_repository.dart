import 'dart:convert';

import 'package:flutter/services.dart';

/// A single curated spelling-quiz entry.
///
/// The pack lives in two JSON assets — `spelling.json` (base) and
/// `spelling_extra.json` (extras). Both share the same shape; the repository
/// merges them with id-based de-duplication.
class SpellingEntry {
  const SpellingEntry({
    required this.id,
    required this.answer,
    required this.answerAr,
    required this.prompt,
    required this.promptAr,
    required this.category,
    required this.categoryAr,
    required this.difficulty,
  });

  final String id;
  final String answer;
  final String answerAr;
  final String prompt;
  final String promptAr;
  final String category;
  final String categoryAr;
  final int difficulty;

  factory SpellingEntry.fromJson(Map<String, dynamic> json) {
    return SpellingEntry(
      id: json['id'] as String,
      answer: json['answer'] as String,
      answerAr: (json['answer_ar'] as String?) ?? json['answer'] as String,
      prompt: (json['prompt'] as String?) ?? '',
      promptAr:
          (json['prompt_ar'] as String?) ?? json['prompt'] as String? ?? '',
      category: (json['category'] as String?) ?? 'General',
      categoryAr: (json['category_ar'] as String?) ?? 'عام',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
    );
  }

  String answerFor({required bool arabic}) => arabic ? answerAr : answer;
  String promptFor({required bool arabic}) => arabic ? promptAr : prompt;
  String categoryFor({required bool arabic}) => arabic ? categoryAr : category;
}

class SpellingRepository {
  const SpellingRepository();

  Future<List<SpellingEntry>> loadEntries() async {
    final base = await _tryReadPack('assets/data/spelling.json') ?? const [];
    final extras =
        await _tryReadPack('assets/data/spelling_extra.json') ?? const [];
    final out = <SpellingEntry>[];
    final seen = <String>{};
    for (final e in [...base, ...extras]) {
      if (seen.add(e.id)) out.add(e);
    }
    return out;
  }

  Future<List<SpellingEntry>?> _tryReadPack(String path) async {
    try {
      final byteData = await rootBundle.load(path);
      final jsonString = utf8.decode(byteData.buffer.asUint8List());
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((j) => SpellingEntry.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
