import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'package:aziz_academy/core/services/audio_service.dart';

/// Cloud Neural TTS via the `/api/speak` Vercel serverless proxy
/// (Azure Cognitive Services under the hood). Quality is dramatically
/// better than the browser Web Speech API — Zariyah / Hamed for Arabic,
/// Jenny / Guy for English. Only takes effect if Azure keys are configured
/// on the Vercel project; otherwise the proxy returns 501 and the caller
/// transparently falls back to browser TTS.
///
/// We pipe the MP3 through `audioplayers` since that's already the path
/// used for Quran reciter audio — same lifecycle and ducking behaviour.
class CloudTtsService {
  CloudTtsService({required AudioService audioService})
    : _audioService = audioService;

  final AudioPlayer _player = AudioPlayer();
  final AudioService _audioService;
  bool _isMuted = false;
  bool _isPlaying = false;
  Completer<void>? _stopRequested;

  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      _player.stop();
      _isPlaying = false;
    }
  }

  /// Build the same-origin URL the proxy expects. Same query string ⇒
  /// same edge-cache key, so popular phrases (daily verse, common dua)
  /// only hit Azure once per cache lifetime per POP.
  static String urlFor({
    required String text,
    required bool arabic,
    bool male = false,
  }) {
    final params = <String, String>{
      'text': text,
      'lang': arabic ? 'ar' : 'en',
      if (male) 'gender': 'male',
    };
    final q = params.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    return '/api/speak?$q';
  }

  /// Play the given text via the cloud proxy. Throws on any failure
  /// (proxy 501 because Azure is unconfigured, network down, CORS, etc).
  /// Callers should catch and fall back to browser TTS.
  Future<void> speak(
    String text, {
    required bool arabic,
    bool male = false,
  }) async {
    if (_isMuted || text.isEmpty) return;
    if (text.length > 2000) {
      throw ArgumentError('text too long for cloud TTS (max 2000 chars)');
    }

    if (_stopRequested != null && !_stopRequested!.isCompleted) {
      _stopRequested!.complete();
    }
    if (_isPlaying) {
      await _player.stop();
    }
    _isPlaying = true;
    _audioService.duckBgm();
    _stopRequested = Completer<void>();

    final url = urlFor(text: text, arabic: arabic, male: male);
    final naturalEnd = _player.onPlayerComplete.first;
    final timeout = Future<void>.delayed(const Duration(seconds: 60));

    try {
      await _player.play(UrlSource(url));
      await Future.any<void>([
        naturalEnd,
        _stopRequested!.future,
        timeout,
      ]);
    } catch (e) {
      debugPrint('Cloud TTS error: $e');
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
