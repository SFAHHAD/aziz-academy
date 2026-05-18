import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tasbih digital counter — tracks the current dhikr count for the active
/// phrase and a small history of all-time taps. State is pure on-device.
class TasbihState {
  const TasbihState({
    this.count = 0,
    this.target = 33,
    this.phrase = 'subhanallah',
    this.totalLifetime = 0,
  });
  final int count;
  final int target;
  final String phrase;
  final int totalLifetime;

  TasbihState copyWith({
    int? count,
    int? target,
    String? phrase,
    int? totalLifetime,
  }) => TasbihState(
    count: count ?? this.count,
    target: target ?? this.target,
    phrase: phrase ?? this.phrase,
    totalLifetime: totalLifetime ?? this.totalLifetime,
  );
}

const _kKey = 'tasbih_v1';

final tasbihProvider = AsyncNotifierProvider<TasbihNotifier, TasbihState>(
  TasbihNotifier.new,
);

class TasbihNotifier extends AsyncNotifier<TasbihState> {
  SharedPreferences? _prefs;

  @override
  Future<TasbihState> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kKey);
    if (raw == null) return const TasbihState();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return TasbihState(
        count: (m['c'] as num?)?.toInt() ?? 0,
        target: (m['t'] as num?)?.toInt() ?? 33,
        phrase: (m['p'] as String?) ?? 'subhanallah',
        totalLifetime: (m['tl'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return const TasbihState();
    }
  }

  Future<void> _persist(TasbihState s) async {
    _prefs ??= await SharedPreferences.getInstance();
    state = AsyncData(s);
    await _prefs!.setString(
      _kKey,
      jsonEncode({
        'c': s.count,
        't': s.target,
        'p': s.phrase,
        'tl': s.totalLifetime,
      }),
    );
  }

  Future<void> tap() async {
    final cur = state.value ?? const TasbihState();
    await _persist(
      cur.copyWith(count: cur.count + 1, totalLifetime: cur.totalLifetime + 1),
    );
  }

  Future<void> reset() async {
    final cur = state.value ?? const TasbihState();
    await _persist(cur.copyWith(count: 0));
  }

  Future<void> setTarget(int target) async {
    if (target < 1) return;
    final cur = state.value ?? const TasbihState();
    await _persist(cur.copyWith(target: target));
  }

  Future<void> setPhrase(String phrase) async {
    final cur = state.value ?? const TasbihState();
    await _persist(cur.copyWith(phrase: phrase, count: 0));
  }
}
