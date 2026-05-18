import 'package:aziz_academy/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// Golden-path smoke tests — boot the full app at known locales and verify it
// renders something kid-facing without throwing.
//
// We don't drive go_router navigation here because most routes use deferred
// imports that don't resolve in the unit test runtime. Instead we:
//   1. Pump the full app under both locales
//   2. Let it pump to settle (with a timeout for any slow-loading providers)
//   3. Verify MaterialApp.router is mounted, no exceptions surfaced, and at
//      least one Material widget has rendered (i.e. we got past the bare-
//      bones bootstrap)
//
// The intent is to catch the kind of accidental break that a unit test on
// individual screens would miss — a bad provider override, a global theme
// regression, a router config error.
// =============================================================================

Future<void> _bootApp(WidgetTester tester, {required String locale}) async {
  SharedPreferences.setMockInitialValues({'app_locale': locale});

  // Bigger viewport so the splash + home contents can lay out without the
  // tester's default 800×600 fighting them.
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const ProviderScope(child: AzizAcademyApp()),
  );

  // Several pumps to flush async providers (locale, settings, etc.) without
  // blocking forever on animations the splash schedules.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('boots cleanly under Arabic locale', (tester) async {
    await _bootApp(tester, locale: 'ar');
    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('boots cleanly under English locale', (tester) async {
    await _bootApp(tester, locale: 'en');
    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('renders a Navigator after first frames', (tester) async {
    await _bootApp(tester, locale: 'en');
    // The .router constructor mounts a Navigator inside its router stack.
    expect(find.byType(Navigator), findsWidgets);
  });

  testWidgets('does not show the bilingual error fallback on a clean boot',
      (tester) async {
    await _bootApp(tester, locale: 'ar');
    expect(find.text('Something went wrong'), findsNothing);
    expect(find.text('حصلت مشكلة بسيطة'), findsNothing);
  });
}
