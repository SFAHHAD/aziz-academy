import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';

class CapitalEntry {
  const CapitalEntry({
    required this.id,
    required this.country,
    required this.countryAr,
    required this.capital,
    required this.capitalAr,
    required this.continent,
    required this.flagEmoji,
    required this.options,
    required this.optionsAr,
    required this.funFact,
    required this.difficulty,
    this.imageUrl,
    this.flagUrl,
    this.flagAsset,
  });

  final String id;
  final String country;
  final String countryAr;
  final String capital;
  final String capitalAr;
  final String continent;
  final String flagEmoji;
  final List<String> options;
  final List<String> optionsAr;
  final String funFact;
  final int difficulty;
  final String? imageUrl;
  final String? flagUrl;
  final String? flagAsset;

  factory CapitalEntry.fromJson(Map<String, dynamic> json) {
    return CapitalEntry(
      id: json['id'] as String,
      country: json['country'] as String,
      countryAr: json['country_ar'] as String? ?? json['country'] as String,
      capital: json['capital'] as String,
      capitalAr: json['capital_ar'] as String? ?? json['capital'] as String,
      continent: json['continent'] as String,
      flagEmoji: json['flag_emoji'] as String,
      options: List<String>.from(json['options'] as List),
      optionsAr: json['options_ar'] != null
          ? List<String>.from(json['options_ar'] as List)
          : List<String>.from(json['options'] as List),
      funFact: json['fun_fact'] as String,
      difficulty: json['difficulty'] as int,
      imageUrl: json['image_url'] as String?,
      flagUrl: json['flag_url'] as String?,
      flagAsset: json['flag_asset'] as String?,
    );
  }

  QuizQuestion toQuizQuestion({required bool arabic}) {
    final resolvedFlagUrl = flagAsset ?? 'assets/images/flags/$id.png';
    final opts = arabic
        ? List<String>.from(optionsAr)
        : List<String>.from(options);
    opts.shuffle(math.Random());
    return QuizQuestion(
      id: id,
      question: arabic
          ? 'ما عاصمة $countryAr؟'
          : 'What is the capital of $country?',
      options: opts,
      correctAnswer: arabic ? capitalAr : capital,
      category: continent,
      funFact: funFact,
      imageUrl: imageUrl,
      flagUrl: resolvedFlagUrl,
      difficulty: difficulty,
    );
  }
}

class CapitalsRepository {
  const CapitalsRepository();

  static const _assetPath = 'assets/data/capitals.json';

  Future<List<QuizQuestion>> loadQuestions({bool arabic = true}) async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (e) => CapitalEntry.fromJson(
              e as Map<String, dynamic>,
            ).toQuizQuestion(arabic: arabic),
          )
          .toList();
    } catch (e, st) {
      debugPrint('CapitalsRepository.loadQuestions failed: $e\n$st');
      rethrow;
    }
  }
}
