import 'package:flutter/foundation.dart';

/// The shared, canonical quiz question model used across ALL modules
/// (Capitals, Maps, Logos). Every module's repository maps its raw
/// JSON entries to this model before handing data to providers.
@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.category,
    required this.funFact,
    this.imageUrl,
    this.flagUrl,
    this.lat,
    this.lng,
  });

  /// Unique identifier for this question (e.g. 'sa', 'apple').
  final String id;

  /// The question text displayed to the child.
  final String question;

  /// All answer choices, including the correct one. Always shuffled
  /// before display — never depend on position for correctness.
  final List<String> options;

  /// The single correct answer. Must be one of [options].
  final String correctAnswer;

  /// Optional asset path or network URL for an accompanying image.
  /// Null when no image is associated with this question.
  final String? imageUrl;

  /// Module or continent the question belongs to (e.g. 'Asia', 'Technology').
  final String category;

  /// A kid-friendly fun fact shown after the answer is revealed.
  final String funFact;

  /// Network URL for the country flag image (flagcdn.com). Null for non-capitals modules.
  final String? flagUrl;

  /// Optional latitude representing the geographic center.
  final double? lat;

  /// Optional longitude representing the geographic center.
  final double? lng;

  // ---------------------------------------------------------------------------
  // Serialisation helpers
  // ---------------------------------------------------------------------------

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final q = QuizQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswer: json['correct_answer'] as String,
      category: json['category'] as String,
      funFact: json['fun_fact'] as String,
      imageUrl: json['image_url'] as String?,
      flagUrl: json['flag_url'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
    assert(
      q.options.length >= 2,
      'QuizQuestion "${q.id}" must have at least 2 options, got ${q.options.length}.',
    );
    return q;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correct_answer': correctAnswer,
        'category': category,
        'fun_fact': funFact,
        if (imageUrl != null) 'image_url': imageUrl,
        if (flagUrl != null) 'flag_url': flagUrl,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  // ---------------------------------------------------------------------------
  // Value equality & debugging
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizQuestion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'QuizQuestion(id: $id, question: $question, correct: $correctAnswer)';

  QuizQuestion copyWith({
    String? id,
    String? question,
    List<String>? options,
    String? correctAnswer,
    String? imageUrl,
    String? flagUrl,
    double? lat,
    double? lng,
    String? category,
    String? funFact,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      imageUrl: imageUrl ?? this.imageUrl,
      flagUrl: flagUrl ?? this.flagUrl,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      category: category ?? this.category,
      funFact: funFact ?? this.funFact,
    );
  }
}
