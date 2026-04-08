import 'package:aziz_academy/core/services/local_backup_service.dart';
import 'package:aziz_academy/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('validateBackupPayload', () {
    test('accepts v2 export shape', () {
      expect(
        validateBackupPayload({
          'v': 2,
          'app': 'aziz_academy',
          'achievements': <String, dynamic>{},
          'recapQueue': <dynamic>[],
        }, l10n),
        isNull,
      );
    });

    test('accepts v1 export shape', () {
      expect(
        validateBackupPayload({
          'v': 1,
          'app': 'aziz_academy',
          'achievements': <String, dynamic>{},
          'recapQueue': <dynamic>[],
        }, l10n),
        isNull,
      );
    });

    test('rejects wrong app id', () {
      expect(
        validateBackupPayload({
          'v': 2,
          'app': 'other',
          'achievements': <String, dynamic>{},
          'recapQueue': <dynamic>[],
        }, l10n),
        isNotNull,
      );
    });

    test('rejects bad version', () {
      expect(
        validateBackupPayload({
          'v': 99,
          'app': 'aziz_academy',
          'achievements': <String, dynamic>{},
          'recapQueue': <dynamic>[],
        }, l10n),
        isNotNull,
      );
    });
  });
}
