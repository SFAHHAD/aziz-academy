import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/features/alphabet/english_alphabet_screen.dart';
import 'package:aziz_academy/features/shapes_basics/shapes_basics_screen.dart';
import 'package:aziz_academy/features/number_bonds/number_bonds_screen.dart';
import 'package:aziz_academy/features/place_value/place_value_screen.dart';
import 'package:aziz_academy/features/skip_counting/skip_counting_screen.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';

/// Smoke tests for the v1.1.97 screens. Each pumps the screen and just
/// verifies it renders without throwing — catches `AppTextStyles` typos
/// and missing `flutter_riverpod` providers at compile + first-frame
/// time so they don't ship to production.

Future<void> _pump(WidgetTester tester, Widget child) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'app_locale': 'en'});

  tester.view.physicalSize = const Size(375, 800);
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
        locale: const Locale('en'),
        routerConfig: router,
      ),
    ),
  );
  // Give async providers (settings, prefs) a few frames to resolve.
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('EnglishAlphabetScreen renders without throwing',
      (tester) async {
    await _pump(tester, const EnglishAlphabetScreen());
    expect(tester.takeException(), isNull);
    // 26 letters in the grid — finding "A" should always work since
    // it's the first tile.
    expect(find.text('A'), findsWidgets);
  });

  testWidgets('ShapesBasicsScreen renders without throwing', (tester) async {
    await _pump(tester, const ShapesBasicsScreen());
    expect(tester.takeException(), isNull);
    // First tile shows the circle name.
    expect(find.text('Circle'), findsWidgets);
  });

  testWidgets('NumberBondsScreen renders mode picker', (tester) async {
    await _pump(tester, const NumberBondsScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('Pick a target'), findsOneWidget);
    expect(find.text('Bonds to 10'), findsOneWidget);
    expect(find.text('Bonds to 20'), findsOneWidget);
  });

  testWidgets('PlaceValueScreen renders mode picker', (tester) async {
    await _pump(tester, const PlaceValueScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('Pick a mode'), findsOneWidget);
    expect(find.text('What number?'), findsOneWidget);
  });

  testWidgets('SkipCountingScreen renders mode picker', (tester) async {
    await _pump(tester, const SkipCountingScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('Pick a step'), findsOneWidget);
    expect(find.text('By 2s'), findsOneWidget);
    expect(find.text('By 10s'), findsOneWidget);
  });
}
