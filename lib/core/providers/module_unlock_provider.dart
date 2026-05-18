import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/xp_provider.dart';

// =============================================================================
// Module unlock state
// =============================================================================

class ModuleUnlocks {
  const ModuleUnlocks({
    this.capitals = true,
    this.flags = true,
    this.maps = true,
    this.logos = false,
    this.math = false,
    this.sciences = false,
  });

  final bool capitals;
  final bool flags;
  final bool maps;
  final bool logos;
  final bool math;
  final bool sciences;

  // ── Human-readable unlock requirements (displayed on locked cards) ──────────

  /// Minimum XP level at which Logos unlocks.
  static const int logosRequiredLevel = 2;

  /// Alternative unlock: complete this many Capitals quizzes.
  static const int logosCapitalsRequired = 3;

  /// Minimum XP level at which Math unlocks.
  static const int mathRequiredLevel = 2;

  /// Alternative unlock: complete this many Flags quizzes.
  static const int mathFlagsRequired = 5;

  /// Minimum XP level at which Sciences unlocks.
  static const int sciencesRequiredLevel = 3;

  /// Alternative unlock: complete this many Flags quizzes.
  static const int sciencesFlagsRequired = 10;
}

// =============================================================================
// Provider (pure derived — no state of its own)
// =============================================================================

/// Computes which modules are accessible based on the learner's XP level and
/// quiz completion counts.  Reads [achievementProvider] and [xpProvider].
final moduleUnlockProvider = Provider<ModuleUnlocks>((ref) {
  final ach = ref.watch(achievementProvider).value;
  final xp = ref.watch(xpProvider).value;

  if (ach == null || xp == null) {
    return const ModuleUnlocks(); // defaults: only starter modules unlocked
  }

  final level = xp.level;

  return ModuleUnlocks(
    capitals: true,
    flags: true,
    maps: true,
    logos:
        level >= ModuleUnlocks.logosRequiredLevel ||
        ach.capitalsCompleted >= ModuleUnlocks.logosCapitalsRequired,
    math:
        level >= ModuleUnlocks.mathRequiredLevel ||
        ach.flagsCompleted >= ModuleUnlocks.mathFlagsRequired,
    sciences:
        level >= ModuleUnlocks.sciencesRequiredLevel ||
        ach.flagsCompleted >= ModuleUnlocks.sciencesFlagsRequired,
  );
});
