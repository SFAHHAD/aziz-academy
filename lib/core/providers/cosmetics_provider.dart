import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CosmeticsState {
  const CosmeticsState({
    this.owned = const <String>{},
    this.equippedFrame = 'frame_basic',
    this.equippedAvatar = 'av_owl',
  });

  final Set<String> owned;
  final String equippedFrame;
  final String equippedAvatar;

  CosmeticsState copyWith({
    Set<String>? owned,
    String? equippedFrame,
    String? equippedAvatar,
  }) => CosmeticsState(
    owned: owned ?? this.owned,
    equippedFrame: equippedFrame ?? this.equippedFrame,
    equippedAvatar: equippedAvatar ?? this.equippedAvatar,
  );
}

const _kKey = 'cosmetics_v1';

final cosmeticsProvider =
    AsyncNotifierProvider<CosmeticsNotifier, CosmeticsState>(
      CosmeticsNotifier.new,
      name: 'cosmeticsProvider',
    );

class CosmeticsNotifier extends AsyncNotifier<CosmeticsState> {
  SharedPreferences? _prefs;

  @override
  Future<CosmeticsState> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_kKey);
    if (raw == null) {
      return const CosmeticsState(owned: {'frame_basic', 'av_owl'});
    }
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return CosmeticsState(
        owned: ((m['o'] as List?) ?? const []).cast<String>().toSet(),
        equippedFrame: m['f'] as String? ?? 'frame_basic',
        equippedAvatar: m['a'] as String? ?? 'av_owl',
      );
    } catch (_) {
      return const CosmeticsState(owned: {'frame_basic', 'av_owl'});
    }
  }

  Future<void> _persist(CosmeticsState s) async {
    _prefs ??= await SharedPreferences.getInstance();
    state = AsyncData(s);
    await _prefs!.setString(
      _kKey,
      jsonEncode({
        'o': s.owned.toList(),
        'f': s.equippedFrame,
        'a': s.equippedAvatar,
      }),
    );
  }

  Future<void> grant(String id) async {
    final cur = state.value ?? const CosmeticsState();
    if (cur.owned.contains(id)) return;
    final next = Set<String>.from(cur.owned)..add(id);
    await _persist(cur.copyWith(owned: next));
  }

  Future<void> equipFrame(String id) async {
    final cur = state.value ?? const CosmeticsState();
    if (!cur.owned.contains(id)) return;
    await _persist(cur.copyWith(equippedFrame: id));
  }

  Future<void> equipAvatar(String id) async {
    final cur = state.value ?? const CosmeticsState();
    if (!cur.owned.contains(id)) return;
    await _persist(cur.copyWith(equippedAvatar: id));
  }

  Future<void> reset() async {
    await _persist(const CosmeticsState(owned: {'frame_basic', 'av_owl'}));
  }
}
