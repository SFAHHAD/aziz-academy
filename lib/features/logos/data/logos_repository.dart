import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/painting.dart' show Color;
import 'package:aziz_academy/core/models/quiz_question.dart';

// ---------------------------------------------------------------------------
// DTO — mirrors logos.json shape exactly.
// ---------------------------------------------------------------------------

class LogoEntry {
  const LogoEntry({
    required this.id,
    required this.brand,
    required this.brandAr,
    required this.logoUrl,
    required this.brandColor,
    required this.options,
    required this.optionsAr,
    required this.correctAnswer,
    required this.correctAnswerAr,
    required this.category,
    required this.difficulty,
  });

  final String id;
  final String brand;
  final String brandAr;
  final String logoUrl;        // Network URL from clearbit / logo.dev CDN
  final Color brandColor;
  final List<String> options;
  final List<String> optionsAr;
  final String correctAnswer;
  final String correctAnswerAr;
  final String category;
  final int difficulty;

  factory LogoEntry.fromJson(Map<String, dynamic> json) {
    final hex = (json['brand_color'] as String).replaceFirst('#', 'FF');

    // Prefer bundled assets; fall back to network URL when present in JSON.
    final logoUrl = json['logo_asset'] as String? ??
        (json['logo_url'] as String?) ??
        '';

    // Support Arabic options, fall back to English
    final optionsAr = json['options_ar'] != null
        ? List<String>.from(json['options_ar'] as List)
        : List<String>.from(json['options'] as List);

    return LogoEntry(
      id: json['id'] as String,
      brand: json['brand'] as String,
      brandAr: json['brand_ar'] as String? ?? json['brand'] as String,
      logoUrl: logoUrl,
      brandColor: Color(int.parse(hex, radix: 16)),
      options: List<String>.from(json['options'] as List),
      optionsAr: optionsAr,
      correctAnswer: json['correct_answer'] as String,
      correctAnswerAr:
          json['correct_answer_ar'] as String? ?? json['correct_answer'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as int,
    );
  }

  /// Maps to [QuizQuestion]:
  ///  • question  = Arabic brand name (shown in reveal)
  ///  • imageUrl  = network logo URL
  ///  • options   = Arabic options, shuffled
  ///  • correctAnswer = Arabic brand name
  QuizQuestion toQuizQuestion() {
    // Shuffle Arabic options randomly each time.
    final shuffled = List<String>.from(optionsAr)..shuffle(math.Random());

    return QuizQuestion(
      id: id,
      question: brandAr,               // Arabic brand name for reveal
      options: shuffled,
      correctAnswer: correctAnswerAr,  // Arabic correct answer to match options
      category: category,
      funFact: id,                      // reuse funFact to carry the l10n key
      imageUrl: logoUrl,                // CDN URL — loaded with Image.network
    );
  }
}

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class LogosRepository {
  const LogosRepository();

  static const _assetPath = 'assets/data/logos.json';

  Future<List<QuizQuestion>> loadQuestions() async {
    final raw = await rootBundle.loadString(_assetPath);
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) =>
            LogoEntry.fromJson(e as Map<String, dynamic>).toQuizQuestion())
        .toList();
  }
}
