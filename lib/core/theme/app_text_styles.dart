import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography scale for Aziz Academy — "The Celestial Academy" edition.
///
/// Display/Headline: Plus Jakarta Sans (editorial, impactful)
/// Body/Label: Be Vietnam Pro (legible, sophisticated)
///
/// All defaults use [AppColors.textDark] (#D7E3FC) — the on-surface token.
abstract final class AppTextStyles {

  // ---------- Display ----------
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: AppColors.textDark,
        letterSpacing: -1,
        height: 1.1,
      );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
        height: 1.2,
      );

  // ---------- Headings ----------
  static TextStyle get headingLarge => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      );

  static TextStyle get headingMedium => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      );

  static TextStyle get headingSmall => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      );

  // ---------- Body (Be Vietnam Pro) ----------
  static TextStyle get bodyLarge => GoogleFonts.beVietnamPro(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.beVietnamPro(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textMedium,
        height: 1.6,
      );

  // ---------- Labels / Buttons ----------
  static TextStyle get labelLarge => GoogleFonts.beVietnamPro(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
        letterSpacing: 0.5,
      );

  static TextStyle get labelMedium => GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textMedium,
      );

  static TextStyle get labelSmall => GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textMedium,
      );

  // ---------- Caption / Hints ----------
  static TextStyle get caption => GoogleFonts.beVietnamPro(
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
