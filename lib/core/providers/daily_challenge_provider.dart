import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aziz_academy/core/models/quiz_question.dart';
import 'package:aziz_academy/core/models/quiz_session_state.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/recap_queue_provider.dart';
import 'package:aziz_academy/core/models/recap_module.dart';
import 'package:aziz_academy/core/providers/xp_provider.dart';
import 'package:aziz_academy/features/capitals/data/capitals_repository.dart';
import 'package:aziz_academy/features/flags/data/flags_repository.dart';
import 'package:aziz_academy/features/logos/data/logos_repository.dart';
import 'package:aziz_academy/features/sciences/data/sciences_repository.dart';

// =============================================================================
// State
// =============================================================================

class DailyChallengeState {
  const DailyChallengeState({
    required this.dateKey,
    required this.questions,
    this.isCompleted = false,
    this.currentIndex = 0,
    this.score = 0,
    this.livesRemaining = 3,
    this.status = QuizStatus.inProgress,
    this.lastAnswerCorrect,
    this.xpEarned = 0,
  });

  final String dateKey;
  final List<QuizQuestion> questions;
  final bool isCompleted;
  final int currentIndex;
  final int score;
  final int livesRemaining;
  final QuizStatus status;
  final bool? lastAnswerCorrect;
  final int xpEarned;

  int get totalQuestions => questions.length;
  bool get isGameOver => livesRemaining <= 0;
  bool get isComplete => status == QuizStatus.complete;
  double get progress =>
      totalQuestions == 0 ? 0 : currentIndex / totalQuestions;

  QuizQuestion? get currentQuestion =>
      status == QuizStatus.inProgress && currentIndex < questions.length
      ? questions[currentIndex]
      : null;

  /// Time remaining until reset (local midnight).
  static Duration timeUntilReset() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  DailyChallengeState copyWith({
    String? dateKey,
    List<QuizQuestion>? questions,
    bool? isCompleted,
    int? currentIndex,
    int? score,
    int? livesRemaining,
    QuizStatus? status,
    bool? lastAnswerCorrect,
    bool clearLastAnswer = false,
    int? xpEarned,
  }) {
    return DailyChallengeState(
      dateKey: dateKey ?? this.dateKey,
      questions: questions ?? this.questions,
      isCompleted: isCompleted ?? this.isCompleted,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      status: status ?? this.status,
      lastAnswerCorrect: clearLastAnswer
          ? null
          : (lastAnswerCorrect ?? this.lastAnswerCorrect),
      xpEarned: xpEarned ?? this.xpEarned,
    );
  }
}

// =============================================================================
// SharedPreferences keys
// =============================================================================

abstract final class _DCKeys {
  static const date = 'dc_date';
  static const questions = 'dc_questions';
  static const isCompleted = 'dc_is_completed';
  static const score = 'dc_score';
  static const xpEarned = 'dc_xp_earned';
}

// =============================================================================
// Provider
// =============================================================================

final dailyChallengeProvider =
    AsyncNotifierProvider<DailyChallengeNotifier, DailyChallengeState>(
      DailyChallengeNotifier.new,
      name: 'dailyChallengeProvider',
    );

class DailyChallengeNotifier extends AsyncNotifier<DailyChallengeState> {
  SharedPreferences? _prefs;

  @override
  Future<DailyChallengeState> build() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _loadOrGenerate();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Load / Generate
  // ---------------------------------------------------------------------------

