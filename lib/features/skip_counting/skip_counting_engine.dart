import 'dart:math' as math;

import 'package:aziz_academy/core/teaching/teaching_hint.dart';
import 'package:aziz_academy/core/utils/digits.dart' as digits;

/// Skip Counting — show a sequence like `4, 6, 8, ?, 12, 14` and ask
/// the kid to fill the blank. Three skip-modes (2s, 5s, 10s); the blank
/// position is random inside the visible window so the kid can't just
/// copy "two more than the last shown number".

enum SkipMode { twos, fives, tens }

int stepFor(SkipMode m) => switch (m) {
      SkipMode.twos => 2,
      SkipMode.fives => 5,
      SkipMode.tens => 10,
    };

class SkipQuestion {
  const SkipQuestion({
    required this.mode,
    required this.sequence,
    required this.blankIndex,
    required this.answer,
  });

  final SkipMode mode;
  /// Six values, with the value at [blankIndex] being the kid's answer.
  final List<int> sequence;
  final int blankIndex;
  final int answer;
}

SkipQuestion generateSkipQuestion(
  SkipMode mode, {
  math.Random? rng,
  Map<int, int>? weights,
}) {
  final r = rng ?? math.Random();
  final step = stepFor(mode);
  final maxStart = switch (mode) {
    SkipMode.twos => 40,
    SkipMode.fives => 60,
    SkipMode.tens => 90,
  };

  // Adaptive path: if weights given, try to construct a sequence whose
  // blank lands on a previously-missed answer. Falls back to uniform
  // if no weighted answer can be placed validly.
  if (weights != null && weights.isNotEmpty) {
    final placed = _tryPlaceWeightedAnswer(
      step: step,
      maxStart: maxStart,
      weights: weights,
      r: r,
    );
    if (placed != null) {
      return SkipQuestion(
        mode: mode,
        sequence: placed.$1,
        blankIndex: placed.$2,
        answer: placed.$1[placed.$2],
      );
    }
  }

  // Uniform path (original contract). First visible value must be a
  // multiple of step >= step itself so kids see canonical sequences
  // (2,4,6… / 5,10,15… / 10,20,30…).
  final start = step + r.nextInt(maxStart ~/ step) * step;
  final seq = List<int>.generate(6, (i) => start + i * step);
  // Pick a blank in the middle 4 positions so there is context on
  // both sides; index 0 or 5 would degenerate to "+/- step from the
  // only neighbour".
  final blankIndex = 1 + r.nextInt(4);
  return SkipQuestion(
    mode: mode,
    sequence: seq,
    blankIndex: blankIndex,
    answer: seq[blankIndex],
  );
}

/// Try to construct a 6-value sequence where the blank lands on a
/// weighted (=previously-missed) answer. Returns `(sequence, blankIndex)`
/// or `null` if no weighted answer admits a valid placement.
(List<int>, int)? _tryPlaceWeightedAnswer({
  required int step,
  required int maxStart,
  required Map<int, int> weights,
  required math.Random r,
}) {
  // Build a weighted pool of candidate answers.
  const baseWeight = 1;
  const biasWeight = 3;
  final pool = <int>[];
  for (final e in weights.entries) {
    final w = baseWeight + e.value * biasWeight;
    for (var k = 0; k < w; k++) {
      pool.add(e.key);
    }
  }
  if (pool.isEmpty) return null;
  // Sample target, then try blankIndex 1..4 in shuffled order.
  final target = pool[r.nextInt(pool.length)];
  if (target % step != 0) return null; // can't sit in a canonical seq
  final candidates = [1, 2, 3, 4]..shuffle(r);
  for (final blankIndex in candidates) {
    final start = target - blankIndex * step;
    // start must be a canonical multiple >= step, and start + 5*step
    // must still be a "kid-friendly" number (≤ maxStart + 5*step).
    if (start < step) continue;
    if (start > maxStart) continue;
    if (start % step != 0) continue;
    final seq = List<int>.generate(6, (i) => start + i * step);
    return (seq, blankIndex);
  }
  return null;
}

/// Mini-lesson for a wrong pick. Uses the left neighbour (or the
/// right one for blank=1 edge) to show the kid the +step relationship
/// in the sequence.
TeachingHint skipTeachingHint(SkipQuestion q, {bool arabic = false}) {
  final step = stepFor(q.mode);
  final prev = q.sequence[q.blankIndex - 1];
  final p = digits.localizeDigits(prev, arabic: arabic);
  final s = digits.localizeDigits(step, arabic: arabic);
  final ans = digits.localizeDigits(q.answer, arabic: arabic);
  return TeachingHint(
    en: '$prev + $step = ${q.answer}. Keep adding $step.',
    ar: '$p + $s = $ans. تابع بإضافة $s.',
  );
}

/// Four unique options, including the correct answer. Distractors are
/// near misses (off-by-step in either direction) so the kid can't just
/// reject far-away outliers.
List<int> generateSkipOptions(
  SkipQuestion q, {
  math.Random? rng,
}) {
  final r = rng ?? math.Random();
  final step = stepFor(q.mode);
  final set = <int>{q.answer};
  // Add the obvious near-miss distractors first.
  for (final delta in [step, -step, step ~/ 2, -step ~/ 2, 2 * step, -2 * step]) {
    if (delta == 0) continue;
    final cand = q.answer + delta;
    if (cand >= 0 && cand <= 200) set.add(cand);
    if (set.length >= 4) break;
  }
  var attempts = 0;
  while (set.length < 4 && attempts < 50) {
    final cand = q.answer + (r.nextBool() ? 1 : -1) * (1 + r.nextInt(step + 2));
    if (cand >= 0 && cand <= 200 && cand != q.answer) set.add(cand);
    attempts++;
  }
  for (var v = 0; v <= 200 && set.length < 4; v++) {
    set.add(v);
  }
  final list = set.toList()..shuffle(r);
  return list.take(4).toList();
}
