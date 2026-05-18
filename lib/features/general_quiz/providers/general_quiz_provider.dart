import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/core/agents/event_bus.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/core/models/quiz_difficulty.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/general_quiz_pool_provider.dart';
import 'package:aziz_academy/features/general_quiz/data/general_quiz_repository.dart';

final generalQuizRepositoryProvider = Provider<GeneralQuizRepository>(
  (ref) => const GeneralQuizRepository(),
  name: 'generalQuizRepositoryProvider',
);

final generalQuizEntriesProvider =
    AsyncNotifierProvider<GeneralQuizEntriesNotifier, List<GeneralQuizEntry>>(
      GeneralQuizEntriesNotifier.new,
      name: 'generalQuizEntriesProvider',
    );

class GeneralQuizEntriesNotifier extends AsyncNotifier<List<GeneralQuizEntry>> {
  @override
  Future<List<GeneralQuizEntry>> build() async {
    // Single canonical source: read from generalQuizPoolProvider so the
    // 31-pack merge happens at most once per session no matter how many
    // surfaces (general quiz, boss round, worksheet) consume it.
    return ref.watch(generalQuizPoolProvider.future);
  }
}

final generalQuizQuestionsProvider = Provider<AsyncValue<List<QuizQuestion>>>((
  ref,
) {
  final entriesAsync = ref.watch(generalQuizEntriesProvider);
  final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
  return entriesAsync.whenData(
    (entries) =>
        entries.map((e) => e.toQuizQuestion(arabic: isArabic)).toList(),
  );
}, name: 'generalQuizQuestionsProvider');

class GeneralQuizCategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setFilter(String? category) => state = category;
}

final generalQuizCategoryFilterProvider =
    NotifierProvider<GeneralQuizCategoryFilterNotifier, String?>(
      GeneralQuizCategoryFilterNotifier.new,
    );

class GeneralQuizDifficultyNotifier extends Notifier<QuizDifficulty> {
  @override
  QuizDifficulty build() => QuizDifficulty.medium;
  void set(QuizDifficulty d) => state = d;
}

final generalQuizDifficultyProvider =
    NotifierProvider<GeneralQuizDifficultyNotifier, QuizDifficulty>(
      GeneralQuizDifficultyNotifier.new,
      name: 'generalQuizDifficultyProvider',
    );

final generalQuizProvider =
    AsyncNotifierProvider<GeneralQuizNotifier, QuizSessionState>(
      GeneralQuizNotifier.new,
      name: 'generalQuizProvider',
    );

class GeneralQuizNotifier extends AsyncNotifier<QuizSessionState> {
  @override
  Future<QuizSessionState> build() async {
    final entries = await ref.watch(generalQuizEntriesProvider.future);
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final questions = entries
        .map((e) => e.toQuizQuestion(arabic: isArabic))
        .toList();
    final out = _build(questions);
    if (out.status == QuizStatus.inProgress) {
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.sessionStarted,
          module: 'general_quiz',
          timestamp: DateTime.now(),
        ),
      );
      _lastQuestionStartedAt = DateTime.now();
    }
    return out;
  }

  DateTime? _lastQuestionStartedAt;

  QuizSessionState _build(List<QuizQuestion> questions) {
    final category = ref.watch(generalQuizCategoryFilterProvider);
    var filtered = questions;
    if (category != null) {
      filtered = questions.where((q) => q.category == category).toList();
    }
    final diff = ref.watch(generalQuizDifficultyProvider);
    if (diff != QuizDifficulty.hard) {
      final minQ = 8.clamp(1, filtered.length);
      final cap = ((filtered.length * diff.poolFraction).ceil()).clamp(
        minQ,
        filtered.length,
      );
      filtered = filtered.take(cap).toList();
    }
    if (filtered.isEmpty) {
      return QuizSessionState(
        questions: const [],
        currentIndex: 0,
        score: 0,
        livesRemaining: 3,
        status: QuizStatus.complete,
      );
    }
    return QuizSessionState(
      questions: List.of(filtered)..shuffle(),
      currentIndex: 0,
      score: 0,
      livesRemaining: 3,
      status: QuizStatus.inProgress,
    );
  }

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
        module: 'general_quiz',
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
    if (nextIndex >= session.totalQuestions) {
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.sessionEnded,
          module: 'general_quiz',
          timestamp: DateTime.now(),
          score: session.score,
        ),
      );
      state = AsyncData(
        session.copyWith(
          currentIndex: nextIndex,
          status: QuizStatus.complete,
          clearLastAnswer: true,
        ),
      );
    } else {
      _lastQuestionStartedAt = DateTime.now();
      state = AsyncData(
        session.copyWith(
          currentIndex: nextIndex,
          status: QuizStatus.inProgress,
          clearLastAnswer: true,
        ),
      );
    }
  }

  void restart() {
    final session = state.value;
    if (session == null) return;
    state = AsyncData(
      session.copyWith(
        questions: List.of(session.questions)..shuffle(),
        currentIndex: 0,
        score: 0,
        livesRemaining: 3,
        status: QuizStatus.inProgress,
        clearLastAnswer: true,
      ),
    );
  }
}
