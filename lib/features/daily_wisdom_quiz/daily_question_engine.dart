import 'dart:math' as math;

/// Pure deterministic-per-day question generator for the Daily Wisdom
/// Quiz. Given a date and three content pools (Hadith / 99 Names /
/// Prophet), returns the same question for every kid on that day so a
/// family can talk about it together. The next day rotates to a
/// different section + a different item.
///
/// All inputs are passed in — no clocks, no globals — so the function
/// is unit-testable to the millisecond.

enum DailyQuestionKind { hadith, asma, prophet }

/// A pool item that can be used as either the correct answer or a
/// distractor. The engine cares only about `id` (for de-duping) and
/// the two strings the UI shows: prompt (the text the kid reads, in
/// either lang) and answer (the four options).
class DailyPoolItem {
  const DailyPoolItem({
    required this.id,
    required this.promptEn,
    required this.promptAr,
    required this.answerEn,
    required this.answerAr,
  });

  final String id;
  final String promptEn;
  final String promptAr;
  final String answerEn;
  final String answerAr;
}

class DailyQuestion {
  const DailyQuestion({
    required this.kind,
    required this.correct,
    required this.options,
  });

  final DailyQuestionKind kind;
  final DailyPoolItem correct;
  final List<DailyPoolItem> options;
}

/// Build today's question. Days rotate through Hadith → Asma → Prophet
/// based on `(dayOfYear + year) % 3` so the section also varies across
/// years on the same day. The seed is derived from the full date so
/// the choice within a section is also deterministic.
DailyQuestion buildDailyQuestion({
  required DateTime date,
  required List<DailyPoolItem> hadith,
  required List<DailyPoolItem> asma,
  required List<DailyPoolItem> prophet,
}) {
  final dayOfYear = _dayOfYear(date);
  final seed = date.year * 1000 + dayOfYear;
  final rng = math.Random(seed);

  final kindIdx = (dayOfYear + date.year) % 3;
  final kind = DailyQuestionKind.values[kindIdx];
  final pool = switch (kind) {
    DailyQuestionKind.hadith => hadith,
    DailyQuestionKind.asma => asma,
    DailyQuestionKind.prophet => prophet,
  };

  if (pool.length < 4) {
    // Defensive fallback — should never happen with shipped packs.
    return DailyQuestion(
      kind: kind,
      correct: pool.isEmpty
          ? const DailyPoolItem(
              id: '',
              promptEn: '',
              promptAr: '',
              answerEn: '',
              answerAr: '',
            )
          : pool.first,
      options: pool,
    );
  }

  final correctIdx = rng.nextInt(pool.length);
  final correct = pool[correctIdx];

  // Pick 3 distinct distractors.
  final remaining = [
    for (var i = 0; i < pool.length; i++)
      if (i != correctIdx) pool[i],
  ]..shuffle(rng);
  final distractors = remaining.take(3).toList();

  final options = [correct, ...distractors]..shuffle(rng);
  return DailyQuestion(kind: kind, correct: correct, options: options);
}

/// Day-of-year (1..366). Leap years correctly bump Feb 29 → day 60.
int _dayOfYear(DateTime d) {
  final start = DateTime(d.year, 1, 1);
  return d.difference(start).inDays + 1;
}

/// Whether two DateTimes represent the same calendar day. Used by the
/// streak provider to decide if the player has already played today.
bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Whether [today] is the calendar day immediately after [previous].
/// Used to decide if a streak continues vs. resets.
bool isNextCalendarDay(DateTime previous, DateTime today) {
  final next = DateTime(previous.year, previous.month, previous.day + 1);
  return isSameCalendarDay(next, today);
}
