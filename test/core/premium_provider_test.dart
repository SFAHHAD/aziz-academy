import 'package:flutter_test/flutter_test.dart';

import 'package:aziz_academy/core/providers/premium_provider.dart';

void main() {
  final now = DateTime(2026, 5, 17, 12);

  group('isEntitlementActive', () {
    test('a non-premium row is never active', () {
      expect(
        isEntitlementActive(isPremium: false, until: null, now: now),
        isFalse,
      );
      expect(
        isEntitlementActive(
          isPremium: false,
          until: now.add(const Duration(days: 30)),
          now: now,
        ),
        isFalse,
      );
    });

    test('premium with no expiry is active', () {
      expect(
        isEntitlementActive(isPremium: true, until: null, now: now),
        isTrue,
      );
    });

    test('premium is active while the period is in the future', () {
      expect(
        isEntitlementActive(
          isPremium: true,
          until: now.add(const Duration(days: 1)),
          now: now,
        ),
        isTrue,
      );
    });

    test('premium has lapsed once the period is in the past', () {
      expect(
        isEntitlementActive(
          isPremium: true,
          until: now.subtract(const Duration(days: 1)),
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('PremiumState', () {
    test('free is not premium', () {
      expect(PremiumState.free.isPremium, isFalse);
      expect(PremiumState.free.plan, isNull);
    });

    test('carries plan and expiry', () {
      final until = now.add(const Duration(days: 365));
      final s = PremiumState(isPremium: true, plan: 'yearly', until: until);
      expect(s.isPremium, isTrue);
      expect(s.plan, 'yearly');
      expect(s.until, until);
    });
  });
}
