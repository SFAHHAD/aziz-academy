import 'package:aziz_academy/l10n/app_localizations.dart';

/// Difficulty level shared across all quiz modules.
enum QuizDifficulty { easy, medium, hard }

extension QuizDifficultyExt on QuizDifficulty {
  String label(AppLocalizations l10n) {
    switch (this) {
      case QuizDifficulty.easy:
        return l10n.difficultyEasy;
      case QuizDifficulty.medium:
        return l10n.difficultyMedium;
      case QuizDifficulty.hard:
        return l10n.difficultyHard;
    }
  }

  String get emoji {
    switch (this) {
      case QuizDifficulty.easy:   return '🌱';
      case QuizDifficulty.medium: return '⚡';
      case QuizDifficulty.hard:   return '🔥';
    }
  }

  /// Fraction of the question pool to use for this level.
  double get poolFraction {
    switch (this) {
      case QuizDifficulty.easy:   return 0.20;
      case QuizDifficulty.medium: return 0.50;
      case QuizDifficulty.hard:   return 1.00;
    }
  }
}
