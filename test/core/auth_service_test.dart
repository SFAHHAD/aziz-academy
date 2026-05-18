import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/core/services/auth_service.dart';

void main() {
  group('isValidEmail', () {
    test('accepts well-formed addresses', () {
      expect(isValidEmail('parent@example.com'), isTrue);
      expect(isValidEmail('  a.b@sub.domain.co  '), isTrue);
    });

    test('rejects malformed addresses', () {
      expect(isValidEmail(''), isFalse);
      expect(isValidEmail('no-at-sign'), isFalse);
      expect(isValidEmail('two@@at.com'), isFalse);
      expect(isValidEmail('no@dot'), isFalse);
      expect(isValidEmail('with space@x.com'), isFalse);
    });
  });

  group('isAcceptablePassword', () {
    test('requires at least 8 characters', () {
      expect(isAcceptablePassword('1234567'), isFalse);
      expect(isAcceptablePassword('12345678'), isTrue);
      expect(isAcceptablePassword('a long enough password'), isTrue);
    });
  });

  group('AuthResult', () {
    test('ok is a live success', () {
      const r = AuthResult.ok();
      expect(r.success, isTrue);
      expect(r.needsConfirmation, isFalse);
      expect(r.messageKey, isNull);
    });

    test('confirmEmail is a success that still needs confirmation', () {
      const r = AuthResult.confirmEmail();
      expect(r.success, isTrue);
      expect(r.needsConfirmation, isTrue);
    });

    test('fail carries a message key and is not a success', () {
      const r = AuthResult.fail('email_in_use');
      expect(r.success, isFalse);
      expect(r.messageKey, 'email_in_use');
      expect(r.needsConfirmation, isFalse);
    });
  });

  group('AuthService without an initialised backend', () {
    test('reports unavailable and never throws', () async {
      // supabaseReady is false in tests — every call must degrade safely.
      final svc = AuthService();
      expect(svc.isAvailable, isFalse);
      expect(svc.isSignedIn, isFalse);
      expect(svc.currentUser, isNull);

      final up = await svc.signUpWithEmail(
        email: 'p@example.com',
        password: 'longenough',
      );
      expect(up.success, isFalse);
      expect(up.messageKey, 'backend_unavailable');

      final inn = await svc.signInWithEmail(
        email: 'p@example.com',
        password: 'longenough',
      );
      expect(inn.success, isFalse);
      expect(inn.messageKey, 'backend_unavailable');

      // signOut is a no-op, not an error.
      await svc.signOut();
    });
  });
}
