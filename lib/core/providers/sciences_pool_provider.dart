import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/features/sciences/data/sciences_repository.dart';

/// Session-cached merged Sciences pool. Boss round, sciences quiz, and
/// random quiz all read from the same in-memory list — avoids re-loading
/// the multi-level science packs (sciences.json + l2..l6) on every entry.
///
/// The locale-dependent transformation to QuizQuestion happens at the
/// consumer site, so the cache holds the locale-agnostic ScienceEntry list.
final sciencesPoolProvider = FutureProvider<List<ScienceEntry>>((ref) async {
  const repo = SciencesRepository();
  return repo.loadEntries();
});
