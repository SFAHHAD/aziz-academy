import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/family_profiles_provider.dart';

/// Per-profile activity record. Unlike achievements/coins/XP — which are
/// shared device-wide by design (one device → one trophy room) — this is
/// scoped to a single [ProfileSlot]. It answers "how is *this* kid doing?"
/// so the family-profiles feature is meaningful: each sibling sees their
/// own streak and consistency, not the device total.
///
/// Everything is on-device only, no PII, consistent with the app's privacy
/// architecture.
class ProfileActivity {
  const ProfileActivity({
    this.daysActive = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.totalSessions = 0,
    this.sessionsToday = 0,
    this.lastActiveDate = '',
    this.memberSince = '',
    this.recentDays = const [],
  });

  /// Distinct calendar days this profile has opened the app.
  final int daysActive;

  /// Current consecutive-day streak.
  final int streak;

  /// Highest streak ever reached.
  final int bestStreak;

  /// Total sessions (app opens) recorded for this profile.
  final int totalSessions;

  /// Sessions counted for today specifically.
  final int sessionsToday;

  /// `yyyy-MM-dd` of the most recent active day, or `''` if never active.
  final String lastActiveDate;

  /// `yyyy-MM-dd` of the first ever active day, or `''`.
  final String memberSince;

  /// Up to the last 14 distinct active day strings, oldest-first. Drives
  /// the activity calendar strip on the profile card.
  final List<String> recentDays;

  bool get hasData => totalSessions > 0;

  ProfileActivity copyWith({
    int? daysActive,
    int? streak,
    int? bestStreak,
    int? totalSessions,
    int? sessionsToday,
    String? lastActiveDate,
    String? memberSince,
    List<String>? recentDays,
  }) => ProfileActivity(
    daysActive: daysActive ?? this.daysActive,
    streak: streak ?? this.streak,
    bestStreak: bestStreak ?? this.bestStreak,
    totalSessions: totalSessions ?? this.totalSessions,
    sessionsToday: sessionsToday ?? this.sessionsToday,
    lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    memberSince: memberSince ?? this.memberSince,
    recentDays: recentDays ?? this.recentDays,
  );

  Map<String, dynamic> toJson() => {
    'd': daysActive,
    's': streak,
    'b': bestStreak,
    't': totalSessions,
    'st': sessionsToday,
    'la': lastActiveDate,
    'ms': memberSince,
    'rd': recentDays,
  };

  static ProfileActivity fromJson(Map<String, dynamic> m) => ProfileActivity(
    daysActive: (m['d'] as num?)?.toInt() ?? 0,
    streak: (m['s'] as num?)?.toInt() ?? 0,
    bestStreak: (m['b'] as num?)?.toInt() ?? 0,
    totalSessions: (m['t'] as num?)?.toInt() ?? 0,
    sessionsToday: (m['st'] as num?)?.toInt() ?? 0,
    lastActiveDate: (m['la'] as String?) ?? '',
    memberSince: (m['ms'] as String?) ?? '',
    recentDays:
        ((m['rd'] as List?) ?? const []).whereType<String>().toList(),
  );
}

/// Formats a [DateTime] as `yyyy-MM-dd` (local). Pure — exposed for tests.
String activityDayKey(DateTime d) {
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

/// Applies one activity ping to [prev] for the day [now]. Pure function so
/// the streak/day-rollover logic is unit-testable without SharedPreferences.
ProfileActivity applyActivityPing(ProfileActivity prev, DateTime now) {
  final today = activityDayKey(now);
  final yesterday = activityDayKey(now.subtract(const Duration(days: 1)));

  // Same calendar day — only the session counters move.
  if (prev.lastActiveDate == today) {
    return prev.copyWith(
      sessionsToday: prev.sessionsToday + 1,
      totalSessions: prev.totalSessions + 1,
    );
  }

  // A new active day.
  final newStreak = prev.lastActiveDate == yesterday ? prev.streak + 1 : 1;
  final recent = [...prev.recentDays, today];
  // Keep only the most recent 14 distinct days.
  final trimmed = recent.length > 14
      ? recent.sublist(recent.length - 14)
      : recent;

  return prev.copyWith(
    daysActive: prev.daysActive + 1,
    streak: newStreak,
    bestStreak: newStreak > prev.bestStreak ? newStreak : prev.bestStreak,
    totalSessions: prev.totalSessions + 1,
    sessionsToday: 1,
    lastActiveDate: today,
    memberSince: prev.memberSince.isEmpty ? today : prev.memberSince,
    recentDays: trimmed,
  );
}

const _kKey = 'profile_activity_v1';

/// Exposes the [ProfileActivity] of the *currently active* profile slot.
/// Rebuilds when the active slot changes (sibling switch).
final profileActivityProvider =
    AsyncNotifierProvider<ProfileActivityNotifier, ProfileActivity>(
      ProfileActivityNotifier.new,
      name: 'profileActivityProvider',
    );

class ProfileActivityNotifier extends AsyncNotifier<ProfileActivity> {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _prefsInstance() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<Map<String, ProfileActivity>> _loadAll() async {
    final prefs = await _prefsInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map(
        (k, v) => MapEntry(
          k,
          ProfileActivity.fromJson(v as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveAll(Map<String, ProfileActivity> all) async {
    final prefs = await _prefsInstance();
    await prefs.setString(
      _kKey,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  int get _activeSlotId =>
      ref.watch(familyProfilesProvider).value?.activeSlotId ?? 0;

  @override
  Future<ProfileActivity> build() async {
    final slotId = _activeSlotId;
    final all = await _loadAll();
    return all['$slotId'] ?? const ProfileActivity();
  }

  /// Records one session ("the kid opened the app"). Call once per app
  /// launch. [now] is injectable for tests.
  Future<void> recordActivity({DateTime? now}) async {
    final when = now ?? DateTime.now();
    final slotId = ref.read(familyProfilesProvider).value?.activeSlotId ?? 0;
    final all = await _loadAll();
    final prev = all['$slotId'] ?? const ProfileActivity();
    final next = applyActivityPing(prev, when);
    all['$slotId'] = next;
    await _saveAll(all);
    state = AsyncData(next);
  }
}
