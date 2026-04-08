import 'package:aziz_academy/core/models/recap_module.dart';
import 'package:aziz_academy/core/providers/recap_queue_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecapEntry.tryParse', () {
    test('parses non-math without snap', () {
      final e = RecapEntry.tryParse({'m': 'capitals', 'id': 'q1'});
      expect(e, isNotNull);
      expect(e!.module, RecapModule.capitals);
      expect(e.questionId, 'q1');
      expect(e.snapshotJson, isNull);
    });

    test('parses math with snap', () {
      final e = RecapEntry.tryParse({
        'm': 'math',
        'id': 'm1',
        'snap': '{"stem":"2+2"}',
      });
      expect(e, isNotNull);
      expect(e!.module, RecapModule.math);
      expect(e.snapshotJson, '{"stem":"2+2"}');
    });

    test('drops math without snap', () {
      expect(RecapEntry.tryParse({'m': 'math', 'id': 'm1'}), isNull);
    });

    test('parses maps', () {
      final e = RecapEntry.tryParse({'m': 'maps', 'id': 'x1'});
      expect(e, isNotNull);
      expect(e!.module, RecapModule.maps);
    });
  });
}
