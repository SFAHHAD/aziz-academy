import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/features/legal/about_screen.dart';
import 'package:aziz_academy/features/legal/install_guide_screen.dart';
import 'package:aziz_academy/features/legal/privacy_policy_screen.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';

// =============================================================================
// Mobile breakpoint smoke tests.
//
// We pump the public-facing legal/install pages at three real-world phone
// widths (iPhone SE 320, iPhone 13 mini 375, iPhone 14 Plus 414) and verify:
//   1. The widget tree builds without throwing.
//   2. No RenderFlex / overflow exceptions are reported by the framework.
//
// Vertical overflow inside scrollables is fine; horizontal overflow is what
// we're catching — that's what makes a phone layout look broken.
// =============================================================================

const _phoneWidths = <double>[320, 375, 414];

Future<void> _pumpAtWidth(
  WidgetTester tester,
  Widget child, {
  required double width,
  String locale = 'en',
}) async {
  SharedPreferences.setMockInitialValues({'app_locale': locale});

  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AboutScreen mobile breakpoints', () {
    for (final w in _phoneWidths) {
      testWidgets('builds cleanly at ${w.toInt()}px wide (en)', (tester) async {
        await _pumpAtWidth(tester, const AboutScreen(),
            width: w, locale: 'en');
        expect(tester.takeException(), isNull);
        expect(find.text('Aziz Academy'), findsOneWidget);
      });

      testWidgets('builds cleanly at ${w.toInt()}px wide (ar)', (tester) async {
        await _pumpAtWidth(tester, const AboutScreen(),
            width: w, locale: 'ar');
        expect(tester.takeException(), isNull);
        expect(find.text('أكاديمية عزيز'), findsOneWidget);
      });
    }
  });

  group('PrivacyPolicyScreen mobile breakpoints', () {
    for (final w in _phoneWidths) {
      testWidgets('builds cleanly at ${w.toInt()}px wide (en)', (tester) async {
        await _pumpAtWidth(tester, const PrivacyPolicyScreen(),
            width: w, locale: 'en');
        expect(tester.takeException(), isNull);
        expect(find.text('Privacy'), findsOneWidget);
      });

      testWidgets('builds cleanly at ${w.toInt()}px wide (ar)', (tester) async {
        await _pumpAtWidth(tester, const PrivacyPolicyScreen(),
            width: w, locale: 'ar');
        expect(tester.takeException(), isNull);
        expect(find.text('الخصوصية'), findsOneWidget);
      });
    }
  });

  group('InstallGuideScreen mobile breakpoints', () {
    for (final w in _phoneWidths) {
      testWidgets('builds cleanly at ${w.toInt()}px wide (en)', (tester) async {
        await _pumpAtWidth(tester, const InstallGuideScreen(),
            width: w, locale: 'en');
        expect(tester.takeException(), isNull);
        expect(find.text('Install on phone'), findsOneWidget);
      });

      testWidgets('builds cleanly at ${w.toInt()}px wide (ar)', (tester) async {
        await _pumpAtWidth(tester, const InstallGuideScreen(),
            width: w, locale: 'ar');
        expect(tester.takeException(), isNull);
        expect(find.text('تثبيت التطبيق'), findsOneWidget);
      });
    }
  });

  group('Render boxes stay inside the viewport horizontally', () {
    testWidgets('AboutScreen at 320px has no horizontal RenderFlex overflow',
        (tester) async {
      final overflows = <String>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed by')) {
          overflows.add(details.exceptionAsString());
        }
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await _pumpAtWidth(tester, const AboutScreen(),
          width: 320, locale: 'en');

      // Overflow is reported as the message
      // "A RenderFlex overflowed by 12 pixels on the right.".
      // Vertical overflow ("on the bottom") is OK in scrollables.
      final horizontal = overflows
          .where((e) =>
              e.contains('on the right') || e.contains('on the left'))
          .toList();
      expect(horizontal, isEmpty,
          reason: 'unexpected horizontal overflow: $horizontal');
    });
  });
}
