import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kid / parent toggles persisted on device.
///
/// `ttsEnabled` defaults to **false** as of v1.1.96 — the product policy
/// is "real audio only": Quran reciter audio (everyayah CDN) is the only
/// voice the kid hears. Hadith / azkar will get real recitations later;
/// until then the screens just hide the speak buttons. A parent can
/// re-enable AI voices manually in the parent settings.
class AppSettings {
  const AppSettings({
    this.soundEnabled = true,
    this.soundVolume = 0.8,
    this.ttsEnabled = false,
    this.preferredArVoice,
    this.preferredEnVoice,
    this.preferredReciter = 'Alafasy_128kbps',
    this.cloudVoices = false,
    this.reducedMotion = false,
    this.coPlayMode = false,
    this.practiceMode = false,
    this.onboardingCompleted = false,
    this.dyslexiaFont = false,
    this.largerText = false,
    this.shortRounds = false,
    this.lightMode = false,
    this.audioQuiz = false,
    this.adaptiveDifficulty = true,
  });

  final bool soundEnabled;
  final double soundVolume; // 0.0 to 1.0
  final bool ttsEnabled;
  final String? preferredArVoice;
  final String? preferredEnVoice;
  final String preferredReciter;
  final bool cloudVoices;
  final bool reducedMotion;
  final bool coPlayMode;
  final bool practiceMode;
  final bool onboardingCompleted;
  final bool dyslexiaFont;
  final bool largerText;
  final bool shortRounds;
  final bool lightMode;
  final bool audioQuiz;
  final bool adaptiveDifficulty;

  AppSettings copyWith({
    bool? soundEnabled,
    double? soundVolume,
    bool? ttsEnabled,
    Object? preferredArVoice = _unset,
    Object? preferredEnVoice = _unset,
    String? preferredReciter,
    bool? cloudVoices,
    bool? reducedMotion,
    bool? coPlayMode,
    bool? practiceMode,
    bool? onboardingCompleted,
    bool? dyslexiaFont,
    bool? largerText,
    bool? shortRounds,
    bool? lightMode,
    bool? audioQuiz,
    bool? adaptiveDifficulty,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      preferredArVoice: identical(preferredArVoice, _unset)
          ? this.preferredArVoice
          : preferredArVoice as String?,
      preferredEnVoice: identical(preferredEnVoice, _unset)
          ? this.preferredEnVoice
          : preferredEnVoice as String?,
      preferredReciter: preferredReciter ?? this.preferredReciter,
      cloudVoices: cloudVoices ?? this.cloudVoices,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      coPlayMode: coPlayMode ?? this.coPlayMode,
      practiceMode: practiceMode ?? this.practiceMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      dyslexiaFont: dyslexiaFont ?? this.dyslexiaFont,
      largerText: largerText ?? this.largerText,
      shortRounds: shortRounds ?? this.shortRounds,
      lightMode: lightMode ?? this.lightMode,
      audioQuiz: audioQuiz ?? this.audioQuiz,
      adaptiveDifficulty: adaptiveDifficulty ?? this.adaptiveDifficulty,
    );
  }
}

// Sentinel for distinguishing "not passed" from "set to null" in copyWith.
const Object _unset = Object();

class _Keys {
  static const blob = 'app_settings_v1';
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
      AppSettingsNotifier.new,
      name: 'appSettingsProvider',
    );

