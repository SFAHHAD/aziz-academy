import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  // Release native AudioPlayer channels when the provider scope is destroyed.
  ref.onDispose(service.dispose);
  return service;
});

class AudioService {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _isMuted = false;

  AudioService() {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _bgmPlayer.setVolume(0.3); // Lower volume for background music
    _sfxPlayer.setVolume(0.8);
  }

  void updateMuteStatus(bool isMuted) {
    _isMuted = isMuted;
    if (_isMuted) {
      _bgmPlayer.pause();
    } else {
      _bgmPlayer.resume();
    }
  }

  Future<void> startBgm() async {
    // Disabled BGM to prevent autoplay block exceptions
  }

  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
  }

  /// Lowers BGM volume during TTS speech so voices are clearly audible.
  void duckBgm() => _bgmPlayer.setVolume(0.08);

  /// Restores BGM to its normal background level after TTS finishes.
  void unduckBgm() => _bgmPlayer.setVolume(0.3);

  Future<void> playCorrectSound() async {
    // Relying on Visual feedback + TTS only (No CORS blocking)
  }

  Future<void> playWrongSound() async {
    // Relying on Visual feedback + TTS only
  }

  Future<void> playVictorySound() async {
    // Relying on Visual feedback + TTS only
  }

  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
