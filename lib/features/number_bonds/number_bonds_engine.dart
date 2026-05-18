import 'dart:math' as math;

import 'package:aziz_academy/core/teaching/teaching_hint.dart';
import 'package:aziz_academy/core/utils/digits.dart' as digits;

/// Number Bonds — "what plus X makes the target?" Foundation for mental
/// addition in ages 6-8. Two bands: bonds-to-10 and bonds-to-20.

enum BondTarget { ten, twenty }

class BondQuestion {
  const BondQuestion({
    required this.target,
    required this.shown,
    required this.answer,
  });

  /// 10 or 20 — the bond target.
  final int target;

  /// The operand shown to the kid (e.g. 7 in "7 + ? = 10").
  final int shown;

  /// The complement (e.g. 3 in "7 + ? = 10").
  final int answer;
}

BondQuestion generateBondQuestion(
  BondTarget target, {
  math.Random? rng,
  Map<int, int>? weights,
}) {
  final r = rng ?? math.Random();
  final t = target == BondTarget.ten ? 10 : 20;
  // Avoid trivial 0/target endpoints — keep the shown in 1..t-1.
  final shown = _pickShown(t, r, weights);
  return BondQuestion(target: t, shown: shown, answer: t - shown);
}

int _pickShown(int target, math.Random r, Map<int, int>? weights) {
  // Pure uniform sampling when no weights — preserves the original
  // contract for tests and untracked callers.
  if (weights == null || weights.isEmpty) {
    return 1 + r.nextInt(target - 1);
  }
  // Build a weighted pool where each candidate `shown` gets:
  //   baseWeight + miss-count-for-that-shown × biasWeight
  // baseWeight keeps every value reachable so the kid sees variety
  // even after we know their weak spots.
  const baseWeight = 1;
  const biasWeight = 3;
  final pool = <int>[];
  for (var s = 1; s <= target - 1; s++) {
    final misses = weights[s] ?? 0;
    final w = baseWeight + misses * biasWeight;
    for (var k = 0; k < w; k++) {
      pool.add(s);
    }
  }
  return pool[r.nextInt(pool.length)];
}

/// Mini-lesson for a wrong pick on this question. Frames the bond as
/// a subtraction so the kid sees the "missing-addend ↔ subtraction"
/// link — that's the conceptual bridge to mental subtraction next.
TeachingHint bondTeachingHint(BondQuestion q, {bool arabic = false}) {
  final t = digits.localizeDigits(q.target, arabic: arabic);
  final s = digits.localizeDigits(q.shown, arabic: arabic);
  final a = digits.localizeDigits(q.answer, arabic: arabic);
  return TeachingHint(
    en: '${q.target} − ${q.shown} = ${q.answer}.  '
        '${q.shown} + ${q.answer} = ${q.target}.',
    ar: '$t − $s = $a.  $s + $a = $t.',
  );
}

/// Four answer options including the correct one. The distractors are
/// near the correct answer so the kid can't pick by elimination.
List<int> generateBondOptions(
  BondQuestion q, {
  math.Random? rng,
}) {
  final r = rng ?? math.Random();
  final set = <int>{q.answer};
  // Try near-by integers in [0, target] first.
  final maxV = q.target;
  var attempts = 0;
  while (set.length < 4 && attempts < 50) {
    final delta = 1 + r.nextInt(3); // 1..3
    final sign = r.nextBool() ? 1 : -1;
    final cand = q.answer + sign * delta;
    if (cand >= 0 && cand <= maxV && cand != q.answer) {
      set.add(cand);
    }
    attempts++;
  }
  // Fallback: top up with any unused values in range.
  for (var v = 0; v <= maxV && set.length < 4; v++) {
    set.add(v);
  }
  final list = set.toList()..shuffle(r);
  return list;
}
