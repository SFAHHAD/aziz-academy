import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/quran_progress_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts with empty set', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(quranProgressProvider.future);
    expect(state, isEmpty);
  });

  test('toggle adds then removes', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(quranProgressProvider.future);
    final notifier = container.read(quranProgressProvider.notifier);

    await notifier.toggle('surah_al_ikhlas');
    expect(notifier.isMemorized('surah_al_ikhlas'), isTrue);
    expect(container.read(quranProgressProvider).value!.length, 1);

    await notifier.toggle('surah_al_ikhlas');
    expect(notifier.isMemorized('surah_al_ikhlas'), isFalse);
    expect(container.read(quranProgressProvider).value, isEmpty);
  });

  test('isMemorized is false for never-toggled ids', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(quranProgressProvider.future);
    final notifier = container.read(quranProgressProvider.notifier);

    await notifier.toggle('surah_an_nas');
    expect(notifier.isMemorized('surah_an_nas'), isTrue);
    expect(notifier.isMemorized('surah_al_falaq'), isFalse);
    expect(notifier.isMemorized('not_a_surah'), isFalse);
  });

  test('multiple surahs can be tracked independently', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(quranProgressProvider.future);
    final notifier = container.read(quranProgressProvider.notifier);

    await notifier.toggle('surah_al_ikhlas');
    await notifier.toggle('surah_al_falaq');
    await notifier.toggle('surah_an_nas');

    final state = container.read(quranProgressProvider).value!;
    expect(state.length, 3);
    expect(state, containsAll([
      'surah_al_ikhlas',
      'surah_al_falaq',
      'surah_an_nas',
    ]));

    // remove just one
    await notifier.toggle('surah_al_falaq');
    expect(notifier.isMemorized('surah_al_falaq'), isFalse);
    expect(notifier.isMemorized('surah_al_ikhlas'), isTrue);
    expect(notifier.isMemorized('surah_an_nas'), isTrue);
  });

  test('persists across container rebuilds', () async {
    final c1 = ProviderContainer();
    await c1.read(quranProgressProvider.future);
    await c1.read(quranProgressProvider.notifier).toggle('surah_al_kawthar');
    c1.dispose();

    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    final state = await c2.read(quranProgressProvider.future);
    expect(state, contains('surah_al_kawthar'));
  });

  test('handles corrupt stored JSON by returning empty set', () async {
    SharedPreferences.setMockInitialValues({
      'quran_memorized_surahs_v1': 'not-valid-json{',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = await container.read(quranProgressProvider.future);
    expect(state, isEmpty);
  });
}
