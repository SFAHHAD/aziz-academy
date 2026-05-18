import 'dart:math' as math;

import 'package:aziz_academy/core/teaching/teaching_hint.dart';
import 'package:aziz_academy/core/utils/digits.dart' as digits;

/// Place Value practice — two question shapes for two-digit numbers:
///   • blocksToNumber: show tens-rods + ones-cubes, ask for the number.
///   • numberToBlocks: show a number, ask how many tens (or ones).
/// Both keep the answer in [0, 99] so a 6-8 year old can map blocks
/// directly to digits.

enum PvMode { blocksToNumber, numberToBlocks }

class PvQuestion {
  const PvQuestion({
    required this.mode,
    required this.number,
    required this.tens,
    required this.ones,
    required this.askTens,
    required this.answer,
  });

  final PvMode mode;
  final int number;
  final int tens;
  final int ones;
  /// For [PvMode.numberToBlocks] only — true if the question asks for the
  /// tens digit, false for ones. Ignored when mode is blocksToNumber.
  final bool askTens;
  final int answer;
}

PvQuestion generatePvQuestion(
  PvMode mode, {
  math.Random? rng,
  Map<int, int>? weights,
}) {
  final r = rng ?? math.Random();
  // Keep numbers in 10..99 so there is always at least one tens-rod.
  final number = _pickNumber(r, weights);
  final tens = number ~/ 10;
  final ones = number % 10;
  switch (mode) {
    case PvMode.blocksToNumber:
      return PvQuestion(
        mode: mode,
        number: number,
        tens: tens,
        ones: ones,
        askTens: false,
        answer: number,
      );
    case PvMode.numberToBlocks:
      final askTens = r.nextBool();
      return PvQuestion(
        mode: mode,
        number: number,
        tens: tens,
        ones: ones,
        askTens: askTens,
        answer: askTens ? tens : ones,
      );
  }
}

int _pickNumber(math.Random r, Map<int, int>? weights) {
  // Pure uniform when no weights — preserves the original contract.
  if (weights == null || weights.isEmpty) {
    return 10 + r.nextInt(90);
  }
  // baseWeight + miss-count × biasWeight per candidate number in
  // 10..99. Same shape as the Number Bonds weighted sampler.
  const baseWeight = 1;
  const biasWeight = 3;
  final pool = <int>[];
  for (var n = 10; n <= 99; n++) {
    final misses = weights[n] ?? 0;
    final w = baseWeight + misses * biasWeight;
    for (var k = 0; k < w; k++) {
      pool.add(n);
    }
  }
  return pool[r.nextInt(pool.length)];
}

/// Mini-lesson for a wrong pick. Explicitly breaks the number into
/// `tens × 10 + ones`, so the kid sees the column-arithmetic decomp
/// they'll need for the next stage.
TeachingHint pvTeachingHint(PvQuestion q, {bool arabic = false}) {
  final n = digits.localizeDigits(q.number, arabic: arabic);
  final t = digits.localizeDigits(q.tens, arabic: arabic);
  final o = digits.localizeDigits(q.ones, arabic: arabic);
  final tx10 = digits.localizeDigits(q.tens * 10, arabic: arabic);
  switch (q.mode) {
    case PvMode.blocksToNumber:
      return TeachingHint(
        en: '${q.tens} tens + ${q.ones} ones = $tx10 + ${q.ones} = ${q.number}.',
        ar: '$t عشرات + $o آحاد = $tx10 + $o = $n.',
      );
    case PvMode.numberToBlocks:
      if (q.askTens) {
        return TeachingHint(
          en: 'In $n the first digit ($t) is the tens place — $t tens = $tx10.',
          ar: 'في $n الرقم الأول ($t) منزلة العشرات — $t عشرات = $tx10.',
        );
      }
      return TeachingHint(
        en: 'In $n the last digit ($o) is the ones place — $o ones = $o.',
        ar: 'في $n الرقم الأخير ($o) منزلة الآحاد — $o آحاد = $o.',
      );
  }
}

/// Four options including the correct answer, kept inside the valid
/// range for the question (0..99 for blocks→number, 0..9 for the
/// digit-extraction mode).
List<int> generatePvOptions(
  PvQuestion q, {
  math.Random? rng,
}) {
  final r = rng ?? math.Random();
  final maxV = q.mode == PvMode.blocksToNumber ? 99 : 9;
  final set = <int>{q.answer};
  var attempts = 0;
  while (set.length < 4 && attempts < 60) {
    final delta = q.mode == PvMode.blocksToNumber
        ? 1 + r.nextInt(11) // 1..11
        : 1 + r.nextInt(3); // 1..3
    final sign = r.nextBool() ? 1 : -1;
    final cand = q.answer + sign * delta;
    if (cand >= 0 && cand <= maxV && cand != q.answer) {
      set.add(cand);
    }
    attempts++;
  }
  for (var v = 0; v <= maxV && set.length < 4; v++) {
    set.add(v);
  }
  final list = set.toList()..shuffle(r);
  return list;
}
