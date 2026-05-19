import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aziz_academy/core/services/supabase_bootstrap.dart';

// =============================================================================
// Q-Bank remote service
//
// Mirrors the schema in supabase/migrations/2026_05_18_qbank_drafts.sql.
// All methods are no-ops when [supabaseReady] is false — the admin UI sees
// an empty draft list and pure-bundled content, matching guest behaviour.
//
// Authorization is enforced server-side via RLS + the admin_users allowlist.
// Client-side we still gate the editor UI on [isAdmin], but a non-admin who
// tries to write directly via this service will get a 403 from Supabase.
// =============================================================================

enum QBankDraftStatus { draft, review, published, archived }

extension QBankDraftStatusX on QBankDraftStatus {
  String get wire => name; // matches the CHECK constraint values

  static QBankDraftStatus parse(String? s) {
    switch (s) {
      case 'draft':
        return QBankDraftStatus.draft;
      case 'review':
        return QBankDraftStatus.review;
      case 'published':
        return QBankDraftStatus.published;
      case 'archived':
        return QBankDraftStatus.archived;
      default:
        return QBankDraftStatus.draft;
    }
  }
}

/// One row from the qbank_drafts table. The [payload] is the question's
/// raw JSON shape (same as the bundled JSON files); the app merges it on
/// top of the bundled pool by `(poolId, id)`.
class QBankDraft {
  const QBankDraft({
    required this.poolId,
    required this.id,
    required this.status,
    required this.payload,
    required this.updatedAt,
  });

  final String poolId;
  final String id;
  final QBankDraftStatus status;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;

  factory QBankDraft.fromRow(Map<String, dynamic> row) {
    return QBankDraft(
      poolId: row['pool_id'] as String,
      id: row['id'] as String,
      status: QBankDraftStatusX.parse(row['status'] as String?),
      payload: Map<String, dynamic>.from(row['payload'] as Map),
      updatedAt: DateTime.tryParse('${row['updated_at']}') ?? DateTime.now(),
    );
  }
}

/// One row from qbank_audit — the change log.
class QBankAuditEntry {
  const QBankAuditEntry({
    required this.id,
    required this.poolId,
    required this.questionId,
    required this.action,
    required this.before,
    required this.after,
    required this.at,
  });

  final int id;
  final String poolId;
  final String questionId;
  final String action;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final DateTime at;

  factory QBankAuditEntry.fromRow(Map<String, dynamic> row) {
    Map<String, dynamic>? toMap(Object? v) =>
        v == null ? null : Map<String, dynamic>.from(v as Map);
    return QBankAuditEntry(
      id: row['id'] as int,
      poolId: row['pool_id'] as String,
      questionId: row['question_id'] as String,
      action: row['action'] as String,
      before: toMap(row['before']),
      after: toMap(row['after']),
      at: DateTime.tryParse('${row['at']}') ?? DateTime.now(),
    );
  }
}

class QBankWriteResult {
  const QBankWriteResult.ok() : ok = true, error = null;
  const QBankWriteResult.fail(this.error) : ok = false;
  final bool ok;
  final String? error;
}

class QBankRemoteService {
  QBankRemoteService();

  SupabaseClient get _client => Supabase.instance.client;

