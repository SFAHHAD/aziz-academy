import 'package:aziz_academy/core/models/quiz_question.dart';

// =============================================================================
// Shared quiz session state — used by both Capitals and Logos modules.
// =============================================================================

/// Represents the status of a quiz session.
enum QuizStatus { loading, inProgress, complete }

/// Immutable snapshot of a quiz session at any given moment.
class QuizSessionState {
  const QuizSessionState({
    required this.questions,
    required this.currentIndex,
    required this.score,
    required this.status,
    required this.livesRemaining,
    this.lastAnswerCorrect,
  });

  final List<QuizQuestion> questions;
  final int currentIndex;
  final int score;
  final QuizStatus status;
  final int livesRemaining;
  final bool? lastAnswerCorrect;

  // ---------------------------------------------------------------------------
  // Derived helpers
  // ---------------------------------------------------------------------------

  QuizQuestion? get currentQuestion =>
      status == QuizStatus.inProgress && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  int get totalQuestions => questions.length;
  int get answeredCount => currentIndex;
  double get progress =>
      totalQuestions == 0 ? 0 : currentIndex / totalQuestions;
  double get scorePercent =>
      totalQuestions == 0 ? 0 : score / totalQuestions;
  bool get isComplete => status == QuizStatus.complete;
  bool get isGameOver => livesRemaining <= 0;

  // ---------------------------------------------------------------------------
  // Copy-with
  // ---------------------------------------------------------------------------

  QuizSessionState copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? score,
    QuizStatus? status,
    int? livesRemaining,
    bool? lastAnswerCorrect,
    bool clearLastAnswer = false,
  }) {
    return QuizSessionState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      status: status ?? this.status,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      lastAnswerCorrect:
          clearLastAnswer ? null : (lastAnswerCorrect ?? this.lastAnswerCorrect),
    );
  }

  @override
  String toString() =>
      'QuizSessionState(index: $currentIndex/$totalQuestions, score: $score, status: $status)';
}
