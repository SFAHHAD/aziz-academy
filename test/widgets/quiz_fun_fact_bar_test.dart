import 'package:aziz_academy/core/widgets/quiz_fun_fact_bar.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('QuizFunFactBar shows correct-answer line when wrong', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(
          body: QuizFunFactBar(
            funFact: 'Sample fact',
            wasWrong: true,
            correctAnswer: 'Paris',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Correct answer'), findsOneWidget);
    expect(find.textContaining('Paris'), findsOneWidget);
    expect(find.textContaining('Sample fact'), findsOneWidget);
  });

  testWidgets('QuizFunFactBar hides correct line when not wrong', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(
          body: QuizFunFactBar(
            funFact: 'Nice!',
            wasWrong: false,
            correctAnswer: 'X',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Correct answer'), findsNothing);
  });
}
