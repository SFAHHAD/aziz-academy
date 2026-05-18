import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography scale for Aziz Academy.
///
/// Cairo is the single bundled face: it covers Arabic + Latin and ships in
/// `assets/fonts/Cairo-Regular.ttf` (registered in pubspec.yaml). All styles
/// use [AppColors.textDark] (#D7E3FC) — the on-surface token — by default.
abstract final class AppTextStyles {
  static const String _family = 'Cairo';
  // Fallback chain: Amiri covers the Arabic Presentation Forms (ﷺ) and the
  // Latin Extended Additional diacritics (ḥ ʿ) used in transliteration —
  // without it, CanvasKit can't find a glyph and loops in
  // requestAnimationFrame. NotoColorEmoji (COLRv1 variant) covers emojis
  // locally so we never reach for fonts.gstatic.com.
  static const List<String> _fallback = ['Amiri', 'NotoColorEmoji'];

  // ---------- Display ----------
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 48,
    fontWeight: FontWeight.w900,
    color: AppColors.textDark,
    letterSpacing: -1,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    height: 1.2,
  );

  // ---------- Headings ----------
  static const TextStyle headingLarge = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  // ---------- Body ----------
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textMedium,
    height: 1.6,
  );

  // ---------- Labels / Buttons ----------
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: 0.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textMedium,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMedium,
  );

  // ---------- Caption / Hints ----------
  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textMedium,
  );

  // ---------- Gold variants ----------
  static TextStyle get displayLargeGold =>
      displayLarge.copyWith(color: AppColors.secondary);

  static TextStyle get headingMediumGold =>
      headingMedium.copyWith(color: AppColors.secondary);
}
