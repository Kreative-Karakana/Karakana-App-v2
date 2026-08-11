import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/subscriptions/models/entitlement_status.dart';

/// Issue #33: the subscription status screen renders directly off
/// [EntitlementStatus.fromJson] and its derived getters ([remainingDays],
/// [plan]) — these tests pin down that parsing against the exact response
/// shapes documented in docs/apps/subscriptions.md so a backend field
/// rename breaks a test here rather than showing a blank screen.
void main() {
  group('EntitlementStatus.fromJson', () {
    test('never subscribed', () {
      final entitlement = EntitlementStatus.fromJson(const {
        'has_active_subscription': false,
        'trial_eligible': true,
        'status': 'none',
        'subscription': null,
        'features': [],
      });

      expect(entitlement.hasActiveSubscription, isFalse);
      expect(entitlement.trialEligible, isTrue);
      expect(entitlement.isNone, isTrue);
      expect(entitlement.hadPriorAccess, isFalse);
      expect(entitlement.plan, isNull);
      expect(entitlement.expiryDate, isNull);
      expect(entitlement.remainingDays, isNull);
    });

    test('active trial parses plan, start/expiry dates, and features', () {
      final entitlement = EntitlementStatus.fromJson({
        'has_active_subscription': true,
        'trial_eligible': false,
        'status': 'trial',
        'subscription': {
          'id': 1,
          'plan': {
            'id': 2,
            'name': 'Jaribio',
            'slug': 'trial',
            'billing_period': 'custom',
            'duration_days': 3,
            'price': '0.00',
            'currency': 'TZS',
            'features': [
              {
                'code': 'USIMAMIZI_WA_BIASHARA_ACCESS',
                'name': 'Usimamizi wa Biashara',
                'description': '',
              },
            ],
          },
          'status': 'trial',
          'start_date': '2026-07-01T00:00:00Z',
          'expiry_date':
              DateTime.now().add(const Duration(days: 2)).toIso8601String(),
          'created_at': '2026-07-01T00:00:00Z',
        },
        'features': ['USIMAMIZI_WA_BIASHARA_ACCESS'],
      });

      expect(entitlement.isTrial, isTrue);
      expect(entitlement.trialEligible, isFalse);
      expect(entitlement.hasActiveSubscription, isTrue);
      expect(entitlement.plan?.name, 'Jaribio');
      expect(entitlement.plan?.features.single.code,
          'USIMAMIZI_WA_BIASHARA_ACCESS');
      expect(entitlement.featureCodes, ['USIMAMIZI_WA_BIASHARA_ACCESS']);
      expect(entitlement.startDate, DateTime.parse('2026-07-01T00:00:00Z'));
      expect(entitlement.remainingDays, 2);
    });

    test('expired reports the nested (lapsed) subscription, not null', () {
      final entitlement = EntitlementStatus.fromJson(const {
        'has_active_subscription': false,
        'trial_eligible': false,
        'status': 'expired',
        'subscription': {
          'id': 1,
          'plan': null,
          'status': 'trial',
          'start_date': '2026-07-01T00:00:00Z',
          'expiry_date': '2026-07-04T00:00:00Z',
          'created_at': '2026-07-01T00:00:00Z',
        },
        'features': [],
      });

      expect(entitlement.isExpired, isTrue);
      expect(entitlement.trialEligible, isFalse);
      expect(entitlement.hadPriorAccess, isTrue);
      expect(entitlement.expiryDate, DateTime.parse('2026-07-04T00:00:00Z'));
      // Expiry is in the past — remainingDays clamps to zero, never negative.
      expect(entitlement.remainingDays, 0);
    });

    test('expired paid access can remain trial eligible', () {
      final entitlement = EntitlementStatus.fromJson(const {
        'has_active_subscription': false,
        'trial_eligible': true,
        'status': 'expired',
        'subscription': null,
        'features': [],
      });

      expect(entitlement.isExpired, isTrue);
      expect(entitlement.trialEligible, isTrue);
    });
  });
}
