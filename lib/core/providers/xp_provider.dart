import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// Level system
// =============================================================================

/// Minimum cumulative XP required to *reach* each level (index = level − 1).
/// Level 1 = 0 XP, Level 2 = 500 XP, Level 3 = 1 500 XP, etc.
const _kThresholds = [0, 500, 1500, 3000, 5500, 9000];

/// Base XP awarded per correct answer in any quiz session.
const kXpPerCorrect = 10;

/// Bonus XP for finishing a round with all lives intact (perfect score).
const kXpPerfectBonus = 50;

/// Returns the level (1-indexed) corresponding to [xp] total XP.
int levelForXp(int xp) {
  for (var i = _kThresholds.length - 1; i >= 0; i--) {
    if (xp >= _kThresholds[i]) return i + 1;
  }
  return 1;
}

int _thresholdFor(int level) {
  final idx = (level - 1).clamp(0, _kThresholds.length - 1);
  return _kThresholds[idx];
}

int _nextThresholdFor(int level) {
  final idx = level.clamp(0, _kThresholds.length - 1);
  if (idx >= _kThresholds.length) return _thresholdFor(level) + 5000;
  return _kThresholds[idx];
}

// =============================================================================
// State
// =============================================================================

class XpState {
  const XpState({this.totalXp = 0});

  final int totalXp;

  int get level => levelForXp(totalXp);

  bool get isMaxLevel => level >= _kThresholds.length;

  /// XP accumulated within the current level (resets each level-up).
  int get xpInCurrentLevel => totalXp - _thresholdFor(level);

  /// XP span of the current level (0 if at max level).
  int get xpNeededForNextLevel =>
      isMaxLevel ? 0 : _nextThresholdFor(level) - _thresholdFor(level);

  /// 0.0–1.0 fill for the in-level progress bar.
  double get progressInLevel {
    if (isMaxLevel) return 1.0;
    final span = xpNeededForNextLevel;
    if (span <= 0) return 1.0;
    return (xpInCurrentLevel / span).clamp(0.0, 1.0);
  }

  XpState copyWith({int? totalXp}) =>
      XpState(totalXp: totalXp ?? this.totalXp);
}

// =============================================================================
// SharedPreferences key
// =============================================================================

const _kXpKey = 'xp_total_xp';

// =============================================================================
// Provider
// =============================================================================

final xpProvider = AsyncNotifierProvider<XpNotifier, XpState>(
  XpNotifier.new,
  name: 'xpProvider',
);

class XpNotifier extends AsyncNotifier<XpState> {
  late SharedPreferences _prefs;

  @override
  Future<XpState> build() async {
    _prefs = await SharedPreferences.getInstance();
    return XpState(totalXp: _prefs.getInt(_kXpKey) ?? 0);
  }

  /// Adds [amount] XP and persists the new total.
  Future<void> addXp(int amount) async {
    if (amount <= 0) return;
    final current = state.value ?? const XpState();
    final next = current.copyWith(totalXp: current.totalXp + amount);
    state = AsyncData(next);
    await _prefs.setInt(_kXpKey, next.totalXp);
  }

  /// Computes the XP earned from a single quiz session.
  static int sessionXp({required int score, required int livesRemaining}) {
    final perfect = livesRemaining == 3 ? kXpPerfectBonus : 0;
    return score * kXpPerCorrect + perfect;
  }

  /// Replaces the total directly (used by backup-restore).
  Future<void> setTotalXp(int xp) async {
    final next = XpState(totalXp: xp.clamp(0, 999999));
    state = AsyncData(next);
    await _prefs.setInt(_kXpKey, next.totalXp);
  }
}
