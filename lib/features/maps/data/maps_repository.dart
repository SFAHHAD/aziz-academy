import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';

class MapEntry {
  const MapEntry({
    required this.id,
    required this.country,
    required this.countryAr,
    required this.lat,
    required this.lng,
    required this.continent,
    required this.flagUrl,
  });

  final String id;
  final String country;
  final String countryAr;
  final double lat;
  final double lng;
  final String continent;
  final String flagUrl;

  factory MapEntry.fromJson(Map<String, dynamic> json) {
    return MapEntry(
      id: json['id'] as String,
      country: json['country'] as String,
      countryAr: json['country_ar'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      continent: json['continent'] as String,
      flagUrl: json['flag_emoji'] as String? ?? 'https://flagcdn.com/w160/${json['id'] as String}.png',
    );
  }
}

class MapsRepository {
  const MapsRepository();

  static const _assetPath = 'assets/data/capitals.json';

  Future<List<QuizQuestion>> loadQuestions() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final parseList = decoded.map((e) => MapEntry.fromJson(e as Map<String, dynamic>)).toList();
      
      final random = math.Random();
      final List<QuizQuestion> questions = [];
      
      for (final entry in parseList) {
        final wrongOptions = <String>{};
        while (wrongOptions.length < 3) {
          final candidate = parseList[random.nextInt(parseList.length)];
          if (candidate.id != entry.id) {
            wrongOptions.add(candidate.countryAr);
          }
        }
        
        final options = [entry.countryAr, ...wrongOptions]..shuffle(random);
        
        questions.add(QuizQuestion(
          id: entry.id,
          question: 'ما اسم الدولة المشار إليها في الخريطة؟', // What is the name of the country pointed to on the map?
          options: options,
          correctAnswer: entry.countryAr,
          category: entry.continent,
          funFact: 'This is ${entry.countryAr}.', // Maybe add custom fun fact later
          lat: entry.lat,
          lng: entry.lng,
          flagUrl: entry.flagUrl,
        ));
      }
      return questions;
    } catch (e, st) {
      debugPrint('MapsRepository.loadQuestions failed: $e\n$st');
      return [];
    }
  }
}
