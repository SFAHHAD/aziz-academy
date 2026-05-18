import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aziz_academy/core/models/recap_module.dart';

// =============================================================================
// Model
// =============================================================================

class RecapEntry {
  const RecapEntry({
    required this.module,
    required this.questionId,
    this.snapshotJson,
    this.missCount = 1,
    this.lastMissed,
  });

  final RecapModule module;
  final String questionId;

  /// Full [QuizQuestion.toJson] for [RecapModule.math] only (stable recap).
  final String? snapshotJson;

  /// How many times this question has been answered incorrectly in total.
  final int missCount;

  /// ISO-8601 date (yyyy-MM-dd) of the most recent wrong answer.
  final String? lastMissed;

  String get _dedupeKey => '${module.name}:$questionId';

  /// Spaced-repetition interval: days to wait before this item is due again.
  /// missCount=1 → 0 days (always due), 2 → 1 day, 3 → 2 days, 4 → 4 days …
  int get intervalDays {
    if (missCount <= 1) return 0;
    return (1 << (missCount - 2)).clamp(1, 30);
  }

  /// True when this item is scheduled for review today.
  bool get isDueForReview {
    if (lastMissed == null) return true;
    final last = DateTime.tryParse(lastMissed!);
    if (last == null) return true;
    return DateTime.now().isAfter(last.add(Duration(days: intervalDays)));
  }

  Map<String, dynamic> toJson() => {
        'm': module.name,
        'id': questionId,
        if (snapshotJson != null) 'snap': snapshotJson,
        'mc': missCount,
        if (lastMissed != null) 'lm': lastMissed,
      };

  static RecapEntry? tryParse(Map<String, dynamic> j) {
    final name = j['m'] as String?;
    final module = switch (name) {
      'capitals' => RecapModule.capitals,
      'flags' => RecapModule.flags,
      'maps' => RecapModule.maps,
      'sciences' => RecapModule.sciences,
      'math' => RecapModule.math,
      _ => null,
    };
    if (module == null) return null;
    final id = j['id'] as String?;
    if (id == null) return null;
    final snap = j['snap'] as String?;
    if (module == RecapModule.math && (snap == null || snap.isEmpty)) {
      return null;
    }
    final mc = ((j['mc'] as int?) ?? 1).clamp(1, 99);
    final lm = j['lm'] as String?;
    return RecapEntry(
      module: module,
      questionId: id,
      snapshotJson: snap,
      missCount: mc,
      lastMissed: lm,
    );
  }

  RecapEntry copyWith({int? missCount, String? lastMissed}) => RecapEntry(
        module: module,
        questionId: questionId,
        snapshotJson: snapshotJson,
        missCount: missCount ?? this.missCount,
        lastMissed: lastMissed ?? this.lastMissed,
      );
}

final recapQueueProvider =
    AsyncNotifierProvider<RecapQueueNotifier, List<RecapEntry>>(
  RecapQueueNotifier.new,
);

class RecapQueueNotifier extends AsyncNotifier<List<RecapEntry>> {
  static const _k = 'recap_queue_v2';
  static const _kLegacyV1 = 'recap_queue_v1';
  static const _kLegacy = 'recap_queue';

  @override
  Future<List<RecapEntry>> build() async {
    final p = await SharedPreferences.getInstance();
    var list = _decode(p.getString(_k));
    if (list.isEmpty) {
      final legacyRaw =
          p.getString(_kLegacyV1) ?? p.getString(_kLegacy);
      if (legacyRaw != null && legacyRaw.isNotEmpty) {
        list = _decode(legacyRaw);
        if (list.isNotEmpty) {
          await p.setString(
            _k,
            jsonEncode(list.map((e) => e.toJson()).toList()),
          );
        }
        await p.remove(_kLegacyV1);
        await p.remove(_kLegacy);
      }
    }
    return list;
  }

