import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gender of the kid profile. Stored as a short string so the JSON stays
/// stable and migrations are trivial. `''` means unspecified — the app
/// then uses gender-neutral Arabic forms (see `gendered_ar.dart`).
abstract final class Gender {
  static const boy = 'boy';
  static const girl = 'girl';
  static const unset = '';

  /// Normalises any stored/legacy value to one of the three canonical
  /// strings. Unknown input degrades to [unset].
  static String normalize(String? raw) {
    switch (raw) {
      case boy:
        return boy;
      case girl:
        return girl;
      default:
        return unset;
    }
  }
}

class ProfileState {
  const ProfileState({
    this.displayName = '',
    this.ageBand = '8-10',
    this.gender = Gender.unset,
  });

  final String displayName;
  final String ageBand; // '6-8' | '8-10' | '10-12'
  final String gender; // Gender.boy | Gender.girl | Gender.unset

  ProfileState copyWith({
    String? displayName,
    String? ageBand,
    String? gender,
  }) => ProfileState(
    displayName: displayName ?? this.displayName,
    ageBand: ageBand ?? this.ageBand,
    gender: gender ?? this.gender,
  );
}

const _kKey = 'profile_v1';

final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
  name: 'profileProvider',
);

class ProfileNotifier extends AsyncNotifier<ProfileState> {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _prefsInstance() async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<ProfileState> build() async {
    final prefs = await _prefsInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return const ProfileState();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return ProfileState(
        displayName: (m['n'] as String?) ?? '',
        ageBand: (m['a'] as String?) ?? '8-10',
        gender: Gender.normalize(m['g'] as String?),
      );
    } catch (_) {
      return const ProfileState();
    }
  }

  Future<void> _persist(ProfileState s) async {
    state = AsyncData(s);
    final prefs = await _prefsInstance();
    await prefs.setString(
      _kKey,
      jsonEncode({'n': s.displayName, 'a': s.ageBand, 'g': s.gender}),
    );
  }

  Future<void> setDisplayName(String name) async {
    final cur = state.value ?? const ProfileState();
    await _persist(cur.copyWith(displayName: name.trim()));
  }

  Future<void> setAgeBand(String band) async {
    final cur = state.value ?? const ProfileState();
    await _persist(cur.copyWith(ageBand: band));
  }

  Future<void> setGender(String gender) async {
    final cur = state.value ?? const ProfileState();
    await _persist(cur.copyWith(gender: Gender.normalize(gender)));
  }
}
