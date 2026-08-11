import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/subscriptions/models/entitlement_status.dart';
import 'package:karakana_app/features/subscriptions/utils/post_activation_redirect.dart';

void main() {
  const inactive = EntitlementStatus(
    hasActiveSubscription: false,
    trialEligible: false,
    status: 'none',
    expiryDate: null,
  );
  const active = EntitlementStatus(
    hasActiveSubscription: true,
    trialEligible: false,
    status: 'active',
    expiryDate: null,
  );

  test('redirects to Business Management after fresh backend confirmation',
      () async {
    final coordinator = PostActivationRedirectCoordinator();
    var redirects = 0;

    final confirmed = await coordinator.confirmAndRedirect(
      refreshEntitlement: () async => active,
      redirect: () async => redirects += 1,
      delay: (_) async {},
    );

    expect(confirmed, isTrue);
    expect(redirects, 1);
    expect(businessManagementRoute, '/zana/biz-manager');
  });

  test('does not redirect when entitlement remains inactive', () async {
    final coordinator = PostActivationRedirectCoordinator();
    var refreshes = 0;
    var redirects = 0;

    final confirmed = await coordinator.confirmAndRedirect(
      refreshEntitlement: () async {
        refreshes += 1;
        return inactive;
      },
      redirect: () async => redirects += 1,
      maxAttempts: 3,
      delay: (_) async {},
    );

    expect(confirmed, isFalse);
    expect(refreshes, 3);
    expect(redirects, 0);
  });

  test('bounded retry catches a late gateway entitlement update', () async {
    final coordinator = PostActivationRedirectCoordinator();
    var refreshes = 0;
    var redirects = 0;

    final confirmed = await coordinator.confirmAndRedirect(
      refreshEntitlement: () async {
        refreshes += 1;
        return refreshes < 3 ? inactive : active;
      },
      redirect: () async => redirects += 1,
      maxAttempts: 4,
      delay: (_) async {},
    );

    expect(confirmed, isTrue);
    expect(refreshes, 3);
    expect(redirects, 1);
  });

  test('concurrent success callbacks cannot navigate twice', () async {
    final coordinator = PostActivationRedirectCoordinator();
    final response = Completer<EntitlementStatus?>();
    var refreshes = 0;
    var redirects = 0;

    Future<EntitlementStatus?> refresh() {
      refreshes += 1;
      return response.future;
    }

    final first = coordinator.confirmAndRedirect(
      refreshEntitlement: refresh,
      redirect: () async => redirects += 1,
    );
    final second = coordinator.confirmAndRedirect(
      refreshEntitlement: refresh,
      redirect: () async => redirects += 1,
    );
    response.complete(active);

    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(refreshes, 1);
    expect(redirects, 1);

    await coordinator.confirmAndRedirect(
      refreshEntitlement: refresh,
      redirect: () async => redirects += 1,
    );
    expect(refreshes, 1);
    expect(redirects, 1);
  });
}
