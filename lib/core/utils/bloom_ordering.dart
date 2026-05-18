import 'package:aziz_academy/features/general_quiz/data/general_quiz_repository.dart';

/// Adaptive Bloom-level ordering for quiz entries.
///
/// When a pack is authored with the optional `bloom_level` scaffolding,
/// the adaptive engine prefers an interleave that scaffolds the learner
/// from "remember" → "understand" → "apply" within each session, instead
/// of a flat `difficulty` sort. Items without a bloom level fall through
/// to plain difficulty ordering.
///
/// This is the foundation for Wave 18's pedagogy ask: "schema scaffolding
/// → adaptive engine sorts by mastery." It's a small, deterministic
/// reordering — no model, no state — so it's safe to ship now and use
/// from any quiz flow that wants gentle progression.
const Map<String, int> _bloomRank = {
  'remember': 0,
  'understand': 1,
  'apply': 2,
};

int _bloomScore(GeneralQuizEntry e) =>
    _bloomRank[e.bloomLevel] ?? -1; // -1 puts unknown at the front

/// Returns a copy of [entries] reordered by:
///  1. Items WITHOUT a bloom_level keep relative order at the front.
///  2. Items WITH bloom_level follow, sorted remember → understand → apply.
///  3. Within each bloom band, ties break on existing `difficulty`.
List<GeneralQuizEntry> orderByBloom(Iterable<GeneralQuizEntry> entries) {
  final list = entries.toList();
  list.sort((a, b) {
    final ba = _bloomScore(a);
    final bb = _bloomScore(b);
    if (ba != bb) return ba.compareTo(bb);
    return a.difficulty.compareTo(b.difficulty);
  });
  return list;
}
