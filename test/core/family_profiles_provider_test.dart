import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/family_profiles_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('addSlot up to 4, no more', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(familyProfilesProvider.future);
    final n = c.read(familyProfilesProvider.notifier);
    await n.addSlot(name: 'A');
    await n.addSlot(name: 'B');
    await n.addSlot(name: 'C');
    await n.addSlot(name: 'D');
    await n.addSlot(name: 'E'); // ignored
    final s = c.read(familyProfilesProvider).value!;
    expect(s.slots, hasLength(4));
  });

  test('switchTo updates active slot', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(familyProfilesProvider.future);
    final n = c.read(familyProfilesProvider.notifier);
    await n.addSlot(name: 'A');
    final s1 = c.read(familyProfilesProvider).value!;
    final addedId = s1.slots.last.id;
    await n.switchTo(0);
    expect(c.read(familyProfilesProvider).value!.activeSlotId, 0);
    await n.switchTo(addedId);
    expect(c.read(familyProfilesProvider).value!.activeSlotId, addedId);
  });

  test('removeSlot keeps at least 1', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(familyProfilesProvider.future);
    final n = c.read(familyProfilesProvider.notifier);
    final s = c.read(familyProfilesProvider).value!;
    await n.removeSlot(s.slots.first.id);
    expect(c.read(familyProfilesProvider).value!.slots, hasLength(1));
  });

  test('updateSlot mutates fields', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(familyProfilesProvider.future);
    final n = c.read(familyProfilesProvider.notifier);
    await n.updateSlot(0, name: 'Aziz', avatarEmoji: '🐲');
    final s = c.read(familyProfilesProvider).value!;
    expect(s.slots.first.name, 'Aziz');
    expect(s.slots.first.avatarEmoji, '🐲');
  });

  test('ProfileSlot json roundtrip', () {
    const s = ProfileSlot(id: 3, name: 'Aziz', ageBand: '8-10', avatarEmoji: '🦊');
    final back = ProfileSlot.fromJson(s.toJson());
    expect(back.id, 3);
    expect(back.name, 'Aziz');
    expect(back.ageBand, '8-10');
    expect(back.avatarEmoji, '🦊');
  });
}
