import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/app_settings_provider.dart';

/// Regression tests for the v1.1.96 "real audio only" migration:
/// existing installs that had ttsEnabled=true must get flipped to
/// false exactly once on next load; new installs must default to
/// false; the parent's later re-enable must persist.

void main() {
  group('AppSettings default', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('new install — ttsEnabled defaults to false', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final s = await c.read(appSettingsProvider.future);
      expect(s.ttsEnabled, isFalse);
    });

    test('constant AppSettings() has ttsEnabled=false', () {
      const s = AppSettings();
      expect(s.ttsEnabled, isFalse);
    });
  });

  group('real-audio-only migration', () {
    test('existing install with tts=true is flipped to false', () async {
      // Simulate an install from before v1.1.96 — ttsEnabled saved as
      // true, migration flag absent.
      SharedPreferences.setMockInitialValues({
        'app_settings_v1': jsonEncode({
          'sound': true,
          'vol': 0.8,
          'tts': true, // legacy: AI voices were on
          'rec': 'Alafasy_128kbps',
          'cv': false,
          'rm': false,
          'co': false,
          'pr': false,
          'ob': true,
          'dys': false,
          'lt': false,
          'sr': false,
          'lm': false,
          'aq': false,
          'adp': true,
        }),
        // Crucially: NO migration flag, so the upgrade kicks in.
      });

      final c = ProviderContainer();
      addTearDown(c.dispose);
      final s = await c.read(appSettingsProvider.future);
      expect(s.ttsEnabled, isFalse,
          reason: 'legacy tts=true must be migrated to false');
    });

    test('migration persists — second read still false', () async {
      SharedPreferences.setMockInitialValues({
        'app_settings_v1': jsonEncode({'tts': true}),
      });

      final c1 = ProviderContainer();
      await c1.read(appSettingsProvider.future);
      c1.dispose();

      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      final s = await c2.read(appSettingsProvider.future);
      expect(s.ttsEnabled, isFalse);
    });

    test('parent re-enable after migration is respected', () async {
      SharedPreferences.setMockInitialValues({
        'app_settings_v1': jsonEncode({'tts': true}),
      });

      final c1 = ProviderContainer();
      await c1.read(appSettingsProvider.future);
      // Migration just flipped it to false. Parent re-enables.
      await c1.read(appSettingsProvider.notifier).setTtsEnabled(true);
      c1.dispose();

      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      final s = await c2.read(appSettingsProvider.future);
      expect(s.ttsEnabled, isTrue,
          reason: 'after the one-time migration, parent toggle wins');
    });

    test('migration only runs once — flag prevents replay', () async {
      // Pre-set both: the migration flag is true (already migrated),
      // AND the user has explicitly re-enabled tts=true.
      // The build() must respect their choice.
      SharedPreferences.setMockInitialValues({
        'app_settings_v1': jsonEncode({'tts': true}),
        'real_audio_only_migrated_v1': true,
      });

      final c = ProviderContainer();
      addTearDown(c.dispose);
      final s = await c.read(appSettingsProvider.future);
      expect(s.ttsEnabled, isTrue,
          reason: 'with flag set, no migration — user choice wins');
    });
  });
}
