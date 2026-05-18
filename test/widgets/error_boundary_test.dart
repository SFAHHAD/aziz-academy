import 'package:aziz_academy/core/widgets/error_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _Boom extends StatelessWidget {
  const _Boom();
  @override
  Widget build(BuildContext context) {
    throw FlutterError('intentional test failure');
  }
}

void main() {
  setUp(() {
    ErrorWidget.builder = friendlyErrorWidgetBuilder;
  });

  tearDown(() {
    ErrorWidget.builder = (details) => ErrorWidget(details.exception);
  });

  testWidgets('shows the bilingual fallback when a child build throws',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: const _Boom()),
      ),
    );

    // Take the expected exception so the test framework doesn't fail
    // on it — we triggered it on purpose.
    final caught = tester.takeException();
    expect(caught, isA<FlutterError>());

    // Either Arabic or English copy renders depending on the test host's
    // platform locale. Both lines must be from our friendly card.
    final friendlyEn = find.text('Something went wrong');
    final friendlyAr = find.text('حصلت مشكلة بسيطة');
    expect(
      friendlyEn.evaluate().isNotEmpty || friendlyAr.evaluate().isNotEmpty,
      isTrue,
      reason: 'expected friendly error card to render',
    );
  });

  testWidgets('debug builds expose the exception text', (tester) async {
    // Only meaningful in debug. Skip this assertion in release-mode tests.
    if (!kDebugMode) return;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: const _Boom()),
      ),
    );
    expect(tester.takeException(), isA<FlutterError>());
    expect(find.textContaining('intentional test failure'), findsOneWidget);
  });
}
