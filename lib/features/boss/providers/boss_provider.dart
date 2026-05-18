import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/agents/event_bus.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/general_quiz_pool_provider.dart';
import 'package:aziz_academy/core/providers/iq_pool_provider.dart';
import 'package:aziz_academy/core/providers/sciences_pool_provider.dart';

/// Boss Round: 5 difficulty=3 questions, 1 life, victory triples coin payout.
@immutable
class BossState {
  const BossState({
    required this.questions,
    required this.currentIndex,
    required this.score,
    required this.status,
    this.lastAnswerCorrect,
  });

  final List<QuizQuestion> questions;
  final int currentIndex;
  final int score;
  final BossStatus status;
  final bool? lastAnswerCorrect;

  QuizQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;
  bool get isReady => status == BossStatus.ready;
  bool get isInProgress => status == BossStatus.inProgress;
  bool get isWin => status == BossStatus.win;
  bool get isLoss => status == BossStatus.loss;
  int get totalQuestions => questions.length;

  BossState copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? score,
    BossStatus? status,
    bool? lastAnswerCorrect,
    bool clearLastAnswer = false,
  }) => BossState(
    questions: questions ?? this.questions,
    currentIndex: currentIndex ?? this.currentIndex,
    score: score ?? this.score,
    status: status ?? this.status,
    lastAnswerCorrect: clearLastAnswer
        ? null
        : (lastAnswerCorrect ?? this.lastAnswerCorrect),
  );
}

enum BossStatus { ready, inProgress, win, loss }

const int _bossQuestionCount = 5;

final bossProvider = NotifierProvider<BossNotifier, BossState>(
  BossNotifier.new,
);

class BossNotifier extends Notifier<BossState> {
  @override
  BossState build() {
    return const BossState(
      questions: [],
      currentIndex: 0,
      score: 0,
      status: BossStatus.ready,
    );
  }

  Future<void> start() async {
    final isArabic = ref.read(localeProvider).value?.languageCode == 'ar';
    final pool = <QuizQuestion>[];

    try {
      final sciences = await ref.read(sciencesPoolProvider.future);
      pool.addAll(
        sciences
            .where((e) => e.difficulty >= 3)
            .map((e) => e.toQuizQuestion(arabic: isArabic)),
      );
    } catch (_) {
      /* skip */
    }

    try {
      final iq = await ref.read(iqPoolProvider.future);
      pool.addAll(
        iq
            .where((e) => e.difficulty >= 3)
            .map((e) => e.toQuizQuestion(arabic: isArabic)),
      );
    } catch (_) {
      /* skip */
    }

    try {
      // Use the session-cached pool — boss + general quiz + worksheet all
      // call into the same in-memory list, so the 31-pack merge happens
      // once per session, not once per entry.
      final gq = await ref.read(generalQuizPoolProvider.future);
      pool.addAll(
        gq
            .where((e) => e.difficulty >= 3)
            .map((e) => e.toQuizQuestion(arabic: isArabic)),
      );
    } catch (_) {
      /* skip */
    }

    pool.shuffle(math.Random());
    final picked = pool.take(_bossQuestionCount).toList();

    state = BossState(
      questions: picked,
      currentIndex: 0,
      score: 0,
      status: BossStatus.inProgress,
    );
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.sessionStarted,
        module: 'boss',
        timestamp: DateTime.now(),
      ),
    );
    _lastQuestionStartedAt = DateTime.now();
  }

  DateTime? _lastQuestionStartedAt;

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
        module: 'boss',
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
          module: 'boss',
          timestamp: DateTime.now(),
          score: state.score,
        ),
      );
      state = state.copyWith(status: BossStatus.loss, lastAnswerCorrect: false);
      return false;
    }
    state = state.copyWith(score: state.score + 1, lastAnswerCorrect: true);
    return true;
  }

  void next() {
    if (!state.isInProgress) return;
    final nextIdx = state.currentIndex + 1;
    if (nextIdx >= state.questions.length) {
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.sessionEnded,
          module: 'boss',
          timestamp: DateTime.now(),
          score: state.score,
        ),
      );
      state = state.copyWith(status: BossStatus.win, clearLastAnswer: true);
    } else {
      _lastQuestionStartedAt = DateTime.now();
      state = state.copyWith(currentIndex: nextIdx, clearLastAnswer: true);
    }
  }

  void resetToReady() {
    state = const BossState(
      questions: [],
      currentIndex: 0,
      score: 0,
      status: BossStatus.ready,
    );
  }
}
