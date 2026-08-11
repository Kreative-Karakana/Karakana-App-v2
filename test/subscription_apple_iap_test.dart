import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:karakana_app/features/payments/services/iap_service.dart';
import 'package:karakana_app/features/subscriptions/config/subscription_checkout_config.dart';
import 'package:karakana_app/features/subscriptions/models/entitlement_status.dart';
import 'package:karakana_app/features/subscriptions/models/subscription_plan.dart';
import 'package:karakana_app/features/subscriptions/screens/subscription_screen.dart';

import 'support/fake_subscription_api.dart';

const weeklyProduct = 'com.kreativekarakana.karakana.subscription.weekly';
const monthlyProduct = 'com.kreativekarakana.karakana.subscription.monthly';

class _FakeSubscriptionStore implements SubscriptionPurchaseStore {
  bool available = true;
  IAPPurchaseResult purchaseResult = const IAPPurchaseResult(IAPResult.success);
  IAPPurchaseResult restoreResult =
      const IAPPurchaseResult(IAPResult.nothingToRestore);
  final Set<String> loaded = {};
  final Set<String> queried = {};
  final List<String> purchases = [];
  int restores = 0;
  VoidCallback? onPurchase;
  VoidCallback? onRestore;

  final Map<String, ProductDetails> products = {
    weeklyProduct: ProductDetails(
      id: weeklyProduct,
      title: 'Wiki moja',
      description: 'Usimamizi wa Biashara',
      price: 'TSh 4,900',
      rawPrice: 4900,
      currencyCode: 'TZS',
    ),
    monthlyProduct: ProductDetails(
      id: monthlyProduct,
      title: 'Mwezi mmoja',
      description: 'Usimamizi wa Biashara',
      price: 'TSh 24,900',
      rawPrice: 24900,
      currencyCode: 'TZS',
    ),
  };

  @override
  Future<bool> initialize() async => available;

  @override
  Future<void> loadProducts(
    Set<String> productIds, {
    IAPProductKind? kind,
  }) async {
    queried.addAll(productIds);
    loaded.addAll(productIds.where(products.containsKey));
  }

  @override
  ProductDetails? getProduct(String productId) =>
      loaded.contains(productId) ? products[productId] : null;

  @override
  StoreProductPresentation? getSubscriptionPresentation(String productId) {
    final product = getProduct(productId);
    if (product == null) return null;
    return StoreProductPresentation(
      localizedPrice: product.price,
      billingPeriod: productId == weeklyProduct ? 'kwa wiki' : 'kwa mwezi',
    );
  }

  @override
  Future<IAPPurchaseResult> purchase(
    String productId, {
    IAPProductKind kind = IAPProductKind.course,
  }) async {
    purchases.add(productId);
    onPurchase?.call();
    return purchaseResult;
  }

  @override
  Future<IAPPurchaseResult> restorePurchases() async {
    restores += 1;
    onRestore?.call();
    return restoreResult;
  }
}

List<SubscriptionPlan> _plans() => const [
      SubscriptionPlan(
        id: 1,
        name: 'Daily',
        slug: 'usimamizi-wa-biashara-daily',
        billingPeriod: 'daily',
        durationDays: 1,
        price: '1000.00',
        currency: 'TZS',
        features: [],
        appleIapProductId: 'com.kreativekarakana.karakana.subscription.daily',
      ),
      SubscriptionPlan(
        id: 2,
        name: 'Weekly',
        slug: 'usimamizi-wa-biashara-weekly',
        billingPeriod: 'weekly',
        durationDays: 7,
        price: '4900.00',
        currency: 'TZS',
        features: [],
        appleIapProductId: weeklyProduct,
      ),
      SubscriptionPlan(
        id: 3,
        name: 'Monthly',
        slug: 'usimamizi-wa-biashara-monthly',
        billingPeriod: 'monthly',
        durationDays: 30,
        price: '24900.00',
        currency: 'TZS',
        features: [],
        appleIapProductId: monthlyProduct,
      ),
    ];

