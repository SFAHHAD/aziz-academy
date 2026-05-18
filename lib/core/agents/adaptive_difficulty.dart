import 'dart:math' as math;

import 'package:aziz_academy/core/agents/learner_state.dart';

/// A1 — Adaptive Difficulty.
///
/// Given a pool of items each carrying a `difficulty` (1=easy, 2=mid, 3=hard)
/// and the learner's current skill on the module, returns a sampled subset
/// biased toward the band that gives ~75-85% success.
///
/// The function is deliberately stateless and pure — fed by learner_state.
List<T> adaptiveSample<T>({
  required List<T> pool,
  required int count,
  required double skill,
  required int Function(T) difficultyOf,
  math.Random? rng,
}) {
  if (pool.isEmpty || count <= 0) return const [];
  if (pool.length <= count) return List<T>.from(pool)..shuffle(rng);
  final r = rng ?? math.Random();
  final band = difficultyBandFor(skill);
  final preferred = preferredDifficulties(band).toSet();

  // Two-bucket pick: 70% from preferred difficulties, 30% from anything.
  final preferredItems = pool
      .where((e) => preferred.contains(difficultyOf(e)))
      .toList();
  final fallback = List<T>.from(pool);

  final picked = <T>[];
  final seen = <T>{};
  final fromPreferred = (count * 0.7).round();

  void take(List<T> source, int n) {
    final src = List<T>.from(source)..shuffle(r);
    for (final item in src) {
      if (picked.length >= count) break;
      if (seen.add(item)) picked.add(item);
      if (picked.where((e) => seen.contains(e)).length >= n + (count - n)) {
        // never used; bail when full.
      }
      if (picked.length >= n) break;
    }
  }

  take(preferredItems.isEmpty ? fallback : preferredItems, fromPreferred);
  // Fill the rest from anywhere not yet picked.
  final remaining = fallback.where((e) => !seen.contains(e)).toList()
    ..shuffle(r);
  for (final item in remaining) {
    if (picked.length >= count) break;
    picked.add(item);
    seen.add(item);
  }
  picked.shuffle(r);
  return picked;
}

/// Convenience: read skill from a LearnerState then sample.
List<T> adaptiveSampleFor<T>({
  required List<T> pool,
  required int count,
  required String module,
  required LearnerState learner,
  required int Function(T) difficultyOf,
  math.Random? rng,
}) {
  return adaptiveSample(
    pool: pool,
    count: count,
    skill: learner.skillFor(module),
    difficultyOf: difficultyOf,
    rng: rng,
  );
}
