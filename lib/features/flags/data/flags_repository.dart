import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';

class FlagsRepository {
  const FlagsRepository();

  static const _assetPath = 'assets/data/capitals.json';

  Future<List<QuizQuestion>> loadQuestions({bool arabic = true}) async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;

      final random = math.Random();
      final allCountries = decoded
          .map(
            (e) => arabic
                ? (e['country_ar'] as String? ?? e['country'] as String)
                : e['country'] as String,
          )
          .toList();

      return decoded.map((e) {
        final id = e['id'] as String;
        final country = arabic
            ? (e['country_ar'] as String? ?? e['country'] as String)
            : e['country'] as String;
        final flagAsset = e['flag_asset'] as String?;
        final continent = e['continent'] as String;

        final resolvedFlagAsset = flagAsset ?? 'assets/images/flags/$id.png';

        final wrongOptions = <String>{};
        while (wrongOptions.length < 3) {
          final randCountry = allCountries[random.nextInt(allCountries.length)];
          if (randCountry != country) {
            wrongOptions.add(randCountry);
          }
        }
        final options = [...wrongOptions, country]..shuffle(random);

        return QuizQuestion(
          id: 'flag_$id',
          question: arabic ? 'لمن هذا العلم؟' : 'Whose flag is this?',
          options: options,
          correctAnswer: country,
          category: continent,
          funFact: arabic
              ? 'هذا هو علم $country! ${e['fun_fact']}'
              : 'This is the flag of $country! ${e['fun_fact']}',
          flagUrl: resolvedFlagAsset,
        );
      }).toList();
    } catch (e, stack) {
      debugPrint('Error loading flags data: $e\n$stack');
      return [];
    }
  }
}
