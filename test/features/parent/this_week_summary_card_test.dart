import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/providers/daily_quiz_streak_provider.dart';
import 'package:aziz_academy/core/providers/multiplication_progress_provider.dart';
import 'package:aziz_academy/features/parent/presentation/widgets/this_week_summary_card.dart';

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(375, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ThisWeekSummaryCard(arabic: false),
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders with empty state — no callouts, all zeros',
      (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await _pump(tester, c);
    expect(tester.takeException(), isNull);
    // The "Strongest" callout should NOT appear when no tables have data.
    expect(find.textContaining('Strongest'), findsNothing);
    // "At a glance" header is always present.
    expect(find.text('At a glance'), findsOneWidget);
  });

  testWidgets('shows strongest + shaky callout when tables have data',
      (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(multiplicationProgressProvider.future);
    final notifier = c.read(multiplicationProgressProvider.notifier);
    // Strong: ×3 at 100%. Shaky: ×7 at 30%.
    await notifier.recordRound(table: 3, correct: 10, total: 10);
    await notifier.recordRound(table: 7, correct: 3, total: 10);

    await _pump(tester, c);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Strongest'), findsOneWidget);
    expect(find.textContaining('Needs practice'), findsOneWidget);
  });

  testWidgets('renders correctly when only daily streak has data',
      (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(dailyQuizStreakProvider.future);
    await c.read(dailyQuizStreakProvider.notifier).recordAnswer(correct: true);

    await _pump(tester, c);
    expect(tester.takeException(), isNull);
    // Streak tile should show 1.
    expect(find.text('Daily streak'), findsOneWidget);
  });
}
