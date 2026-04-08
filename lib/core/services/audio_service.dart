import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioServiceProvider = Provider((ref) => AudioService());

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
