import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/features/capitals/providers/capitals_provider.dart';
import 'package:aziz_academy/features/capitals/data/capitals_repository.dart';

// ---------------------------------------------------------------------------
// Fake repository — returns a fixed list without touching the asset bundle.
// ---------------------------------------------------------------------------

class _FakeCapitalsRepository implements CapitalsRepository {
  static final _questions = [
    QuizQuestion(
      id: 'fr',
      question: 'What is the capital of France? 🇫🇷',
      options: ['Paris', 'Lyon', 'Marseille', 'Nice'],
      correctAnswer: 'Paris',
      category: 'Europe',
      funFact: "The Eiffel Tower was built for the 1889 World's Fair.",
    ),
    QuizQuestion(
      id: 'jp',
      question: 'What is the capital of Japan? 🇯🇵',
      options: ['Tokyo', 'Osaka', 'Kyoto', 'Hiroshima'],
      correctAnswer: 'Tokyo',
      category: 'Asia',
      funFact: "Tokyo is the world's most populous metropolitan area.",
    ),
    QuizQuestion(
      id: 'de',
      question: 'What is the capital of Germany? 🇩🇪',
      options: ['Berlin', 'Munich', 'Hamburg', 'Frankfurt'],
      correctAnswer: 'Berlin',
      category: 'Europe',
      funFact: 'Berlin has more bridges than Venice.',
    ),
  ];

  @override
  Future<List<QuizQuestion>> loadQuestions() async => List.of(_questions);
}

// ---------------------------------------------------------------------------
// Helper — creates a ProviderContainer with the fake repo injected.
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer() {
  return ProviderContainer(
    overrides: [
      capitalsRepositoryProvider
          .overrideWithValue(_FakeCapitalsRepository()),
    ],
  );
}

/// Awaits both async providers so tests start from a ready state.
Future<void> _waitForReady(ProviderContainer container) async {
  await container.read(capitalsQuestionsProvider.future);
  final session = await container.read(capitalsQuizProvider.future);
  // Sanity: session must be inProgress with 3 lives
  assert(session.status == QuizStatus.inProgress);
  assert(session.livesRemaining == 3);
}

void main() {
  group('capitalsQuestionsProvider', () {
    test('loads 3 questions from the fake repository', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(capitalsQuestionsProvider.future);

      expect(result, hasLength(3));
      expect(result.first.correctAnswer, isNotEmpty);
    });

    test('each question has at least 2 options', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final questions = await container.read(capitalsQuestionsProvider.future);

      for (final q in questions) {
        expect(q.options.length, greaterThanOrEqualTo(2));
      }
    });
  });

  group('capitalsQuizProvider — session state', () {
    test('resolves to inProgress once questions load', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await _waitForReady(container);

      final session = container.read(capitalsQuizProvider).value!;
      expect(session.status, QuizStatus.inProgress);
      expect(session.currentQuestion, isNotNull);
    });

    test('correct answer increments score', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await _waitForReady(container);

      final notifier = container.read(capitalsQuizProvider.notifier);
      final correctAnswer =
          container.read(capitalsQuizProvider).value!.currentQuestion!.correctAnswer;

      final wasCorrect = notifier.submitAnswer(correctAnswer);

      expect(wasCorrect, isTrue);
      expect(container.read(capitalsQuizProvider).value!.score, 1);
      expect(container.read(capitalsQuizProvider).value!.lastAnswerCorrect, isTrue);
    });

    test('wrong answer does not increment score', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await _waitForReady(container);

      final notifier = container.read(capitalsQuizProvider.notifier);
      final wasCorrect = notifier.submitAnswer('DEFINITELY_WRONG');

      expect(wasCorrect, isFalse);
      expect(container.read(capitalsQuizProvider).value!.score, 0);
      expect(container.read(capitalsQuizProvider).value!.lastAnswerCorrect, isFalse);
    });

    test('nextQuestion advances the index', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await _waitForReady(container);

      final notifier = container.read(capitalsQuizProvider.notifier);
      notifier.nextQuestion();

      expect(container.read(capitalsQuizProvider).value!.currentIndex, 1);
    });

    test('completing all questions sets status to complete', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await _waitForReady(container);

      final notifier = container.read(capitalsQuizProvider.notifier);

      // Advance through all 3 fake questions.
      notifier.nextQuestion();
      notifier.nextQuestion();
      notifier.nextQuestion();

      final session = container.read(capitalsQuizProvider).value!;
      expect(session.status, QuizStatus.complete);
      expect(session.isComplete, isTrue);
    });

    test('restart resets index and score to zero', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await _waitForReady(container);

      final notifier = container.read(capitalsQuizProvider.notifier);

      // Play a couple of questions with correct answers.
      final q1 = container
          .read(capitalsQuizProvider)
          .value!
          .currentQuestion!
          .correctAnswer;
      notifier.submitAnswer(q1);
      notifier.nextQuestion();

      notifier.restart();

      final session = container.read(capitalsQuizProvider).value!;
      expect(session.score, 0);
      expect(session.currentIndex, 0);
      expect(session.status, QuizStatus.inProgress);
    });

    test('progress returns correct fraction', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await _waitForReady(container);

      final notifier = container.read(capitalsQuizProvider.notifier);

      // 0 of 3 answered.
      expect(container.read(capitalsQuizProvider).value!.progress, 0.0);

      notifier.nextQuestion(); // 1 of 3
      expect(
        container.read(capitalsQuizProvider).value!.progress,
        closeTo(1 / 3, 0.001),
      );
    });

    test('submitAnswer returns false when session is not ready', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      // Don't await — questions not yet loaded.
      final notifier = container.read(capitalsQuizProvider.notifier);
      final result = notifier.submitAnswer('Paris');
      expect(result, isFalse);
    });
  });
}
