import 'dart:math' as math;

/// Generic 4-option multiple-choice quiz engine. Used by the 99 Names,
/// Hadith, and Prophet quizzes. Each item must expose a stable id and a
/// category so distractors can prefer same-category wrong answers (they
/// are pedagogically harder than random ones).
///
/// Each [QuizItem] carries:
///  - `id`: stable unique key (used to detect duplicates / the correct
///    answer among options).
///  - `category`: bucket for same-theme distractor selection. Pass any
///    empty string if the content has no category — distractors will
///    just come from the full pool.
abstract class QuizItem {
  String get id;
  String get category;
}

class QuizRound<T extends QuizItem> {
  const QuizRound({required this.name, required this.options});
  final T name;
  final List<T> options;
}

/// Build [roundSize] questions where each is a 4-option MCQ. Returns
/// empty if the pool is too small to fill 4 options.
List<QuizRound<T>> buildQuizRound<T extends QuizItem>(
  List<T> pool, {
  int roundSize = 10,
  math.Random? rng,
}) {
  if (pool.length < 4) return const [];
  final r = rng ?? math.Random();
  final shuffled = [...pool]..shuffle(r);
  final picks = shuffled.take(roundSize).toList();
  return [
    for (final n in picks)
      QuizRound<T>(name: n, options: buildQuizOptions(n, pool, rng: r)),
  ];
}

/// Build 4 options for one question: the correct item plus 3 distractors,
/// preferring same-category fallbacks. The result is shuffled so the
/// correct answer is not always at position 0.
List<T> buildQuizOptions<T extends QuizItem>(
  T correct,
  List<T> pool, {
  math.Random? rng,
}) {
  final r = rng ?? math.Random();
  final sameCat = pool
      .where((n) => n.category == correct.category && n.id != correct.id)
      .toList()
    ..shuffle(r);
  final others = pool.where((n) => n.id != correct.id).toList()..shuffle(r);
  final distractors = <T>[];
  for (final cand in [...sameCat, ...others]) {
    if (distractors.length >= 3) break;
    if (distractors.any((d) => d.id == cand.id)) continue;
    distractors.add(cand);
  }
  final options = [correct, ...distractors]..shuffle(r);
  return options;
}

/// 0..3 star result: same rubric the asma quiz used. Clamped so absurd
/// inputs (negative score, score > total) never blow up the result UI.
int quizStarsFor(int score, int total) {
  if (total <= 0) return 0;
  return (score / total * 3).round().clamp(0, 3);
}
