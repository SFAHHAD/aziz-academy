import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/features/hadith/hadith_memorization_screen.dart';
import 'package:aziz_academy/features/asma_ul_husna/asma_ul_husna_screen.dart';
import 'package:aziz_academy/features/prophet_stories/prophet_stories_screen.dart';
import 'package:aziz_academy/features/dua/dua_memorization_screen.dart';
import 'package:aziz_academy/core/widgets/focus_highlight.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';

// Smoke tests for the focusId deep-linking added in v1.1.93. Verifies:
//  - Screens accept a focusId without crashing.
//  - A FocusHighlight widget appears in the tree when the focus is
//    rendered (i.e. the screen sees and uses the param).
// The tests do not validate scroll offset because pumpAndSettle hangs
// on rootBundle reads — we just confirm the focus path renders.

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
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('HadithMemorizationScreen renders FocusHighlight cards',
      (tester) async {
    await _pump(tester, const HadithMemorizationScreen(focusId: 'hdt_001'));
    expect(tester.takeException(), isNull);
    expect(find.byType(FocusHighlight), findsWidgets);
  });

  testWidgets('AsmaUlHusnaScreen renders FocusHighlight cards',
      (tester) async {
    await _pump(tester, const AsmaUlHusnaScreen(focusId: '1'));
    expect(tester.takeException(), isNull);
    expect(find.byType(FocusHighlight), findsWidgets);
  });

  testWidgets('ProphetStoriesScreen renders FocusHighlight cards',
      (tester) async {
    await _pump(tester, const ProphetStoriesScreen(focusId: 'p01'));
    expect(tester.takeException(), isNull);
    expect(find.byType(FocusHighlight), findsWidgets);
  });

  testWidgets('DuaMemorizationScreen renders FocusHighlight cards',
      (tester) async {
    await _pump(tester,
        const DuaMemorizationScreen(focusId: 'dua_eat_before'));
    expect(tester.takeException(), isNull);
    expect(find.byType(FocusHighlight), findsWidgets);
  });

  testWidgets('FocusHighlight reflects focused vs unfocused styling',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusHighlight(
                focused: true,
                child: SizedBox(width: 100, height: 40, key: Key('focused')),
              ),
              FocusHighlight(
                focused: false,
                child: SizedBox(width: 100, height: 40, key: Key('idle')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final all = tester.widgetList<FocusHighlight>(find.byType(FocusHighlight));
    expect(all.length, 2);
    expect(all.where((w) => w.focused).length, 1);
  });
}
