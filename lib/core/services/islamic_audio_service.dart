import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/services/islamic_audio_registry.dart';

/// Plays bundled MP3 recordings for the Islamic content suite — Hadith,
/// Azkar, 99 Names of Allah, Du'a, Tajweed. Mirrors the
/// [QuranRecitationService] pattern but reads from local assets instead of
/// a CDN, so playback works offline.
///
/// The recordings policy (v1.1.96+): the kid should only ever hear real
/// human recitation. Synthetic TTS is off by default. This service exposes
/// a single `play(category, id)` entry point that the [RealAudioButton]
/// widget calls. If the asset is missing it throws — the caller decides
/// whether to fall back to TTS or hide the button entirely.
final islamicAudioServiceProvider = Provider<IslamicAudioService>((ref) {
  final audio = ref.read(audioServiceProvider);
  final svc = IslamicAudioService(audioService: audio);
  ref.onDispose(svc.dispose);

  void apply(AppSettings? s) {
    final on = (s?.soundEnabled ?? true);
    svc.setMuted(!on);
  }

  apply(ref.read(appSettingsProvider).value);
  ref.listen<AsyncValue<AppSettings>>(
    appSettingsProvider,
    (_, next) => apply(next.value),
  );
  return svc;
});

class IslamicAudioService {
  IslamicAudioService({required AudioService audioService})
    : _audioService = audioService;

  final AudioPlayer _player = AudioPlayer();
  final AudioService _audioService;
  bool _isMuted = false;
  bool _isPlaying = false;
  Completer<void>? _stopRequested;

  bool get isPlaying => _isPlaying;

  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      _player.stop();
      _isPlaying = false;
    }
  }

  /// Returns true when the build is known to ship a recording for this
  /// (category, id) pair. Cheap — pure registry lookup.
  bool hasRecording(String category, String id) =>
      islamicAudioAsset(category, id) != null;

  /// Play a bundled MP3. Throws if the registry has no recording for this
  /// (category, id) pair, or if playback fails — callers fall back to TTS.
  /// Resolves when playback ends or `stop()` is called.
  Future<void> play({required String category, required String id}) async {
    if (_isMuted) return;
    final asset = islamicAudioAsset(category, id);
    if (asset == null) {
      throw StateError('No Islamic audio registered for $category/$id');
    }

    // Cancel any in-flight play. Mirrors QuranRecitationService.playVerse
    // to avoid leaking ducked-BGM state when the user taps two buttons in
    // rapid succession.
    if (_stopRequested != null && !_stopRequested!.isCompleted) {
      _stopRequested!.complete();
    }
    if (_isPlaying) {
      await _player.stop();
    }
    _isPlaying = true;
    _audioService.duckBgm();
    _stopRequested = Completer<void>();

    final naturalEnd = _player.onPlayerComplete.first;
    final timeout = Future<void>.delayed(const Duration(seconds: 60));
    try {
      await _player.play(AssetSource(asset));
      await Future.any<void>([
        naturalEnd,
        _stopRequested!.future,
        timeout,
      ]);
    } catch (e) {
      debugPrint('Islamic audio play error ($category/$id): $e');
      rethrow;
    } finally {
      _isPlaying = false;
      _stopRequested = null;
      _audioService.unduckBgm();
    }
  }

  Future<void> stop() async {
    if (_stopRequested != null && !_stopRequested!.isCompleted) {
      _stopRequested!.complete();
    }
    await _player.stop();
    _isPlaying = false;
    _audioService.unduckBgm();
  }

  void dispose() {
    _player.dispose();
  }
}
