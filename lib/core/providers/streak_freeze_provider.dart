import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Streak Freeze inventory — purchased "skip-a-day" insurance for the
/// Brain Boost daily streak. When the daily provider would otherwise reset
/// the streak (because yesterday wasn't completed), it can spend one
/// freeze to keep the streak alive.
///
/// Owned count is a simple integer; freezes don't expire.
class StreakFreezeState {
  const StreakFreezeState({this.owned = 0, this.consumedYmd});
  final int owned;
  final String? consumedYmd;

  StreakFreezeState copyWith({int? owned, String? consumedYmd}) =>
      StreakFreezeState(
        owned: owned ?? this.owned,
        consumedYmd: consumedYmd ?? this.consumedYmd,
      );
}

const _kKey = 'streak_freeze_v1';

final streakFreezeProvider =
    AsyncNotifierProvider<StreakFreezeNotifier, StreakFreezeState>(
      StreakFreezeNotifier.new,
      name: 'streakFreezeProvider',
    );

class StreakFreezeNotifier extends AsyncNotifier<StreakFreezeState> {
  SharedPreferences? _prefs;

  @override
  Future<StreakFreezeState> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kKey);
    if (raw == null) return const StreakFreezeState();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return StreakFreezeState(
        owned: (m['o'] as num?)?.toInt() ?? 0,
        consumedYmd: m['c'] as String?,
      );
    } catch (_) {
      return const StreakFreezeState();
    }
  }

  Future<void> _persist(StreakFreezeState s) async {
    _prefs ??= await SharedPreferences.getInstance();
    state = AsyncData(s);
    await _prefs!.setString(
      _kKey,
      jsonEncode({'o': s.owned, 'c': s.consumedYmd}),
    );
  }

  /// Add freezes to the inventory (e.g., from shop purchase).
  Future<void> grant(int n) async {
    final cur = state.value ?? const StreakFreezeState();
    await _persist(cur.copyWith(owned: cur.owned + n));
  }

  /// Spend one freeze. Returns true if a freeze was consumed.
  Future<bool> consume(String ymd) async {
    final cur = state.value ?? const StreakFreezeState();
    if (cur.owned <= 0) return false;
    await _persist(cur.copyWith(owned: cur.owned - 1, consumedYmd: ymd));
    return true;
  }
}
