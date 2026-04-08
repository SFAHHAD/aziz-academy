import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final soundOn = ref.watch(appSettingsProvider).value?.soundEnabled ?? true;
  final service = TtsService();
  service.updateMuteStatus(!soundOn);
  return service;
});

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isMuted = false;

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    // Await configurations to ensure TTS engine is ready
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage("ar"); // broader support than ar-SA on Web
    await _flutterTts.setSpeechRate(0.5); 
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0); 
  }

  void updateMuteStatus(bool isMuted) {
    _isMuted = isMuted;
    if (_isMuted) {
      _flutterTts.stop();
    }
  }

  Future<void> speakArabic(String text) async {
    if (_isMuted || text.isEmpty) return;
    try {
      await _flutterTts.setLanguage("ar");
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speakArabic: $e');
    }
  }

  Future<void> speakEnglish(String text) async {
    if (_isMuted || text.isEmpty) return;
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speakEnglish: $e');
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
