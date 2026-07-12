import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/subscriptions/models/entitlement_status.dart';
import 'package:karakana_app/features/subscriptions/models/subscription_plan.dart';
import 'package:karakana_app/features/subscriptions/models/trial_activation_result.dart';
import 'package:karakana_app/features/subscriptions/providers/subscription_status_provider.dart';

import 'support/fake_subscription_api.dart';

/// Issue #33: [SubscriptionStatusProvider] is what the subscription screen
/// actually renders off — these tests exercise its loading/error/trial
/// states in isolation from any widget tree, mirroring the pattern
/// `BusinessManagementProvider`'s own tests use.
void main() {
  group('SubscriptionStatusProvider.load', () {
    test('populates entitlement and plans on success', () async {
      final api = FakeSubscriptionApi(
        status: const EntitlementStatus(
          hasActiveSubscription: true,
          status: 'active',
          expiryDate: null,
        ),
        plans: const [
          SubscriptionPlan(
            id: 1,
            name: 'Monthly',
            slug: 'monthly',
            billingPeriod: 'monthly',
            durationDays: 30,
            price: '5000.00',
            currency: 'TZS',
            features: [],
          ),
        ],
      );
      final provider = SubscriptionStatusProvider(service: api);

      await provider.load();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.entitlement?.isActive, isTrue);
      expect(provider.plans, hasLength(1));
      expect(provider.plans.single.name, 'Monthly');
    });

    test('surfaces a friendly error and leaves entitlement null on failure',
        () async {
      final api = FakeSubscriptionApi()
        ..failNext = DioException(
          requestOptions: RequestOptions(path: '/api/v1/subscriptions/me/'),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 500,
            data: {'detail': 'Hitilafu ya seva.'},
          ),
        );
      final provider = SubscriptionStatusProvider(service: api);

      await provider.load();

      expect(provider.isLoading, isFalse);
      expect(provider.entitlement, isNull);
      expect(provider.errorMessage, isNotNull);
    });

    test('a plans-catalog failure does not block entitlement from loading',
        () async {
      final api = FakeSubscriptionApi()
        ..failNextPlans = DioException(
          requestOptions: RequestOptions(path: '/api/v1/subscriptions/plans/'),
        );
      final provider = SubscriptionStatusProvider(service: api);

      await provider.load();

      expect(provider.entitlement, isNotNull);
      expect(provider.errorMessage, isNull);
      expect(provider.plansErrorMessage, isNotNull);
      expect(provider.plans, isEmpty);
    });
  });

  group('SubscriptionStatusProvider.activateTrial', () {
    test('a fresh trial returns true and refreshes entitlement', () async {
      const trialEntitlement = EntitlementStatus(
        hasActiveSubscription: true,
        status: 'trial',
        expiryDate: null,
      );
      final api = FakeSubscriptionApi(
        trialActivationResult: const TrialActivationResult(
          trialStarted: true,
          entitlement: trialEntitlement,
        ),
      );
      final provider = SubscriptionStatusProvider(service: api);

      final started = await provider.activateTrial();

      expect(started, isTrue);
      expect(provider.entitlement?.isTrial, isTrue);
      expect(provider.isActivatingTrial, isFalse);
    });

    test('an already-used trial returns false without erroring', () async {
      const noneEntitlement = EntitlementStatus(
        hasActiveSubscription: false,
        status: 'none',
        expiryDate: null,
      );
      final api = FakeSubscriptionApi(
        trialActivationResult: const TrialActivationResult(
          trialStarted: false,
          entitlement: noneEntitlement,
        ),
      );
      final provider = SubscriptionStatusProvider(service: api);

      final started = await provider.activateTrial();

      expect(started, isFalse);
      expect(provider.trialErrorMessage, isNull);
      expect(provider.entitlement?.isNone, isTrue);
    });

    test('a network failure surfaces trialErrorMessage', () async {
      final api = FakeSubscriptionApi()
        ..failNextTrialActivation = DioException(
          requestOptions:
              RequestOptions(path: '/api/v1/subscriptions/trial/activate/'),
        );
      final provider = SubscriptionStatusProvider(service: api);

      final started = await provider.activateTrial();

      expect(started, isFalse);
      expect(provider.trialErrorMessage, isNotNull);
    });
  });
}
