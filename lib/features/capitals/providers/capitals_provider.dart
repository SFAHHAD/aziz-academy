import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/features/capitals/data/capitals_repository.dart';

// =============================================================================
// 1. REPOSITORY PROVIDER
// Provides a singleton CapitalsRepository instance.
// =============================================================================

/// Provides the [CapitalsRepository] singleton.
///
/// Override this in tests to inject a mock repository:
/// ```dart
/// container = ProviderContainer(overrides: [
///   capitalsRepositoryProvider.overrideWithValue(FakeCapitalsRepository()),
/// ]);
/// ```
final capitalsRepositoryProvider = Provider<CapitalsRepository>(
  (ref) => const CapitalsRepository(),
  name: 'capitalsRepositoryProvider',
);

// =============================================================================
// CONTINENT FILTER PROVIDER
// Holds the currently selected continent for quiz filtering.
// Null = show all questions (used by the global quiz entry).
// Set by MapsScreen before navigating to /capitals.
// =============================================================================

/// Holds the continent filter for the quiz session.
///
/// Set this before navigating to [CapitalsScreen] to start a continent quiz:
/// ```dart
/// ref.read(continentFilterProvider.notifier).set('Africa');
/// context.go(AppRoutes.capitals);
/// ```
final continentFilterProvider =
    NotifierProvider<ContinentFilterNotifier, String?>(
  ContinentFilterNotifier.new,
  name: 'continentFilterProvider',
);

class ContinentFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String continent) => state = continent;
  void clear() => state = null;
}


// =============================================================================
// 2. QUESTIONS PROVIDER
// Asynchronously loads all quiz questions from the JSON asset.
// =============================================================================

/// Loads the full list of [QuizQuestion]s from capitals.json.
///
/// UI should watch this with:
/// ```dart
/// final questionsAsync = ref.watch(capitalsQuestionsProvider);
/// questionsAsync.when(data: ..., loading: ..., error: ...);
/// ```
final capitalsQuestionsProvider =
    AsyncNotifierProvider<CapitalsQuestionsNotifier, List<QuizQuestion>>(
  CapitalsQuestionsNotifier.new,
  name: 'capitalsQuestionsProvider',
);

class CapitalsQuestionsNotifier
    extends AsyncNotifier<List<QuizQuestion>> {
  @override
  Future<List<QuizQuestion>> build() async {
    final repo = ref.read(capitalsRepositoryProvider);
    return repo.loadQuestions();
  }

  /// Reloads questions from disk (useful for hot-reload / testing).
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(capitalsRepositoryProvider);
      return repo.loadQuestions();
    });
  }
}

// QuizStatus and QuizSessionState are defined in
// lib/core/models/quiz_session_state.dart and re-exported via this file's
// imports for backward compatibility.


// =============================================================================
// 4. QUIZ SESSION PROVIDER
// The primary provider the UI should use to drive the quiz screen.
// It is an AsyncNotifier so it can properly await the questions load.
// =============================================================================

/// Manages the live quiz session for the Capitals module.
///
/// Because this provider depends on async data, it exposes
/// `AsyncValue<QuizSessionState>`. In your UI:
///
/// ```dart
/// final sessionAsync = ref.watch(capitalsQuizProvider);
/// sessionAsync.when(
///   loading: () => const LoadingSpinner(),
///   error: (e, st) => ErrorView(error: e),
///   data: (session) => QuizView(session: session),
/// );
///
/// // Actions (always safe to call regardless of loading state):
/// ref.read(capitalsQuizProvider.notifier).submitAnswer('Paris');
/// ref.read(capitalsQuizProvider.notifier).nextQuestion();
/// ref.read(capitalsQuizProvider.notifier).restart();
/// ```
final capitalsQuizProvider =
    AsyncNotifierProvider<CapitalsQuizNotifier, QuizSessionState>(
  CapitalsQuizNotifier.new,
  name: 'capitalsQuizProvider',
);

class CapitalsQuizNotifier extends AsyncNotifier<QuizSessionState> {
  @override
  Future<QuizSessionState> build() async {
    var questions = await ref.watch(capitalsQuestionsProvider.future);

    // Filter by continent when launched from the map explorer.
    final continent = ref.watch(continentFilterProvider);
    if (continent != null) {
      questions = questions
          .where((q) => q.category == continent)
          .toList();
    }

    if (questions.isEmpty) {
      // Edge case: continent has no questions yet.
      return QuizSessionState(
        questions: const [],
        currentIndex: 0,
        score: 0,
        livesRemaining: 3,
        status: QuizStatus.complete,
      );
    }

    return QuizSessionState(
      questions: List.of(questions)..shuffle(),
      currentIndex: 0,
      score: 0,
      livesRemaining: 3,
      status: QuizStatus.inProgress,
    );
  }

  // ---------------------------------------------------------------------------
  // Actions — each mutates the current QuizSessionState synchronously.
  // ---------------------------------------------------------------------------

  /// Records the child's answer for the current question.
  ///
  /// Returns `true` if [answer] matches [QuizQuestion.correctAnswer].
  /// Returns `false` if the session is not yet ready or already complete.
  bool submitAnswer(String answer) {
    final current = state.value?.currentQuestion;
    if (current == null) return false;

    final session = state.value!;
    final isCorrect = answer.trim() == current.correctAnswer.trim();
    state = AsyncData(session.copyWith(
      score: isCorrect ? session.score + 1 : session.score,
      livesRemaining:
          isCorrect ? session.livesRemaining : session.livesRemaining - 1,
      lastAnswerCorrect: isCorrect,
    ));
    return isCorrect;
  }

  /// Moves to the next question, or marks the session complete if done.
  void nextQuestion() {
    final session = state.value;
    if (session == null || session.isGameOver) return;

    final nextIndex = session.currentIndex + 1;
    if (nextIndex >= session.totalQuestions) {
      state = AsyncData(session.copyWith(
        currentIndex: nextIndex,
        status: QuizStatus.complete,
        clearLastAnswer: true,
      ));
    } else {
      state = AsyncData(session.copyWith(
        currentIndex: nextIndex,
        status: QuizStatus.inProgress,
        clearLastAnswer: true,
      ));
    }
  }

  /// Resets the session — re-shuffles questions and starts from zero.
  void restart() {
    final session = state.value;
    if (session == null) return;

    state = AsyncData(session.copyWith(
      questions: List.of(session.questions)..shuffle(),
      currentIndex: 0,
      score: 0,
      livesRemaining: 3,
      status: QuizStatus.inProgress,
      clearLastAnswer: true,
    ));
  }
}
