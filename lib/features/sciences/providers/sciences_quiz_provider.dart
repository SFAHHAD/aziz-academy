import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/core/agents/event_bus.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/core/models/quiz_difficulty.dart';
import 'package:aziz_academy/core/models/recap_module.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/recap_arm_provider.dart';
import 'package:aziz_academy/core/providers/sciences_pool_provider.dart';
import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/utils/adaptive_order.dart';
import 'package:aziz_academy/features/sciences/data/sciences_repository.dart';

final sciencesRepositoryProvider = Provider<SciencesRepository>(
  (ref) => const SciencesRepository(),
  name: 'sciencesRepositoryProvider',
);

final sciencesQuestionsProvider =
    AsyncNotifierProvider<SciencesQuestionsNotifier, List<QuizQuestion>>(
      SciencesQuestionsNotifier.new,
      name: 'sciencesQuestionsProvider',
    );

class SciencesQuestionsNotifier extends AsyncNotifier<List<QuizQuestion>> {
  @override
  Future<List<QuizQuestion>> build() async {
    // Read from session-cached pool — boss + sciences quiz + random quiz
    // share the same entries list. Locale change reuses the cache.
    final entries = await ref.watch(sciencesPoolProvider.future);
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    return entries.map((e) => e.toQuizQuestion(arabic: isArabic)).toList();
  }
}

final sciencesQuizProvider =
    AsyncNotifierProvider<SciencesQuizNotifier, QuizSessionState>(
      SciencesQuizNotifier.new,
      name: 'sciencesQuizProvider',
    );

class SciencesCategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setFilter(String? category) => state = category;
}

final categoryFilterProvider =
    NotifierProvider<SciencesCategoryFilterNotifier, String?>(
      SciencesCategoryFilterNotifier.new,
    );

class SciencesDifficultyNotifier extends Notifier<QuizDifficulty> {
  @override
  QuizDifficulty build() => QuizDifficulty.medium;
  void set(QuizDifficulty d) => state = d;
}

final sciencesDifficultyProvider =
    NotifierProvider<SciencesDifficultyNotifier, QuizDifficulty>(
      SciencesDifficultyNotifier.new,
      name: 'sciencesDifficultyProvider',
    );

class SciencesQuizNotifier extends AsyncNotifier<QuizSessionState> {
  @override
  Future<QuizSessionState> build() async {
    final questions = await ref.watch(sciencesQuestionsProvider.future);
    final category = ref.watch(categoryFilterProvider);

    var filtered = questions;
    if (category != null) {
      filtered = questions.where((q) => q.category == category).toList();
    }

    final adaptive =
        ref.watch(appSettingsProvider).value?.adaptiveDifficulty ?? true;
    if (adaptive) {
      final skill =
          ref.read(learnerStateProvider).value?.skillFor('sciences') ?? 0.5;
      filtered = adaptiveOrder<QuizQuestion>(
        filtered,
        skill,
        (q) => q.difficulty,
      );
    }

    final diff = ref.watch(sciencesDifficultyProvider);
    if (diff != QuizDifficulty.hard) {
      final minQ = 8.clamp(1, filtered.length);
      final cap = ((filtered.length * diff.poolFraction).ceil()).clamp(
        minQ,
        filtered.length,
      );
      filtered = filtered.take(cap).toList();
    }

    final arm = ref.read(recapArmProvider);
    if (arm != null &&
        arm.module == RecapModule.sciences &&
        arm.entries.isNotEmpty) {
      final idSet = arm.ids.toSet();
      filtered = filtered.where((q) => idSet.contains(q.id)).toList();
      Future.microtask(() => ref.read(recapArmProvider.notifier).clear());
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

    final out = QuizSessionState(
      questions: List.of(filtered)..shuffle(),
      currentIndex: 0,
      score: 0,
      livesRemaining: 3,
      status: QuizStatus.inProgress,
    );
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.sessionStarted,
        module: 'sciences',
        timestamp: DateTime.now(),
      ),
    );
    _lastQuestionStartedAt = DateTime.now();
    return out;
  }

  DateTime? _lastQuestionStartedAt;

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
        module: 'sciences',
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
          module: 'sciences',
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
