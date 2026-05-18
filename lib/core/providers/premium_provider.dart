import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aziz_academy/core/providers/auth_session_provider.dart';
import 'package:aziz_academy/core/services/supabase_bootstrap.dart';

/// Whether an entitlement row counts as currently-active premium.
/// Pure — unit-tested. A null [until] means "no expiry tracked".
bool isEntitlementActive({
  required bool isPremium,
  DateTime? until,
  required DateTime now,
}) {
  if (!isPremium) return false;
  if (until == null) return true;
  return until.isAfter(now);
}

/// Premium subscription state for the signed-in account.
class PremiumState {
  const PremiumState({this.isPremium = false, this.plan, this.until});

  final bool isPremium;

  /// 'monthly' | 'yearly' | null.
  final String? plan;

  /// When the current period ends, or null.
  final DateTime? until;

  /// The free (non-premium) state — guests and free accounts.
  static const free = PremiumState();
}

/// Resolves the current account's premium entitlement from Supabase.
///
/// The `entitlements` table is read-only to clients (RLS) — only the
/// payment webhook can grant premium, so a client can never make itself
/// premium. Guests and signed-out users are always [PremiumState.free].
final premiumProvider = FutureProvider<PremiumState>((ref) async {
  final session = ref.watch(authSessionProvider).value ?? AuthSession.guest;
  if (!supabaseReady || !session.signedIn) return PremiumState.free;

  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return PremiumState.free;

  try {
    final row = await client
        .from('entitlements')
        .select('is_premium, plan, premium_until')
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return PremiumState.free;

    final until = DateTime.tryParse('${row['premium_until']}');
    final active = isEntitlementActive(
      isPremium: row['is_premium'] == true,
      until: until,
      now: DateTime.now(),
    );
    return PremiumState(
      isPremium: active,
      plan: row['plan'] as String?,
      until: until,
    );
  } catch (e) {
    debugPrint('premiumProvider lookup failed: $e');
    return PremiumState.free;
  }
});

/// Convenience boolean — true only for an active premium account.
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(premiumProvider).value?.isPremium ?? false;
});
