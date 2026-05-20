import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/services/audio_service.dart';
import 'package:aziz_academy/core/services/cloud_tts_service.dart';

// =============================================================================
// Feedback context types
// =============================================================================

enum TtsFeedbackType {
  correct,
  srsItemCleared,
  wrong,
  reviewComplete,
  dailyChallengeComplete,
  streakAchieved,
  levelUp,
  encouragement,
  welcome,
}

// =============================================================================
// Message pools — Arabic (Cairo tone) & English (warm teacher tone)
// =============================================================================

const _arMessages = <TtsFeedbackType, List<String>>{
  TtsFeedbackType.correct: [
    'ممتاز!',
    'أحسنت!',
    'رائع جداً!',
    'صحيح! أنت نجم!',
    'بارك الله فيك!',
  ],
  TtsFeedbackType.srsItemCleared: [
    'أتقنت هذا السؤال!',
    'رائع! لن يعود هذا السؤال مجدداً!',
    'ممتاز، لقد أتقنت هذا المفهوم!',
  ],
  TtsFeedbackType.wrong: [
    'لا بأس، حاول مرة أخرى!',
    'لا تقلق، سنراجعه معاً!',
    'اجتهد أكثر في المرة القادمة!',
    'كل خطأ يجعلك أذكى!',
  ],
  TtsFeedbackType.reviewComplete: [
    'أنهيت جلسة المراجعة! عمل رائع!',
    'أحسنت! استمر في التعلم!',
    'مراجعة ممتازة! أنت في تقدم مستمر!',
  ],
  TtsFeedbackType.dailyChallengeComplete: [
    'أكملت التحدي اليومي! أنت بطل!',
    'ممتاز! نقاط مضاعفة لك!',
    'رائع! حافظ على تحديك اليومي!',
  ],
  TtsFeedbackType.streakAchieved: [
    'سلسلة رائعة! استمر هكذا!',
    'أنت لا تتوقف! سلسلة جديدة!',
  ],
  TtsFeedbackType.levelUp: [
    'مستوى جديد! أنت تتقدم بسرعة!',
    'ترقيت! أحسنت يا بطل!',
  ],
  TtsFeedbackType.encouragement: [
    'لا تستسلم، أنت قادر!',
    'كل خطأ يجعلك أذكى!',
    'استمر، النجاح قادم!',
  ],
  TtsFeedbackType.welcome: [
    'أهلاً وسهلاً في أكاديمية عزيز!',
    'مرحباً بك! هيا نتعلم معاً!',
  ],
};

const _enMessages = <TtsFeedbackType, List<String>>{
  TtsFeedbackType.correct: [
    'Excellent!',
    'Great job!',
    "That's right!",
    "You're a star!",
    'Brilliant!',
  ],
  TtsFeedbackType.srsItemCleared: [
    "You've mastered that one!",
    'Amazing — that question is conquered!',
    "Great work, you won't see that question again!",
  ],
  TtsFeedbackType.wrong: [
    'Not quite, keep trying!',
    "Don't worry, practice makes perfect!",
    "Good effort! Let's review this together.",
    'Every mistake makes you smarter!',
  ],
  TtsFeedbackType.reviewComplete: [
    'Review complete! Fantastic work!',
    'Well done! Keep up the great learning!',
    "Excellent review session! You're improving fast!",
  ],
  TtsFeedbackType.dailyChallengeComplete: [
    "Daily challenge done! You're a champion!",
    'Awesome! Double XP earned!',
    "Great job completing today's challenge!",
  ],
  TtsFeedbackType.streakAchieved: [
    'Amazing streak! Keep it going!',
    "You're on fire! New streak!",
  ],
  TtsFeedbackType.levelUp: [
    'Level up! You\'re advancing fast!',
    'Promoted! Well done, champion!',
  ],
  TtsFeedbackType.encouragement: [
    "Don't give up — you can do it!",
    'Every mistake makes you smarter!',
    'Keep going, success is coming!',
  ],
  TtsFeedbackType.welcome: [
    'Welcome to Aziz Academy!',
    "Hello! Let's learn together!",
  ],
};

// =============================================================================
// Provider
// =============================================================================

