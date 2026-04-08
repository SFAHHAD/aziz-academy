import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/core/models/quiz_difficulty.dart';
import 'package:aziz_academy/core/models/recap_module.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/recap_arm_provider.dart';

enum MathOperation { addition, subtraction, multiplication, division }

class MathOperationFilterNotifier extends Notifier<MathOperation?> {
  @override
  MathOperation? build() => null;
  void setFilter(MathOperation? op) => state = op;
}
final mathOperationProvider = NotifierProvider<MathOperationFilterNotifier, MathOperation?>(MathOperationFilterNotifier.new);

class MathDifficultyNotifier extends Notifier<QuizDifficulty> {
  @override
  QuizDifficulty build() => QuizDifficulty.medium;
  void set(QuizDifficulty d) => state = d;
}

final mathDifficultyProvider =
    NotifierProvider<MathDifficultyNotifier, QuizDifficulty>(
  MathDifficultyNotifier.new,
  name: 'mathDifficultyProvider',
);

final mathQuizProvider =
    AsyncNotifierProvider<MathQuizNotifier, QuizSessionState>(
  MathQuizNotifier.new,
  name: 'mathQuizProvider',
);

class MathQuizNotifier extends AsyncNotifier<QuizSessionState> {
  @override
  Future<QuizSessionState> build() async {
    final arm = ref.read(recapArmProvider);
    if (arm != null &&
        arm.module == RecapModule.math &&
        arm.entries.isNotEmpty) {
      final questions = <QuizQuestion>[];
      for (final e in arm.entries) {
        final raw = e.snapshotJson;
        if (raw == null) continue;
        try {
          questions.add(
            QuizQuestion.fromJson(
              Map<String, dynamic>.from(jsonDecode(raw) as Map),
            ),
          );
        } catch (_) {}
      }
      Future.microtask(() => ref.read(recapArmProvider.notifier).clear());
      if (questions.isEmpty) {
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

    final operation = ref.watch(mathOperationProvider);
    final diff = ref.watch(mathDifficultyProvider);
    final count =
        diff == QuizDifficulty.easy ? 5 : (diff == QuizDifficulty.medium ? 10 : 15);
    final questions = _generateQuestions(operation, count: count, difficulty: diff);

    return QuizSessionState(
      questions: questions,
      currentIndex: 0,
      score: 0,
      livesRemaining: 3,
      status: QuizStatus.inProgress,
    );
  }

  List<QuizQuestion> _generateQuestions(MathOperation? opFilter, {required int count, QuizDifficulty difficulty = QuizDifficulty.medium}) {
    final random = math.Random();
    List<QuizQuestion> generated = [];

    // Number ranges per difficulty
    final addMax  = difficulty == QuizDifficulty.easy ? 10 : (difficulty == QuizDifficulty.medium ? 40 : 99);
    final mulMax  = difficulty == QuizDifficulty.easy ? 5  : (difficulty == QuizDifficulty.medium ? 10 : 15);

    for (var i = 0; i < count; i++) {
      final op = opFilter ?? MathOperation.values[random.nextInt(MathOperation.values.length)];
      int a, b, answer;
      String operatorStr;

      switch (op) {
        case MathOperation.addition:
          a = random.nextInt(addMax) + 1;
          b = random.nextInt(addMax) + 1;
          answer = a + b;
          operatorStr = '+';
          break;
        case MathOperation.subtraction:
          a = random.nextInt(addMax) + addMax ~/ 2;
          b = random.nextInt(a - 1).clamp(1, a - 1);
          answer = a - b;
          operatorStr = '-';
          break;
        case MathOperation.multiplication:
          a = random.nextInt(mulMax) + 2;
          b = random.nextInt(mulMax) + 2;
          answer = a * b;
          operatorStr = '×';
          break;
        case MathOperation.division:
          b = random.nextInt(mulMax) + 2;
          answer = random.nextInt(mulMax) + 2;
          a = b * answer;
          operatorStr = '÷';
          break;
      }

      // Generate 3 plausible fake options
      Set<int> wrongOptions = {};
      while (wrongOptions.length < 3) {
        // Generate a number close to the answer
        int offset = random.nextInt(10) - 5;
        if (offset == 0) offset = 2; // avoid picking correct answer
        int fake = answer + offset;
        if (fake >= 0 && fake != answer) {
          wrongOptions.add(fake);
        }
      }

      final allOptions = [...wrongOptions.map((e) => e.toString()), answer.toString()]..shuffle(random);

      String categoryStr = _getOpCategoryStr(op);

      generated.add(
        QuizQuestion(
          id: 'math_${op.name}_$i',
          question: '$a $operatorStr $b = ؟',
          options: allOptions,
          correctAnswer: answer.toString(),
          category: categoryStr,
          funFact: 'عمل رائع! الإجابة الصحيحة هي $answer.',
        ),
      );
    }
    return generated;
  }

  String _getOpCategoryStr(MathOperation op) {
    switch (op) {
      case MathOperation.addition: return 'الجمع';
      case MathOperation.subtraction: return 'الطرح';
      case MathOperation.multiplication: return 'الضرب';
      case MathOperation.division: return 'القسمة';
    }
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
    final operation = ref.read(mathOperationProvider);
    final diff = ref.read(mathDifficultyProvider);
    final count = diff == QuizDifficulty.easy ? 5 : (diff == QuizDifficulty.medium ? 10 : 15);
    final newQuestions = _generateQuestions(operation, count: count, difficulty: diff);
    
    state = AsyncData(QuizSessionState(
      questions: newQuestions,
      currentIndex: 0,
      score: 0,
      livesRemaining: 3,
      status: QuizStatus.inProgress,
    ));
  }
}
