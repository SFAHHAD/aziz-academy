import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/features/fractions_practice/fractions_practice_screen.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required String locale,
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({'app_locale': locale});

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
  if (msg.contains('on the bottom') || msg.contains('on the top')) return;
  fail('Unexpected exception: $msg');
}

void main() {
  group('FractionsPracticeScreen', () {
    for (final locale in ['en', 'ar']) {
      testWidgets('builds at 375px ($locale)', (tester) async {
        await _pump(tester, const FractionsPracticeScreen(), locale: locale);
        _expectClean(tester);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    }
  });
}