  /// Replaces the entire queue from an imported backup (validated JSON list).
  Future<void> replaceQueueFromBackup(List<dynamic> raw) async {
    final next = raw
        .map((e) => RecapEntry.tryParse(Map<String, dynamic>.from(e as Map)))
        .whereType<RecapEntry>()
        .toList();
    if (next.length > 50) {
      await _save(next.sublist(next.length - 50));
    } else {
      await _save(next);
    }
  }

  List<RecapEntry> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => RecapEntry.tryParse(Map<String, dynamic>.from(e as Map)))
          .whereType<RecapEntry>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<RecapEntry> entries) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _k,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
    state = AsyncData(entries);
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Records a wrong answer. If the entry already exists, increments its
  /// [missCount] (raising SRS priority). [snapshotJson] required for math.
  Future<void> recordWrong(
    RecapModule module,
    String questionId, {
    String? snapshotJson,
  }) async {
    if (module == RecapModule.math &&
        (snapshotJson == null || snapshotJson.isEmpty)) {
      return;
    }
    final cur = List<RecapEntry>.from(await future);
    final today = _todayStr();
    final key = '${module.name}:$questionId';
    final existingIdx = cur.indexWhere((e) => e._dedupeKey == key);
    if (existingIdx >= 0) {
      // Increment priority — this question needs more attention.
      cur[existingIdx] = cur[existingIdx].copyWith(
        missCount: cur[existingIdx].missCount + 1,
        lastMissed: today,
      );
      await _save(cur);
      return;
    }
    var next = [
      ...cur,
      RecapEntry(
        module: module,
        questionId: questionId,
        snapshotJson: snapshotJson,
        missCount: 1,
        lastMissed: today,
      ),
    ];
    if (next.length > 50) next = next.sublist(next.length - 50);
    await _save(next);
  }

  /// Called from Review Mode when the learner answers correctly.
  /// Decrements [missCount]; removes the entry once it reaches zero (mastered).
  Future<void> markCorrect(RecapModule module, String questionId) async {
    final cur = List<RecapEntry>.from(await future);
    final key = '${module.name}:$questionId';
    final idx = cur.indexWhere((e) => e._dedupeKey == key);
    if (idx < 0) return;
    final entry = cur[idx];
    if (entry.missCount <= 1) {
      cur.removeAt(idx);
    } else {
      cur[idx] = entry.copyWith(
        missCount: entry.missCount - 1,
        lastMissed: _todayStr(),
      );
    }
    await _save(cur);
  }

  Future<void> removeEntries(List<RecapEntry> remove) async {
    if (remove.isEmpty) return;
    final drop = remove.map((e) => e._dedupeKey).toSet();
    final cur = await future;
    final next = cur.where((e) => !drop.contains(e._dedupeKey)).toList();
    await _save(next);
  }

  RecapModule? get firstModuleWithPending {
    final q = state.value ?? [];
    for (final m in RecapModule.values) {
      if (q.any((e) => e.module == m)) return m;
    }
    return null;
  }

  /// All queued entries for the first module that has pending items (order preserved).
  List<RecapEntry> entriesForFirstModule() {
    final mod = firstModuleWithPending;
    if (mod == null) return [];
    return (state.value ?? []).where((e) => e.module == mod).toList();
  }
}

// =============================================================================
// Derived providers
// =============================================================================

/// Per-module count of questions in the review queue.
final moduleReviewCountProvider = Provider<Map<RecapModule, int>>((ref) {
  final entries = ref.watch(recapQueueProvider).value ?? [];
  final counts = <RecapModule, int>{};
  for (final e in entries) {
    counts[e.module] = (counts[e.module] ?? 0) + 1;
  }
  return counts;
});

/// Number of questions missed ≥2 times — truly struggling.
final strugglingCountProvider = Provider<int>((ref) {
  final entries = ref.watch(recapQueueProvider).value ?? [];
  return entries.where((e) => e.missCount >= 2).length;
});
