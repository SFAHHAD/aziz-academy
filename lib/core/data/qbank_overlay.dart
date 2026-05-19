import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/providers/qbank_drafts_provider.dart';
import 'package:aziz_academy/core/services/qbank_remote_service.dart';

// =============================================================================
// Q-Bank runtime overlay
//
// Each quiz feature has its own repository that loads its pool from
// `assets/data/<pool_id>.json` via rootBundle. To let admin-added questions
// appear in the live app without a rebuild, this helper layers published
// drafts (from Supabase) on top of the bundled JSON.
//
// Usage in a feature repository:
//
//   import 'package:aziz_academy/core/data/qbank_overlay.dart';
//
//   final repo = ref.watch(...);
//   final items = await loadPoolWithOverlay(
//     ref: ref,
//     poolId: 'capitals',
//     assetPath: 'assets/data/capitals.json',
//   );
//
// Behaviour:
//   - Reads bundled JSON from rootBundle (must be a top-level array).
//   - Reads published drafts via `publishedDraftsProvider`.
//   - For each draft, if (pool_id, id) matches a bundled item, the draft's
//     payload OVERRIDES the bundled item. If the id is new, the draft is
//     APPENDED.
//   - If Supabase is offline or returns nothing, bundled JSON wins; the
//     app degrades gracefully to pure-bundled behaviour.
//
// Order: bundled items first (in their bundled order), then any draft-only
// items appended. Stable for quizzes that depend on consistent ordering.
// =============================================================================

class _OverlayResult {
  const _OverlayResult(this.items, this.draftCount, this.overrideCount);
  final List<Map<String, dynamic>> items;
  final int draftCount;
  final int overrideCount;
}

Future<List<Map<String, dynamic>>> loadPoolWithOverlay({
  required Ref ref,
  required String poolId,
  required String assetPath,
}) async {
  final bundledRaw = await rootBundle.loadString(assetPath);
  final bundled = (jsonDecode(bundledRaw) as List)
      .cast<Map<String, dynamic>>();

  // Pull published drafts. Provider is cached; if it errors, fall back to
  // bundled only.
  final draftsAsync = ref.read(publishedDraftsProvider);
  final draftsMap = draftsAsync.maybeWhen(
    data: (m) => m,
    orElse: () => const <String, QBankDraft>{},
  );

  // Index bundled by id for O(1) override lookup.
  final byId = <String, Map<String, dynamic>>{};
  for (final item in bundled) {
    final id = item['id'];
    if (id is String) byId[id] = item;
  }

  final List<Map<String, dynamic>> out = [];
  int overrideCount = 0;
  for (final item in bundled) {
    final id = item['id'];
    if (id is String) {
      final draft = draftsMap['$poolId::$id'];
      if (draft != null) {
        out.add(Map<String, dynamic>.from(draft.payload));
        overrideCount++;
        continue;
      }
    }
    out.add(item);
  }

  // Append draft-only items (drafts whose id is not in the bundled pool).
  int newCount = 0;
  for (final entry in draftsMap.entries) {
    if (!entry.key.startsWith('$poolId::')) continue;
    final draftId = entry.value.id;
    if (!byId.containsKey(draftId)) {
      out.add(Map<String, dynamic>.from(entry.value.payload));
      newCount++;
    }
  }

  return out;
}

/// Convenience provider for a single pool. Auto-rebuilds when the
/// publishedDraftsProvider invalidates (e.g. after admin publishes a draft).
final overlayedPoolProvider = FutureProvider.family<List<Map<String, dynamic>>, ({String poolId, String assetPath})>((ref, key) async {
  return loadPoolWithOverlay(
    ref: ref,
    poolId: key.poolId,
    assetPath: key.assetPath,
  );
});
