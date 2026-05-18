import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/core/agents/event_bus.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/features/logos/data/logos_repository.dart';

// =============================================================================
// 1. REPOSITORY PROVIDER
// =============================================================================

final logosRepositoryProvider = Provider<LogosRepository>(
  (ref) => const LogosRepository(),
  name: 'logosRepositoryProvider',
);

// =============================================================================
// 2. QUESTIONS PROVIDER
// =============================================================================

final logosQuestionsProvider =
    AsyncNotifierProvider<LogosQuestionsNotifier, List<QuizQuestion>>(
      LogosQuestionsNotifier.new,
      name: 'logosQuestionsProvider',
    );

class LogosQuestionsNotifier extends AsyncNotifier<List<QuizQuestion>> {
  @override
  Future<List<QuizQuestion>> build() async {
    final repo = ref.read(logosRepositoryProvider);
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    return repo.loadQuestions(arabic: isArabic);
  }
}

// =============================================================================
// 3. QUIZ SESSION PROVIDER  (mirrors CapitalsQuizNotifier exactly)
// =============================================================================

final logosQuizProvider =
    AsyncNotifierProvider<LogosQuizNotifier, QuizSessionState>(
      LogosQuizNotifier.new,
      name: 'logosQuizProvider',
    );

class LogosQuizNotifier extends AsyncNotifier<QuizSessionState> {
  @override
  Future<QuizSessionState> build() async {
    final questions = await ref.watch(logosQuestionsProvider.future);
    final out = QuizSessionState(
      questions: List.of(questions)..shuffle(),
      currentIndex: 0,
      score: 0,
      livesRemaining: 3,
      status: QuizStatus.inProgress,
    );
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.sessionStarted,
        module: 'logos',
        timestamp: DateTime.now(),
      ),
    );
    _lastQuestionStartedAt = DateTime.now();
    return out;
  }

  DateTime? _lastQuestionStartedAt;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  bool submitAnswer(String answer) {
    final current = state.value?.currentQuestion;
    if (current == null) return false;

    final session = state.value!;
    final isCorrect = answer.trim() == current.correctAnswer.trim();

    final practice = readPracticeMode(ref);
    final nextLives = isCorrect
        ? session.livesRemaining
        : (practice ? session.livesRemaining : session.livesRemaining - 1);

    final lat = _lastQuestionStartedAt == null
        ? 0
        : DateTime.now().difference(_lastQuestionStartedAt!).inMilliseconds;
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.questionAnswered,
        module: 'logos',
        timestamp: DateTime.now(),
        questionId: current.id,
        category: current.category,
        correct: isCorrect,
        latencyMs: lat,
      ),
    );

    state = AsyncData(
      session.copyWith(
        score: isCorrect ? session.score + 1 : session.score,
        livesRemaining: nextLives,
        lastAnswerCorrect: isCorrect,
      ),
    );
    return isCorrect;
  }

  void nextQuestion() {
    final session = state.value;
    if (session == null || session.isGameOver) return;

    final nextIndex = session.currentIndex + 1;
    final isComplete = nextIndex >= session.totalQuestions;

    if (isComplete) {
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.sessionEnded,
          module: 'logos',
          timestamp: DateTime.now(),
          score: session.score,
        ),
      );
    } else {
      _lastQuestionStartedAt = DateTime.now();
    }

    state = AsyncData(
      session.copyWith(
        currentIndex: nextIndex,
        status: isComplete ? QuizStatus.complete : QuizStatus.inProgress,
        clearLastAnswer: true,
      ),
    );
  }

  void restart() {
    final questions = state.value?.questions;
    if (questions == null) return;
    state = AsyncData(
      QuizSessionState(
        questions: List.of(questions)..shuffle(),
        currentIndex: 0,
        score: 0,
        livesRemaining: 3,
        status: QuizStatus.inProgress,
      ),
    );
  }
}
