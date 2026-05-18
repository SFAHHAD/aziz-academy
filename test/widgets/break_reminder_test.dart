import 'package:aziz_academy/core/widgets/break_reminder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BreakReminderHost renders the child without showing the banner '
      'before the threshold elapses', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BreakReminderHost(
          threshold: const Duration(seconds: 5),
          snooze: const Duration(seconds: 1),
          child: const Scaffold(body: Text('CHILD_OK')),
        ),
      ),
    );
    expect(find.text('CHILD_OK'), findsOneWidget);
    // Banner copy should NOT appear immediately.
    expect(find.text('Break time!'), findsNothing);
  });

  testWidgets('BreakReminderHost is a no-op wrapper when never reaches '
      'threshold', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BreakReminderHost(
          threshold: const Duration(hours: 24),
          child: const Scaffold(body: Text('CHILD_OK')),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('CHILD_OK'), findsOneWidget);
    expect(find.text('Break time!'), findsNothing);
  });
}
