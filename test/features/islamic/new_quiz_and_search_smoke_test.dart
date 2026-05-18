import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/features/hadith/hadith_quiz_screen.dart';
import 'package:aziz_academy/features/prophet_stories/prophet_quiz_screen.dart';
import 'package:aziz_academy/features/islamic_search/islamic_search_screen.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';

// Mobile smoke tests for the three new screens shipped this session:
// Hadith Quiz, Prophet Quiz, Islamic Search. Same bounded-pump pattern
// as the other Islamic smoke tests — pumpAndSettle hangs on rootBundle
// async loads.

const _w = 375.0;

Future<void> _pumpAtWidth(
  WidgetTester tester,
  Widget child, {
  required String locale,
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'app_locale': locale});

  tester.view.physicalSize = const Size(_w, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/',
    routes: [GoRoute(path: '/', builder: (_, _) => child)],
  );

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale(locale),
        routerConfig: router,
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void _expectClean(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception == null) return;
  final msg = exception.toString();
  if (msg.contains('on the right') || msg.contains('on the left')) {
    fail('Horizontal overflow: $msg');
  }
  fail('Unexpected exception: $msg');
}

void main() {
  group('HadithQuizScreen', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('builds at 375px ($locale)', (tester) async {
        await _pumpAtWidth(tester, const HadithQuizScreen(), locale: locale);
        _expectClean(tester);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    }
  });

  group('ProphetQuizScreen', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('builds at 375px ($locale)', (tester) async {
        await _pumpAtWidth(tester, const ProphetQuizScreen(), locale: locale);
        _expectClean(tester);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    }
  });

  group('IslamicSearchScreen', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('builds at 375px ($locale)', (tester) async {
        await _pumpAtWidth(tester, const IslamicSearchScreen(),
            locale: locale);
        _expectClean(tester);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
      });
    }
  });
}