  Future<DailyChallengeState> _loadOrGenerate() async {
    _prefs ??= await SharedPreferences.getInstance();
    final storedDate = _prefs!.getString(_DCKeys.date);
    final today = _todayKey();

    if (storedDate == today) {
      final qJson = _prefs!.getString(_DCKeys.questions);
      final completed = _prefs!.getBool(_DCKeys.isCompleted) ?? false;
      final savedScore = _prefs!.getInt(_DCKeys.score) ?? 0;
      final savedXp = _prefs!.getInt(_DCKeys.xpEarned) ?? 0;

      if (qJson != null) {
        try {
          final qList = (jsonDecode(qJson) as List)
              .map(
                (e) =>
                    QuizQuestion.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
          return DailyChallengeState(
            dateKey: today,
            questions: qList,
            isCompleted: completed,
            score: completed ? savedScore : 0,
            status: completed ? QuizStatus.complete : QuizStatus.inProgress,
            xpEarned: savedXp,
          );
        } catch (e, st) {
          debugPrint(
            'DailyChallenge: failed to restore saved session: $e\n$st',
          );
        }
      }
    }

    return _generateAndSave(today);
  }

  Future<DailyChallengeState> _generateAndSave(String today) async {
    _prefs ??= await SharedPreferences.getInstance();
    final questions = await _buildQuestions();

    final s = DailyChallengeState(dateKey: today, questions: questions);

    await Future.wait([
      _prefs!.setString(_DCKeys.date, today),
      _prefs!.setString(
        _DCKeys.questions,
        jsonEncode(questions.map((q) => q.toJson()).toList()),
      ),
      _prefs!.setBool(_DCKeys.isCompleted, false),
      _prefs!.setInt(_DCKeys.score, 0),
      _prefs!.setInt(_DCKeys.xpEarned, 0),
    ]);

    return s;
  }

  Future<List<QuizQuestion>> _buildQuestions() async {
    final rng = math.Random();
    final pool = <QuizQuestion>[];

    // 2 capitals
    try {
      final all = await const CapitalsRepository().loadQuestions();
      all.shuffle(rng);
      pool.addAll(all.take(2));
    } catch (e) {
      debugPrint('DailyChallenge: capitals load failed: $e');
    }

    // 2 flags
    try {
      final all = await const FlagsRepository().loadQuestions();
      all.shuffle(rng);
      pool.addAll(all.take(2));
    } catch (e) {
      debugPrint('DailyChallenge: flags load failed: $e');
    }

    // 2 sciences
    try {
      final all = await const SciencesRepository().loadQuestions();
      all.shuffle(rng);
      pool.addAll(all.take(2));
    } catch (e) {
      debugPrint('DailyChallenge: sciences load failed: $e');
    }

    // 2 logos
    try {
      final all = await const LogosRepository().loadQuestions();
      all.shuffle(rng);
      pool.addAll(all.take(2));
    } catch (e) {
      debugPrint('DailyChallenge: logos load failed: $e');
    }

    // 2 math (generated inline)
    pool.addAll(_generateMathQs(2, rng));

    pool.shuffle(rng);

    // Ensure we always return exactly 10 questions (pad with math if modules fail)
    while (pool.length < 10) {
      pool.addAll(_generateMathQs(10 - pool.length, rng));
    }

    // Inject up to 2 high-priority struggling questions at the front.
    await _injectReviewBoost(pool);

    return pool.take(10).toList();
  }

  /// Inserts ≤2 questions with missCount ≥ 2 at the front of [pool],
  /// displacing an equal number of tail items.
  Future<void> _injectReviewBoost(List<QuizQuestion> pool) async {
    try {
      final queue = await ref.read(recapQueueProvider.future);
      final struggling = [...queue]
        ..removeWhere((e) => e.missCount < 2 || e.module == RecapModule.maps);
      struggling.sort((a, b) => b.missCount.compareTo(a.missCount));

      var injected = 0;
      for (final entry in struggling) {
        if (injected >= 2) break;
        QuizQuestion? q;
        try {
          switch (entry.module) {
            case RecapModule.math:
              if (entry.snapshotJson != null) {
                q = QuizQuestion.fromJson(
                  Map<String, dynamic>.from(
                    jsonDecode(entry.snapshotJson!) as Map,
                  ),
                );
              }
              break;
            case RecapModule.capitals:
              final caps = await const CapitalsRepository().loadQuestions();
              for (final c in caps) {
                if (c.id == entry.questionId) {
                  q = c;
                  break;
                }
              }
              break;
            case RecapModule.flags:
              final flags = await const FlagsRepository().loadQuestions();
              for (final c in flags) {
                if (c.id == entry.questionId) {
                  q = c;
                  break;
                }
              }
              break;
            case RecapModule.sciences:
              final sciences = await const SciencesRepository().loadQuestions();
              for (final c in sciences) {
                if (c.id == entry.questionId) {
                  q = c;
                  break;
                }
              }
              break;
            case RecapModule.maps:
              break;
          }
        } catch (e) {
          debugPrint('DailyChallenge: recap lookup failed: $e');
          continue;
        }
        if (q != null && !pool.any((p) => p.id == q!.id)) {
          if (pool.length >= 10) pool.removeLast();
          pool.insert(0, q);
          injected++;
        }
      }
    } catch (e) {
      debugPrint('DailyChallenge: recap injection failed: $e');
    }
  }

  List<QuizQuestion> _generateMathQs(int count, math.Random rng) {
    const ops = ['+', '-', '×', '÷'];
    final result = <QuizQuestion>[];
    for (var i = 0; i < count; i++) {
      final opIdx = rng.nextInt(4);
      int a, b, answer;
      switch (opIdx) {
        case 0:
          a = rng.nextInt(40) + 1;
          b = rng.nextInt(40) + 1;
          answer = a + b;
          break;
        case 1:
          a = rng.nextInt(40) + 20;
          b = rng.nextInt(a - 1).clamp(1, a - 1);
          answer = a - b;
          break;
        case 2:
          a = rng.nextInt(10) + 2;
          b = rng.nextInt(10) + 2;
          answer = a * b;
          break;
        default:
          b = rng.nextInt(9) + 2;
          answer = rng.nextInt(9) + 2;
          a = b * answer;
      }
      final wrongSet = <int>{};
      while (wrongSet.length < 3) {
        int offset = rng.nextInt(10) - 5;
        if (offset == 0) offset = 1;
        final fake = answer + offset;
        if (fake >= 0 && fake != answer) wrongSet.add(fake);
      }
      final options = [...wrongSet.map((e) => e.toString()), answer.toString()]
        ..shuffle(rng);
      result.add(
        QuizQuestion(
          id: 'dc_math_${i}_${rng.nextInt(9999)}',
          question: '$a ${ops[opIdx]} $b = ؟',
          options: options,
          correctAnswer: answer.toString(),
          category: 'math',
          funFact: 'عمل رائع! الإجابة الصحيحة هي $answer.',
        ),
      );
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Game actions
  // ---------------------------------------------------------------------------

  /// Submits an answer for the current question. Returns true if correct.
  ///
  /// Records score/lives/`lastAnswerCorrect` but does NOT advance the
  /// question. Call [nextQuestion] when the reveal animation finishes,
  /// otherwise the UI flashes the next question's correct answer during the
  /// reveal window (the screen only knows about a single
  /// `state.currentQuestion`, so advancing here would leak the next answer).
  bool answer(String choice) {
    final s = state.value;
    if (s == null || s.status != QuizStatus.inProgress) return false;
    final q = s.currentQuestion;
    if (q == null) return false;

    final correct = choice == q.correctAnswer;
    final newScore = correct ? s.score + 1 : s.score;
    final newLives = (correct ? s.livesRemaining : s.livesRemaining - 1).clamp(
      0,
      3,
    );

    state = AsyncData(
      s.copyWith(
        score: newScore,
        livesRemaining: newLives,
        lastAnswerCorrect: correct,
      ),
    );

    return correct;
  }

  /// Advances to the next question, or marks the session complete if we've
  /// run out of questions or lives.
  void nextQuestion() {
    final s = state.value;
    if (s == null || s.status != QuizStatus.inProgress) return;
    final newIndex = s.currentIndex + 1;
    final isDone = newIndex >= s.totalQuestions || s.livesRemaining <= 0;
    state = AsyncData(
      s.copyWith(
        currentIndex: newIndex,
        status: isDone ? QuizStatus.complete : QuizStatus.inProgress,
      ),
    );
  }

  /// Called when the session ends — persists completion, awards 2× XP.
  Future<int> complete() async {
    _prefs ??= await SharedPreferences.getInstance();
    final s = state.value;
    if (s == null || s.isCompleted) return 0;

    final baseXp = XpNotifier.sessionXp(
      score: s.score,
      livesRemaining: s.livesRemaining,
    );
    final doubleXp = baseXp * 2;

    final finished = s.copyWith(isCompleted: true, xpEarned: doubleXp);
    state = AsyncData(finished);

    await Future.wait([
      _prefs!.setBool(_DCKeys.isCompleted, true),
      _prefs!.setInt(_DCKeys.score, s.score),
      _prefs!.setInt(_DCKeys.xpEarned, doubleXp),
    ]);

    // Award 2× XP
    await ref.read(xpProvider.notifier).addXp(doubleXp);

    // Sync correct answers + streak to achievementProvider
    await ref
        .read(achievementProvider.notifier)
        .recordDailyChallenge(score: s.score);

    return doubleXp;
  }

  /// Force a regeneration (for debug / testing).
  Future<void> forceReset() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_DCKeys.date);
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadOrGenerate);
  }
}
