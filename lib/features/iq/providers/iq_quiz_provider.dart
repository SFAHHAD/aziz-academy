import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/core/agents/event_bus.dart';
import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/core/models/quiz_difficulty.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/iq_pool_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/features/iq/data/iq_repository.dart';

final iqRepositoryProvider = Provider<IqRepository>(
  (ref) => const IqRepository(),
  name: 'iqRepositoryProvider',
);

final iqEntriesProvider =
    AsyncNotifierProvider<IqEntriesNotifier, List<IqEntry>>(
      IqEntriesNotifier.new,
      name: 'iqEntriesProvider',
    );

class IqEntriesNotifier extends AsyncNotifier<List<IqEntry>> {
  @override
  Future<List<IqEntry>> build() async {
    // Read from session-cached pool — boss + iq quiz + brain boost daily +
    // brain boost champion + random quiz all share the same entries list.
    return ref.watch(iqPoolProvider.future);
  }
}

/// Bilingual question list — switches automatically with locale.
final iqQuestionsProvider = Provider<AsyncValue<List<QuizQuestion>>>((ref) {
  final entriesAsync = ref.watch(iqEntriesProvider);
  final localeAsync = ref.watch(localeProvider);
  final isArabic = localeAsync.value?.languageCode == 'ar';
  return entriesAsync.whenData(
    (entries) =>
        entries.map((e) => e.toQuizQuestion(arabic: isArabic)).toList(),
  );
}, name: 'iqQuestionsProvider');

class IqCategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setFilter(String? category) => state = category;
}

final iqCategoryFilterProvider =
    NotifierProvider<IqCategoryFilterNotifier, String?>(
      IqCategoryFilterNotifier.new,
    );

class IqDifficultyNotifier extends Notifier<QuizDifficulty> {
  @override
  QuizDifficulty build() => QuizDifficulty.medium;
  void set(QuizDifficulty d) => state = d;
}

final iqDifficultyProvider =
    NotifierProvider<IqDifficultyNotifier, QuizDifficulty>(
      IqDifficultyNotifier.new,
      name: 'iqDifficultyProvider',
    );

final iqQuizProvider = AsyncNotifierProvider<IqQuizNotifier, QuizSessionState>(
  IqQuizNotifier.new,
  name: 'iqQuizProvider',
);

/// Set of question IDs in the current session that came from the spaced
/// repetition prefix. The UI listens to this to show a "comeback" badge when
/// the kid answers one correctly.
final iqSessionRepeatIdsProvider =
    NotifierProvider<IqSessionRepeatIdsNotifier, Set<String>>(
      IqSessionRepeatIdsNotifier.new,
      name: 'iqSessionRepeatIdsProvider',
    );

class IqSessionRepeatIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};
  void setIds(Set<String> ids) => state = ids;
  void clear() => state = const <String>{};
}

