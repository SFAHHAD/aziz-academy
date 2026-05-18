import 'package:aziz_academy/core/models/quiz_question.dart';

/// A2 — Tutor Companion ("Aziz").
///
/// Emits *hints*, never answers. Bilingual scripted lines so v1 doesn't need
/// an LLM (latency-critical, kid-safe). When/if an LLM is added later,
/// pre-compute hints at question-load time so tap-to-hint stays instant.
class TutorCompanion {
  const TutorCompanion();

  /// Hint level 1: gentle, "look again"-style.
  /// Hint level 2: structural — narrows the choices.
  /// Hint level 3: strong — reveals the first letter / first word.
  String hint({
    required QuizQuestion question,
    required int level,
    required bool arabic,
  }) {
    final lvl = level.clamp(1, 3);
    if (lvl == 1) {
      return arabic
          ? 'محاولة ذكية! اقرأ السؤال مرة ثانية وفكر بهدوء.'
          : 'Smart try! Read the question once more and take your time.';
    }
    if (lvl == 2) {
      // Narrow: pick the longest option as a structural hint signal.
      final longest = question.options.fold<String>(
        '',
        (a, b) => b.length > a.length ? b : a,
      );
      return arabic
          ? 'فكر في الإجابات الطويلة مثل: "$longest" هل تبدو معقولة؟'
          : 'Think about the longer answers (like "$longest") — does it fit?';
    }
    // Level 3 — first character mask.
    final correct = question.correctAnswer.trim();
    if (correct.isEmpty) {
      return arabic ? 'حاول التخمين الذكي.' : 'Make your best guess.';
    }
    final first = correct.runes.first;
    final firstChar = String.fromCharCode(first);
    return arabic
        ? 'الإجابة تبدأ بحرف: "$firstChar"'
        : 'The answer starts with: "$firstChar"';
  }

  /// Encouragement after a wrong answer (light, non-shaming).
  String afterWrong({required bool arabic, required int wrongStreak}) {
    if (wrongStreak >= 3) {
      return arabic
          ? 'لا بأس، نأخذ نفسًا ونحاول مرة أخرى.'
          : 'No worries — let\'s take a breath and try again.';
    }
    if (wrongStreak == 2) {
      return arabic
          ? 'قريب جدًا! حاول مرة أخرى.'
          : 'So close! Give it another go.';
    }
    return arabic ? 'محاولة جيدة، أكمل.' : 'Good try, keep going.';
  }

  /// Praise after a correct answer (varied to avoid repetition).
  String afterCorrect({required bool arabic, required int correctStreak}) {
    if (correctStreak >= 5) {
      return arabic ? 'لا يُصدق! أنت مذهل.' : 'Unbelievable! You\'re on fire.';
    }
    if (correctStreak >= 3) {
      return arabic ? 'استمر على هذا الإيقاع!' : 'Keep this rhythm going!';
    }
    return arabic ? 'إجابة ممتازة!' : 'Great answer!';
  }
}
