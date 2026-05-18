import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/account_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('generateGuestId', () {
    test('has the G- prefix and 8 body characters', () {
      final id = generateGuestId(Random(1));
      expect(id.startsWith('G-'), isTrue);
      expect(id.length, 10);
    });

    test('uses only the unambiguous alphabet (no 0/O/1/I/L)', () {
      for (var seed = 0; seed < 50; seed++) {
        final body = generateGuestId(Random(seed)).substring(2);
        expect(RegExp(r'^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]+$').hasMatch(body),
            isTrue, reason: 'bad chars in $body');
      }
    });

    test('is effectively unique across many draws', () {
      final seen = <String>{};
      for (var i = 0; i < 500; i++) {
        seen.add(generateGuestId());
      }
      expect(seen.length, greaterThan(490));
    });
  });

  group('AccountState', () {
    test('defaults to the guest tier', () {
      const s = AccountState(guestId: 'G-ABCDEFGH');
      expect(s.tier, AccountTier.guest);
      expect(s.isGuest, isTrue);
    });

    test('shortCode strips the G- prefix', () {
      expect(const AccountState(guestId: 'G-ABCDEFGH').shortCode,
          'ABCDEFGH');
      expect(const AccountState(guestId: 'PLAIN').shortCode, 'PLAIN');
    });
  });

  group('accountProvider', () {
    test('mints a guest id on first launch', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final state = await c.read(accountProvider.future);
      expect(state.guestId.startsWith('G-'), isTrue);
      expect(state.isGuest, isTrue);
    });

    test('persists the guest id — stable across reloads', () async {
      final c1 = ProviderContainer();
      final first = await c1.read(accountProvider.future);
      c1.dispose();

      // A new container reads the same SharedPreferences-backed value.
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      final second = await c2.read(accountProvider.future);
      expect(second.guestId, first.guestId);
    });

    test('honours a pre-existing stored id', () async {
      SharedPreferences.setMockInitialValues({
        'account_guest_id_v1': 'G-PRESETXX',
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final state = await c.read(accountProvider.future);
      expect(state.guestId, 'G-PRESETXX');
    });
  });
}
