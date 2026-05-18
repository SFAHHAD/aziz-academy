import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/services/sync_service.dart';

void main() {
  group('isLocalOnlyKey', () {
    test('excludes the device guest id and auth-library keys', () {
      expect(SyncService.isLocalOnlyKey('account_guest_id_v1'), isTrue);
      expect(SyncService.isLocalOnlyKey('sb-pwd-auth-token'), isTrue);
      expect(SyncService.isLocalOnlyKey('sb_provider_token'), isTrue);
      expect(SyncService.isLocalOnlyKey('supabase.auth.token'), isTrue);
    });

    test('keeps ordinary progress keys', () {
      expect(SyncService.isLocalOnlyKey('xp_total_xp'), isFalse);
      expect(SyncService.isLocalOnlyKey('family_profiles_v1'), isFalse);
      expect(SyncService.isLocalOnlyKey('profile_v1'), isFalse);
      expect(SyncService.isLocalOnlyKey('profile_activity_v1'), isFalse);
    });
  });

  group('encodeValue', () {
    test('tags each primitive type', () {
      expect(SyncService.encodeValue(true), {'t': 'b', 'v': true});
      expect(SyncService.encodeValue(7), {'t': 'i', 'v': 7});
      expect(SyncService.encodeValue(3.5), {'t': 'd', 'v': 3.5});
      expect(SyncService.encodeValue('hi'), {'t': 's', 'v': 'hi'});
      expect(
        SyncService.encodeValue(['a', 'b']),
        {'t': 'sl', 'v': ['a', 'b']},
      );
    });

    test('returns null for an unsupported value', () {
      expect(SyncService.encodeValue(null), isNull);
    });
  });

  group('snapshot round-trip', () {
    test('snapshotFromPrefs captures every non-local key with its type',
        () async {
      SharedPreferences.setMockInitialValues({
        'xp_total_xp': 1200,
        'profile_v1': '{"n":"Aziz"}',
        'reduced_motion': true,
        'some_ratio': 0.75,
        'continents': ['AS', 'EU'],
        'account_guest_id_v1': 'G-LOCALONLY', // must be excluded
        'sb-x-auth-token': 'secret', // must be excluded
      });
      final prefs = await SharedPreferences.getInstance();
      final snap = SyncService.snapshotFromPrefs(prefs);

      expect(snap.keys, containsAll(<String>[
        'xp_total_xp',
        'profile_v1',
        'reduced_motion',
        'some_ratio',
        'continents',
      ]));
      expect(snap.containsKey('account_guest_id_v1'), isFalse);
      expect(snap.containsKey('sb-x-auth-token'), isFalse);
      expect(snap['xp_total_xp'], {'t': 'i', 'v': 1200});
    });

    test('restoreToPrefs writes the snapshot back with exact types',
        () async {
      SharedPreferences.setMockInitialValues({'xp_total_xp': 1200});
      final source = await SharedPreferences.getInstance();
      final snap = SyncService.snapshotFromPrefs(source);

      // Fresh, empty store on the "other device".
      SharedPreferences.setMockInitialValues({});
      final target = await SharedPreferences.getInstance();
      await SyncService.restoreToPrefs(target, snap);

      expect(target.getInt('xp_total_xp'), 1200);
    });

    test('restore preserves bool / double / string-list types', () async {
      SharedPreferences.setMockInitialValues({
        'flag': true,
        'ratio': 0.5,
        'tags': ['x', 'y', 'z'],
      });
      final source = await SharedPreferences.getInstance();
      final snap = SyncService.snapshotFromPrefs(source);

      SharedPreferences.setMockInitialValues({});
      final target = await SharedPreferences.getInstance();
      await SyncService.restoreToPrefs(target, snap);

      expect(target.getBool('flag'), true);
      expect(target.getDouble('ratio'), 0.5);
      expect(target.getStringList('tags'), ['x', 'y', 'z']);
    });

    test('restore never reinstates an excluded local-only key', () async {
      // A snapshot that (defensively) contains a local-only key.
      final tainted = {
        'xp_total_xp': {'t': 'i', 'v': 5},
        'account_guest_id_v1': {'t': 's', 'v': 'G-FROMCLOUD'},
      };
      SharedPreferences.setMockInitialValues({
        'account_guest_id_v1': 'G-THISDEVICE',
      });
      final prefs = await SharedPreferences.getInstance();
      await SyncService.restoreToPrefs(prefs, tainted);

      expect(prefs.getInt('xp_total_xp'), 5);
      // The device keeps its own identity.
      expect(prefs.getString('account_guest_id_v1'), 'G-THISDEVICE');
    });
  });
}
