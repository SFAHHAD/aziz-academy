import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/core/agents/event_bus.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/core/models/recap_module.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/recap_arm_provider.dart';
import 'package:aziz_academy/features/maps/data/maps_repository.dart';

final mapsQuizProvider =
    AsyncNotifierProvider<MapsQuizNotifier, QuizSessionState>(
      MapsQuizNotifier.new,
      name: 'mapsQuizProvider',
    );

class MapsQuizNotifier extends AsyncNotifier<QuizSessionState> {
  static const _repo = MapsRepository();

  @override
  Future<QuizSessionState> build() async {
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    var questions = await _repo.loadQuestions(arabic: isArabic);

    final arm = ref.read(recapArmProvider);
    if (arm != null &&
        arm.module == RecapModule.maps &&
        arm.entries.isNotEmpty) {
      final idSet = arm.ids.toSet();
      questions = questions.where((q) => idSet.contains(q.id)).toList()
        ..shuffle();
      Future.microtask(() => ref.read(recapArmProvider.notifier).clear());
    } else {
      questions.shuffle();
    }

    if (questions.isEmpty) {
      return QuizSessionState(
        questions: const [],
        currentIndex: 0,
        score: 0,
        livesRemaining: 3,
        status: QuizStatus.complete,
      );
    }

    final out = QuizSessionState(
      questions: questions,
      currentIndex: 0,
      score: 0,
      livesRemaining: 3,
      status: QuizStatus.inProgress,
    );
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.sessionStarted,
        module: 'maps',
        timestamp: DateTime.now(),
      ),
    );
    _lastQuestionStartedAt = DateTime.now();
    return out;
  }

  DateTime? _lastQuestionStartedAt;

  void submitAnswer(String answer) {
    if (!state.hasValue) return;
    final currentState = state.value!;
    if (currentState.status != QuizStatus.inProgress) return;

    final q = currentState.currentQuestion;
    final isCorrect = (q?.correctAnswer == answer);

    final newScore = isCorrect ? currentState.score + 1 : currentState.score;
    final practice = readPracticeMode(ref);
    int newLives = currentState.livesRemaining;
    if (!isCorrect && !practice) newLives--;

    QuizStatus newStatus = currentState.status;
    if (newLives <= 0) {
      newStatus = QuizStatus.complete;
    } else if (currentState.currentIndex >= currentState.questions.length - 1) {
      newStatus = QuizStatus.complete;
    }

    final lat = _lastQuestionStartedAt == null
        ? 0
        : DateTime.now().difference(_lastQuestionStartedAt!).inMilliseconds;
    if (q != null) {
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.questionAnswered,
          module: 'maps',
          timestamp: DateTime.now(),
          questionId: q.id,
          category: q.category,
          correct: isCorrect,
          latencyMs: lat,
        ),
      );
    }

    if (newStatus == QuizStatus.complete &&
        currentState.status != QuizStatus.complete) {
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.sessionEnded,
          module: 'maps',
          timestamp: DateTime.now(),
          score: newScore,
        ),
      );
    }

    state = AsyncData(
      currentState.copyWith(
        score: newScore,
        livesRemaining: newLives,
        status: newStatus,
      ),
    );
  }

  void nextQuestion() {
    if (!state.hasValue) return;
    final currentState = state.value!;
    if (currentState.status == QuizStatus.complete) return;

    _lastQuestionStartedAt = DateTime.now();
    state = AsyncData(
      currentState.copyWith(currentIndex: currentState.currentIndex + 1),
    );
  }

  void reset() {
    state = const AsyncLoading();
    ref.invalidateSelf();
  }
}
