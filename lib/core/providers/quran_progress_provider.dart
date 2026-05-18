import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Set of surah IDs (e.g. "surah_al_ikhlas") the kid has marked as
/// memorized. Persists to SharedPreferences so progress survives reloads.
/// Surfaces a star indicator on the Quran-screen chip + a "X / N memorized"
/// counter so the kid can see their progress at a glance.
final quranProgressProvider =
    AsyncNotifierProvider<QuranProgressNotifier, Set<String>>(
  QuranProgressNotifier.new,
  name: 'quranProgressProvider',
);

const _kKey = 'quran_memorized_surahs_v1';

class QuranProgressNotifier extends AsyncNotifier<Set<String>> {
  SharedPreferences? _prefs;

  @override
  Future<Set<String>> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _decode();
  }

  Set<String> _decode() {
    final raw = _prefs!.getString(_kKey);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      return (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _persist(Set<String> ids) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_kKey, jsonEncode(ids.toList()));
  }

  bool isMemorized(String surahId) {
    final s = state.value;
    return s != null && s.contains(surahId);
  }

  Future<void> toggle(String surahId) async {
    final cur = state.value ?? <String>{};
    final next = Set<String>.from(cur);
    if (!next.add(surahId)) next.remove(surahId);
    state = AsyncData(next);
    await _persist(next);
  }
}
