import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';

class FlagsRepository {
  const FlagsRepository();

  static const _assetPath = 'assets/data/capitals.json';

  Future<List<QuizQuestion>> loadQuestions() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;

      final random = math.Random();
      final allCountriesAr = decoded
          .map((e) => e['country_ar'] as String? ?? e['country'] as String)
          .toList();

      return decoded.map((e) {
        final id = e['id'] as String;
        final countryAr = e['country_ar'] as String? ?? e['country'] as String;
        final flagAsset = e['flag_asset'] as String?;
        final continent = e['continent'] as String;

        // Ensure offline flags are used
        final resolvedFlagAsset = flagAsset ?? 'assets/images/flags/$id.png';

        // Generate 3 random wrong country options
        final wrongOptions = <String>{};
        while (wrongOptions.length < 3) {
          final randCountry = allCountriesAr[random.nextInt(allCountriesAr.length)];
          if (randCountry != countryAr) {
            wrongOptions.add(randCountry);
          }
        }

        final options = [...wrongOptions, countryAr]..shuffle(random);

        return QuizQuestion(
          id: 'flag_$id',
          question: 'لمن هذا العلم؟',
          options: options,
          correctAnswer: countryAr,
          category: continent,
          funFact: 'هذا هو علم $countryAr! ${e['fun_fact']}',
          flagUrl: resolvedFlagAsset, // Utilizing flagUrl parameter for large image display
        );
      }).toList();
    } catch (e, stack) {
      debugPrint('Error loading flags data: $e\n$stack');
      return [];
    }
  }
}
