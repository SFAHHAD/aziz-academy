import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The device's account identity.
///
/// Phase 1a (current): every install has an **official guest identity** —
/// a stable, locally-generated id that persists across launches. The app
/// is fully usable as a guest with no registration; this is the default
/// and always will be.
///
/// Phase 1b (next): an optional parent sign-in (Apple / Google via
/// Firebase Auth) attaches a cloud identity *to this guest id*, so the
/// kid's progress can sync across devices. The guest id becomes the
/// merge key — nothing is lost when a guest later signs in.
///
/// No PII is stored here. The guest id is a random token, not derived
/// from anything personal.
enum AccountTier {
  /// No cloud account — playing locally. The default.
  guest,

  /// A parent has signed in; cloud sync is available. (Phase 1b.)
  signedIn,
}

class AccountState {
  const AccountState({required this.guestId, this.tier = AccountTier.guest});

  /// Stable, locally-generated identity for this install. Always present —
  /// it is the merge key a cloud account will later attach to.
  final String guestId;

  /// Current account tier. `guest` until a parent signs in.
  final AccountTier tier;

  bool get isGuest => tier == AccountTier.guest;

  /// Short, human-readable form for display ("G-AB12CD" → "AB12CD").
  String get shortCode =>
      guestId.startsWith('G-') ? guestId.substring(2) : guestId;

  AccountState copyWith({String? guestId, AccountTier? tier}) => AccountState(
    guestId: guestId ?? this.guestId,
    tier: tier ?? this.tier,
  );
}

const _kGuestIdKey = 'account_guest_id_v1';

/// Characters used for the guest id — unambiguous (no 0/O, 1/I/L) so the
/// short code is easy for a parent to read aloud or type.
const _kIdAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

/// Generates a fresh guest id like `G-7QK4MX2P`. Pure — exposed for tests.
String generateGuestId([Random? random]) {
  final r = random ?? Random.secure();
  final buf = StringBuffer('G-');
  for (var i = 0; i < 8; i++) {
    buf.write(_kIdAlphabet[r.nextInt(_kIdAlphabet.length)]);
  }
  return buf.toString();
}

final accountProvider = AsyncNotifierProvider<AccountNotifier, AccountState>(
  AccountNotifier.new,
  name: 'accountProvider',
);

class AccountNotifier extends AsyncNotifier<AccountState> {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _prefsInstance() async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<AccountState> build() async {
    final prefs = await _prefsInstance();
    var id = prefs.getString(_kGuestIdKey);
    if (id == null || id.isEmpty) {
      // First launch — mint and persist the guest identity once.
      id = generateGuestId();
      await prefs.setString(_kGuestIdKey, id);
    }
    return AccountState(guestId: id);
  }
}
