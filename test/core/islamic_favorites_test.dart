import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/islamic_favorites_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts with empty sets for every kind', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(islamicFavoritesProvider.future);
    expect(state[IslamicFavKind.hadith], isEmpty);
    expect(state[IslamicFavKind.asma], isEmpty);
    expect(state[IslamicFavKind.prophet], isEmpty);
  });

  test('toggle adds then removes', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(islamicFavoritesProvider.future);
    final notifier = container.read(islamicFavoritesProvider.notifier);

    await notifier.toggle(IslamicFavKind.hadith, 'hdt_001');
    expect(notifier.isFavorite(IslamicFavKind.hadith, 'hdt_001'), isTrue);

    await notifier.toggle(IslamicFavKind.hadith, 'hdt_001');
    expect(notifier.isFavorite(IslamicFavKind.hadith, 'hdt_001'), isFalse);
  });

  test('each kind is namespaced (no cross-contamination)', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(islamicFavoritesProvider.future);
    final notifier = container.read(islamicFavoritesProvider.notifier);

    await notifier.toggle(IslamicFavKind.hadith, 'shared_id');
    expect(notifier.isFavorite(IslamicFavKind.hadith, 'shared_id'), isTrue);
    expect(notifier.isFavorite(IslamicFavKind.asma, 'shared_id'), isFalse);
    expect(notifier.isFavorite(IslamicFavKind.prophet, 'shared_id'), isFalse);
  });

  test('persists across container rebuilds', () async {
    final c1 = ProviderContainer();
    await c1.read(islamicFavoritesProvider.future);
    await c1
        .read(islamicFavoritesProvider.notifier)
        .toggle(IslamicFavKind.asma, '42');
    c1.dispose();

    // New container, same SharedPreferences backing.
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    final state = await c2.read(islamicFavoritesProvider.future);
    expect(state[IslamicFavKind.asma], contains('42'));
  });
}
