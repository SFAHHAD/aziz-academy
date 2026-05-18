import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/models/recap_module.dart';
import 'package:aziz_academy/core/providers/recap_queue_provider.dart';
import 'package:aziz_academy/features/capitals/data/capitals_repository.dart';
import 'package:aziz_academy/features/flags/data/flags_repository.dart';
import 'package:aziz_academy/features/sciences/data/sciences_repository.dart';

// =============================================================================
// Models
// =============================================================================

class ReviewItem {
  const ReviewItem({required this.question, required this.entry});

  final QuizQuestion question;
  final RecapEntry entry;
}

enum ReviewStatus { inProgress, complete }

class ReviewSessionState {
  const ReviewSessionState({
    required this.items,
    this.currentIndex = 0,
    this.correctCount = 0,
    this.masteredCount = 0,
    this.status = ReviewStatus.inProgress,
    this.lastAnswerCorrect,
  });

  final List<ReviewItem> items;
  final int currentIndex;
  final int correctCount;

  /// Questions fully removed from the queue during this session.
  final int masteredCount;

  final ReviewStatus status;
  final bool? lastAnswerCorrect;

  int get totalItems => items.length;
  bool get isEmpty => items.isEmpty;
  bool get isComplete =>
      status == ReviewStatus.complete || currentIndex >= totalItems;
  double get progress =>
      totalItems == 0 ? 0 : currentIndex / totalItems;

  ReviewItem? get currentItem =>
      !isComplete && currentIndex < items.length
          ? items[currentIndex]
          : null;

  ReviewSessionState copyWith({
    int? currentIndex,
    int? correctCount,
    int? masteredCount,
    ReviewStatus? status,
    bool? lastAnswerCorrect,
    bool clearLastAnswer = false,
  }) {
    return ReviewSessionState(
      items: items,
      currentIndex: currentIndex ?? this.currentIndex,
      correctCount: correctCount ?? this.correctCount,
      masteredCount: masteredCount ?? this.masteredCount,
      status: status ?? this.status,
      lastAnswerCorrect:
          clearLastAnswer ? null : (lastAnswerCorrect ?? this.lastAnswerCorrect),
    );
  }
}

// =============================================================================
// Provider
// =============================================================================

final reviewModeProvider =
    AsyncNotifierProvider<ReviewModeNotifier, ReviewSessionState>(
  ReviewModeNotifier.new,
  name: 'reviewModeProvider',
);

class ReviewModeNotifier extends AsyncNotifier<ReviewSessionState> {
  @override
  Future<ReviewSessionState> build() async {
    final queue = await ref.watch(recapQueueProvider.future);
    if (queue.isEmpty) {
      return const ReviewSessionState(items: []);
    }

    // Sort: due items first, then by missCount descending (highest priority first).
    final sorted = [...queue]..sort((a, b) {
        final aDue = a.isDueForReview ? 1 : 0;
        final bDue = b.isDueForReview ? 1 : 0;
        if (aDue != bDue) return bDue - aDue;
        return b.missCount.compareTo(a.missCount);
      });

    // Load question objects for each entry.
    final items = <ReviewItem>[];
    for (final entry in sorted) {
      final q = await _loadQuestion(entry);
      if (q != null) items.add(ReviewItem(question: q, entry: entry));
    }

    return ReviewSessionState(items: items);
  }

  // ---------------------------------------------------------------------------
  // Question loading
  // ---------------------------------------------------------------------------

  Future<QuizQuestion?> _loadQuestion(RecapEntry entry) async {
    try {
      switch (entry.module) {
        case RecapModule.math:
          final snap = entry.snapshotJson;
          if (snap == null) return null;
          return QuizQuestion.fromJson(
            Map<String, dynamic>.from(jsonDecode(snap) as Map),
          );
        case RecapModule.capitals:
        case RecapModule.maps:
          final all = await const CapitalsRepository().loadQuestions();
          return _findById(all, entry.questionId);
        case RecapModule.flags:
          final all = await const FlagsRepository().loadQuestions();
          return _findById(all, entry.questionId);
        case RecapModule.sciences:
          final all = await const SciencesRepository().loadQuestions();
          return _findById(all, entry.questionId);
      }
    } catch (_) {
      return null;
    }
  }

  static QuizQuestion? _findById(List<QuizQuestion> list, String id) {
    for (final q in list) {
      if (q.id == id) return q;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Game actions
  // ---------------------------------------------------------------------------

  /// Submits an answer and returns whether it was correct.
  bool answer(String choice) {
    final s = state.value;
    if (s == null || s.isComplete) return false;
    final item = s.currentItem;
    if (item == null) return false;

    final correct = choice == item.question.correctAnswer;
    final newIndex = s.currentIndex + 1;
    final isDone = newIndex >= s.totalItems;

    state = AsyncData(s.copyWith(
      currentIndex: newIndex,
      correctCount: correct ? s.correctCount + 1 : s.correctCount,
      status: isDone ? ReviewStatus.complete : ReviewStatus.inProgress,
      lastAnswerCorrect: correct,
    ));

    return correct;
  }

  /// Persists the SRS outcome for a committed answer (called after delay).
  Future<void> commitAnswer(RecapEntry entry, bool correct) async {
    final notifier = ref.read(recapQueueProvider.notifier);
    if (correct) {
      await notifier.markCorrect(entry.module, entry.questionId);
      // Track mastered count in local state
      final s = state.value;
      if (s != null) {
        state = AsyncData(
          s.copyWith(masteredCount: s.masteredCount + 1),
        );
      }
    } else {
      await notifier.recordWrong(
        entry.module,
        entry.questionId,
        snapshotJson: entry.snapshotJson,
      );
    }
  }

  /// Rebuilds the session from the current queue (after completion).
  Future<void> restart() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}
