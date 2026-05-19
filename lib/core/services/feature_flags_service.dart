import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aziz_academy/core/services/supabase_bootstrap.dart';

// =============================================================================
// Feature flag service
//
// One source of truth for "is this section currently enabled in production?"
// Read by everything that renders a section tile or routes to one; written
// only by the admin via the dashboard.
//
// Behaviour when Supabase is unavailable: all flags default to ON. We never
// hide a section because of a transient backend failure — that would be worse
// than briefly showing a broken section. The admin should leave critical
// sections enabled and only flip new/experimental ones.
// =============================================================================

class FeatureFlag {
  const FeatureFlag({
    required this.key,
    required this.enabled,
    required this.labelEn,
    required this.labelAr,
    required this.category,
  });

  final String key;
  final bool enabled;
  final String labelEn;
  final String labelAr;
  final String category;

  factory FeatureFlag.fromRow(Map<String, dynamic> row) => FeatureFlag(
        key: row['key'] as String,
        enabled: row['enabled'] as bool? ?? true,
        labelEn: (row['label_en'] as String?) ?? '',
        labelAr: (row['label_ar'] as String?) ?? '',
        category: (row['category'] as String?) ?? 'feature',
      );
}

class FeatureFlagsService {
  FeatureFlagsService();

  SupabaseClient get _client => Supabase.instance.client;

  /// Pull every flag (admin view).
  Future<List<FeatureFlag>> fetchAll() async {
    if (!supabaseReady) return const [];
    try {
      final rows = await _client
          .from('feature_flags')
          .select('key, enabled, label_en, label_ar, category')
          .order('category')
          .order('key');
      return [
        for (final r in rows as List)
          FeatureFlag.fromRow(Map<String, dynamic>.from(r as Map))
      ];
    } catch (e) {
      debugPrint('feature_flags fetchAll failed: $e');
      return const [];
    }
  }

  /// Pull only the enabled keys (app boot — minimal payload).
  Future<Set<String>> fetchEnabledKeys() async {
    if (!supabaseReady) return const {};
    try {
      final rows = await _client.from('feature_flags_enabled').select('key');
      return {
        for (final r in rows as List)
          (Map<String, dynamic>.from(r as Map))['key'] as String
      };
    } catch (e) {
      debugPrint('feature_flags fetchEnabledKeys failed: $e');
      return const {};
    }
  }

  Future<bool> setEnabled({required String key, required bool enabled}) async {
    if (!supabaseReady) return false;
    try {
      await _client
          .from('feature_flags')
          .update({'enabled': enabled})
          .eq('key', key);
      return true;
    } catch (e) {
      debugPrint('feature_flags setEnabled failed: $e');
      return false;
    }
  }
}

// -----------------------------------------------------------------------------
// Riverpod plumbing
// -----------------------------------------------------------------------------

final featureFlagsServiceProvider = Provider<FeatureFlagsService>((ref) {
  return FeatureFlagsService();
});

/// All flags (admin UI).
final allFeatureFlagsProvider = FutureProvider<List<FeatureFlag>>((ref) async {
  return ref.watch(featureFlagsServiceProvider).fetchAll();
});

/// The set of enabled keys, cached for the session. App boot warms this;
/// admin toggles invalidate it.
final enabledFeatureKeysProvider = FutureProvider<Set<String>>((ref) async {
  return ref.watch(featureFlagsServiceProvider).fetchEnabledKeys();
});

/// Convenience reader. Defaults to TRUE so a transient Supabase outage
/// never hides core sections. The admin should leave critical sections
/// enabled and use this primarily to gate experimental / risky features.
bool featureEnabled(WidgetRef ref, String key) {
  final asyncSet = ref.watch(enabledFeatureKeysProvider);
  return asyncSet.maybeWhen(
    data: (s) => s.contains(key) || s.isEmpty,
    orElse: () => true,
  );
}
