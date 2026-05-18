import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// Admin overrides + feature flags
//
// Two related stores, both local to the device:
//
//   - **Overrides**: per-question patches. Translation workbench + Q Bank
//     editor write to this. Keyed by `pool/id`, value is a JSON object of the
//     fields to replace at runtime. Exportable as a single JSON blob you can
//     paste into the source pool when you're ready to ship the change.
//
//   - **Feature flags**: simple bool toggles by activity id. The home screen
//     can hide a module instantly without a redeploy if anything breaks.
//
// Persisted in SharedPreferences. Defaults to "no overrides, all flags on".
// =============================================================================

const _kOverridesKey = 'admin_question_overrides_v1';
const _kFlagsKey = 'admin_feature_flags_v1';

class QuestionOverride {
  const QuestionOverride({
    required this.poolId,
    required this.questionId,
    required this.patch,
    required this.updatedAt,
  });

  factory QuestionOverride.fromJson(Map<String, dynamic> m) => QuestionOverride(
    poolId: m['pool'] as String,
    questionId: m['id'] as String,
    patch: Map<String, dynamic>.from(m['patch'] as Map),
    updatedAt: DateTime.parse(m['at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'pool': poolId,
    'id': questionId,
    'patch': patch,
    'at': updatedAt.toIso8601String(),
  };

  final String poolId;
  final String questionId;
  final Map<String, dynamic> patch;
  final DateTime updatedAt;

  String get compoundKey => '$poolId/$questionId';
}

class AdminOverrideStore {
  AdminOverrideStore(this._prefs);
  final SharedPreferences _prefs;

  Map<String, QuestionOverride> read() {
    final raw = _prefs.getString(_kOverridesKey);
    if (raw == null) return <String, QuestionOverride>{};
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return {
        for (final m in list)
          QuestionOverride.fromJson(m).compoundKey: QuestionOverride.fromJson(
            m,
          ),
      };
    } catch (_) {
      return <String, QuestionOverride>{};
    }
  }

  Future<void> _write(Map<String, QuestionOverride> map) async {
    final list = map.values.map((e) => e.toJson()).toList();
    await _prefs.setString(_kOverridesKey, jsonEncode(list));
  }

  Future<void> upsert(QuestionOverride entry) async {
    final map = read();
    map[entry.compoundKey] = entry;
    await _write(map);
  }

  Future<void> delete(String poolId, String questionId) async {
    final map = read();
    map.remove('$poolId/$questionId');
    await _write(map);
  }

  Future<void> clear() async {
    await _prefs.remove(_kOverridesKey);
  }

  String exportJson() {
    final list = read().values.map((e) => e.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }
}

/// Feature flags — `true` means visible/enabled, `false` means hidden.
/// Activity ids match those in `activity_catalog.dart`.
class AdminFlagStore {
  AdminFlagStore(this._prefs);
  final SharedPreferences _prefs;

  Map<String, bool> read() {
    final raw = _prefs.getString(_kFlagsKey);
    if (raw == null) return <String, bool>{};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as bool),
      );
    } catch (_) {
      return <String, bool>{};
    }
  }

  Future<void> set(String activityId, bool enabled) async {
    final map = read();
    if (enabled) {
      map.remove(activityId);
    } else {
      map[activityId] = false;
    }
    await _prefs.setString(_kFlagsKey, jsonEncode(map));
  }

  Future<void> clear() async {
    await _prefs.remove(_kFlagsKey);
  }
}

// =============================================================================
// Riverpod glue
// =============================================================================

final overrideStoreProvider = FutureProvider<AdminOverrideStore>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return AdminOverrideStore(prefs);
});

final flagStoreProvider = FutureProvider<AdminFlagStore>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return AdminFlagStore(prefs);
});

class OverrideMapNotifier extends AsyncNotifier<Map<String, QuestionOverride>> {
  AdminOverrideStore? _store;

  @override
  Future<Map<String, QuestionOverride>> build() async {
    _store = await ref.watch(overrideStoreProvider.future);
    return _store!.read();
  }

  Future<void> upsert(QuestionOverride entry) async {
    _store ??= await ref.read(overrideStoreProvider.future);
    await _store!.upsert(entry);
    state = AsyncData(_store!.read());
  }

  Future<void> remove(String poolId, String questionId) async {
    _store ??= await ref.read(overrideStoreProvider.future);
    await _store!.delete(poolId, questionId);
    state = AsyncData(_store!.read());
  }

  Future<void> clearAll() async {
    _store ??= await ref.read(overrideStoreProvider.future);
    await _store!.clear();
    state = AsyncData(_store!.read());
  }

  String exportJson() => _store?.exportJson() ?? '{}';
}

final overrideMapProvider =
    AsyncNotifierProvider<OverrideMapNotifier, Map<String, QuestionOverride>>(
      OverrideMapNotifier.new,
    );

class FlagMapNotifier extends AsyncNotifier<Map<String, bool>> {
  AdminFlagStore? _store;

  @override
  Future<Map<String, bool>> build() async {
    _store = await ref.watch(flagStoreProvider.future);
    return _store!.read();
  }

  Future<void> set(String activityId, bool enabled) async {
    _store ??= await ref.read(flagStoreProvider.future);
    await _store!.set(activityId, enabled);
    state = AsyncData(_store!.read());
  }

  Future<void> clearAll() async {
    _store ??= await ref.read(flagStoreProvider.future);
    await _store!.clear();
    state = AsyncData(_store!.read());
  }
}

final flagMapProvider =
    AsyncNotifierProvider<FlagMapNotifier, Map<String, bool>>(
      FlagMapNotifier.new,
    );
