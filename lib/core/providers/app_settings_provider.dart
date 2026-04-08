import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kid / parent toggles persisted on device.
class AppSettings {
  const AppSettings({
    this.soundEnabled = true,
    this.reducedMotion = false,
    this.coPlayMode = false,
    this.practiceMode = false,
  });

  final bool soundEnabled;
  final bool reducedMotion;
  final bool coPlayMode;
  final bool practiceMode;

  AppSettings copyWith({
    bool? soundEnabled,
    bool? reducedMotion,
    bool? coPlayMode,
    bool? practiceMode,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      coPlayMode: coPlayMode ?? this.coPlayMode,
      practiceMode: practiceMode ?? this.practiceMode,
    );
  }
}

class _Keys {
  static const blob = 'app_settings_v1';
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
  name: 'appSettingsProvider',
);

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  late SharedPreferences _prefs;

  @override
  Future<AppSettings> build() async {
    _prefs = await SharedPreferences.getInstance();
    return _decode(_prefs.getString(_Keys.blob));
  }

  AppSettings _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const AppSettings();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettings(
        soundEnabled: m['sound'] as bool? ?? true,
        reducedMotion: m['rm'] as bool? ?? false,
        coPlayMode: m['co'] as bool? ?? false,
        practiceMode: m['pr'] as bool? ?? false,
      );
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> _persist(AppSettings s) async {
    await _prefs.setString(
      _Keys.blob,
      jsonEncode({
        'sound': s.soundEnabled,
        'rm': s.reducedMotion,
        'co': s.coPlayMode,
        'pr': s.practiceMode,
      }),
    );
    state = AsyncData(s);
  }

  Future<void> setSoundEnabled(bool v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(soundEnabled: v));
  }

  Future<void> setReducedMotion(bool v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(reducedMotion: v));
  }

  Future<void> setCoPlayMode(bool v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(coPlayMode: v));
  }

  Future<void> setPracticeMode(bool v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(practiceMode: v));
  }

  Future<void> toggleSound() async {
    final cur = state.value ?? const AppSettings();
    await setSoundEnabled(!cur.soundEnabled);
  }
}

bool readPracticeMode(Ref ref) {
  return ref.read(appSettingsProvider).value?.practiceMode ?? false;
}

bool readCoPlayMode(Ref ref) {
  return ref.read(appSettingsProvider).value?.coPlayMode ?? false;
}
