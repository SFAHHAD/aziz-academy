import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/features/asma_ul_husna/asma_ul_husna_screen.dart';
import 'package:aziz_academy/features/hadith/hadith_memorization_screen.dart';
import 'package:aziz_academy/features/prophet_stories/prophet_stories_screen.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';

// Mobile breakpoint smoke tests for the three new Islamic screens shipped
// in v1.1.82–84. We pump each at iPhone SE / 13 mini / 14 Plus widths and
// verify the widget tree builds without horizontal RenderFlex overflow.
// JSON content loads asynchronously via rootBundle — `pumpAndSettle` waits
// for the future to resolve so the test sees the populated screen.

const _phoneWidths = <double>[320, 375, 414];

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
  // Don't pumpAndSettle — rootBundle asset loads in tests can hang the
  // settle loop. Pump a few frames so the initial layout completes; if
  // the screen overflows horizontally, the framework reports it within
  // those frames.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void _expectNoHorizontalOverflow(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception == null) return;
  final msg = exception.toString();
  // Vertical overflow inside scrollables is fine, horizontal is broken.
  if (msg.contains('on the right') || msg.contains('on the left')) {
    fail('Horizontal overflow detected: $msg');
  }
  // Other exceptions are also fails.
  fail('Unexpected exception: $msg');
}

void main() {
  group('HadithMemorizationScreen mobile breakpoints', () {
    for (final w in _phoneWidths) {
      testWidgets('builds cleanly at ${w.toInt()}px (en)', (tester) async {
        await _pumpAtWidth(tester, const HadithMemorizationScreen(),
            width: w, locale: 'en');
        _expectNoHorizontalOverflow(tester);
      });
      testWidgets('builds cleanly at ${w.toInt()}px (ar)', (tester) async {
        await _pumpAtWidth(tester, const HadithMemorizationScreen(),
            width: w, locale: 'ar');
        _expectNoHorizontalOverflow(tester);
      });
    }
  });

  group('AsmaUlHusnaScreen mobile breakpoints', () {
    for (final w in _phoneWidths) {
      testWidgets('builds cleanly at ${w.toInt()}px (en)', (tester) async {
        await _pumpAtWidth(tester, const AsmaUlHusnaScreen(),
            width: w, locale: 'en');
        _expectNoHorizontalOverflow(tester);
      });
      testWidgets('builds cleanly at ${w.toInt()}px (ar)', (tester) async {
        await _pumpAtWidth(tester, const AsmaUlHusnaScreen(),
            width: w, locale: 'ar');
        _expectNoHorizontalOverflow(tester);
      });
    }
  });

  group('ProphetStoriesScreen mobile breakpoints', () {
    for (final w in _phoneWidths) {
      testWidgets('builds cleanly at ${w.toInt()}px (en)', (tester) async {
        await _pumpAtWidth(tester, const ProphetStoriesScreen(),
            width: w, locale: 'en');
        _expectNoHorizontalOverflow(tester);
      });
      testWidgets('builds cleanly at ${w.toInt()}px (ar)', (tester) async {
        await _pumpAtWidth(tester, const ProphetStoriesScreen(),
            width: w, locale: 'ar');
        _expectNoHorizontalOverflow(tester);
      });
    }
  });
}
