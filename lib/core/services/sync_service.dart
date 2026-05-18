import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aziz_academy/core/services/supabase_bootstrap.dart';

/// Outcome of a sync operation.
enum SyncStatus { ok, empty, notSignedIn, backendUnavailable, error }

class PushResult {
  const PushResult(this.status);
  final SyncStatus status;
  bool get ok => status == SyncStatus.ok;
}

class PullResult {
  const PullResult(this.status, {this.updatedAt});
  final SyncStatus status;
  final DateTime? updatedAt;
  bool get ok => status == SyncStatus.ok;
}

class CloudInfo {
  const CloudInfo({this.exists = false, this.updatedAt});
  final bool exists;
  final DateTime? updatedAt;
}

/// Cloud backup & restore of the device's progress.
///
/// The whole app state lives in `SharedPreferences`, so a sync is just a
/// snapshot of that store — every provider's data is captured with no
/// per-provider wiring, and it stays correct as new features are added.
///
/// Sync is **explicit**: a parent backs up / restores from the Account
/// screen. There is no silent auto-push, so a fresh device can never
/// clobber the cloud copy. Last-write-wins; one JSON document per account
/// in the RLS-locked `account_sync` table.
class SyncService {
  /// Keys that must never leave the device:
  ///  - the guest id is this install's own identity;
  ///  - anything belonging to the Supabase auth library is session state
  ///    and restoring it onto another device would corrupt the login.
  static bool isLocalOnlyKey(String key) {
    final k = key.toLowerCase();
    return key == 'account_guest_id_v1' ||
        k.contains('supabase') ||
        k.startsWith('sb-') ||
        k.startsWith('sb_');
  }

  /// Encodes one SharedPreferences value as a type-tagged, JSON-safe map so
  /// a restore writes back the exact original type (int vs double, etc.).
  static Map<String, dynamic>? encodeValue(Object? v) {
    if (v is bool) return {'t': 'b', 'v': v};
    if (v is int) return {'t': 'i', 'v': v};
    if (v is double) return {'t': 'd', 'v': v};
    if (v is String) return {'t': 's', 'v': v};
    if (v is List) return {'t': 'sl', 'v': v.map((e) => '$e').toList()};
    return null;
  }

  /// Builds the sync snapshot from a prefs store. Pure — unit-tested.
  static Map<String, dynamic> snapshotFromPrefs(SharedPreferences prefs) {
    final out = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      if (isLocalOnlyKey(key)) continue;
      final encoded = encodeValue(prefs.get(key));
      if (encoded != null) out[key] = encoded;
    }
    return out;
  }

  /// Writes a snapshot back into a prefs store. Pure — unit-tested.
  /// Local-only keys in the snapshot are ignored defensively.
  static Future<void> restoreToPrefs(
    SharedPreferences prefs,
    Map<String, dynamic> snapshot,
  ) async {
    for (final entry in snapshot.entries) {
      if (isLocalOnlyKey(entry.key)) continue;
      final cell = entry.value;
      if (cell is! Map) continue;
      final t = cell['t'];
      final v = cell['v'];
      switch (t) {
        case 'b':
          if (v is bool) await prefs.setBool(entry.key, v);
        case 'i':
          if (v is int) await prefs.setInt(entry.key, v);
        case 'd':
          if (v is num) await prefs.setDouble(entry.key, v.toDouble());
        case 's':
          if (v is String) await prefs.setString(entry.key, v);
        case 'sl':
          if (v is List) {
            await prefs.setStringList(
              entry.key,
              v.map((e) => '$e').toList(),
            );
          }
      }
    }
  }

  SupabaseClient get _client => Supabase.instance.client;

  String? get _uid => supabaseReady ? _client.auth.currentUser?.id : null;

  /// Uploads the current device snapshot to the cloud (insert or overwrite).
  Future<PushResult> push() async {
    final uid = _uid;
    if (!supabaseReady) return const PushResult(SyncStatus.backendUnavailable);
    if (uid == null) return const PushResult(SyncStatus.notSignedIn);
    try {
      final prefs = await SharedPreferences.getInstance();
      final snapshot = snapshotFromPrefs(prefs);
      await _client.from('account_sync').upsert({
        'user_id': uid,
        'data': snapshot,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      return const PushResult(SyncStatus.ok);
    } catch (e) {
      debugPrint('Sync push failed: $e');
      return const PushResult(SyncStatus.error);
    }
  }

  /// Downloads the cloud snapshot and writes it over local storage.
  /// The caller must restart the app afterwards so providers re-read.
  Future<PullResult> pull() async {
    final uid = _uid;
    if (!supabaseReady) return const PullResult(SyncStatus.backendUnavailable);
    if (uid == null) return const PullResult(SyncStatus.notSignedIn);
    try {
      final row = await _client
          .from('account_sync')
          .select('data, updated_at')
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null || row['data'] is! Map) {
        return const PullResult(SyncStatus.empty);
      }
      final prefs = await SharedPreferences.getInstance();
      await restoreToPrefs(
        prefs,
        Map<String, dynamic>.from(row['data'] as Map),
      );
      return PullResult(
        SyncStatus.ok,
        updatedAt: DateTime.tryParse('${row['updated_at']}'),
      );
    } catch (e) {
      debugPrint('Sync pull failed: $e');
      return const PullResult(SyncStatus.error);
    }
  }

  /// Reads just whether a cloud copy exists and when it was last written —
  /// used to drive the Account screen without downloading the payload.
  Future<CloudInfo> cloudInfo() async {
    final uid = _uid;
    if (!supabaseReady || uid == null) return const CloudInfo();
    try {
      final row = await _client
          .from('account_sync')
          .select('updated_at')
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) return const CloudInfo();
      return CloudInfo(
        exists: true,
        updatedAt: DateTime.tryParse('${row['updated_at']}'),
      );
    } catch (e) {
      debugPrint('Sync cloudInfo failed: $e');
      return const CloudInfo();
    }
  }

  /// Seeds the cloud from this device only when no cloud copy exists yet —
  /// safe to call right after sign-in (it can never overwrite another
  /// device's data).
  Future<void> seedIfEmpty() async {
    final info = await cloudInfo();
    if (!info.exists) await push();
  }
}

final syncServiceProvider = Provider<SyncService>((ref) => SyncService());
