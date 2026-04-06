import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// The single ThemeData factory for Aziz Academy.
///
/// "The Celestial Academy" uses a full dark mode with midnight navy surfaces
/// and academy gold accents, matching the Stitch design system.
abstract final class AppTheme {
  // ---------------------------------------------------------------------------
  // Public surface
  // ---------------------------------------------------------------------------

  /// The primary theme — always dark, matching the Stitch "Nocturnal Navigator".
  static ThemeData get light => buildTheme(fontFamily: 'PlusJakartaSans');

  static ThemeData get dark => buildTheme(fontFamily: 'PlusJakartaSans');

  // ---------------------------------------------------------------------------
  // Core factory
  // ---------------------------------------------------------------------------
  static ThemeData buildTheme({
    required String fontFamily,
    Brightness brightness = Brightness.dark,
  }) {
    final baseText = ThemeData.dark().textTheme;

    // Use Plus Jakarta Sans for display/headlines, Be Vietnam Pro for body
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseText);

    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.primaryNavy,
      primaryContainer: AppColors.primaryNavy,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.primaryNavy,
      secondaryContainer: const Color(0xFFAF8D11),
      onSecondaryContainer: AppColors.accent,
      tertiary: AppColors.accent,
      onTertiary: AppColors.primaryNavy,
      tertiaryContainer: const Color(0xFFC8A900),
      onTertiaryContainer: AppColors.accent,
      error: AppColors.error,
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: AppColors.surface,
      onSurface: AppColors.textDark,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      onSurfaceVariant: AppColors.textMedium,
      outline: AppColors.outline,
      outlineVariant: AppColors.divider,
      inverseSurface: AppColors.textDark,
      onInverseSurface: AppColors.surfaceContainer,
      inversePrimary: const Color(0xFF535F74),
      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: AppColors.primary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          fontSize: 48,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
          letterSpacing: -1,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
          height: 1.6,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textMedium,
          height: 1.6,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: AppColors.textDark,
        ),
        labelMedium: textTheme.labelMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textMedium,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.primaryNavy,
          minimumSize: const Size(56, 56),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50), // Pill shape
          ),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.textMedium,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
