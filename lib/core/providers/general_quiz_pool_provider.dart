import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/features/general_quiz/data/general_quiz_repository.dart';

/// Session-cached merged General Knowledge pool. Every consumer of the
/// 31-pack merge calls into the same in-memory list — avoids repeating the
/// 31 parallel rootBundle reads + JSON parses on every quiz entry.
final generalQuizPoolProvider = FutureProvider<List<GeneralQuizEntry>>((
  ref,
) async {
  const repo = GeneralQuizRepository();
  return repo.loadEntries();
});
