import 'dart:math' as math;

/// Pure question generator for the Mental Math Sprint. Three difficulty
/// bands tune the operand range and operation mix. All generators
/// produce questions with non-negative, whole-number answers so the
/// kid sees a clean integer (no fractions, no negatives).

enum MentalMathBand { easy, medium, hard }

enum MentalOp { add, sub, mul, div }

class MentalQuestion {
  const MentalQuestion({
    required this.a,
    required this.b,
    required this.op,
    required this.answer,
  });

  final int a;
  final int b;
  final MentalOp op;
  final int answer;

  /// "10 + 7" style prompt. The screen builds its own widget but this
  /// is useful for tests + debug.
  String get prompt {
    final sym = switch (op) {
      MentalOp.add => '+',
      MentalOp.sub => '−',
      MentalOp.mul => '×',
      MentalOp.div => '÷',
    };
    return '$a $sym $b';
  }
}

/// Generate one question for the given band. Pass a [rng] for
/// determinism in tests.
MentalQuestion generateMentalQuestion(
  MentalMathBand band, {
  math.Random? rng,
}) {
  final r = rng ?? math.Random();
  switch (band) {
    case MentalMathBand.easy:
      // Easy: addition & subtraction only, single-digit operands.
      // Subtraction is always non-negative.
      final op = r.nextBool() ? MentalOp.add : MentalOp.sub;
      if (op == MentalOp.add) {
        final a = 1 + r.nextInt(10); // 1..10
        final b = 1 + r.nextInt(10);
        return MentalQuestion(a: a, b: b, op: op, answer: a + b);
      } else {
        final a = 2 + r.nextInt(19); // 2..20
        final b = 1 + r.nextInt(a); // 1..a → a-b ≥ 1
        return MentalQuestion(a: a, b: b, op: op, answer: a - b);
      }

    case MentalMathBand.medium:
      // Medium: +/−/× — including a ×-table problem ~⅓ of the time.
      final pick = r.nextInt(3);
      if (pick == 0) {
        // multiplication (×2..×12)
        final a = 2 + r.nextInt(11);
        final b = 1 + r.nextInt(12);
        return MentalQuestion(a: a, b: b, op: MentalOp.mul, answer: a * b);
      } else if (pick == 1) {
        // addition, two-digit
        final a = 10 + r.nextInt(90);
        final b = 5 + r.nextInt(45);
        return MentalQuestion(a: a, b: b, op: MentalOp.add, answer: a + b);
      } else {
        // subtraction, two-digit minus single/two-digit
        final a = 20 + r.nextInt(80);
        final b = 5 + r.nextInt(a - 5);
        return MentalQuestion(a: a, b: b, op: MentalOp.sub, answer: a - b);
      }

    case MentalMathBand.hard:
      // Hard: all four operations, larger ranges, exact divisions only.
      final pick = r.nextInt(4);
      if (pick == 0) {
        // multiplication, larger range
        final a = 5 + r.nextInt(15); // 5..19
        final b = 3 + r.nextInt(12); // 3..14
        return MentalQuestion(a: a, b: b, op: MentalOp.mul, answer: a * b);
      } else if (pick == 1) {
        // division — generate as b * answer so result is always whole
        final b = 2 + r.nextInt(11); // 2..12
        final answer = 2 + r.nextInt(15); // 2..16
        final a = b * answer;
        return MentalQuestion(a: a, b: b, op: MentalOp.div, answer: answer);
      } else if (pick == 2) {
        // larger addition
        final a = 50 + r.nextInt(450); // 50..499
        final b = 20 + r.nextInt(180);
        return MentalQuestion(a: a, b: b, op: MentalOp.add, answer: a + b);
      } else {
        // larger subtraction
        final a = 100 + r.nextInt(400);
        final b = 30 + r.nextInt(a - 30);
        return MentalQuestion(a: a, b: b, op: MentalOp.sub, answer: a - b);
      }
  }
}

/// Build 3 plausible wrong-answer options near the correct value.
/// Returns a list of 4 unique options including the correct answer,
/// shuffled. All options are positive integers.
List<int> generateMentalOptions(MentalQuestion q, {math.Random? rng}) {
  final r = rng ?? math.Random();
  final wrongs = <int>{};
  // Spread by 20% of answer, min ±2.
  final spread = math.max(2, (q.answer * 0.2).round());
  while (wrongs.length < 3) {
    final delta = 1 + r.nextInt(spread * 2);
    final candidate = q.answer + (r.nextBool() ? delta : -delta);
    if (candidate <= 0 || candidate == q.answer) continue;
    wrongs.add(candidate);
  }
  return [q.answer, ...wrongs]..shuffle(r);
}
