import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/providers/streak_freeze_provider.dart';
import 'package:aziz_academy/features/iq/data/iq_repository.dart';
import 'package:aziz_academy/features/iq/providers/iq_quiz_provider.dart';

/// Daily Brain Boost challenge — 5 curated items per day:
///  • 1 item from each of the 4 Brain Boost categories
///    (Patterns, Mental Math, Analogies, Logic)
///  • 1 wildcard sampled at the learner's weakest category
/// Difficulty per item is picked from the learner's per-category skill EMA
/// via [difficultyBandFor] + [preferredDifficulties].
///
/// State: streak counter + last-completed day stamp. Streak increments on a
/// completed daily session if the previous day was already completed; resets
/// on a missed day; preserves on same-day re-opens.

// Daily picks 1 item from each of the 4 core categories. Spatial/Memory
// remain available via the per-category drill but aren't in the daily
// rotation to keep daily length bounded at 5 items.
const _kBrainBoostCats = ['Patterns', 'Mental Math', 'Analogies', 'Logic'];
const _kPrefsKey = 'brain_boost_daily_v1';

/// Streak milestones → cosmetic IDs unlocked on hit. Already-owned items
/// silently no-op via cosmeticsProvider.grant.
const Map<int, String> kStreakMilestones = {
  3: 'frame_blue',
  7: 'frame_gold',
  14: 'frame_purple',
  30: 'av_dragon',
};

@immutable
class BrainBoostDailyState {
  const BrainBoostDailyState({
    this.streak = 0,
    this.lastCompletedYmd,
    this.todayCompleted = false,
    this.recentCompletions = const <String>[],
  });

  /// Current consecutive-day streak (0 if no streak active).
  final int streak;

  /// "YYYY-MM-DD" of the most recent completed daily.
  final String? lastCompletedYmd;

  /// True if the daily was completed for *today* (UTC-naive local date).
  final bool todayCompleted;

  /// Last 14 completion dates ("YYYY-MM-DD"), newest first. Used to render the
  /// 7-day completion strip on the Brain Boost intro.
  final List<String> recentCompletions;

  BrainBoostDailyState copyWith({
    int? streak,
    String? lastCompletedYmd,
    bool? todayCompleted,
    List<String>? recentCompletions,
  }) => BrainBoostDailyState(
    streak: streak ?? this.streak,
    lastCompletedYmd: lastCompletedYmd ?? this.lastCompletedYmd,
    todayCompleted: todayCompleted ?? this.todayCompleted,
    recentCompletions: recentCompletions ?? this.recentCompletions,
  );

  Map<String, dynamic> toJson() => {
    's': streak,
    'last': lastCompletedYmd,
    'rc': recentCompletions,
  };

  static BrainBoostDailyState fromJson(Map<String, dynamic> m) {
    final last = m['last'] as String?;
    return BrainBoostDailyState(
      streak: (m['s'] as num?)?.toInt() ?? 0,
      lastCompletedYmd: last,
      todayCompleted: last == _todayYmd(),
      recentCompletions: ((m['rc'] as List?) ?? const []).cast<String>(),
    );
  }
}

String _todayYmd() {
  final n = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${n.year}-${two(n.month)}-${two(n.day)}';
}

String _yesterdayYmd() => _ymdDaysAgo(1);

String _ymdDaysAgo(int days) {
  final y = DateTime.now().subtract(Duration(days: days));
  String two(int v) => v.toString().padLeft(2, '0');
  return '${y.year}-${two(y.month)}-${two(y.day)}';
}

final brainBoostDailyProvider =
    AsyncNotifierProvider<BrainBoostDailyNotifier, BrainBoostDailyState>(
      BrainBoostDailyNotifier.new,
      name: 'brainBoostDailyProvider',
    );

class BrainBoostDailyNotifier extends AsyncNotifier<BrainBoostDailyState> {
  SharedPreferences? _prefs;

