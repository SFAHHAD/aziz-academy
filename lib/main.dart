import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AzizAcademyApp(),
    ),
  );
}

class AzizAcademyApp extends ConsumerWidget {
  const AzizAcademyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reducedMotion =
        ref.watch(appSettingsProvider).value?.reducedMotion ?? false;
    final localeAsync = ref.watch(localeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,

      locale: localeAsync.value ?? const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      theme: AppTheme.buildTheme(fontFamily: 'Cairo'),
      darkTheme: AppTheme.buildTheme(fontFamily: 'Cairo'),
      themeMode: ThemeMode.dark,

      routerConfig: appRouter,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final widthTweak = screenWidth < 600 ? 0.9 : 1.0;
        final system = mediaQuery.textScaler.scale(1.0);
        final combined = (system * widthTweak).clamp(0.82, 1.38);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(combined),
            disableAnimations:
                reducedMotion || mediaQuery.disableAnimations,
          ),
          child: child!,
        );
      },
    );
  }
}
