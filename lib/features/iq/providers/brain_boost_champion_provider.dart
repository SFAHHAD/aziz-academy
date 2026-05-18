import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/features/iq/data/iq_repository.dart';
import 'package:aziz_academy/features/iq/providers/iq_quiz_provider.dart';

/// Champion Mode — 12-item progression that chains all 4 Brain Boost
/// categories in a fixed E→M→H difficulty ramp:
///
///   q1: Patterns Easy
///   q2: Mental Math Easy
///   q3: Analogies Easy
///   q4: Logic Easy
///   q5: Patterns Medium
///   q6: Mental Math Medium
///   q7: Analogies Medium
///   q8: Logic Medium
///   q9..12: each category at Hard
///
/// The kid faces a balanced difficulty curve across all four reasoning
/// dimensions in a single session. Items are sampled fresh on each entry so
/// repeat plays bring new items.
const _kCats = ['Patterns', 'Mental Math', 'Analogies', 'Logic'];

final brainBoostChampionItemsProvider = Provider<AsyncValue<List<IqEntry>>>((
  ref,
) {
  final entriesAsync = ref.watch(iqEntriesProvider);
  return entriesAsync.whenData((all) {
    if (all.isEmpty) return const <IqEntry>[];
    final byCatDiff = <String, Map<int, List<IqEntry>>>{};
    for (final e in all) {
      byCatDiff
          .putIfAbsent(e.category, () => <int, List<IqEntry>>{})
          .putIfAbsent(e.difficulty, () => <IqEntry>[])
          .add(e);
    }
    final rng = math.Random();
    final picks = <IqEntry>[];
    for (final diff in const [1, 2, 3]) {
      for (final cat in _kCats) {
        final pool = byCatDiff[cat]?[diff] ?? const <IqEntry>[];
        if (pool.isEmpty) continue;
        // Pick a fresh item that wasn't already in picks.
        final candidates = pool
            .where((e) => !picks.any((p) => p.id == e.id))
            .toList();
        final pick =
            (candidates.isEmpty ? pool : candidates)[rng.nextInt(
              (candidates.isEmpty ? pool : candidates).length,
            )];
        picks.add(pick);
      }
    }
    return picks;
  });
}, name: 'brainBoostChampionItemsProvider');
