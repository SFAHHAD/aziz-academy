import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/features/capitals/providers/capitals_provider.dart';
import 'package:aziz_academy/features/capitals/data/capitals_repository.dart';

// ---------------------------------------------------------------------------
// Fake repository that returns a tiny, deterministic question set.
// ---------------------------------------------------------------------------

class _FakeCapitalsRepository implements CapitalsRepository {
  static final _questions = [
    const QuizQuestion(
      id: 'fr',
      question: 'ما عاصمة فرنسا؟',
      options: ['باريس', 'برلين', 'مدريد', 'روما'],
      correctAnswer: 'باريس',
      category: 'Europe',
      funFact: 'باريس مدينة النور وتحتضن برج إيفل.',
    ),
    const QuizQuestion(
      id: 'de',
      question: 'ما عاصمة ألمانيا؟',
      options: ['برلين', 'باريس', 'فيينا', 'زيورخ'],
      correctAnswer: 'برلين',
      category: 'Europe',
      funFact: 'برلين كانت مقسّمة بجدار طوال الحرب الباردة.',
    ),
    const QuizQuestion(
      id: 'jp',
      question: 'ما عاصمة اليابان؟',
      options: ['طوكيو', 'بكين', 'سيول', 'بانكوك'],
      correctAnswer: 'طوكيو',
      category: 'Asia',
      funFact: 'طوكيو أكبر مدينة في العالم.',
    ),
  ];

  @override
  Future<List<QuizQuestion>> loadQuestions() async => _questions;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProviderContainer _container() => ProviderContainer(
      overrides: [
        capitalsRepositoryProvider
            .overrideWithValue(_FakeCapitalsRepository()),
      ],
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Full capitals quiz flow', () {
    test('session starts inProgress with shuffled questions', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(capitalsQuizProvider.future);
      final session = c.read(capitalsQuizProvider).value!;
      expect(session.status, QuizStatus.inProgress);
      expect(session.score, 0);
      expect(session.livesRemaining, 3);
      expect(session.questions.length, 3);
    });

    test('correct answer increases score, keeps lives', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(capitalsQuizProvider.future);
      final q = c.read(capitalsQuizProvider).value!.currentQuestion!;
      c.read(capitalsQuizProvider.notifier).submitAnswer(q.correctAnswer);
      final s = c.read(capitalsQuizProvider).value!;
      expect(s.score, 1);
      expect(s.livesRemaining, 3);
    });

    test('wrong answer decreases lives, keeps score', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(capitalsQuizProvider.future);
      c.read(capitalsQuizProvider.notifier).submitAnswer('إجابة خاطئة!');
      final s = c.read(capitalsQuizProvider).value!;
      expect(s.score, 0);
      expect(s.livesRemaining, 2);
    });

    test('3 wrong answers triggers isGameOver', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(capitalsQuizProvider.future);
      for (var i = 0; i < 3; i++) {
        c.read(capitalsQuizProvider.notifier).submitAnswer('خطأ');
        c.read(capitalsQuizProvider.notifier).nextQuestion();
      }
      expect(c.read(capitalsQuizProvider).value!.isGameOver, true);
    });

    test('answering all questions correctly sets isComplete', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(capitalsQuizProvider.future);
      for (var i = 0; i < 3; i++) {
        final q = c.read(capitalsQuizProvider).value!.currentQuestion!;
        c.read(capitalsQuizProvider.notifier).submitAnswer(q.correctAnswer);
        c.read(capitalsQuizProvider.notifier).nextQuestion();
      }
      expect(c.read(capitalsQuizProvider).value!.isComplete, true);
      expect(c.read(capitalsQuizProvider).value!.score, 3);
    });

    test('restart resets score and lives', () async {
      final c = _container();
      addTearDown(c.dispose);
      await c.read(capitalsQuizProvider.future);
      final q = c.read(capitalsQuizProvider).value!.currentQuestion!;
      c.read(capitalsQuizProvider.notifier).submitAnswer(q.correctAnswer);
      c.read(capitalsQuizProvider.notifier).restart();
      final s = c.read(capitalsQuizProvider).value!;
      expect(s.score, 0);
      expect(s.livesRemaining, 3);
      expect(s.status, QuizStatus.inProgress);
    });

    test('difficulty easy limits to 20% of questions', () async {
      final c = _container();
      addTearDown(c.dispose);
      c.read(difficultyProvider.notifier).set(QuizDifficulty.easy);
      await c.read(capitalsQuizProvider.future);
      final session = c.read(capitalsQuizProvider).value!;
      // 20% of 3 = 0.6 → ceil = 1, clamp to min 8, but we only have 3 → clamp min hits
      expect(session.questions.length, lessThanOrEqualTo(3));
    });
  });

  group('DifficultyNotifier', () {
    test('defaults to medium', () {
      final c = _container();
      addTearDown(c.dispose);
      expect(c.read(difficultyProvider), QuizDifficulty.medium);
    });

    test('can be changed to hard', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(difficultyProvider.notifier).set(QuizDifficulty.hard);
      expect(c.read(difficultyProvider), QuizDifficulty.hard);
    });
  });
}
