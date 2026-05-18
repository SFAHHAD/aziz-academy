import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/family_profiles_provider.dart';
import 'package:aziz_academy/core/providers/profile_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Gender.normalize', () {
    test('keeps the canonical values', () {
      expect(Gender.normalize('boy'), Gender.boy);
      expect(Gender.normalize('girl'), Gender.girl);
      expect(Gender.normalize(''), Gender.unset);
    });

    test('degrades unknown / null input to unset', () {
      expect(Gender.normalize(null), Gender.unset);
      expect(Gender.normalize('male'), Gender.unset);
      expect(Gender.normalize('BOY'), Gender.unset);
      expect(Gender.normalize('other'), Gender.unset);
    });
  });

  group('ProfileSlot gender', () {
    test('json roundtrip preserves gender', () {
      const s = ProfileSlot(
        id: 2,
        name: 'Sara',
        ageBand: '6-8',
        avatarEmoji: '🦄',
        gender: Gender.girl,
      );
      final back = ProfileSlot.fromJson(s.toJson());
      expect(back.gender, Gender.girl);
    });

    test('unset gender is omitted from json but reads back as unset', () {
      const s = ProfileSlot(
        id: 0,
        name: 'A',
        ageBand: '8-10',
        avatarEmoji: '🦉',
      );
      expect(s.toJson().containsKey('g'), isFalse);
      expect(ProfileSlot.fromJson(s.toJson()).gender, Gender.unset);
    });

    test('copyWith updates gender', () {
      const s = ProfileSlot(
        id: 1,
        name: 'A',
        ageBand: '8-10',
        avatarEmoji: '🦉',
      );
      expect(s.copyWith(gender: Gender.boy).gender, Gender.boy);
    });
  });

  group('ProfileState gender', () {
    test('defaults to unset', () {
      expect(const ProfileState().gender, Gender.unset);
    });

    test('setGender persists and normalizes', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(profileProvider.future);
      await c.read(profileProvider.notifier).setGender('girl');
      expect(c.read(profileProvider).value!.gender, Gender.girl);
      await c.read(profileProvider.notifier).setGender('nonsense');
      expect(c.read(profileProvider).value!.gender, Gender.unset);
    });
  });

  group('family provider gender', () {
    test('addSlot stores gender', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(familyProfilesProvider.future);
      await c
          .read(familyProfilesProvider.notifier)
          .addSlot(name: 'Sara', gender: Gender.girl);
      final s = c.read(familyProfilesProvider).value!;
      expect(s.slots.last.gender, Gender.girl);
    });

    test('updateSlot changes gender; mirrors to profileProvider', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(familyProfilesProvider.future);
      await c.read(profileProvider.future);
      await c
          .read(familyProfilesProvider.notifier)
          .updateSlot(0, name: 'Aziz', gender: Gender.boy);
      expect(c.read(familyProfilesProvider).value!.slots.first.gender,
          Gender.boy);
      expect(c.read(profileProvider).value!.gender, Gender.boy);
    });
  });
}
