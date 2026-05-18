import 'package:flutter/material.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';

// =============================================================================
// School curriculum data models
// =============================================================================

class SchoolQuestion {
  const SchoolQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.funFact,
  });

  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String funFact;

  QuizQuestion toQuizQuestion(String category) => QuizQuestion(
    id: id,
    question: question,
    options: List<String>.from(options),
    correctAnswer: correctAnswer,
    category: category,
    funFact: funFact,
  );
}

class SchoolChapter {
  const SchoolChapter({
    required this.id,
    required this.name,
    this.questions = const [],
  });

  final String id;
  final String name;
  final List<SchoolQuestion> questions;

  bool get hasContent => questions.isNotEmpty;
}

class SchoolSubject {
  const SchoolSubject({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.chapters = const [],
  });

  final String id;
  final String name;
  final String emoji;
  final Color color;
  final List<SchoolChapter> chapters;

  bool get hasContent =>
      chapters.isNotEmpty && chapters.any((c) => c.hasContent);

  int get totalQuestions =>
      chapters.fold(0, (sum, c) => sum + c.questions.length);
}

class SchoolGrade {
  const SchoolGrade({
    required this.id,
    required this.name,
    this.subjects = const [],
  });

  final String id;
  final String name;
  final List<SchoolSubject> subjects;
}

class SchoolStage {
  const SchoolStage({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.grades = const [],
  });

  final String id;
  final String name;
  final String emoji;
  final Color color;
  final List<SchoolGrade> grades;
}
