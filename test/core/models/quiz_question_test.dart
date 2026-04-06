import 'package:flutter_test/flutter_test.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';

void main() {
  group('QuizQuestion', () {
    const sampleQuestion = QuizQuestion(
      id: 'test_1',
      question: 'What is the capital of France? 🇫🇷',
      options: ['Paris', 'Lyon', 'Marseille', 'Nice'],
      correctAnswer: 'Paris',
      category: 'Europe',
      funFact: 'The Eiffel Tower was built for the 1889 World\'s Fair.',
    );

    test('fromJson parses all required fields correctly', () {
      final json = {
        'id': 'fr',
        'question': 'What is the capital of France? 🇫🇷',
        'options': ['Paris', 'Lyon', 'Marseille', 'Nice'],
        'correct_answer': 'Paris',
        'category': 'Europe',
        'fun_fact': 'The Eiffel Tower was built for the 1889 World\'s Fair.',
        'image_url': null,
      };

      final question = QuizQuestion.fromJson(json);

      expect(question.id, 'fr');
      expect(question.question, contains('France'));
      expect(question.options, hasLength(4));
      expect(question.correctAnswer, 'Paris');
      expect(question.category, 'Europe');
      expect(question.imageUrl, isNull);
    });

    test('fromJson parses optional imageUrl when present', () {
      final json = {
        'id': 'test',
        'question': 'Question?',
        'options': ['A', 'B'],
        'correct_answer': 'A',
        'category': 'Test',
        'fun_fact': 'Cool fact.',
        'image_url': 'assets/images/test.png',
      };

      final question = QuizQuestion.fromJson(json);
      expect(question.imageUrl, 'assets/images/test.png');
    });

    test('toJson round-trips correctly', () {
      final json = sampleQuestion.toJson();
      final restored = QuizQuestion.fromJson(json);

      expect(restored.id, sampleQuestion.id);
      expect(restored.correctAnswer, sampleQuestion.correctAnswer);
      expect(restored.options, sampleQuestion.options);
    });

    test('equality is based on id only', () {
      const q1 = QuizQuestion(
        id: 'same',
        question: 'Q1?',
        options: ['A', 'B'],
        correctAnswer: 'A',
        category: 'C',
        funFact: 'F',
      );
      const q2 = QuizQuestion(
        id: 'same',
        question: 'Different question text',
        options: ['X', 'Y'],
        correctAnswer: 'X',
        category: 'D',
        funFact: 'G',
      );

      expect(q1, equals(q2));
      expect(q1.hashCode, equals(q2.hashCode));
    });

    test('copyWith preserves unchanged fields', () {
      final updated = sampleQuestion.copyWith(correctAnswer: 'Lyon');
      expect(updated.id, sampleQuestion.id);
      expect(updated.question, sampleQuestion.question);
      expect(updated.correctAnswer, 'Lyon');
    });

    test('assert fires in fromJson when fewer than 2 options are provided', () {
      expect(
        () => QuizQuestion.fromJson({
          'id': 'bad',
          'question': 'Only one option?',
          'options': ['Solo'],
          'correct_answer': 'Solo',
          'category': 'Test',
          'fun_fact': 'This should fail.',
          'image_url': null,
        }),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