Future<(FakeSubscriptionApi, GoRouter)> _pump(
  WidgetTester tester, {
  required _FakeSubscriptionStore store,
  required SubscriptionCheckoutConfig config,
  EntitlementStatus? status,
}) async {
  final api = FakeSubscriptionApi(
    status: status ??
        const EntitlementStatus(
          hasActiveSubscription: false,
          trialEligible: true,
          status: 'none',
          expiryDate: null,
        ),
    plans: _plans(),
  );
  final router = GoRouter(
    initialLocation: '/subscription',
    routes: [
      GoRoute(
        path: '/subscription',
        builder: (_, __) => SubscriptionScreen(
          service: api,
          purchaseStore: store,
          checkoutConfig: config,
        ),
      ),
      GoRoute(
        path: '/zana/biz-manager',
        builder: (_, __) => const Scaffold(body: Text('Business unlocked')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return (api, router);
}

void main() {
  const ios = SubscriptionCheckoutConfig(
    enableExternalSubscriptionCheckout: false,
    enableAppleIap: true,
    enableGooglePlayBilling: false,
  );
  const android = SubscriptionCheckoutConfig(
    enableExternalSubscriptionCheckout: true,
    enableAppleIap: false,
    enableGooglePlayBilling: false,
  );

  testWidgets('iOS offers only weekly/monthly using StoreKit prices',
      (tester) async {
    final store = _FakeSubscriptionStore();
    await _pump(tester, store: store, config: ios);

    expect(
      find.byKey(
        const Key('subscription-choice-usimamizi-wa-biashara-daily'),
      ),
      findsNothing,
    );
    expect(find.text('TSh 4,900'), findsOneWidget);
    expect(find.text('TSh 24,900'), findsOneWidget);
    expect(find.text('kwa wiki'), findsOneWidget);
    expect(find.text('kwa mwezi'), findsOneWidget);
    expect(find.text('Nunua Sasa'), findsNWidgets(2));
    expect(find.text('Endelea na Malipo'), findsNothing);
    expect(store.loaded, {weeklyProduct, monthlyProduct});
    expect(store.queried, {weeklyProduct, monthlyProduct});
  });

  testWidgets('successful Apple purchase refreshes backend entitlement',
      (tester) async {
    final store = _FakeSubscriptionStore();
    final (api, _) = await _pump(tester, store: store, config: ios);
    final initialRefreshes = api.entitlementStatusCalls;
    store.onPurchase = () {
      api.status = EntitlementStatus(
        hasActiveSubscription: true,
        trialEligible: false,
        status: 'active',
        expiryDate: DateTime.now().add(const Duration(days: 7)),
      );
    };

    await tester.tap(find.text('Nunua Sasa').first);
    await tester.pumpAndSettle();

    expect(store.purchases, [weeklyProduct]);
    expect(api.entitlementStatusCalls, greaterThan(initialRefreshes));
    expect(find.text('Business unlocked'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('backend verification failure does not refresh entitlement',
      (tester) async {
    final store = _FakeSubscriptionStore()
      ..purchaseResult = const IAPPurchaseResult(
        IAPResult.error,
        message: 'Uthibitisho wa usajili umeshindwa.',
      );
    final (api, _) = await _pump(tester, store: store, config: ios);
    final initialRefreshes = api.entitlementStatusCalls;

    await tester.tap(find.text('Nunua Sasa').first);
    await tester.pumpAndSettle();

    expect(api.entitlementStatusCalls, initialRefreshes);
    expect(find.text('Business unlocked'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('pending Apple purchase remains locked and explains its state',
      (tester) async {
    final store = _FakeSubscriptionStore()
      ..purchaseResult = const IAPPurchaseResult(IAPResult.pending);
    final (api, _) = await _pump(tester, store: store, config: ios);
    final initialRefreshes = api.entitlementStatusCalls;

    await tester.tap(find.text('Nunua Sasa').first);
    await tester.pumpAndSettle();

    expect(api.entitlementStatusCalls, initialRefreshes);
    expect(find.text('Malipo yanasubiri uthibitisho.'), findsOneWidget);
    expect(find.text('Business unlocked'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('successful restore refreshes entitlement and unlocks access',
      (tester) async {
    final store = _FakeSubscriptionStore()
      ..restoreResult = const IAPPurchaseResult(IAPResult.success);
    final (api, _) = await _pump(tester, store: store, config: ios);
    final initialRefreshes = api.entitlementStatusCalls;
    store.onRestore = () {
      api.status = EntitlementStatus(
        hasActiveSubscription: true,
        trialEligible: false,
        status: 'active',
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        plan: _plans().last,
      );
    };

    final restore = find.text('Rejesha Ununuzi Uliopita');
    await tester.scrollUntilVisible(
      restore,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(restore);
    await tester.pumpAndSettle();

    expect(store.restores, 1);
    expect(api.entitlementStatusCalls, greaterThan(initialRefreshes));
    expect(find.text('Business unlocked'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('empty restore completes cleanly', (tester) async {
    final store = _FakeSubscriptionStore();
    await _pump(tester, store: store, config: ios);

    final restore = find.text('Rejesha Ununuzi Uliopita');
    await tester.scrollUntilVisible(
      restore,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(restore);
    await tester.pumpAndSettle();

    expect(store.restores, 1);
    expect(
      find.text('Hakuna ununuzi wa kurejesha kwenye akaunti hii.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Android keeps EVPay routing without StoreKit actions',
      (tester) async {
    final store = _FakeSubscriptionStore();
    await _pump(tester, store: store, config: android);

    expect(find.text('Endelea na Malipo'), findsNWidgets(2));
    expect(find.text('4,900 TZS'), findsOneWidget);
    expect(find.text('24,900 TZS'), findsOneWidget);
    expect(find.text('BURE'), findsOneWidget);
    expect(
      find.byKey(
        const Key('subscription-choice-usimamizi-wa-biashara-daily'),
      ),
      findsNothing,
    );
    expect(find.text('Nunua Sasa'), findsNothing);
    expect(find.text('Rejesha Ununuzi Uliopita'), findsNothing);
    expect(store.loaded, isEmpty);
  });

  testWidgets(
      'Android honors an existing backend entitlement acquired through Apple',
      (tester) async {
    final store = _FakeSubscriptionStore();
    await _pump(
      tester,
      store: store,
      config: android,
      status: EntitlementStatus(
        hasActiveSubscription: true,
        trialEligible: false,
        status: 'active',
        expiryDate: DateTime.now().add(const Duration(days: 20)),
        plan: _plans().last,
      ),
    );

    expect(find.text('USAJILI AMILIFU'), findsOneWidget);
    expect(find.text('Endelea na Malipo'), findsNothing);
    expect(find.text('Nunua Sasa'), findsNothing);
  });

  testWidgets(
      'iOS honors an existing backend entitlement acquired through EVPay',
      (tester) async {
    final store = _FakeSubscriptionStore();
    await _pump(
      tester,
      store: store,
      config: ios,
      status: EntitlementStatus(
        hasActiveSubscription: true,
        trialEligible: false,
        status: 'active',
        expiryDate: DateTime.now().add(const Duration(days: 20)),
        plan: _plans().last,
      ),
    );

    expect(find.text('USAJILI AMILIFU'), findsOneWidget);
    expect(find.text('Endelea na Malipo'), findsNothing);
    expect(find.text('Nunua Sasa'), findsNothing);
  });
}
