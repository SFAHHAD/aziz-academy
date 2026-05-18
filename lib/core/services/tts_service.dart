import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/services/audio_service.dart';

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
  final service = TtsService(audioService: audioService);

  ref.onDispose(service.dispose);

  // Initial sound setting
  final soundOn = ref.read(appSettingsProvider).value?.soundEnabled ?? true;
  service.updateMuteStatus(!soundOn);

  // Initial locale — default Arabic if not yet loaded
  final lang = ref.read(localeProvider).value?.languageCode ?? 'ar';
  service.updateLocale(lang == 'ar');

  // React to settings changes
  ref.listen<AsyncValue<AppSettings>>(
    appSettingsProvider,
    (_, next) => service.updateMuteStatus(!(next.value?.soundEnabled ?? true)),
  );

  // React to locale changes (seamless EN ↔ AR switch)
  ref.listen<AsyncValue<Locale>>(
    localeProvider,
    (_, next) => service.updateLocale(
      (next.value?.languageCode ?? 'ar') == 'ar',
    ),
  );

  return service;
});

// =============================================================================
// Service
// =============================================================================

class TtsService {
  TtsService({required AudioService audioService})
      : _audioService = audioService {
    _initTts();
  }

  final FlutterTts _tts = FlutterTts();
  final AudioService _audioService;
  final _rng = math.Random();

  bool _isMuted = false;
  bool _isArabic = true;
  bool _isSpeaking = false;

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  Future<void> _initTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setVolume(1.0);
    } catch (e) {
      debugPrint('TTS init: $e');
    }
  }

  /// Applies the voice profile for the given language before each utterance.
  /// Arabic → Cairo-dialect locale, deliberate pacing, natural pitch.
  /// English → warm teacher tone, slightly elevated pitch.
  Future<void> _applyProfile(bool arabic) async {
    if (arabic) {
      await _tts.setLanguage('ar-EG');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
    } else {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.50);
      await _tts.setPitch(1.08);
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

  Future<void> _speak(String text, {bool? arabic}) async {
    if (_isMuted || text.isEmpty || _isSpeaking) return;
    _isSpeaking = true;
    final useArabic = arabic ?? _isArabic;
    try {
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
    final feedback =
        (pool != null && pool.isNotEmpty) ? pool[_rng.nextInt(pool.length)] : '';

    final String utterance;
    if (!correct) {
      final prefix =
          _isArabic ? 'الإجابة الصحيحة هي' : 'The correct answer is';
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
