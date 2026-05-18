import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On-device miss tracker for tap-to-answer quiz screens. Tracks how
/// many times the kid has missed each specific question shape (e.g.
/// for Number Bonds: how often they miss "shown=7, target=10"). The
/// host engine reads these counts and biases sampling toward the
/// trouble spots — closing the adaptive-difficulty gap that the
/// random generators alone can't solve.
///
/// Keys are `"<screen>:<mode>:<discriminator>"`, e.g.
/// `"number_bonds:ten:7"` for "the bond shown=7 within bonds-to-10".
/// Pure on-device — never leaves the device.

class QuizMisses {
  const QuizMisses({required this.byKey});

  final Map<String, int> byKey;

  int missesFor(String key) => byKey[key] ?? 0;

  /// All miss-keys for a given `"screen:mode"` prefix, sorted by miss
  /// count descending. Lets the engine ask "which shown values has
  /// this kid missed the most in bonds-to-10?".
  List<MapEntry<String, int>> topForPrefix(String prefix, {int limit = 8}) {
    final hits = byKey.entries.where((e) => e.key.startsWith('$prefix:'));
    final sorted = hits.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  static const empty = QuizMisses(byKey: {});

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(byKey);

  static QuizMisses fromJson(Map<String, dynamic> j) {
    final out = <String, int>{};
    for (final e in j.entries) {
      final v = e.value;
      if (v is num) out[e.key] = v.toInt();
    }
    return QuizMisses(byKey: out);
  }

  QuizMisses withIncrement(String key) =>
      QuizMisses(byKey: {...byKey, key: missesFor(key) + 1});

  QuizMisses withDecay(String prefix) {
    // Once the kid has clearly mastered something (10+ misses healed
    // by recent practice), it's worth letting some weight evaporate.
    // For now we just cap at 8 so the weighted sampler doesn't get
    // dominated by a single ancient miss.
    final next = <String, int>{};
    for (final e in byKey.entries) {
      if (!e.key.startsWith('$prefix:')) {
        next[e.key] = e.value;
        continue;
      }
      next[e.key] = e.value > 8 ? 8 : e.value;
    }
    return QuizMisses(byKey: next);
  }
}

final quizMissesProvider =
    AsyncNotifierProvider<QuizMissesNotifier, QuizMisses>(
  QuizMissesNotifier.new,
  name: 'quizMissesProvider',
);

const _kKey = 'quiz_misses_v1';

class QuizMissesNotifier extends AsyncNotifier<QuizMisses> {
  SharedPreferences? _prefs;

  @override
  Future<QuizMisses> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kKey);
    if (raw == null || raw.isEmpty) return QuizMisses.empty;
    try {
      return QuizMisses.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return QuizMisses.empty;
    }
  }

  Future<void> recordMiss(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final cur = state.value ?? QuizMisses.empty;
    final next = cur.withIncrement(key);
    state = AsyncData(next);
    await _prefs!.setString(_kKey, jsonEncode(next.toJson()));
  }
}
