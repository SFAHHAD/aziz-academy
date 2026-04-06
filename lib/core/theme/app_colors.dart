import 'package:flutter/material.dart';

/// All brand colors for Aziz Academy — "The Celestial Academy" dark palette.
/// Derived from the Stitch design system: deep midnight navy + academy gold.
/// Do NOT use raw hex codes anywhere else in the codebase.
abstract final class AppColors {
  // ── Brand (Core tokens) ─────────────────────────────────────────────────────
  /// Star Blue — primary text/icon color on dark backgrounds, highlighting.
  static const Color primary = Color(0xFF00E5FF);

  /// Teal — CTAs, highlights.
  static const Color secondary = Color(0xFF00C896);

  /// Jade Green — lighter shimmer / effects.
  static const Color accent = Color(0xFF00A65F);

  /// Deep Cobalt — used for logo, primary containers.
  static const Color primaryNavy = Color(0xFF1A3C6E);

  // ── Surface / Background ────────────────────────────────────────────────────
  /// The void — deepest background (Darkened Deep Cobalt).
  static const Color background = Color(0xFF0F2445);

  /// Main surface (same as background for consistency).
  static const Color surface = Color(0xFF0F2445);

  /// surface_container_low — subtle lift above background.
  static const Color surfaceContainerLow = Color(0xFF16305A);

  /// surface_container — default card background.
  static const Color surfaceContainer = Color(0xFF1A3C6E);

  /// surface_container_high — more prominent cards.
  static const Color surfaceContainerHigh = Color(0xFF225091);

  /// surface_container_highest — top-most foreground elements.
  static const Color surfaceContainerHighest = Color(0xFF2C63B3);

  /// surface_bright — navigation bars, elevated panels.
  static const Color surfaceBright = Color(0xFF2C63B3);

  /// surface_variant — glass fills.
  static const Color surfaceVariant = Color(0xFF2C63B3);

  // ── Legacy aliases (kept for backward-compat across existing screens) ────────
  static const Color surfaceCard = surfaceContainerHigh;
  static const Color surfaceDark = Color(0xFF0C1D3A);
  static const Color surfaceCardDark = surfaceContainer;

  // ── Module colours ──────────────────────────────────────────────────────────
  static const Color mapsColor = Color(0xFF00C896);      // Teal
  static const Color capitalsColor = Color(0xFF00E5FF);  // Star Blue
  static const Color logosColor = Color(0xFFB07FE8);     // Soft purple

  // ── Status ──────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00C896); // Teal
  static const Color error   = Color(0xFFFF3D3D); // Crimson Red
  static const Color warning = Color(0xFFE9C349); // Keep warning gold

  // ── Text ────────────────────────────────────────────────────────────────────
  static const Color textDark   = Color(0xFFE0F4FF); // pale star blue 
  static const Color textMedium = Color(0xFFA5C9E5); // muted 
  static const Color textLight  = Color(0xFFFFFFFF); // pure white
  static const Color textGold   = Color(0xFF00E5FF); // using star blue here for contrast

  // ── Misc ─────────────────────────────────────────────────────────────────────
  static const Color divider  = Color(0xFF225091);
  static const Color outline  = Color(0xFF6B9FE4);
  static const Color disabled = Color(0xFF3B4F72);

  // ── Glass helpers ─────────────────────────────────────────────────────────────
  /// Semi-transparent surface for glassmorphic cards (60% opacity).
  static Color get glassFill =>
      surfaceContainerHighest.withAlpha(153); // 60%

  /// Ghost border for glass cards.
  static Color get glassBorder =>
      const Color(0xFF8DC0F3).withAlpha(38); // 15%

  /// Subtle glow for active/hover states.
  static Color get goldGlow =>
      const Color(0xFF00E5FF).withAlpha(40);

  // ── Gradient helpers ─────────────────────────────────────────────────────────
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A3C6E), Color(0xFF0F2445)],
  );

  /// 135° Star Blue/Teal shimmer — used on primary CTAs.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment(0.7, -0.7),   // ~135°
    end: Alignment(-0.7, 0.7),
    colors: [Color(0xFF00E5FF), Color(0xFF00C896)],
  );

  /// Hero / AppBar gradient.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1628), Color(0xFF071325)],
  );

  /// Glow-track active color gradient (burning fuse progress).
  static const LinearGradient progressGradient = LinearGradient(
    colors: [Color(0xFFE9C349), Color(0xFFAF8D11)],
  );

  /// Glassmorphic card gradient.
  static LinearGradient glassCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      const Color(0xFF2A3548).withAlpha(153),
      const Color(0xFF1F2A3D).withAlpha(120),
    ],
  );
}
