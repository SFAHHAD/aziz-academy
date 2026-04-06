import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/main.dart';

void main() {
  testWidgets('AzizAcademyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AzizAcademyApp()),
    );
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
