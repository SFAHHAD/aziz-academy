import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/agents/event_bus.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/features/capitals/providers/capitals_provider.dart';
import 'package:aziz_academy/features/general_quiz/providers/general_quiz_provider.dart';
import 'package:aziz_academy/features/iq/providers/iq_quiz_provider.dart';
import 'package:aziz_academy/features/sciences/providers/sciences_quiz_provider.dart';

/// Survival mode: one life, infinite questions, sudden-death. Score == correct
/// answers before the first miss. The streak doubles as the score multiplier.
@immutable
class SurvivalState {
  const SurvivalState({
    required this.questions,
    required this.currentIndex,
    required this.score,
    required this.status,
    this.lastAnswerCorrect,
  });

  final List<QuizQuestion> questions;
  final int currentIndex;
  final int score;
  final SurvivalStatus status;
  final bool? lastAnswerCorrect;

  QuizQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  bool get isReady => status == SurvivalStatus.ready;
  bool get isInProgress => status == SurvivalStatus.inProgress;
  bool get isGameOver => status == SurvivalStatus.gameOver;

  SurvivalState copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? score,
    SurvivalStatus? status,
    bool? lastAnswerCorrect,
    bool clearLastAnswer = false,
  }) {
    return SurvivalState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      status: status ?? this.status,
      lastAnswerCorrect: clearLastAnswer
          ? null
          : (lastAnswerCorrect ?? this.lastAnswerCorrect),
    );
  }
}

enum SurvivalStatus { ready, inProgress, gameOver }

const String _survivalHighScoreKey = 'survival_high_score_v1';

final survivalHighScoreProvider =
    AsyncNotifierProvider<SurvivalHighScoreNotifier, int>(
      SurvivalHighScoreNotifier.new,
    );

class SurvivalHighScoreNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_survivalHighScoreKey) ?? 0;
  }

  Future<void> recordScore(int score) async {
    final current = state.value ?? 0;
    if (score <= current) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_survivalHighScoreKey, score);
    state = AsyncData(score);
  }
}

final survivalProvider = NotifierProvider<SurvivalNotifier, SurvivalState>(
  SurvivalNotifier.new,
);

class SurvivalNotifier extends Notifier<SurvivalState> {
  @override
  SurvivalState build() {
    return const SurvivalState(
      questions: [],
      currentIndex: 0,
      score: 0,
      status: SurvivalStatus.ready,
    );
  }

  void start() {
    final pool = <QuizQuestion>[];
    void take(AsyncValue<List<QuizQuestion>> a) {
      a.whenData(pool.addAll);
    }

    take(ref.read(capitalsQuestionsProvider));
    take(ref.read(sciencesQuestionsProvider));
    take(ref.read(iqQuestionsProvider));
    take(ref.read(generalQuizQuestionsProvider));
    pool.shuffle(math.Random());

    state = SurvivalState(
      questions: pool,
      currentIndex: 0,
      score: 0,
      status: SurvivalStatus.inProgress,
    );
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.sessionStarted,
        module: 'survival',
        timestamp: DateTime.now(),
      ),
    );
    _lastQuestionStartedAt = DateTime.now();
  }

  DateTime? _lastQuestionStartedAt;

  /// Returns true on correct answer (advance), false on miss (game over).
  bool submitAnswer(String answer) {
    final q = state.currentQuestion;
    if (q == null || !state.isInProgress) return false;
    final correct = answer.trim() == q.correctAnswer.trim();

    final lat = _lastQuestionStartedAt == null
        ? 0
        : DateTime.now().difference(_lastQuestionStartedAt!).inMilliseconds;
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.questionAnswered,
        module: 'survival',
        timestamp: DateTime.now(),
        questionId: q.id,
        category: q.category,
        correct: correct,
        latencyMs: lat,
      ),
    );

    if (!correct) {
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.sessionEnded,
          module: 'survival',
          timestamp: DateTime.now(),
          score: state.score,
        ),
      );
      state = state.copyWith(
        status: SurvivalStatus.gameOver,
        lastAnswerCorrect: false,
      );
      return false;
    }
    state = state.copyWith(score: state.score + 1, lastAnswerCorrect: true);
    return true;
  }

  void next() {
    if (!state.isInProgress) return;
    final nextIdx = state.currentIndex + 1;
    if (nextIdx >= state.questions.length) {
      // Ran out of questions — also a "win", treat as game over but with full score.
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.sessionEnded,
          module: 'survival',
          timestamp: DateTime.now(),
          score: state.score,
        ),
      );
      state = state.copyWith(
        status: SurvivalStatus.gameOver,
        clearLastAnswer: true,
      );
    } else {
      _lastQuestionStartedAt = DateTime.now();
      state = state.copyWith(currentIndex: nextIdx, clearLastAnswer: true);
    }
  }

  void resetToReady() {
    state = const SurvivalState(
      questions: [],
      currentIndex: 0,
      score: 0,
      status: SurvivalStatus.ready,
    );
  }
}