final ttsServiceProvider = Provider<TtsService>((ref) {
  final audioService = ref.read(audioServiceProvider);
  final cloud = CloudTtsService(audioService: audioService);
  final service = TtsService(audioService: audioService, cloud: cloud);

  ref.onDispose(() {
    service.dispose();
    cloud.dispose();
  });

  // Initial state from settings.
  final settings = ref.read(appSettingsProvider).value;
  final soundOn = settings?.soundEnabled ?? true;
  final ttsOn = settings?.ttsEnabled ?? true;
  final muted = !(soundOn && ttsOn);
  service.updateMuteStatus(muted);
  cloud.setMuted(muted);
  service.setPreferredVoices(
    arabicVoiceName: settings?.preferredArVoice,
    englishVoiceName: settings?.preferredEnVoice,
  );
  service.setCloudEnabled(settings?.cloudVoices ?? false);

  // Initial locale — default Arabic if not yet loaded
  final lang = ref.read(localeProvider).value?.languageCode ?? 'ar';
  service.updateLocale(lang == 'ar');

  // React to settings changes — mute when either toggle is off.
  ref.listen<AsyncValue<AppSettings>>(appSettingsProvider, (_, next) {
    final s = next.value;
    final on = (s?.soundEnabled ?? true) && (s?.ttsEnabled ?? true);
    service.updateMuteStatus(!on);
    cloud.setMuted(!on);
    service.setPreferredVoices(
      arabicVoiceName: s?.preferredArVoice,
      englishVoiceName: s?.preferredEnVoice,
    );
    service.setCloudEnabled(s?.cloudVoices ?? false);
  });

  // React to locale changes (seamless EN ↔ AR switch)
  ref.listen<AsyncValue<Locale>>(
    localeProvider,
    (_, next) =>
        service.updateLocale((next.value?.languageCode ?? 'ar') == 'ar'),
  );

  return service;
});

// =============================================================================
// Service
// =============================================================================

class TtsService {
  TtsService({required AudioService audioService, CloudTtsService? cloud})
    : _audioService = audioService,
      _cloud = cloud {
    _initTts();
  }

  final FlutterTts _tts = FlutterTts();
  final AudioService _audioService;
  final CloudTtsService? _cloud;
  final _rng = math.Random();

  bool _isMuted = false;
  bool _isArabic = true;
  bool _isSpeaking = false;
  // When true and the cloud service is available, _speak tries the cloud
  // proxy first and falls back to browser Web Speech on failure. Toggled
  // via AppSettings.cloudVoices in the provider listener above.
  bool _cloudEnabled = false;

  void setCloudEnabled(bool enabled) {
    _cloudEnabled = enabled;
  }

  // Memoized best-voice picks per language (queried once after voice list ready)
  Map<String, String>? _arVoice;
  Map<String, String>? _enVoice;
  bool _voicesResolved = false;

  // User-selected overrides (set via setPreferredVoices). When set, these
  // beat the auto-pick. Null/empty falls back to auto.
  String? _userArVoiceName;
  String? _userEnVoiceName;
  // Cached full voice list so we can resolve user picks to their locale.
  List<dynamic>? _voicesCache;

  /// Update the user's chosen voice names. Pass null/empty to revert to auto.
  void setPreferredVoices({
    String? arabicVoiceName,
    String? englishVoiceName,
  }) {
    _userArVoiceName = (arabicVoiceName?.isEmpty ?? true)
        ? null
        : arabicVoiceName;
    _userEnVoiceName = (englishVoiceName?.isEmpty ?? true)
        ? null
        : englishVoiceName;
  }

  /// Returns the cached list of available voices (each entry has 'name' and
  /// 'locale' keys). Triggers an async fetch if not yet resolved.
  Future<List<Map<String, String>>> availableVoices() async {
    if (!_voicesResolved) await _resolveBestVoices();
    final out = <Map<String, String>>[];
    for (final raw in _voicesCache ?? const []) {
      if (raw is! Map) continue;
      final name = raw['name']?.toString() ?? '';
      final locale = raw['locale']?.toString() ?? '';
      if (name.isEmpty) continue;
      out.add({'name': name, 'locale': locale});
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  Future<void> _initTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setVolume(1.0);
      await _resolveBestVoices();
    } catch (e) {
      debugPrint('TTS init: $e');
    }
  }

  /// Web Speech API populates voices asynchronously. We poll briefly, then
  /// pick the most natural-sounding voice for AR and EN by ranking name hints
  /// (Natural > Neural > Online > Premium > anything matching the lang).
  Future<void> _resolveBestVoices() async {
    if (_voicesResolved) return;
    try {
      List<dynamic>? voices;
      for (var attempt = 0; attempt < 8; attempt++) {
        voices = await _tts.getVoices as List<dynamic>?;
        if (voices != null && voices.isNotEmpty) break;
        await Future.delayed(const Duration(milliseconds: 120));
      }
      if (voices == null || voices.isEmpty) {
        _voicesResolved = true;
        return;
      }
      _voicesCache = voices;
      _arVoice = _pickBest(voices, langPrefix: 'ar');
      _enVoice = _pickBest(voices, langPrefix: 'en');
      _voicesResolved = true;
    } catch (e) {
      debugPrint('TTS voice resolve: $e');
      _voicesResolved = true;
    }
  }

