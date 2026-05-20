import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/core/services/qbank_remote_service.dart';

/// Singleton service.
final qBankRemoteServiceProvider = Provider<QBankRemoteService>((ref) {
  return QBankRemoteService();
});

/// Cached current-user admin flag. Refreshed when the user signs in/out
/// (callers can `ref.invalidate(isAdminProvider)` to force a re-check).
final isAdminProvider = FutureProvider<bool>((ref) async {
  final svc = ref.watch(qBankRemoteServiceProvider);
  return svc.isAdmin();
});

/// All published drafts, keyed by (pool_id, id), ready for the runtime
/// overlay merge. Cached for the session; admins can invalidate it after
/// publishing a new question.
final publishedDraftsProvider = FutureProvider<Map<String, QBankDraft>>((ref) async {
  final svc = ref.watch(qBankRemoteServiceProvider);
  final list = await svc.fetchPublished();
  return {for (final d in list) '${d.poolId}::${d.id}': d};
});

/// All drafts (admin view) — optionally filtered by pool.
final allDraftsForPoolProvider =
    FutureProvider.family<List<QBankDraft>, String?>((ref, poolId) async {
  final svc = ref.watch(qBankRemoteServiceProvider);
  return svc.fetchAllDrafts(poolId: poolId);
});

/// Recent change log for the "what changed lately" header on the admin page.
final recentAuditProvider = FutureProvider<List<QBankAuditEntry>>((ref) async {
  final svc = ref.watch(qBankRemoteServiceProvider);
  return svc.fetchRecentAudit(limit: 50);
});