  @override
  Future<BrainBoostDailyState> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kPrefsKey);
    if (raw == null) return const BrainBoostDailyState();
    try {
      return BrainBoostDailyState.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const BrainBoostDailyState();
    }
  }

  Future<void> _persist(BrainBoostDailyState s) async {
    _prefs ??= await SharedPreferences.getInstance();
    state = AsyncData(s);
    await _prefs!.setString(_kPrefsKey, jsonEncode(s.toJson()));
  }

  /// Mark today's daily as completed. Increments streak if yesterday was the
  /// last completion, otherwise resets to 1. No-op if already completed today.
  /// Returns the milestone cosmetic ID if today's streak hit a threshold (so
  /// callers can show a celebration), null otherwise.
  Future<String?> markCompleted() async {
    final cur = state.value ?? const BrainBoostDailyState();
    if (cur.todayCompleted) return null;
    final today = _todayYmd();
    var continuing = cur.lastCompletedYmd == _yesterdayYmd();
    // Streak Freeze recovery: if the user missed exactly one day but has a
    // freeze in inventory, consume it to keep the streak alive instead of
    // resetting. The freeze's `consumedYmd` is set so we don't double-spend.
    if (!continuing && cur.lastCompletedYmd != null) {
      final freezes = await ref.read(streakFreezeProvider.future);
      final dayBeforeYesterday = _ymdDaysAgo(2);
      final missedJustOne = cur.lastCompletedYmd == dayBeforeYesterday;
      if (missedJustOne && freezes.owned > 0) {
        final spent = await ref
            .read(streakFreezeProvider.notifier)
            .consume(today);
        if (spent) continuing = true;
      }
    }
    final newStreak = continuing ? cur.streak + 1 : 1;
    final newRecent = {today, ...cur.recentCompletions}.toList()
      ..sort((a, b) => b.compareTo(a));
    if (newRecent.length > 14) newRecent.removeRange(14, newRecent.length);
    final next = cur.copyWith(
      streak: newStreak,
      lastCompletedYmd: today,
      todayCompleted: true,
      recentCompletions: newRecent,
    );
    await _persist(next);
    return kStreakMilestones[newStreak];
  }
}

/// Picks today's 5 daily items from the loaded IQ entries, deterministic per
/// device-day (so the same items show up if the user reopens).
final brainBoostDailyItemsProvider = Provider<AsyncValue<List<IqEntry>>>((ref) {
  final entriesAsync = ref.watch(iqEntriesProvider);
  final learner = ref.watch(learnerStateProvider).value;
  return entriesAsync.whenData((all) {
    if (all.isEmpty) return const <IqEntry>[];
    final byCat = <String, List<IqEntry>>{};
    for (final e in all) {
      byCat.putIfAbsent(e.category, () => []).add(e);
    }

    // Deterministic seed: device day plus a stable string. Same items per day.
    final seedStr = _todayYmd() + (learner?.totalSessions ?? 0).toString();
    final rng = math.Random(seedStr.hashCode);

    final picks = <IqEntry>[];
    for (final cat in _kBrainBoostCats) {
      final pool = byCat[cat];
      if (pool == null || pool.isEmpty) continue;
      final pick = _pickAtSkill(pool, learner, cat, rng);
      if (pick != null) picks.add(pick);
    }

    // Wildcard: weakest category, second pick (if available, distinct id).
    final weakestCat = _weakestCategory(learner);
    final wcPool = byCat[weakestCat];
    if (wcPool != null && wcPool.isNotEmpty) {
      final candidates = wcPool
          .where((e) => !picks.any((p) => p.id == e.id))
          .toList();
      if (candidates.isNotEmpty) {
        final wc = candidates[rng.nextInt(candidates.length)];
        picks.add(wc);
      }
    }

    return picks;
  });
}, name: 'brainBoostDailyItemsProvider');

IqEntry? _pickAtSkill(
  List<IqEntry> pool,
  LearnerState? learner,
  String category,
  math.Random rng,
) {
  final skill = learner?.skillForCategory('iq', category) ?? 0.5;
  final band = difficultyBandFor(skill);
  final preferred = preferredDifficulties(band);
  for (final d in preferred) {
    final atDiff = pool.where((e) => e.difficulty == d).toList();
    if (atDiff.isNotEmpty) return atDiff[rng.nextInt(atDiff.length)];
  }
  return pool[rng.nextInt(pool.length)];
}

String _weakestCategory(LearnerState? learner) {
  if (learner == null) return _kBrainBoostCats.first;
  final cats = learner.skillByModuleCategory['iq'] ?? const {};
  final attempted = _kBrainBoostCats.where(cats.containsKey).toList();
  if (attempted.isEmpty) return _kBrainBoostCats.first;
  attempted.sort((a, b) => cats[a]!.compareTo(cats[b]!));
  return attempted.first;
}