  /// Resolve a user-picked voice name back to its full {name, locale} record
  /// using the cached voice list. Null if not found.
  Map<String, String>? _lookupVoiceByName(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final raw in _voicesCache ?? const []) {
      if (raw is! Map) continue;
      if (raw['name']?.toString() == name) {
        return {
          'name': name,
          'locale': raw['locale']?.toString() ?? '',
        };
      }
    }
    return null;
  }

  /// Rank candidate voices by name quality hints. Higher score = more natural.
  /// Tuned to strongly prefer modern Neural/Natural voices and demote the
  /// older legacy/eSpeak-style voices that sound robotic.
  Map<String, String>? _pickBest(
    List<dynamic> voices, {
    required String langPrefix,
  }) {
    int scoreOf(String name, String locale) {
      final n = name.toLowerCase();
      var s = 0;

      // Modern neural engines — these sound dramatically better than legacy.
      if (n.contains('natural')) s += 200;
      if (n.contains('neural')) s += 180;
      // Online voices on Windows 10/11 are the SAPI Neural voices; usually
      // the second-best tier after Natural and far above the legacy variants.
      if (n.contains('online')) s += 120;
      if (n.contains('premium') || n.contains('enhanced')) s += 100;

      // Vendor signal — Microsoft Neural Arabic is excellent, Google Arabic
      // is okay. Apple "Siri" voices sound human; rank them high.
      if (n.contains('siri')) s += 90;
      if (n.contains('microsoft')) s += 50;
      if (n.contains('google')) s += 40;

      // Penalize legacy / poor-quality voice families that sound robotic.
      if (n.contains('espeak')) s -= 200;
      if (n.contains('festival')) s -= 200;
      if (n.contains('compact') || n.contains('lite')) s -= 50;

      // Penalize voices that end in numeric suffixes — those are usually
      // the older fallback voices ("Voice 1", "Voice 2", etc.).
      if (RegExp(r'\b(voice\s*\d|\d+)$').hasMatch(n)) s -= 30;

      // Locale fit — for Arabic, prefer Gulf/MSA register (closer to Quranic
      // pronunciation kids hear at home). For English, prefer en-US.
      if (langPrefix == 'ar') {
        if (locale.startsWith('ar-SA') || locale.startsWith('ar-XA')) s += 40;
        if (locale.startsWith('ar-AE') ||
            locale.startsWith('ar-KW') ||
            locale.startsWith('ar-QA') ||
            locale.startsWith('ar-BH') ||
            locale.startsWith('ar-OM')) {
          s += 35;
        }
        if (locale.startsWith('ar-EG')) s += 15;
      }
      if (langPrefix == 'en' && locale.startsWith('en-US')) s += 10;
      if (langPrefix == 'en' && locale.startsWith('en-GB')) s += 5;
      return s;
    }

    Map<String, String>? best;
    var bestScore = -10000;
    for (final raw in voices) {
      if (raw is! Map) continue;
      final name = raw['name']?.toString() ?? '';
      final locale = raw['locale']?.toString() ?? '';
      if (!locale.toLowerCase().startsWith(langPrefix)) continue;
      final s = scoreOf(name, locale);
      if (s > bestScore) {
        bestScore = s;
        best = {'name': name, 'locale': locale};
      }
    }
    return best;
  }

  /// Applies the voice profile for the given language before each utterance.
  /// Arabic → Gulf/MSA-leaning voice when available, deliberate pacing,
  /// slightly warm pitch. English → warm teacher tone.
  Future<void> _applyProfile(bool arabic) async {
    if (!_voicesResolved) await _resolveBestVoices();
    if (arabic) {
      final v = _lookupVoiceByName(_userArVoiceName) ?? _arVoice;
      await _tts.setLanguage(v?['locale'] ?? 'ar-SA');
      if (v != null) {
        try {
          final name = v['name'];
          final locale = v['locale'];
          if (name is String && locale is String) {
            await _tts.setVoice({'name': name, 'locale': locale});
          }
        } catch (_) {}
      }
      // Slower + slightly lower pitch reads as more reverent and less
      // synthetic for Arabic religious content. Tuned by ear after the
      // 2026-05-12 "I don't like the app voices" feedback.
      await _tts.setSpeechRate(0.40);
      await _tts.setPitch(0.96);
    } else {
      final v = _lookupVoiceByName(_userEnVoiceName) ?? _enVoice;
      await _tts.setLanguage(v?['locale'] ?? 'en-US');
      if (v != null) {
        try {
          final name = v['name'];
          final locale = v['locale'];
          if (name is String && locale is String) {
            await _tts.setVoice({'name': name, 'locale': locale});
          }
        } catch (_) {}
      }
      // Slightly slower than default + warmer pitch — kids understand
      // English narration better at this pace.
      await _tts.setSpeechRate(0.46);
      await _tts.setPitch(1.04);
    }
  }

  // ---------------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------------

  void updateMuteStatus(bool isMuted) {
    _isMuted = isMuted;
    if (_isMuted) _tts.stop();
  }

  /// Called by the provider when the app locale toggles.
  void updateLocale(bool isArabic) => _isArabic = isArabic;

  void dispose() => _tts.stop();

  // ---------------------------------------------------------------------------
  // Core speak — ducks BGM, applies voice profile, speaks, restores BGM
  // ---------------------------------------------------------------------------

  Future<void> _speak(
    String text, {
    bool? arabic,
    bool bypassMute = false,
  }) async {
    if ((!bypassMute && _isMuted) || text.isEmpty || _isSpeaking) return;
    _isSpeaking = true;
    final useArabic = arabic ?? _isArabic;
    try {
      // Cloud-first when the user has opted in. If the proxy is configured,
      // they get Azure Neural quality. If not (no key set on Vercel, network
      // down, CORS, 5xx), we silently fall back to the browser TTS path so
      // there's never a silent failure for the user.
      if (_cloudEnabled && _cloud != null) {
        try {
          await _cloud.speak(text, arabic: useArabic);
          return;
        } catch (e) {
          debugPrint('Cloud TTS failed, falling back to browser TTS: $e');
        }
      }
      _audioService.duckBgm();
      await _applyProfile(useArabic);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak: $e');
    } finally {
      _audioService.unduckBgm();
      _isSpeaking = false;
    }
  }

  /// Force a speak even when the user has muted TTS. Used by the voice
  /// picker preview, where the user is explicitly asking to hear a voice
  /// and silent failure would be confusing.
  Future<void> previewVoice(String text, {required bool arabic}) =>
      _speak(text, arabic: arabic, bypassMute: true);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Speaks a randomly chosen contextual message in the current app locale.
  /// Pass [extra] to append additional text (e.g. the correct answer).
  Future<void> speakFeedback(TtsFeedbackType type, {String? extra}) async {
    final pool = _isArabic ? _arMessages[type] : _enMessages[type];
    if (pool == null || pool.isEmpty) return;
    final msg = pool[_rng.nextInt(pool.length)];
    await _speak(extra != null ? '$msg $extra' : msg);
  }

  /// Combines a contextual feedback phrase with the correct answer in one
  /// natural utterance. Use this in quiz screens instead of [speakArabic].
  ///
  /// - [correct] true → praise + answer text
  /// - [correct] false → consolation + "الإجابة الصحيحة هي …" / "The correct answer is …"
  /// - [srsItem] true + [correct] true → mastery celebration
  Future<void> speakAnswerFeedback(
    String answerText, {
    required bool correct,
    bool srsItem = false,
  }) async {
    final type = (correct && srsItem)
        ? TtsFeedbackType.srsItemCleared
        : correct
        ? TtsFeedbackType.correct
        : TtsFeedbackType.wrong;

    final pool = _isArabic ? _arMessages[type] : _enMessages[type];
    final feedback = (pool != null && pool.isNotEmpty)
        ? pool[_rng.nextInt(pool.length)]
        : '';

    final String utterance;
    if (!correct) {
      final prefix = _isArabic ? 'الإجابة الصحيحة هي' : 'The correct answer is';
      utterance = '$feedback $prefix $answerText';
    } else {
      utterance = '$feedback $answerText';
    }

    await _speak(utterance);
  }

  /// Locale-aware: speaks [arabicText] when AR, [englishText] when EN.
  Future<void> speakLocale(String arabicText, String englishText) =>
      _speak(_isArabic ? arabicText : englishText);

  // Backward-compatible helpers (existing call sites continue to work)

  /// Always speaks in Arabic regardless of app locale.
  Future<void> speakArabic(String text) => _speak(text, arabic: true);

  /// Always speaks in English regardless of app locale.
  Future<void> speakEnglish(String text) => _speak(text, arabic: false);

  Future<void> stop() async => _tts.stop();
}
