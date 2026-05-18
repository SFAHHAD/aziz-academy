import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/quiz_bests_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts empty when no record exists', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final bests = await container.read(quizBestsProvider.future);
    expect(bests.bestFor('number_bonds:ten'), 0);
    expect(bests.hasRecord('number_bonds:ten'), isFalse);
  });

  test('recordScore stores a new best and returns isNewBest=true', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(quizBestsProvider.future); // build
    final res = await container
        .read(quizBestsProvider.notifier)
        .recordScore('number_bonds:ten', 7);
    expect(res.isNewBest, isTrue);
    expect(res.previousBest, 0);
    final after = container.read(quizBestsProvider).value!;
    expect(after.bestFor('number_bonds:ten'), 7);
  });

  test('lower score does not overwrite a higher one', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(quizBestsProvider.future);
    await container
        .read(quizBestsProvider.notifier)
        .recordScore('number_bonds:ten', 9);
    final res = await container
        .read(quizBestsProvider.notifier)
        .recordScore('number_bonds:ten', 5);
    expect(res.isNewBest, isFalse);
    expect(res.previousBest, 9);
    expect(container.read(quizBestsProvider).value!.bestFor('number_bonds:ten'),
        9);
  });

  test('keys are independent across modes', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(quizBestsProvider.future);
    final notifier = container.read(quizBestsProvider.notifier);
    await notifier.recordScore('number_bonds:ten', 8);
    await notifier.recordScore('number_bonds:twenty', 6);
    await notifier.recordScore('place_value:blocks', 10);
    final v = container.read(quizBestsProvider).value!;
    expect(v.bestFor('number_bonds:ten'), 8);
    expect(v.bestFor('number_bonds:twenty'), 6);
    expect(v.bestFor('place_value:blocks'), 10);
    expect(v.bestFor('skip_counting:twos'), 0);
  });

  test('state persists across container disposals', () async {
    final c1 = ProviderContainer();
    await c1.read(quizBestsProvider.future);
    await c1
        .read(quizBestsProvider.notifier)
        .recordScore('skip_counting:fives', 10);
    c1.dispose();

    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    final reloaded = await c2.read(quizBestsProvider.future);
    expect(reloaded.bestFor('skip_counting:fives'), 10);
  });
}
