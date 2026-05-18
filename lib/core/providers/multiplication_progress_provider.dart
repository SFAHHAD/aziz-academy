import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the kid's per-table multiplication accuracy. After each round,
/// the screen calls [recordResult(table, correct, total)]. We keep a
/// running correct/total per table (×2..×12) so the home screen can
/// highlight "shaky tables" and so the practice screen can drill the
/// ones a kid struggles with most.
///
/// Persists to SharedPreferences under a single JSON blob. Pure-local —
/// no cloud sync (consistent with the privacy posture).
class MultiplicationStats {
  const MultiplicationStats({required this.tables});

  /// Map of table (2..12) → (correct, total).
  final Map<int, ({int correct, int total})> tables;

  static const empty = MultiplicationStats(tables: {});

  int correctFor(int table) => tables[table]?.correct ?? 0;
  int totalFor(int table) => tables[table]?.total ?? 0;

  /// Accuracy as a 0..1 ratio, or null if the table has never been
  /// attempted (so the UI can show "—" instead of "0%").
  double? accuracyFor(int table) {
    final t = tables[table];
    if (t == null || t.total == 0) return null;
    return t.correct / t.total;
  }

  /// Tables that have at least one attempt and are below the given
  /// threshold. Sorted weakest-first so the practice screen can suggest
  /// the most-needed drill first.
  List<int> shakyTables({double threshold = 0.8}) {
    final entries = tables.entries
        .where((e) =>
            e.value.total > 0 && (e.value.correct / e.value.total) < threshold)
        .toList();
    entries.sort(
      (a, b) => (a.value.correct / a.value.total)
          .compareTo(b.value.correct / b.value.total),
    );
    return entries.map((e) => e.key).toList();
  }

  Map<String, dynamic> toJson() => {
        for (final e in tables.entries)
          e.key.toString(): {'c': e.value.correct, 't': e.value.total},
      };

  static MultiplicationStats fromJson(Map<String, dynamic> j) {
    final out = <int, ({int correct, int total})>{};
    for (final e in j.entries) {
      final k = int.tryParse(e.key);
      if (k == null) continue;
      final v = e.value as Map<String, dynamic>;
      out[k] = (
        correct: (v['c'] as num?)?.toInt() ?? 0,
        total: (v['t'] as num?)?.toInt() ?? 0,
      );
    }
    return MultiplicationStats(tables: out);
  }

  MultiplicationStats withRound(int table, int correct, int total) {
    final prev = tables[table] ?? (correct: 0, total: 0);
    final next = <int, ({int correct, int total})>{
      ...tables,
      table: (correct: prev.correct + correct, total: prev.total + total),
    };
    return MultiplicationStats(tables: next);
  }
}

final multiplicationProgressProvider = AsyncNotifierProvider<
    MultiplicationProgressNotifier, MultiplicationStats>(
  MultiplicationProgressNotifier.new,
  name: 'multiplicationProgressProvider',
);

const _kKey = 'mult_progress_v1';

class MultiplicationProgressNotifier
    extends AsyncNotifier<MultiplicationStats> {
  SharedPreferences? _prefs;

  @override
  Future<MultiplicationStats> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kKey);
    if (raw == null || raw.isEmpty) return MultiplicationStats.empty;
    try {
      return MultiplicationStats.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return MultiplicationStats.empty;
    }
  }

  Future<void> recordRound({
    required int table,
    required int correct,
    required int total,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    final cur = state.value ?? MultiplicationStats.empty;
    final next = cur.withRound(table, correct, total);
    state = AsyncData(next);
    await _prefs!.setString(_kKey, jsonEncode(next.toJson()));
  }

  Future<void> reset() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_kKey);
    state = const AsyncData(MultiplicationStats.empty);
  }
}
