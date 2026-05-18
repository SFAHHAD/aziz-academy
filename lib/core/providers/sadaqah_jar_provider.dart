import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Visual sadaqah (charity) jar — purely gamified habit tracker. Kids can
/// "drop" coins into a virtual jar to mirror a real-life sadaqah box. The
/// number is a learner-set goal and a contributed running total; it never
/// touches the actual coin balance and never sends money. Pure on-device
/// state for the family/parent to celebrate giving habits offline.
class SadaqahJarState {
  const SadaqahJarState({this.dropped = 0, this.goal = 100, this.lastYmd});
  final int dropped;
  final int goal;
  final String? lastYmd;

  double get progress => goal == 0 ? 0 : (dropped / goal).clamp(0.0, 1.0);
  bool get goalMet => dropped >= goal && goal > 0;

  SadaqahJarState copyWith({int? dropped, int? goal, String? lastYmd}) =>
      SadaqahJarState(
        dropped: dropped ?? this.dropped,
        goal: goal ?? this.goal,
        lastYmd: lastYmd ?? this.lastYmd,
      );
}

const _kKey = 'sadaqah_jar_v1';

final sadaqahJarProvider =
    AsyncNotifierProvider<SadaqahJarNotifier, SadaqahJarState>(
      SadaqahJarNotifier.new,
      name: 'sadaqahJarProvider',
    );

class SadaqahJarNotifier extends AsyncNotifier<SadaqahJarState> {
  SharedPreferences? _prefs;

  @override
  Future<SadaqahJarState> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kKey);
    if (raw == null) return const SadaqahJarState();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return SadaqahJarState(
        dropped: (m['d'] as num?)?.toInt() ?? 0,
        goal: (m['g'] as num?)?.toInt() ?? 100,
        lastYmd: m['l'] as String?,
      );
    } catch (_) {
      return const SadaqahJarState();
    }
  }

  Future<void> _persist(SadaqahJarState s) async {
    _prefs ??= await SharedPreferences.getInstance();
    state = AsyncData(s);
    await _prefs!.setString(
      _kKey,
      jsonEncode({'d': s.dropped, 'g': s.goal, 'l': s.lastYmd}),
    );
  }

  Future<void> drop(int amount) async {
    if (amount <= 0) return;
    final cur = state.value ?? const SadaqahJarState();
    final ymd =
        '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
    await _persist(cur.copyWith(dropped: cur.dropped + amount, lastYmd: ymd));
  }

  Future<void> setGoal(int goal) async {
    if (goal < 1) return;
    final cur = state.value ?? const SadaqahJarState();
    await _persist(cur.copyWith(goal: goal));
  }

  Future<void> empty() async {
    final cur = state.value ?? const SadaqahJarState();
    await _persist(cur.copyWith(dropped: 0));
  }
}