/// One-time migration flag: when missing, the next build() forces
/// ttsEnabled to false ("real audio only" policy introduced in v1.1.96).
/// Existing installs that had AI voices on get flipped exactly once;
/// any subsequent re-enable by the parent persists normally.
const _kRealAudioMigrationKey = 'real_audio_only_migrated_v1';

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  SharedPreferences? _prefs;

  @override
  Future<AppSettings> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    var settings = _decode(_prefs!.getString(_Keys.blob));
    if (!(_prefs!.getBool(_kRealAudioMigrationKey) ?? false)) {
      // Force AI voices off on first run after the policy change.
      if (settings.ttsEnabled) {
        settings = settings.copyWith(ttsEnabled: false);
        await _persistOnly(settings);
      }
      await _prefs!.setBool(_kRealAudioMigrationKey, true);
    }
    return settings;
  }

  Future<void> _persistOnly(AppSettings s) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _Keys.blob,
      jsonEncode({
        'sound': s.soundEnabled,
        'vol': s.soundVolume,
        'tts': s.ttsEnabled,
        'vAr': s.preferredArVoice,
        'vEn': s.preferredEnVoice,
        'rec': s.preferredReciter,
        'cv': s.cloudVoices,
        'rm': s.reducedMotion,
        'co': s.coPlayMode,
        'pr': s.practiceMode,
        'ob': s.onboardingCompleted,
        'dys': s.dyslexiaFont,
        'lt': s.largerText,
        'sr': s.shortRounds,
        'lm': s.lightMode,
        'aq': s.audioQuiz,
        'adp': s.adaptiveDifficulty,
      }),
    );
  }

  AppSettings _decode(String? raw) {
    if (raw == null || raw.isEmpty) return const AppSettings();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettings(
        soundEnabled: m['sound'] as bool? ?? true,
        soundVolume: (m['vol'] as num?)?.toDouble() ?? 0.8,
        ttsEnabled: m['tts'] as bool? ?? false,
        preferredArVoice: m['vAr'] as String?,
        preferredEnVoice: m['vEn'] as String?,
        preferredReciter: m['rec'] as String? ?? 'Alafasy_128kbps',
        cloudVoices: m['cv'] as bool? ?? false,
        reducedMotion: m['rm'] as bool? ?? false,
        coPlayMode: m['co'] as bool? ?? false,
        practiceMode: m['pr'] as bool? ?? false,
        onboardingCompleted: m['ob'] as bool? ?? false,
        dyslexiaFont: m['dys'] as bool? ?? false,
        largerText: m['lt'] as bool? ?? false,
        shortRounds: m['sr'] as bool? ?? false,
        lightMode: m['lm'] as bool? ?? false,
        audioQuiz: m['aq'] as bool? ?? false,
        adaptiveDifficulty: m['adp'] as bool? ?? true,
      );
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> _persist(AppSettings s) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _Keys.blob,
      jsonEncode({
        'sound': s.soundEnabled,
        'vol': s.soundVolume,
        'tts': s.ttsEnabled,
        'vAr': s.preferredArVoice,
        'vEn': s.preferredEnVoice,
        'rec': s.preferredReciter,
        'cv': s.cloudVoices,
        'rm': s.reducedMotion,
        'co': s.coPlayMode,
        'pr': s.practiceMode,
        'ob': s.onboardingCompleted,
        'dys': s.dyslexiaFont,
        'lt': s.largerText,
        'sr': s.shortRounds,
        'lm': s.lightMode,
        'aq': s.audioQuiz,
        'adp': s.adaptiveDifficulty,
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

  Future<void> markOnboardingCompleted() async {
    final cur = state.value ?? const AppSettings();
    if (cur.onboardingCompleted) return;
    await _persist(cur.copyWith(onboardingCompleted: true));
  }

  Future<void> setDyslexiaFont(bool v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(dyslexiaFont: v));
  }

  Future<void> setLargerText(bool v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(largerText: v));
  }

  Future<void> setShortRounds(bool v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(shortRounds: v));
  }

  Future<void> setLightMode(bool v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(lightMode: v));
  }

  Future<void> setAudioQuiz(bool v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(audioQuiz: v));
  }

  Future<void> setSoundVolume(double v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(soundVolume: v.clamp(0.0, 1.0)));
  }

  Future<void> setAdaptiveDifficulty(bool v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(adaptiveDifficulty: v));
  }

  Future<void> setTtsEnabled(bool v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(ttsEnabled: v));
  }

  /// Pass null to clear the override and fall back to auto-pick.
  Future<void> setPreferredArVoice(String? v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(preferredArVoice: v));
  }

  Future<void> setPreferredEnVoice(String? v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(preferredEnVoice: v));
  }

  Future<void> setPreferredReciter(String v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(preferredReciter: v));
  }

  Future<void> setCloudVoices(bool v) async {
    final cur = state.value ?? const AppSettings();
    await _persist(cur.copyWith(cloudVoices: v));
  }
}

bool readPracticeMode(Ref ref) {
  return ref.read(appSettingsProvider).value?.practiceMode ?? false;
}

bool readCoPlayMode(Ref ref) {
  return ref.read(appSettingsProvider).value?.coPlayMode ?? false;
}
