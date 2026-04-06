import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';

enum MathOperation { addition, subtraction, multiplication, division }

class MathOperationFilterNotifier extends Notifier<MathOperation?> {
  @override
  MathOperation? build() => null;
  void setFilter(MathOperation? op) => state = op;
}
final mathOperationProvider = NotifierProvider<MathOperationFilterNotifier, MathOperation?>(MathOperationFilterNotifier.new);

final mathQuizProvider =
    AsyncNotifierProvider<MathQuizNotifier, QuizSessionState>(
  MathQuizNotifier.new,
  name: 'mathQuizProvider',
);

class MathQuizNotifier extends AsyncNotifier<QuizSessionState> {
  @override
  Future<QuizSessionState> build() async {
    final operation = ref.watch(mathOperationProvider);
    final questions = _generateQuestions(operation, count: 10);

    return QuizSessionState(
      questions: questions,
      currentIndex: 0,
      score: 0,
      livesRemaining: 3,
      status: QuizStatus.inProgress,
    );
  }

  List<QuizQuestion> _generateQuestions(MathOperation? opFilter, {required int count}) {
    final random = math.Random();
    List<QuizQuestion> generated = [];

    for (var i = 0; i < count; i++) {
      final op = opFilter ?? MathOperation.values[random.nextInt(MathOperation.values.length)];
      int a, b, answer;
      String operatorStr;

      switch (op) {
        case MathOperation.addition:
          a = random.nextInt(40) + 1; // 1 to 40
          b = random.nextInt(40) + 1; // 1 to 40
          answer = a + b;
          operatorStr = '+';
          break;
        case MathOperation.subtraction:
          a = random.nextInt(50) + 10; // 10 to 59
          b = random.nextInt(a - 1) + 1; // 1 to a-1
          answer = a - b;
          operatorStr = '-';
          break;
        case MathOperation.multiplication:
          a = random.nextInt(10) + 2; // 2 to 11
          b = random.nextInt(10) + 2; // 2 to 11
          answer = a * b;
          operatorStr = '×';
          break;
        case MathOperation.division:
          b = random.nextInt(10) + 2; // 2 to 11
          answer = random.nextInt(10) + 2; // 2 to 11 (the result)
          a = b * answer; // a is always divisible by b
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
    state = AsyncData(session.copyWith(
      score: isCorrect ? session.score + 1 : session.score,
      livesRemaining:
          isCorrect ? session.livesRemaining : session.livesRemaining - 1,
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
    // Math dynamically generates NEW questions on restart for endless replayability!
    final operation = ref.read(mathOperationProvider);
    final newQuestions = _generateQuestions(operation, count: 10);
    
    state = AsyncData(QuizSessionState(
      questions: newQuestions,
      currentIndex: 0,
      score: 0,
      livesRemaining: 3,
      status: QuizStatus.inProgress,
    ));
  }
}
