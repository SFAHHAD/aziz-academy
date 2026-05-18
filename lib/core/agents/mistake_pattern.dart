import 'package:aziz_academy/core/agents/learner_state.dart';

/// A3 — Mistake-Pattern agent.
///
/// Clusters recent errors by `(module, category)` and surfaces hot spots
/// (categories with ≥3 misses in the last 50). Drives targeted drills.
class MistakePattern {
  const MistakePattern({
    required this.module,
    required this.category,
    required this.missCount,
  });

  final String module;
  final String category;
  final int missCount;
}

List<MistakePattern> hotMistakePatterns(LearnerState s, {int minMisses = 3}) {
  final counts = <String, int>{};
  for (final e in s.recentErrors) {
    final key = '${e.module}|${e.category}';
    counts[key] = (counts[key] ?? 0) + 1;
  }
  final out = <MistakePattern>[];
  counts.forEach((k, v) {
    if (v >= minMisses) {
      final parts = k.split('|');
      out.add(
        MistakePattern(
          module: parts[0],
          category: parts.length > 1 ? parts[1] : '',
          missCount: v,
        ),
      );
    }
  });
  out.sort((a, b) => b.missCount.compareTo(a.missCount));
  return out;
}