class IqQuizNotifier extends AsyncNotifier<QuizSessionState> {
  @override
  Future<QuizSessionState> build() async {
    final entries = await ref.watch(iqEntriesProvider.future);
    final isArabic = ref.watch(localeProvider).value?.languageCode == 'ar';
    final adaptive =
        ref.watch(appSettingsProvider).value?.adaptiveDifficulty ?? true;
    final ordered = adaptive ? _adaptiveOrder(entries) : entries;
    final questions = ordered
        .map((e) => e.toQuizQuestion(arabic: isArabic))
        .toList();
    final out = _build(questions);
    if (out.status == QuizStatus.inProgress) {
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.sessionStarted,
          module: 'iq',
          timestamp: DateTime.now(),
        ),
      );
      _lastQuestionStartedAt = DateTime.now();
    }
    return out;
  }

  DateTime? _lastQuestionStartedAt;

  /// Adaptive difficulty: bias the entry list toward the difficulty band
  /// matching the kid's "iq" EMA skill. Below 0.4 → prefer easy (diff=1);
  /// 0.4–0.7 → medium (diff=2); ≥0.7 → hard (diff=3). The target band lands
  /// up front; the other bands trail in skill-distance order so a shorter
  /// session still has variety.
  List<IqEntry> _adaptiveOrder(List<IqEntry> entries) {
    final learner = ref.read(learnerStateProvider).value;
    final skill = learner?.skillFor('iq') ?? 0.5;
    final int target;
    if (skill < 0.4) {
      target = 1;
    } else if (skill < 0.7) {
      target = 2;
    } else {
      target = 3;
    }
    final ranked = [...entries]
      ..sort(
        (a, b) => (a.difficulty - target).abs().compareTo(
          (b.difficulty - target).abs(),
        ),
      );
    return ranked;
  }

  QuizSessionState _build(List<QuizQuestion> questions) {
    final category = ref.watch(iqCategoryFilterProvider);
    var filtered = questions;
    if (category != null) {
      filtered = questions.where((q) => q.category == category).toList();
    }
    final diff = ref.watch(iqDifficultyProvider);
    if (diff != QuizDifficulty.hard) {
      final minQ = 8.clamp(1, filtered.length);
      final cap = ((filtered.length * diff.poolFraction).ceil()).clamp(
        minQ,
        filtered.length,
      );
      filtered = filtered.take(cap).toList();
    }
    if (filtered.isEmpty) {
      return QuizSessionState(
        questions: const [],
        currentIndex: 0,
        score: 0,
        livesRemaining: 3,
        status: QuizStatus.complete,
      );
    }

    // Spaced repetition: prepend up to 2 recent mistakes (same module, same
    // category if a category filter is active) so the kid re-encounters items
    // they got wrong. Pulls from the learner_state recentErrors log.
    final repeats = _spacedRepetitionPicks(questions, filtered, category);
    ref
        .read(iqSessionRepeatIdsProvider.notifier)
        .setIds(repeats.map((q) => q.id).toSet());
    final ordered = <QuizQuestion>[...repeats, ...List.of(filtered)..shuffle()];
    // De-dup any item that already appeared via the SR prefix.
    final seenIds = <String>{};
    final unique = <QuizQuestion>[];
    for (final q in ordered) {
      if (seenIds.add(q.id)) unique.add(q);
    }

    return QuizSessionState(
      questions: unique,
      currentIndex: 0,
      score: 0,
      livesRemaining: 3,
      status: QuizStatus.inProgress,
    );
  }

  List<QuizQuestion> _spacedRepetitionPicks(
    List<QuizQuestion> all,
    List<QuizQuestion> currentPool,
    String? activeCategory,
  ) {
    final learner = ref.read(learnerStateProvider).value;
    if (learner == null) return const [];
    final mistakes = learner.recentErrors
        .where((e) => e.module == 'iq')
        .where((e) => activeCategory == null || e.category == activeCategory)
        .take(8)
        .toList();
    if (mistakes.isEmpty) return const [];
    final byId = {for (final q in all) q.id: q};
    final picks = <QuizQuestion>[];
    for (final m in mistakes) {
      final q = byId[m.questionId];
      if (q != null) picks.add(q);
      if (picks.length >= 2) break;
    }
    return picks;
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

    final lat = _lastQuestionStartedAt == null
        ? 0
        : DateTime.now().difference(_lastQuestionStartedAt!).inMilliseconds;
    EventBus.instance.emit(
      LearningEvent(
        type: LearningEventType.questionAnswered,
        module: 'iq',
        timestamp: DateTime.now(),
        questionId: current.id,
        category: current.category,
        correct: isCorrect,
        latencyMs: lat,
      ),
    );

    state = AsyncData(
      session.copyWith(
        score: isCorrect ? session.score + 1 : session.score,
        livesRemaining: nextLives,
        lastAnswerCorrect: isCorrect,
      ),
    );
    return isCorrect;
  }

  void nextQuestion() {
    final session = state.value;
    if (session == null || session.isGameOver) return;
    final nextIndex = session.currentIndex + 1;
    if (nextIndex >= session.totalQuestions) {
      EventBus.instance.emit(
        LearningEvent(
          type: LearningEventType.sessionEnded,
          module: 'iq',
          timestamp: DateTime.now(),
          score: session.score,
        ),
      );
      state = AsyncData(
        session.copyWith(
          currentIndex: nextIndex,
          status: QuizStatus.complete,
          clearLastAnswer: true,
        ),
      );
    } else {
      _lastQuestionStartedAt = DateTime.now();
      state = AsyncData(
        session.copyWith(
          currentIndex: nextIndex,
          status: QuizStatus.inProgress,
          clearLastAnswer: true,
        ),
      );
    }
  }

  void restart() {
    final session = state.value;
    if (session == null) return;
    state = AsyncData(
      session.copyWith(
        questions: List.of(session.questions)..shuffle(),
        currentIndex: 0,
        score: 0,
        livesRemaining: 3,
        status: QuizStatus.inProgress,
        clearLastAnswer: true,
      ),
    );
  }
}
