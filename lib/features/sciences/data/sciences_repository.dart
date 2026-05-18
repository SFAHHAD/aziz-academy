import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';

class ScienceEntry {
  const ScienceEntry({
    required this.id,
    required this.question,
    required this.questionAr,
    required this.options,
    required this.optionsAr,
    required this.correctAnswer,
    required this.correctAnswerAr,
    required this.category,
    this.funFact,
    this.difficulty = 1,
  });

  final String id;
  final String question;
  final String? questionAr;
  final List<String> options;
  final List<String> optionsAr;
  final String correctAnswer;
  final String? correctAnswerAr;
  final String category;
  final String? funFact;
  final int difficulty;

  factory ScienceEntry.fromJson(Map<String, dynamic> json) {
    return ScienceEntry(
      id: json['id'] as String,
      question: json['question'] as String,
      questionAr: json['question_ar'] as String?,
      options: List<String>.from(json['options'] as List),
      optionsAr: json['options_ar'] != null
          ? List<String>.from(json['options_ar'] as List)
          : List<String>.from(json['options'] as List),
      correctAnswer: json['correct_answer'] as String,
      correctAnswerAr: json['correct_answer_ar'] as String?,
      category: json['category'] as String,
      funFact: json['fun_fact'] as String?,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
    );
  }

  QuizQuestion toQuizQuestion({required bool arabic}) {
    final opts = arabic
        ? List<String>.from(optionsAr)
        : List<String>.from(options);
    opts.shuffle(math.Random());
    return QuizQuestion(
      id: id,
      question: arabic ? (questionAr ?? question) : question,
      options: opts,
      correctAnswer: arabic
          ? (correctAnswerAr ?? correctAnswer)
          : correctAnswer,
      category: category,
      funFact:
          funFact ??
          (arabic
              ? 'هل تعلم أن هذا الاكتشاف غير العالم؟'
              : 'Did you know this discovery changed the world?'),
      difficulty: difficulty,
    );
  }
}

class SciencesRepository {
  const SciencesRepository();

  Future<List<QuizQuestion>> loadQuestions({bool arabic = true}) async {
    final entries = await loadEntries();
    return entries.map((e) => e.toQuizQuestion(arabic: arabic)).toList();
  }

  Future<List<ScienceEntry>> loadEntries() async {
    final base = await _readPack('assets/data/sciences.json');
    final extras = await Future.wait([
      _tryReadPack('assets/data/sciences_l2.json'),
      _tryReadPack('assets/data/sciences_l3.json'),
      _tryReadPack('assets/data/sciences_l4.json'),
      _tryReadPack('assets/data/sciences_l5.json'),
      _tryReadPack('assets/data/sciences_l6.json'),
    ]);
    final seen = base.map((e) => e.id).toSet();
    final out = <ScienceEntry>[...base];
    for (final pack in extras) {
      if (pack == null) continue;
      for (final e in pack) {
        if (seen.add(e.id)) out.add(e);
      }
    }
    return out;
  }

  Future<List<ScienceEntry>> _readPack(String path) async {
    final byteData = await rootBundle.load(path);
    final jsonString = utf8.decode(byteData.buffer.asUint8List());
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map(
          (jsonObj) => ScienceEntry.fromJson(jsonObj as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<ScienceEntry>?> _tryReadPack(String path) async {
    try {
      return await _readPack(path);
    } catch (_) {
      return null;
    }
  }
}
