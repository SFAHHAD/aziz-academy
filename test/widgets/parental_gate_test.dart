import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/core/widgets/parental_gate.dart';

void main() {
  group('ParentalChallenge', () {
    test('answer is the product of the operands', () {
      const ch = ParentalChallenge(13, 7);
      expect(ch.answer, 91);
      expect(ch.question, '13 × 7');
    });

    test('accepts the correct answer, rejects wrong / junk input', () {
      const ch = ParentalChallenge(12, 4);
      expect(ch.accepts('48'), isTrue);
      expect(ch.accepts(' 48 '), isTrue);
      expect(ch.accepts('47'), isFalse);
      expect(ch.accepts(''), isFalse);
      expect(ch.accepts('abc'), isFalse);
    });

    test('generate stays within the intended operand ranges', () {
      for (var seed = 0; seed < 100; seed++) {
        final ch = ParentalChallenge.generate(Random(seed));
        expect(ch.a, inInclusiveRange(11, 19));
        expect(ch.b, inInclusiveRange(3, 9));
      }
    });
  });

  group('showParentalGate dialog', () {
    testWidgets('passing the challenge resolves true', (tester) async {
      late Future<bool> result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      result = showParentalGate(context, arabic: false),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Ask a grown-up'), findsOneWidget);

      // Read the challenge text ("a × b") and solve it.
      final q = tester.widget<Text>(find.textContaining('×')).data!;
      final parts = q.split('×').map((s) => int.parse(s.trim())).toList();
      await tester.enterText(
        find.byType(TextField),
        '${parts[0] * parts[1]}',
      );
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(await result, isTrue);
    });

    testWidgets('cancelling resolves false', (tester) async {
      late Future<bool> result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      result = showParentalGate(context, arabic: false),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    });
  });
}
