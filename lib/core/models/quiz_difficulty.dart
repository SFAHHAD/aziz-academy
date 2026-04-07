/// Difficulty level shared across all quiz modules.
enum QuizDifficulty { easy, medium, hard }

extension QuizDifficultyExt on QuizDifficulty {
  String get labelAr {
    switch (this) {
      case QuizDifficulty.easy:   return 'سهل';
      case QuizDifficulty.medium: return 'متوسط';
      case QuizDifficulty.hard:   return 'صعب';
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
