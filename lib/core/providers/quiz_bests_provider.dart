import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic personal-best store for short tap-to-answer rounds. Keyed by
/// `"<screen>:<mode>"` (e.g. `"number_bonds:ten"`) so a single
/// SharedPreferences blob covers Number Bonds (per target), Place
/// Value (per mode), Skip Counting (per step), and any future round-
/// style screen. Pure on-device persistence — the values never leave
/// the device. Defaults to 0 when no record exists.

class QuizBests {
  const QuizBests({required this.byKey});

  final Map<String, int> byKey;

  int bestFor(String key) => byKey[key] ?? 0;

  bool hasRecord(String key) => byKey.containsKey(key);

  static const empty = QuizBests(byKey: {});

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(byKey);

  static QuizBests fromJson(Map<String, dynamic> j) {
    final out = <String, int>{};
    for (final e in j.entries) {
      final v = e.value;
      if (v is num) out[e.key] = v.toInt();
    }
    return QuizBests(byKey: out);
  }

  QuizBests withMax(String key, int score) {
    if (score <= bestFor(key)) return this;
    return QuizBests(byKey: {...byKey, key: score});
  }
}

final quizBestsProvider =
    AsyncNotifierProvider<QuizBestsNotifier, QuizBests>(
  QuizBestsNotifier.new,
  name: 'quizBestsProvider',
);

const _kKey = 'quiz_bests_v1';

class QuizBestsNotifier extends AsyncNotifier<QuizBests> {
  SharedPreferences? _prefs;

  @override
  Future<QuizBests> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kKey);
    if (raw == null || raw.isEmpty) return QuizBests.empty;
    try {
      return QuizBests.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return QuizBests.empty;
    }
  }

  /// Returns `(isNewBest, previousBest)`. Callers use the tuple to show
  /// either "🌟 New best!" or "Previous best: N/M" on the result panel.
  Future<({bool isNewBest, int previousBest})> recordScore(
    String key,
    int score,
  ) async {
    _prefs ??= await SharedPreferences.getInstance();
    final cur = state.value ?? QuizBests.empty;
    final prev = cur.bestFor(key);
    final isNewBest = score > prev;
    if (isNewBest) {
      final next = cur.withMax(key, score);
      state = AsyncData(next);
      await _prefs!.setString(_kKey, jsonEncode(next.toJson()));
    }
    return (isNewBest: isNewBest, previousBest: prev);
  }
}
