import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aziz_academy/core/models/recap_module.dart';

class RecapEntry {
  const RecapEntry({
    required this.module,
    required this.questionId,
    this.snapshotJson,
  });

  final RecapModule module;
  final String questionId;

  /// Full [QuizQuestion.toJson] for [RecapModule.math] only (stable recap).
  final String? snapshotJson;

  String get _dedupeKey => '${module.name}:$questionId';

  Map<String, dynamic> toJson() => {
        'm': module.name,
        'id': questionId,
        if (snapshotJson != null) 'snap': snapshotJson,
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
    return RecapEntry(module: module, questionId: id, snapshotJson: snap);
  }
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
    if (next.length > 28) {
      await _save(next.sublist(next.length - 28));
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

  /// Remember a wrong answer. [snapshotJson] required for math (full question JSON).
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
    if (cur.any((e) => e._dedupeKey == '${module.name}:$questionId')) {
      return;
    }
    var next = [
      ...cur,
      RecapEntry(
        module: module,
        questionId: questionId,
        snapshotJson: snapshotJson,
      ),
    ];
    if (next.length > 28) {
      next = next.sublist(next.length - 28);
    }
    await _save(next);
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
