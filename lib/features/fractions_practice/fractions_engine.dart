import 'dart:math' as math;

/// Pure question generator for the Fractions Practice screen. A Fraction
/// is just (numerator, denominator). Denominators stay in 2..10 (kid
/// range), numerators in 1..denominator-1 (proper fractions only) so
/// the visual is always less than a whole. Equal-fraction questions
/// (1/2 vs 2/4) are deliberately filtered out — they confuse the
/// "which is bigger?" prompt.

enum FractionMode { identify, compare }

class FractionVal {
  const FractionVal(this.numerator, this.denominator);
  final int numerator;
  final int denominator;

  double get value => numerator / denominator;

  @override
  String toString() => '$numerator/$denominator';

  @override
  bool operator ==(Object other) =>
      other is FractionVal &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);
}

class IdentifyQuestion {
  const IdentifyQuestion({
    required this.correct,
    required this.options,
  });
  final FractionVal correct;
  final List<FractionVal> options;
}

class CompareQuestion {
  const CompareQuestion({
    required this.left,
    required this.right,
    required this.leftIsBigger,
  });
  final FractionVal left;
  final FractionVal right;
  final bool leftIsBigger;
}

/// Random proper fraction with denominator in 2..[maxDenominator].
FractionVal _randomProperFraction(math.Random r, {int maxDenominator = 10}) {
  final d = 2 + r.nextInt(maxDenominator - 1); // 2..maxDenominator
  final n = 1 + r.nextInt(d - 1); // 1..d-1
  return FractionVal(n, d);
}

/// Build one "identify the fraction" question. The correct value plus
/// 3 distractors that look plausible but aren't equal-value.
IdentifyQuestion generateIdentifyQuestion({math.Random? rng}) {
  final r = rng ?? math.Random();
  final correct = _randomProperFraction(r);
  final wrongs = <FractionVal>{};
  // Generate plausible distractors: shift numerator and/or denominator
  // by 1, or pick another random fraction. Skip exact-equal-value
  // (e.g. 1/2 and 2/4) so the question has one unambiguous answer.
  var guard = 0;
  while (wrongs.length < 3 && guard < 50) {
    guard++;
    final candidate = _randomProperFraction(r);
    if (candidate == correct) continue;
    if (candidate.value == correct.value) continue;
    wrongs.add(candidate);
  }
  final options = [correct, ...wrongs]..shuffle(r);
  return IdentifyQuestion(correct: correct, options: options);
}

/// Build one "which is bigger?" question. Guaranteed unequal values.
CompareQuestion generateCompareQuestion({math.Random? rng}) {
  final r = rng ?? math.Random();
  FractionVal left;
  FractionVal right;
  var guard = 0;
  do {
    left = _randomProperFraction(r);
    right = _randomProperFraction(r);
    guard++;
  } while (left.value == right.value && guard < 50);
  return CompareQuestion(
    left: left,
    right: right,
    leftIsBigger: left.value > right.value,
  );
}

/// 0..3 stars from score-out-of-total. Same rubric as the other quizzes.
int fractionStarsFor(int score, int total) {
  if (total <= 0) return 0;
  return (score / total * 3).round().clamp(0, 3);
}
