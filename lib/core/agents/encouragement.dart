import 'package:aziz_academy/core/agents/learner_state.dart';

/// C2 — Encouragement agent. Reads frustration signals from learner state
/// and decides whether to interrupt mid-quiz with a kind break suggestion.
class EncouragementAgent {
  const EncouragementAgent();

  /// True when we should *suggest* a break (never force it).
  bool shouldSuggestBreak(LearnerState s) => s.frustrationLevel >= 0.6;

  /// True when we should warm the kid up with an easier question next.
  bool shouldDropDifficulty(LearnerState s) => s.frustrationLevel >= 0.4;

  /// Friendly bilingual message for the suggestion.
  String breakMessage({required bool arabic}) {
    return arabic
        ? 'خذ نفسًا 🌿 — كل خطأ خطوة نحو التعلم. هل تريد استراحة قصيرة؟'
        : 'Take a breath 🌿 — every mistake is part of learning. Want a quick break?';
  }
}
