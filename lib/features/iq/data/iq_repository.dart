import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';

/// Bilingual IQ question — both English and Arabic payloads parsed,
/// caller picks language at conversion time.
class IqEntry {
  const IqEntry({
    required this.id,
    required this.question,
    required this.questionAr,
    required this.options,
    required this.optionsAr,
    required this.correctAnswer,
    required this.correctAnswerAr,
    required this.category,
    required this.categoryAr,
    this.funFact,
    this.funFactAr,
    this.difficulty = 1,
  });

  final String id;
  final String question;
  final String questionAr;
  final List<String> options;
  final List<String> optionsAr;
  final String correctAnswer;
  final String correctAnswerAr;
  final String category;
  final String categoryAr;
  final String? funFact;
  final String? funFactAr;
  final int difficulty;

  factory IqEntry.fromJson(Map<String, dynamic> json) {
    return IqEntry(
      id: json['id'] as String,
      question: json['question'] as String,
      questionAr:
          (json['question_ar'] as String?) ?? json['question'] as String,
      options: List<String>.from(json['options'] as List),
      optionsAr: json['options_ar'] != null
          ? List<String>.from(json['options_ar'] as List)
          : List<String>.from(json['options'] as List),
      correctAnswer: json['correct_answer'] as String,
      correctAnswerAr:
          (json['correct_answer_ar'] as String?) ??
          json['correct_answer'] as String,
      category: json['category'] as String,
      categoryAr:
          (json['category_ar'] as String?) ?? json['category'] as String,
      funFact: json['fun_fact'] as String?,
      funFactAr: json['fun_fact_ar'] as String?,
      difficulty:
          (json['difficulty'] as num?)?.toInt() ?? _inferDifficulty(json),
    );
  }

  /// Heuristic difficulty fallback for entries without a `difficulty` field:
  /// Logic / Sequences / Mental Math / Analogies → 3, others → 2.
  static int _inferDifficulty(Map<String, dynamic> json) {
    final cat = (json['category'] as String?) ?? '';
    const hard = {'Logic', 'Sequences', 'Mental Math', 'Analogies'};
    return hard.contains(cat) ? 3 : 2;
  }

  QuizQuestion toQuizQuestion({required bool arabic}) {
    final opts = arabic
        ? List<String>.from(optionsAr)
        : List<String>.from(options);
    opts.shuffle(math.Random());
    return QuizQuestion(
      id: id,
      question: arabic ? questionAr : question,
      options: opts,
      correctAnswer: arabic ? correctAnswerAr : correctAnswer,
      category: arabic ? categoryAr : category,
      funFact: arabic
          ? (funFactAr ?? 'تدريب الذكاء يُنمّي قدراتك العقلية.')
          : (funFact ?? 'Training your IQ sharpens your mental abilities.'),
    );
  }
}

class IqRepository {
  const IqRepository();

  static const _kBrainBoostPath = 'assets/data/brain_boost.json';
  static const _kSpatialPath = 'assets/data/brain_boost_spatial.json';
  static const _kMemoryPath = 'assets/data/brain_boost_memory.json';
  static const _kSpatialExtraPath =
      'assets/data/brain_boost_spatial_extra.json';
  static const _kMemoryExtraPath = 'assets/data/brain_boost_memory_extra.json';
  static const _kPatternsExtraPath =
      'assets/data/brain_boost_patterns_extra.json';
  static const _kMentalMathExtraPath =
      'assets/data/brain_boost_mental_math_extra.json';
  static const _kAnalogiesExtraPath =
      'assets/data/brain_boost_analogies_extra.json';
  static const _kLogicExtraPath = 'assets/data/brain_boost_logic_extra.json';
  static const _kPatternsExtra2Path =
      'assets/data/brain_boost_patterns_extra2.json';
  static const _kMentalMathExtra2Path =
      'assets/data/brain_boost_mental_math_extra2.json';
  static const _kAnalogiesExtra2Path =
      'assets/data/brain_boost_analogies_extra2.json';
  static const _kLogicExtra2Path = 'assets/data/brain_boost_logic_extra2.json';
  static const _kAnalogiesExtra3Path =
      'assets/data/brain_boost_analogies_extra3.json';
  static const _kPatternsExtra3Path =
      'assets/data/brain_boost_patterns_extra3.json';
  static const _kLogicExtra3Path = 'assets/data/brain_boost_logic_extra3.json';
  static const _kMemoryExtra2Path =
      'assets/data/brain_boost_memory_extra2.json';
  static const _kMentalMathExtra3Path =
      'assets/data/brain_boost_mental_math_extra3.json';
  static const _kSpatialExtra2Path =
      'assets/data/brain_boost_spatial_extra2.json';
  static const _kLegacyIqPath = 'assets/data/iq.json';
  static const _kReadyThreshold = 50;

  Future<List<IqEntry>> loadEntries() async {
    final brain = await _tryLoad(_kBrainBoostPath);
    if (brain != null && brain.length >= _kReadyThreshold) {
      // Augment with Spatial + Memory + per-category extras if available,
      // deduplicated by id.
      final extras = await Future.wait([
        _tryLoad(_kSpatialPath),
        _tryLoad(_kMemoryPath),
        _tryLoad(_kSpatialExtraPath),
        _tryLoad(_kMemoryExtraPath),
        _tryLoad(_kPatternsExtraPath),
        _tryLoad(_kMentalMathExtraPath),
        _tryLoad(_kAnalogiesExtraPath),
        _tryLoad(_kLogicExtraPath),
        _tryLoad(_kPatternsExtra2Path),
        _tryLoad(_kMentalMathExtra2Path),
        _tryLoad(_kAnalogiesExtra2Path),
        _tryLoad(_kLogicExtra2Path),
        _tryLoad(_kAnalogiesExtra3Path),
        _tryLoad(_kPatternsExtra3Path),
        _tryLoad(_kLogicExtra3Path),
        _tryLoad(_kMemoryExtra2Path),
        _tryLoad(_kMentalMathExtra3Path),
        _tryLoad(_kSpatialExtra2Path),
      ]);
      final combined = <IqEntry>[...brain];
      final seenIds = brain.map((e) => e.id).toSet();
      for (final pack in extras) {
        if (pack == null) continue;
        for (final e in pack) {
          if (seenIds.add(e.id)) combined.add(e);
        }
      }
      return combined;
    }
    final legacy = await _tryLoad(_kLegacyIqPath);
    return legacy ?? const <IqEntry>[];
  }

  Future<List<IqEntry>?> _tryLoad(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final jsonString = utf8.decode(byteData.buffer.asUint8List());
      final decoded = json.decode(jsonString);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(IqEntry.fromJson)
          .toList();
    } catch (_) {
      return null;
    }
  }
}
