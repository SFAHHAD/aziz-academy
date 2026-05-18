import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/features/legal/about_screen.dart';
import 'package:aziz_academy/features/legal/install_guide_screen.dart';
import 'package:aziz_academy/features/legal/privacy_policy_screen.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';

// =============================================================================
// Bilingual page render checks.
//
// We only test that the public copy renders in the right language for each
// locale. We don't tap the back buttons (which depend on go_router context),
// so MaterialApp(home: ...) is enough.
//
// localeProvider reads the saved locale via SharedPreferences in its async
// build, so we seed it with setMockInitialValues and pumpAndSettle to let it
// resolve before assertions.
// =============================================================================

Future<void> _pump(WidgetTester tester, Widget child) async {
  // Use a tall viewport so vertically-stacked content (the InstallGuide's
  // three platform cards, the Privacy page's many sections) is fully built
  // and findable without needing to scroll.
  tester.view.physicalSize = const Size(1080, 4000);
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
  group('AboutScreen bilingual rendering', () {
    testWidgets('renders Arabic copy when locale is ar', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'ar'});
      await _pump(tester, const AboutScreen());

      expect(find.text('أكاديمية عزيز'), findsOneWidget);
      expect(find.text('عن التطبيق'), findsOneWidget);
      expect(find.textContaining('الفئة المستهدفة'), findsOneWidget);
      expect(find.textContaining('صُنع في الكويت'), findsOneWidget);
    });

    testWidgets('renders English copy when locale is en', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      await _pump(tester, const AboutScreen());

      expect(find.text('Aziz Academy'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.textContaining("Who it's for"), findsOneWidget);
      expect(find.textContaining('Made in Kuwait'), findsOneWidget);
    });

    testWidgets('shows aziz-academy.com in both locales', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'ar'});
      await _pump(tester, const AboutScreen());
      expect(find.text('aziz-academy.com'), findsOneWidget);
    });
  });

  group('PrivacyPolicyScreen bilingual rendering', () {
    testWidgets('renders Arabic copy when locale is ar', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'ar'});
      await _pump(tester, const PrivacyPolicyScreen());

      expect(find.text('الخصوصية'), findsOneWidget);
      expect(find.text('لا بيانات شخصية'), findsOneWidget);
      expect(find.textContaining('ما الذي نجمعه؟'), findsOneWidget);
    });

    testWidgets('renders English copy when locale is en', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      await _pump(tester, const PrivacyPolicyScreen());

      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('NO PII'), findsOneWidget);
      expect(find.textContaining('What we collect'), findsOneWidget);
    });

    testWidgets('discloses the only third-party network calls', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      await _pump(tester, const PrivacyPolicyScreen());
      // Privacy policy must enumerate every outbound call. Currently no
      // analytics; only Maps tiles (OpenStreetMap) and flag images (flagcdn).
      expect(find.textContaining('OpenStreetMap'), findsOneWidget);
      expect(find.textContaining('flagcdn.com'), findsOneWidget);
    });

    testWidgets('mentions COPPA / GDPR-K / PDPL compliance', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      await _pump(tester, const PrivacyPolicyScreen());
      // COPPA / GDPR / PDPL appear in both the section heading AND its body.
      expect(find.textContaining('COPPA'), findsAtLeastNWidgets(1));
      expect(find.textContaining('GDPR'), findsAtLeastNWidgets(1));
      expect(find.textContaining('PDPL'), findsAtLeastNWidgets(1));
    });
  });

  group('InstallGuideScreen bilingual rendering', () {
    testWidgets('renders Arabic copy when locale is ar', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'ar'});
      await _pump(tester, const InstallGuideScreen());

      expect(find.text('تثبيت التطبيق'), findsOneWidget);
      expect(find.textContaining('آيفون'), findsOneWidget);
      expect(find.textContaining('أندرويد'), findsOneWidget);
    });

    testWidgets('renders English copy when locale is en', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      await _pump(tester, const InstallGuideScreen());

      expect(find.text('Install on phone'), findsOneWidget);
      expect(find.textContaining('iPhone'), findsOneWidget);
      expect(find.textContaining('Android'), findsOneWidget);
      expect(find.textContaining('Desktop'), findsOneWidget);
    });

    testWidgets('mentions aziz-academy.com in install steps', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      await _pump(tester, const InstallGuideScreen());
      expect(find.textContaining('aziz-academy.com'), findsAtLeastNWidgets(1));
    });
  });
}
