import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/features/account/presentation/account_screen.dart';
import 'package:aziz_academy/features/account/presentation/premium_screen.dart';
import 'package:aziz_academy/features/onboarding/presentation/welcome_screen.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';

/// Smoke tests for the v1.1.113 restructure surfaces — the rebuilt
/// onboarding (now with the parent-account step), the Account hub, and
/// the Plus screen. Each pumps the screen and verifies it renders without
/// throwing, catching missing providers and layout regressions at
/// first-frame time before they ship.

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
  // Give async providers (locale, settings, prefs) a few frames to resolve.
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  testWidgets('WelcomeScreen renders the first onboarding step', (
    tester,
  ) async {
    await _pump(tester, const WelcomeScreen());
    expect(tester.takeException(), isNull);
    // Step 0 — language picker is what a brand-new family sees first.
    expect(find.text('Choose your language'), findsOneWidget);
  });

  testWidgets('AccountScreen renders the guest hub', (tester) async {
    await _pump(tester, const AccountScreen());
    expect(tester.takeException(), isNull);
    // Guest state — the sign-in hub plus the Plus promo are visible.
    expect(find.text('Guest mode'), findsOneWidget);
    expect(find.text('Aziz Academy Plus'), findsWidgets);
  });

  testWidgets('PremiumScreen renders the Plus upgrade hub', (tester) async {
    await _pump(tester, const PremiumScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('What Plus unlocks'), findsOneWidget);
  });
}
