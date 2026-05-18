import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/features/five_pillars/five_pillars_screen.dart';
import 'package:aziz_academy/features/six_articles/six_articles_screen.dart';
import 'package:aziz_academy/features/salah/salah_steps_screen.dart';
import 'package:aziz_academy/features/wudu/wudu_steps_screen.dart';
import 'package:aziz_academy/features/islamic_journey/islamic_journey_screen.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';

// Smoke tests for the five Islamic screens that didn't have coverage yet:
// Five Pillars, Six Articles, Salah Steps, Wudu Steps, Islamic Journey.
// We pump each at 375px (iPhone 13 mini, our smallest common case) in
// both locales and check the tree builds without throwing.

const _phoneWidth = 375.0;

Future<void> _pumpAtWidth(
  WidgetTester tester,
  Widget child, {
  required double width,
  String locale = 'en',
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'app_locale': locale});

  tester.view.physicalSize = Size(width, 800);
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
    fail('Horizontal overflow detected: $msg');
  }
  fail('Unexpected exception: $msg');
}

void main() {
  group('FivePillarsScreen', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('builds at $_phoneWidth ($locale)', (tester) async {
        await _pumpAtWidth(tester, const FivePillarsScreen(),
            width: _phoneWidth, locale: locale);
        _expectClean(tester);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    }
  });

  group('SixArticlesScreen', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('builds at $_phoneWidth ($locale)', (tester) async {
        await _pumpAtWidth(tester, const SixArticlesScreen(),
            width: _phoneWidth, locale: locale);
        _expectClean(tester);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    }
  });

  group('SalahStepsScreen', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('builds at $_phoneWidth ($locale)', (tester) async {
        await _pumpAtWidth(tester, const SalahStepsScreen(),
            width: _phoneWidth, locale: locale);
        _expectClean(tester);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    }
  });

  group('WuduStepsScreen', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('builds at $_phoneWidth ($locale)', (tester) async {
        await _pumpAtWidth(tester, const WuduStepsScreen(),
            width: _phoneWidth, locale: locale);
        _expectClean(tester);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    }
  });

  group('IslamicJourneyScreen', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('builds at $_phoneWidth ($locale)', (tester) async {
        await _pumpAtWidth(tester, const IslamicJourneyScreen(),
            width: _phoneWidth, locale: locale);
        _expectClean(tester);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    }
  });
}
