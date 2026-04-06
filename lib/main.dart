import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AzizAcademyApp(),
    ),
  );
}

class AzizAcademyApp extends StatelessWidget {
  const AzizAcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'أكاديمية عزيز',
      debugShowCheckedModeBanner: false,

      // ── Arabic-only localisation ──────────────────────────────────────────
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      // ── Theme — Celestial Academy (always dark) ────────────────────────────
      theme: AppTheme.buildTheme(fontFamily: 'Cairo'),
      darkTheme: AppTheme.buildTheme(fontFamily: 'Cairo'),
      themeMode: ThemeMode.dark,

      routerConfig: appRouter,
      builder: (context, child) {
        // Enforce responsive text scaling across the entire app
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        
        // Mobile screens get slightly smaller text to prevent overlapping/clipping
        final scale = screenWidth < 600 ? 0.85 : 1.0;
        
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        );
      },
    );
  }
}
