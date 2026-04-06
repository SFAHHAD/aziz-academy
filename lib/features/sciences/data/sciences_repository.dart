import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';

// Raw DTO for parsing sciences.json properly
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
    );
  }

  QuizQuestion toQuizQuestion() {
    // Map to arabic since app is only AR
    final shuffled = List<String>.from(optionsAr)..shuffle(math.Random());
    return QuizQuestion(
      id: id,
      question: questionAr ?? question,
      options: shuffled,
      correctAnswer: correctAnswerAr ?? correctAnswer,
      category: category,
      funFact: funFact ?? 'هل تعلم أن هذا الاكتشاف غير العالم؟', // Fallback
    );
  }
}

class SciencesRepository {
  const SciencesRepository();

  Future<List<QuizQuestion>> loadQuestions() async {
    final byteData = await rootBundle.load('assets/data/sciences.json');
    final jsonString = utf8.decode(byteData.buffer.asUint8List());
    final List<dynamic> jsonList = json.decode(jsonString);

    return jsonList
        .map((jsonObj) => ScienceEntry.fromJson(jsonObj).toQuizQuestion())
        .toList();
  }
}
