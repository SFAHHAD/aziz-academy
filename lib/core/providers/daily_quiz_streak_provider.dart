import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/features/daily_wisdom_quiz/daily_question_engine.dart';

/// State for the Daily Wisdom Quiz: how many days in a row the kid has
/// answered, the last day they played (so we can decide whether the
/// streak continues or resets), and lifetime counts. Persists to
/// SharedPreferences. Pure local — no cloud sync (consistent with
/// the rest of the app's privacy posture).
class DailyQuizStreak {
  const DailyQuizStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCorrect,
    required this.totalAttempts,
    required this.lastPlayedIso,
    required this.lastAnsweredCorrect,
  });

  final int currentStreak;
  final int longestStreak;
  final int totalCorrect;
  final int totalAttempts;
  final String? lastPlayedIso;
  final bool lastAnsweredCorrect;

  bool get playedToday {
    if (lastPlayedIso == null) return false;
    final last = DateTime.tryParse(lastPlayedIso!);
    if (last == null) return false;
    return isSameCalendarDay(last, DateTime.now());
  }

  static const empty = DailyQuizStreak(
    currentStreak: 0,
    longestStreak: 0,
    totalCorrect: 0,
    totalAttempts: 0,
    lastPlayedIso: null,
    lastAnsweredCorrect: false,
  );

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalCorrect': totalCorrect,
        'totalAttempts': totalAttempts,
        'lastPlayedIso': lastPlayedIso,
        'lastAnsweredCorrect': lastAnsweredCorrect,
      };

  static DailyQuizStreak fromJson(Map<String, dynamic> j) => DailyQuizStreak(
        currentStreak: (j['currentStreak'] as num?)?.toInt() ?? 0,
        longestStreak: (j['longestStreak'] as num?)?.toInt() ?? 0,
        totalCorrect: (j['totalCorrect'] as num?)?.toInt() ?? 0,
        totalAttempts: (j['totalAttempts'] as num?)?.toInt() ?? 0,
        lastPlayedIso: j['lastPlayedIso'] as String?,
        lastAnsweredCorrect: j['lastAnsweredCorrect'] as bool? ?? false,
      );
}

/// Pure state transition: given the previous streak state and a new
/// answer result, compute the next state. Exposed for unit-testing.
DailyQuizStreak applyDailyAnswer({
  required DailyQuizStreak prev,
  required DateTime now,
  required bool correct,
}) {
  // If they already played today, this is a duplicate attempt — no-op,
  // but we still update lastAnsweredCorrect so the UI can mirror it.
  if (prev.lastPlayedIso != null) {
    final last = DateTime.tryParse(prev.lastPlayedIso!);
    if (last != null && isSameCalendarDay(last, now)) {
      return DailyQuizStreak(
        currentStreak: prev.currentStreak,
        longestStreak: prev.longestStreak,
        totalCorrect: prev.totalCorrect,
        totalAttempts: prev.totalAttempts,
        lastPlayedIso: prev.lastPlayedIso,
        lastAnsweredCorrect: prev.lastAnsweredCorrect,
      );
    }
  }

  // Streak continues if (a) wrong answer doesn't break it AND (b)
  // today is the calendar day immediately after the last play OR this
  // is the first ever play. A wrong answer doesn't reset — only a day
  // gap does. (Children's app — kindness > strict gamification.)
  int newStreak;
  if (prev.lastPlayedIso == null) {
    newStreak = 1;
  } else {
    final last = DateTime.parse(prev.lastPlayedIso!);
    if (isNextCalendarDay(last, now)) {
      newStreak = prev.currentStreak + 1;
    } else {
      newStreak = 1; // gap — reset to 1 (today counts as day 1)
    }
  }

  return DailyQuizStreak(
    currentStreak: newStreak,
    longestStreak:
        newStreak > prev.longestStreak ? newStreak : prev.longestStreak,
    totalCorrect: prev.totalCorrect + (correct ? 1 : 0),
    totalAttempts: prev.totalAttempts + 1,
    lastPlayedIso: now.toIso8601String(),
    lastAnsweredCorrect: correct,
  );
}

final dailyQuizStreakProvider = AsyncNotifierProvider<
    DailyQuizStreakNotifier, DailyQuizStreak>(
  DailyQuizStreakNotifier.new,
  name: 'dailyQuizStreakProvider',
);

const _kKey = 'daily_quiz_streak_v1';

class DailyQuizStreakNotifier extends AsyncNotifier<DailyQuizStreak> {
  SharedPreferences? _prefs;

  @override
  Future<DailyQuizStreak> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kKey);
    if (raw == null || raw.isEmpty) return DailyQuizStreak.empty;
    try {
      return DailyQuizStreak.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return DailyQuizStreak.empty;
    }
  }

  Future<void> recordAnswer({required bool correct, DateTime? now}) async {
    _prefs ??= await SharedPreferences.getInstance();
    final cur = state.value ?? DailyQuizStreak.empty;
    final next = applyDailyAnswer(
      prev: cur,
      now: now ?? DateTime.now(),
      correct: correct,
    );
    state = AsyncData(next);
    await _prefs!.setString(_kKey, jsonEncode(next.toJson()));
  }
}
