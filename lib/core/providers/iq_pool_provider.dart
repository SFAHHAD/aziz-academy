import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/features/iq/data/iq_repository.dart';

/// Session-cached IQ pool. Boss round, IQ quiz, brain boost daily +
/// champion all read from the same in-memory list — avoids re-loading
/// the multi-pack IQ packs on every entry.
final iqPoolProvider = FutureProvider<List<IqEntry>>((ref) async {
  const repo = IqRepository();
  return repo.loadEntries();
});
