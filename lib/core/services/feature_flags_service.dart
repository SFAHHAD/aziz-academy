import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aziz_academy/core/providers/premium_provider.dart';
import 'package:aziz_academy/core/services/supabase_bootstrap.dart';

// =============================================================================
// Feature flag service (v2 — tier-aware)
//
// Source of truth for "which sections does this user see?" Combines:
//   - feature_flags.tier — admin-controlled (off / free / pro)
//   - premiumProvider     — is THIS user a Plus subscriber?
//
// Behaviour:
//   tier=off  → hidden for everyone (kill switch)
//   tier=free → visible to everyone
//   tier=pro  → visible to Plus subscribers; others see upsell
//
// Fail-open default: if Supabase is down, all sections render. We never
// hide content because of a transient backend issue.
// =============================================================================

enum FeatureTier { off, free, pro }

FeatureTier _parseTier(String? s) {
  switch (s) {
    case 'off':  return FeatureTier.off;
    case 'free': return FeatureTier.free;
    case 'pro':  return FeatureTier.pro;
    default:     return FeatureTier.free;
  }
}

class FeatureFlag {
  const FeatureFlag({
    required this.key,
    required this.tier,
    required this.labelEn,
    required this.labelAr,
    required this.category,
  });

  final String key;
  final FeatureTier tier;
  final String labelEn;
  final String labelAr;
  final String category;

  factory FeatureFlag.fromRow(Map<String, dynamic> row) => FeatureFlag(
        key: row['key'] as String,
        tier: _parseTier(row['tier'] as String?),
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
          .select('key, tier, label_en, label_ar, category')
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

  /// Visible flags only (off ones excluded). What the app caches at boot.
  Future<Map<String, FeatureTier>> fetchVisibleKeys() async {
    if (!supabaseReady) return const {};
    try {
      final rows = await _client
          .from('feature_flags_visible')
          .select('key, tier');
      return {
        for (final r in rows as List)
          (Map<String, dynamic>.from(r as Map))['key'] as String:
              _parseTier((Map<String, dynamic>.from(r as Map))['tier'] as String?),
      };
    } catch (e) {
      debugPrint('feature_flags fetchVisibleKeys failed: $e');
      return const {};
    }
  }

  /// Set a flag's tier. Used by the admin UI.
  Future<bool> setTier({required String key, required FeatureTier tier}) async {
    if (!supabaseReady) return false;
    try {
      await _client
          .from('feature_flags')
          .update({'tier': tier.name})
          .eq('key', key);
      return true;
    } catch (e) {
      debugPrint('feature_flags setTier failed: $e');
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

/// {key: tier} of all NON-OFF flags. App reads this at boot + on refresh.
final visibleFeatureKeysProvider = FutureProvider<Map<String, FeatureTier>>((ref) async {
  return ref.watch(featureFlagsServiceProvider).fetchVisibleKeys();
});

/// What the user actually sees for a given key:
///   - returns `null`        → hidden (off, or not in DB)
///   - returns `pro_locked`  → exists as Pro, user is not Plus — show upsell
///   - returns `unlocked`    → render normally
enum FeatureVisibility { hidden, proLocked, unlocked }

FeatureVisibility featureVisibility(WidgetRef ref, String key) {
  final tiersAsync = ref.watch(visibleFeatureKeysProvider);
  final premiumAsync = ref.watch(premiumProvider);

  // Default: when we don't know, render. Don't hide content on transient errors.
  final tiers = tiersAsync.maybeWhen(
    data: (m) => m,
    orElse: () => const <String, FeatureTier>{},
  );

  // If feature_flags hasn't been wired yet (empty map), assume everything is unlocked.
  if (tiers.isEmpty) return FeatureVisibility.unlocked;

  final tier = tiers[key];
  if (tier == null) return FeatureVisibility.hidden;
  if (tier == FeatureTier.free) return FeatureVisibility.unlocked;

  // tier == pro: check premium
  final isPremium = premiumAsync.maybeWhen(
    data: (p) => p.isPremium,
    orElse: () => false,
  );
  return isPremium ? FeatureVisibility.unlocked : FeatureVisibility.proLocked;
}

/// Convenience reader for screens that just want a yes/no on visibility.
bool featureEnabled(WidgetRef ref, String key) {
  return featureVisibility(ref, key) == FeatureVisibility.unlocked;
}