  /// True if the current user is in the admin_users allowlist. Result is
  /// cached for the session; call [refreshAdminFlag] to re-check after
  /// switching accounts.
  Future<bool> isAdmin() async {
    if (!supabaseReady) return false;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final row = await _client
          .from('admin_users')
          .select('uid')
          .eq('uid', uid)
          .maybeSingle();
      return row != null;
    } catch (e) {
      debugPrint('isAdmin lookup failed: $e');
      return false;
    }
  }

  /// All published drafts — what the app overlays on bundled JSON at runtime.
  Future<List<QBankDraft>> fetchPublished() async {
    if (!supabaseReady) return const [];
    try {
      final rows = await _client
          .from('qbank_published')
          .select('pool_id, id, payload, updated_at');
      return [
        for (final r in rows as List)
          QBankDraft.fromRow(Map<String, dynamic>.from(r as Map))
      ];
    } catch (e) {
      debugPrint('fetchPublished failed: $e');
      return const [];
    }
  }

  /// All drafts (any status) — what the admin editor shows.
  Future<List<QBankDraft>> fetchAllDrafts({String? poolId}) async {
    if (!supabaseReady) return const [];
    try {
      final q = _client.from('qbank_drafts').select(
          'pool_id, id, status, payload, updated_at');
      final rows = poolId == null
          ? await q.order('updated_at', ascending: false).limit(2000)
          : await q
              .eq('pool_id', poolId)
              .order('updated_at', ascending: false)
              .limit(2000);
      return [
        for (final r in rows as List)
          QBankDraft.fromRow(Map<String, dynamic>.from(r as Map))
      ];
    } catch (e) {
      debugPrint('fetchAllDrafts failed: $e');
      return const [];
    }
  }

  /// Upsert a draft. The full payload must validate (see [validatePayload])
  /// before calling — we don't enforce client schema here, RLS only checks
  /// authorisation.
  Future<QBankWriteResult> upsertDraft({
    required String poolId,
    required String id,
    required QBankDraftStatus status,
    required Map<String, dynamic> payload,
  }) async {
    if (!supabaseReady) return const QBankWriteResult.fail('backend_unavailable');
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const QBankWriteResult.fail('not_signed_in');
    try {
      await _client.from('qbank_drafts').upsert({
        'pool_id': poolId,
        'id': id,
        'status': status.wire,
        'payload': payload,
        'author_uid': uid,
      });
      return const QBankWriteResult.ok();
    } catch (e) {
      debugPrint('upsertDraft failed: $e');
      return QBankWriteResult.fail(e.toString());
    }
  }

  /// Hard-delete. Sets archived first if you want a softer move; this is the
  /// nuke path.
  Future<QBankWriteResult> deleteDraft({
    required String poolId,
    required String id,
  }) async {
    if (!supabaseReady) return const QBankWriteResult.fail('backend_unavailable');
    try {
      await _client
          .from('qbank_drafts')
          .delete()
          .eq('pool_id', poolId)
          .eq('id', id);
      return const QBankWriteResult.ok();
    } catch (e) {
      debugPrint('deleteDraft failed: $e');
      return QBankWriteResult.fail(e.toString());
    }
  }

  /// Recent audit entries across all pools (for the operator's "what changed
  /// lately" view).
  Future<List<QBankAuditEntry>> fetchRecentAudit({int limit = 100}) async {
    if (!supabaseReady) return const [];
    try {
      final rows = await _client
          .from('qbank_audit')
          .select('id, pool_id, question_id, action, before, after, at')
          .order('at', ascending: false)
          .limit(limit);
      return [
        for (final r in rows as List)
          QBankAuditEntry.fromRow(Map<String, dynamic>.from(r as Map))
      ];
    } catch (e) {
      debugPrint('fetchRecentAudit failed: $e');
      return const [];
    }
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Validates a question payload against the same rules as
  /// `scripts/validate_quiz_packs.py`. Returns null on success, a
  /// human-readable error on failure (suitable for snackbar / inline UI).
  static String? validatePayload(Map<String, dynamic> p) {
    String? requireString(String key, {int min = 1, int max = 500}) {
      final v = p[key];
      if (v is! String || v.trim().isEmpty) return '$key is required';
      if (v.length < min) return '$key too short ($min min)';
      if (v.length > max) return '$key too long ($max max)';
      return null;
    }

    final id = requireString('id', max: 64);
    if (id != null) return id;

    final qEn = requireString('question_en', max: 500);
    if (qEn != null) return qEn;

    final qAr = requireString('question_ar', max: 500);
    if (qAr != null) return qAr;

    final opts = p['options'];
    if (opts is! List || opts.length != 4) return 'options must be 4 strings';
    final optsCast = opts.map((e) => '$e').toList();
    if (optsCast.toSet().length != 4) return 'options must be unique';

    final ca = p['correct_answer'];
    if (ca is! String) return 'correct_answer is required';
    if (!optsCast.contains(ca)) return 'correct_answer must be in options';
    if (optsCast.first != ca) return 'correct_answer must be options[0] (canonical position)';

    final optsAr = p['options_ar'];
    if (optsAr != null) {
      if (optsAr is! List || optsAr.length != 4) return 'options_ar must be 4 strings';
      final cast = optsAr.map((e) => '$e').toList();
      if (cast.toSet().length != 4) return 'options_ar must be unique';
      final caAr = p['correct_answer_ar'];
      if (caAr is! String) return 'correct_answer_ar is required when options_ar is set';
      if (!cast.contains(caAr)) return 'correct_answer_ar must be in options_ar';
    }

    final diff = p['difficulty'];
    if (diff != null) {
      if (diff is! int || diff < 1 || diff > 3) return 'difficulty must be 1, 2, or 3';
    }

    return null;
  }
}
