import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/agents/event_bus.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/features/capitals/providers/capitals_provider.dart';
import 'package:aziz_academy/features/sciences/providers/sciences_quiz_provider.dart';
import 'package:aziz_academy/features/iq/providers/iq_quiz_provider.dart';
import 'package:aziz_academy/features/general_quiz/providers/general_quiz_provider.dart';

/// Blitz mode: 60-second rapid-fire quiz mixing Capitals + Sciences + IQ +
/// General Knowledge. Score == correct answers within the window. Wrong
/// answers do NOT end the round; the goal is volume + accuracy under time
/// pressure.
@immutable
class BlitzState {
  const BlitzState({
    required this.questions,
    required this.currentIndex,
    required this.score,
    required this.streak,
    required this.bestStreak,
    required this.secondsLeft,
    required this.status,
    this.lastAnswerCorrect,
  });

  final List<QuizQuestion> questions;
  final int currentIndex;
  final int score;
  final int streak;
  final int bestStreak;
  final int secondsLeft;
  final BlitzStatus status;
  final bool? lastAnswerCorrect;

  QuizQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  bool get isComplete => status == BlitzStatus.complete;
  bool get isReady => status == BlitzStatus.ready;
  bool get isInProgress => status == BlitzStatus.inProgress;

  BlitzState copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? score,
    int? streak,
    int? bestStreak,
    int? secondsLeft,
    BlitzStatus? status,
    bool? lastAnswerCorrect,
    bool clearLastAnswer = false,
  }) {
    return BlitzState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      status: status ?? this.status,
      lastAnswerCorrect: clearLastAnswer
          ? null
          : (lastAnswerCorrect ?? this.lastAnswerCorrect),
    );
  }
}

enum BlitzStatus { ready, inProgress, complete }

const int _blitzDurationSeconds = 60;
const int _blitzPoolSize = 200;
const String _highScoreKey = 'blitz_high_score';

final blitzHighScoreProvider =
    AsyncNotifierProvider<BlitzHighScoreNotifier, int>(
      BlitzHighScoreNotifier.new,
      name: 'blitzHighScoreProvider',
    );

class BlitzHighScoreNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_highScoreKey) ?? 0;
  }

  Future<void> recordScore(int score) async {
    final current = state.value ?? 0;
    if (score <= current) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_highScoreKey, score);
    state = AsyncData(score);
  }
}

final blitzProvider = NotifierProvider<BlitzNotifier, BlitzState>(
  BlitzNotifier.new,
  name: 'blitzProvider',
);

class BlitzNotifier extends Notifier<BlitzState> {
  @override
  BlitzState build() {
    return const BlitzState(
      questions: [],
      currentIndex: 0,
      score: 0,
      streak: 0,
      bestStreak: 0,
      secondsLeft: _blitzDurationSeconds,
      status: BlitzStatus.ready,
    );
  }

  /// Pulls questions from every text-based module, shuffles, and seeds the
  /// session. Logos and Maps are skipped because their answers depend on
  /// visual cues the blitz UI doesn't render.
  void start() {
    final pool = <QuizQuestion>[];

    void addFromAsync(AsyncValue<List<QuizQuestion>> async) {
      async.whenData(pool.addAll);
    }

    addFromAsync(ref.read(capitalsQuestionsProvider));
    addFromAsync(ref.read(sciencesQuestionsProvider));
    addFromAsync(ref.read(iqQuestionsProvider));
    addFromAsync(ref.read(generalQuizQuestionsProvider));

    pool.shuffle(math.Random());
    final picked = pool.take(_blitzPoolSize).toList();

    state = BlitzState(
      questions: picked,
      currentIndex: 0,
      score: 0,
      streak: 0,
      bestStreak: 0,
      secondsLeft: _blitzDurationSeconds,
      status: BlitzStatus.inProgress,
    );
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.sessionStarted,
        module: 'blitz',
        timestamp: DateTime.now(),
      ),
    );
    _lastQuestionStartedAt = DateTime.now();
  }

  DateTime? _lastQuestionStartedAt;

  bool submitAnswer(String answer) {
    final s = state;
    final q = s.currentQuestion;
    if (q == null || s.isComplete) return false;
    final correct = answer.trim() == q.correctAnswer.trim();
    final newStreak = correct ? s.streak + 1 : 0;

    final lat = _lastQuestionStartedAt == null
        ? 0
        : DateTime.now().difference(_lastQuestionStartedAt!).inMilliseconds;
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.questionAnswered,
        module: 'blitz',
        timestamp: DateTime.now(),
        questionId: q.id,
        category: q.category,
        correct: correct,
        latencyMs: lat,
      ),
    );

    state = s.copyWith(
      score: correct ? s.score + 1 : s.score,
      streak: newStreak,
      bestStreak: newStreak > s.bestStreak ? newStreak : s.bestStreak,
      lastAnswerCorrect: correct,
    );
    return correct;
  }

  void next() {
    final s = state;
    if (s.isComplete) return;
    final nextIdx = s.currentIndex + 1;
    if (nextIdx >= s.questions.length) {
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.sessionEnded,
          module: 'blitz',
          timestamp: DateTime.now(),
          score: s.score,
        ),
      );
      state = s.copyWith(status: BlitzStatus.complete, clearLastAnswer: true);
    } else {
      _lastQuestionStartedAt = DateTime.now();
      state = s.copyWith(currentIndex: nextIdx, clearLastAnswer: true);
    }
  }

  void tick() {
    final s = state;
    if (!s.isInProgress) return;
    final remaining = s.secondsLeft - 1;
    if (remaining <= 0) {
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.sessionEnded,
          module: 'blitz',
          timestamp: DateTime.now(),
          score: s.score,
        ),
      );
      state = s.copyWith(secondsLeft: 0, status: BlitzStatus.complete);
    } else {
      state = s.copyWith(secondsLeft: remaining);
    }
  }

  void resetToReady() {
    state = const BlitzState(
      questions: [],
      currentIndex: 0,
      score: 0,
      streak: 0,
      bestStreak: 0,
      secondsLeft: _blitzDurationSeconds,
      status: BlitzStatus.ready,
    );
  }
}
