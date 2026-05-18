import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/services/tts_service.dart';

/// Public-CDN Quran recitation. Plays real reciter MP3s from everyayah.com
/// when network is available; otherwise the caller falls back to TTS.
///
/// Why everyayah.com:
///   - Free, no API key, well-known mirror used by many open-source Quran
///     apps (Quran.com, Tarteel, Al-Quran Cloud).
///   - Stable verse-by-verse URL scheme: `/data/<reciter>/SSSAAA.mp3`
///   - Serves multiple reciters; we default to Mishary Alafasy 128kbps.
///
/// Network handling: we let audioplayers report a failure; the calling
/// screen catches the throw and asks the [TtsService] to read the verse
/// instead. The user's "soundEnabled" and "ttsEnabled" toggles still gate
/// playback — reciter audio is treated as another form of "voice speech".
final quranRecitationServiceProvider = Provider<QuranRecitationService>((ref) {
  final audio = ref.read(audioServiceProvider);
  final svc = QuranRecitationService(audioService: audio);
  ref.onDispose(svc.dispose);

  void apply(AppSettings? s) {
    final on = (s?.soundEnabled ?? true) && (s?.ttsEnabled ?? true);
    svc.setMuted(!on);
    svc.setReciter(s?.preferredReciter ?? 'Alafasy_128kbps');
  }

  apply(ref.read(appSettingsProvider).value);
  ref.listen<AsyncValue<AppSettings>>(
    appSettingsProvider,
    (_, next) => apply(next.value),
  );
  return svc;
});

/// EveryAyah reciter codes paired with their display names. Keep this list
/// short and curated — these are the high-quality, widely recognised reciters.
const kReciters = <String, ({String en, String ar})>{
  'Alafasy_128kbps': (en: 'Mishary Alafasy', ar: 'مشاري العفاسي'),
  'Husary_128kbps': (
    en: 'Mahmoud Khalil Al-Husary',
    ar: 'محمود خليل الحصري',
  ),
  'Abdurrahmaan_As-Sudais_192kbps': (
    en: 'Abdurrahmaan As-Sudais',
    ar: 'عبد الرحمن السديس',
  ),
  'Saood_ash-Shuraym_128kbps': (
    en: 'Saud Ash-Shuraim',
    ar: 'سعود الشريم',
  ),
  'Muhammad_Jibreel_128kbps': (
    en: 'Muhammad Jibreel',
    ar: 'محمد جبريل',
  ),
  'Hudhaify_128kbps': (en: 'Ali Al-Hudhaify', ar: 'علي الحذيفي'),
};

class QuranRecitationService {
  QuranRecitationService({required AudioService audioService})
    : _audioService = audioService;

  final AudioPlayer _player = AudioPlayer();
  final AudioService _audioService;
  bool _isMuted = false;
  bool _isPlaying = false;
  String _reciter = 'Alafasy_128kbps';
  // Completer that resolves when stop() is called mid-playback. playVerse
  // races this against the player's natural completion so a Stop tap
  // returns control immediately instead of hanging on the 120s timeout.
  Completer<void>? _stopRequested;

  void setReciter(String reciter) {
    _reciter = reciter;
  }

  void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      _player.stop();
      _isPlaying = false;
    }
  }

  bool get isPlaying => _isPlaying;

  /// Map surah ID (as used in `quran_short_surahs.json`) to the canonical
  /// 1..114 Quran surah number. Add new entries here when new surahs are
  /// bundled into the JSON.
  static const _surahNumByName = <String, int>{
    'surah_al_fatihah': 1,
    'surah_ad_duha': 93,
    'surah_al_inshirah': 94,
    'surah_at_tin': 95,
    'surah_al_qadr': 97,
    'surah_al_fil': 105,
    'surah_al_asr': 103,
    'surah_al_kawthar': 108,
    'surah_al_maun': 107,
    'surah_al_quraish': 106,
    'surah_al_kafirun': 109,
    'surah_al_masad': 111,
    'surah_al_ikhlas': 112,
    'surah_al_falaq': 113,
    'surah_an_nas': 114,
  };

  /// Returns the canonical 1..114 surah number for a known surah id, or
  /// null if the id isn't mapped. Exposed so UI can display the number.
  static int? surahNumberFor(String surahId) => _surahNumByName[surahId];

  /// Returns the recitation URL for a given (surahId, verseNumber), or null
  /// if the surah ID isn't mapped yet. Pure function — no instance state.
  static String? urlFor({
    required String surahId,
    required int verseNumber,
    String reciter = 'Alafasy_128kbps',
  }) {
    final n = _surahNumByName[surahId];
    if (n == null) return null;
    final s = n.toString().padLeft(3, '0');
    final a = verseNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$reciter/$s$a.mp3';
  }

  /// Play a verse from the CDN and resolve when playback ends. Throws on
  /// any error (network, 404, CORS) — the caller should catch and fall
  /// back to TTS. Awaiting completion lets sequential playback (full-surah)
  /// chain verses without a polling loop.
  Future<void> playVerse({
    required String surahId,
    required int verseNumber,
    String? reciter,
  }) async {
    if (_isMuted) return;
    final url = QuranRecitationService.urlFor(
      surahId: surahId,
      verseNumber: verseNumber,
      reciter: reciter ?? _reciter,
    );
    if (url == null) {
      throw StateError('Unknown surah id: $surahId');
    }
    // If a previous playVerse is still awaiting, unblock it before we
    // start a new one. Without this, rapid-tapping two verse buttons
    // leaves the first await hanging on its own stopRequested + the
    // natural-completion stream, leaking ducked BGM state until the 120s
    // timeout fallback.
    if (_stopRequested != null && !_stopRequested!.isCompleted) {
      _stopRequested!.complete();
    }
    if (_isPlaying) {
      await _player.stop();
    }
    _isPlaying = true;
    _audioService.duckBgm();
    _stopRequested = Completer<void>();

    // Race natural completion against an explicit stop request so a Stop
    // tap returns immediately. Also bounded by a 120s timeout in case the
    // player never fires onPlayerComplete (unreachable URL after start, etc).
    final naturalEnd = _player.onPlayerComplete.first;
    final timeout = Future<void>.delayed(const Duration(seconds: 120));
    try {
      await _player.play(UrlSource(url));
      await Future.any<void>([
        naturalEnd,
        _stopRequested!.future,
        timeout,
      ]);
    } catch (e) {
      debugPrint('Quran recitation play error: $e');
      rethrow;
    } finally {
      _isPlaying = false;
      _stopRequested = null;
      _audioService.unduckBgm();
    }
  }

  Future<void> stop() async {
    // Unblock any pending `playVerse` await so the caller's loop can exit
    // immediately. Without this, the await on Future.any can hang on the
    // 120s timeout even after _player.stop() has silenced the audio.
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
