import 'dart:math' as math;

/// Pure quiz logic for the 99-Names quiz. Lives outside the screen so it
/// is unit-testable and easy to reason about: given a pool of names, build
/// a round of N questions where each question has 4 options (1 correct +
/// 3 plausible distractors).
class AsmaName {
  const AsmaName({
    required this.n,
    required this.nameAr,
    required this.tr,
    required this.en,
    required this.enAr,
    required this.category,
  });

  final int n;
  final String nameAr;
  final String tr;
  final String en;
  final String enAr;
  final String category;

  static AsmaName fromJson(Map<String, dynamic> j) => AsmaName(
    n: (j['n'] as num).toInt(),
    nameAr: j['name_ar'] as String? ?? '',
    tr: j['name'] as String? ?? '',
    en: j['en'] as String? ?? '',
    enAr: j['en_ar'] as String? ?? '',
    category: j['category'] as String? ?? '',
  );
}

class AsmaQuestion {
  const AsmaQuestion({required this.name, required this.options});
  final AsmaName name;
  final List<AsmaName> options;
}

/// Pick [roundSize] random names and turn each into a 4-option question.
/// Returns empty if the pool is too small to make a 4-option question
/// (need at least 4 names).
List<AsmaQuestion> buildAsmaQuestions(
  List<AsmaName> pool, {
  int roundSize = 10,
  math.Random? rng,
}) {
  final r = rng ?? math.Random();
  if (pool.length < 4) return const [];
  final shuffled = [...pool]..shuffle(r);
  final picks = shuffled.take(roundSize).toList();
  return [
    for (final n in picks)
      AsmaQuestion(name: n, options: buildAsmaOptions(n, pool, rng: r)),
  ];
}

/// Build 4 options for a question — the correct name plus 3 distractors,
/// preferring distractors from the same category since same-theme wrong
/// answers are pedagogically harder than random ones. Skips distractors
/// with the exact same English meaning as the correct answer.
List<AsmaName> buildAsmaOptions(
  AsmaName correct,
  List<AsmaName> pool, {
  math.Random? rng,
}) {
  final r = rng ?? math.Random();
  final sameCat = pool
      .where((n) => n.category == correct.category && n.n != correct.n)
      .toList()
    ..shuffle(r);
  final others = pool.where((n) => n.n != correct.n).toList()..shuffle(r);
  final distractors = <AsmaName>[];
  for (final cand in [...sameCat, ...others]) {
    if (distractors.length >= 3) break;
    if (distractors.any((d) => d.n == cand.n)) continue;
    if (cand.en == correct.en) continue;
    distractors.add(cand);
  }
  final options = [correct, ...distractors]..shuffle(r);
  return options;
}

/// 3-star result rubric: 0 stars for ≤16% correct, 1 for ≤50%, 2 for
/// ≤83%, 3 for the rest. Implemented as a clamp on `round(score/total*3)`
/// to match the screen's existing display.
int asmaStarsFor(int score, int total) {
  if (total <= 0) return 0;
  return (score / total * 3).round().clamp(0, 3);
}
