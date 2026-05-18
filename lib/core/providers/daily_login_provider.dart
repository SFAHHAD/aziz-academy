import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/coin_provider.dart';

/// Daily-login calendar — gives the kid a small reward for opening the app
/// each day, with bigger milestones at day 7 and day 30. Streak resets if
/// the kid misses a calendar day. Pure on-device, no backend.
class DailyLoginState {
  const DailyLoginState({
    required this.streak,
    required this.lastClaimedYmd,
    required this.totalClaims,
    required this.pendingReward,
  });

  /// Consecutive-days streak. Includes today only after [claimToday].
  final int streak;

  /// `null` until the kid has ever claimed; otherwise the last YMD claimed.
  final String? lastClaimedYmd;

  final int totalClaims;

  /// 0 when nothing to claim today; otherwise the coin amount waiting in the
  /// claim button.
  final int pendingReward;

  bool get canClaimToday => pendingReward > 0;

  DailyLoginState copyWith({
    int? streak,
    String? lastClaimedYmd,
    int? totalClaims,
    int? pendingReward,
  }) => DailyLoginState(
    streak: streak ?? this.streak,
    lastClaimedYmd: lastClaimedYmd ?? this.lastClaimedYmd,
    totalClaims: totalClaims ?? this.totalClaims,
    pendingReward: pendingReward ?? this.pendingReward,
  );
}

const String _kStreakKey = 'daily_login_streak_v1';
const String _kLastYmdKey = 'daily_login_last_ymd_v1';
const String _kTotalKey = 'daily_login_total_v1';

final dailyLoginProvider =
    AsyncNotifierProvider<DailyLoginNotifier, DailyLoginState>(
      DailyLoginNotifier.new,
    );

class DailyLoginNotifier extends AsyncNotifier<DailyLoginState> {
  SharedPreferences? _prefs;

  @override
  Future<DailyLoginState> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final streak = _prefs!.getInt(_kStreakKey) ?? 0;
    final last = _prefs!.getString(_kLastYmdKey);
    final total = _prefs!.getInt(_kTotalKey) ?? 0;
    return _withReward(streak: streak, last: last, total: total);
  }

  /// Award the day's coins and roll the streak forward.
  Future<int> claimToday() async {
    _prefs ??= await SharedPreferences.getInstance();
    final cur = state.value;
    if (cur == null || !cur.canClaimToday) return 0;
    final today = _ymd(DateTime.now());
    final reward = cur.pendingReward;
    final nextStreak = cur.streak + 1;
    await _prefs!.setInt(_kStreakKey, nextStreak);
    await _prefs!.setString(_kLastYmdKey, today);
    await _prefs!.setInt(_kTotalKey, cur.totalClaims + 1);
    state = AsyncData(
      DailyLoginState(
        streak: nextStreak,
        lastClaimedYmd: today,
        totalClaims: cur.totalClaims + 1,
        pendingReward: 0,
      ),
    );
    await ref.read(coinProvider.notifier).award(reward);
    return reward;
  }

  /// For Reset Profile.
  Future<void> resetAll() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_kStreakKey);
    await _prefs!.remove(_kLastYmdKey);
    await _prefs!.remove(_kTotalKey);
    state = const AsyncData(
      DailyLoginState(
        streak: 0,
        lastClaimedYmd: null,
        totalClaims: 0,
        pendingReward: 0,
      ),
    );
  }

  DailyLoginState _withReward({
    required int streak,
    required String? last,
    required int total,
  }) {
    final today = _ymd(DateTime.now());
    if (last == today) {
      // Already claimed today.
      return DailyLoginState(
        streak: streak,
        lastClaimedYmd: last,
        totalClaims: total,
        pendingReward: 0,
      );
    }
    final yesterday = _ymd(DateTime.now().subtract(const Duration(days: 1)));
    final continuing = last == yesterday;
    final nextStreakIfClaimed = continuing ? streak + 1 : 1;
    return DailyLoginState(
      streak: streak,
      lastClaimedYmd: last,
      totalClaims: total,
      pendingReward: rewardFor(nextStreakIfClaimed),
    );
  }

  /// Reward schedule — small daily payout, big bumps at day 7 and 30, then
  /// a small loyalty payout that keeps coming forever.
  static int rewardFor(int dayInStreak) {
    if (dayInStreak >= 30 && dayInStreak % 30 == 0) return 250;
    if (dayInStreak == 7) return 75;
    if (dayInStreak == 3) return 30;
    if (dayInStreak >= 30) return 20;
    if (dayInStreak >= 7) return 15;
    return 10;
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, "0")}-${d.month.toString().padLeft(2, "0")}-${d.day.toString().padLeft(2, "0")}';
}
