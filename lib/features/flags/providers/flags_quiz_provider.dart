import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/core/models/quiz_difficulty.dart';
import 'package:aziz_academy/core/models/recap_module.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/recap_arm_provider.dart';
import 'package:aziz_academy/features/flags/data/flags_repository.dart';

final flagsRepositoryProvider = Provider<FlagsRepository>(
  (ref) => const FlagsRepository(),
  name: 'flagsRepositoryProvider',
);

final flagsQuestionsProvider =
    AsyncNotifierProvider<FlagsQuestionsNotifier, List<QuizQuestion>>(
  FlagsQuestionsNotifier.new,
  name: 'flagsQuestionsProvider',
);

class FlagsQuestionsNotifier extends AsyncNotifier<List<QuizQuestion>> {
  @override
  Future<List<QuizQuestion>> build() async {
    final repo = ref.read(flagsRepositoryProvider);
    return repo.loadQuestions();
  }
}

class FlagsContinentFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setFilter(String? continent) => state = continent;
}
final flagsContinentFilterProvider = NotifierProvider<FlagsContinentFilterNotifier, String?>(FlagsContinentFilterNotifier.new);

class FlagsDifficultyNotifier extends Notifier<QuizDifficulty> {
  @override
  QuizDifficulty build() => QuizDifficulty.medium;
  void set(QuizDifficulty d) => state = d;
}

final flagsDifficultyProvider =
    NotifierProvider<FlagsDifficultyNotifier, QuizDifficulty>(
  FlagsDifficultyNotifier.new,
  name: 'flagsDifficultyProvider',
);

final flagsQuizProvider =
    AsyncNotifierProvider<FlagsQuizNotifier, QuizSessionState>(
  FlagsQuizNotifier.new,
  name: 'flagsQuizProvider',
);

class FlagsQuizNotifier extends AsyncNotifier<QuizSessionState> {
  @override
  Future<QuizSessionState> build() async {
    final questions = await ref.watch(flagsQuestionsProvider.future);
    final continent = ref.watch(flagsContinentFilterProvider);

    var filtered = questions;
    if (continent != null) {
      filtered = questions.where((q) => q.category == continent).toList();
    }

    final diff = ref.watch(flagsDifficultyProvider);
    if (diff != QuizDifficulty.hard) {
      final minQ = 8.clamp(1, filtered.length);
      final cap = ((filtered.length * diff.poolFraction).ceil())
          .clamp(minQ, filtered.length);
      filtered = filtered.take(cap).toList();
    }

    final arm = ref.read(recapArmProvider);
    if (arm != null &&
        arm.module == RecapModule.flags &&
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
    state = AsyncData(session.copyWith(
      score: isCorrect ? session.score + 1 : session.score,
      livesRemaining: nextLives,
      lastAnswerCorrect: isCorrect,
    ));
    return isCorrect;
  }

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
