import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:karakana_app/features/payments/providers/iap_provider.dart';
import 'package:karakana_app/features/payments/services/iap_service.dart';

class _FakePurchaseStore implements SubscriptionPurchaseStore {
  bool available = true;
  IAPPurchaseResult result = const IAPPurchaseResult(IAPResult.success);
  String? failure;
  int initializeCalls = 0;
  final purchases = <String>[];

  @override
  Future<bool> initialize() async {
    initializeCalls++;
    if (failure != null) throw StateError(failure!);
    return available;
  }

  @override
  Future<void> loadProducts(
    Set<String> productIds, {
    IAPProductKind? kind,
  }) async {}

  @override
  ProductDetails? getProduct(String productId) => null;

  @override
  StoreProductPresentation? getSubscriptionPresentation(String productId) =>
      null;

  @override
  Future<IAPPurchaseResult> purchase(
    String productId, {
    IAPProductKind kind = IAPProductKind.course,
  }) async {
    purchases.add(productId);
    if (failure != null) throw StateError(failure!);
    return result;
  }

  @override
  Future<IAPPurchaseResult> restorePurchases() async => result;
}

void main() {
  test(
    'initialization records unavailable store as a user-facing error',
    () async {
      final store = _FakePurchaseStore()..available = false;
      final provider = IAPProvider(store: store);

      await provider.initializeForCourse('course.product');

      expect(store.initializeCalls, 1);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, contains('Uthibitisho'));
    },
  );

  test('successful purchase marks the provider as successful', () async {
    final store = _FakePurchaseStore();
    final provider = IAPProvider(store: store);

    await provider.purchase('course.product');

    expect(store.purchases, ['course.product']);
    expect(provider.purchaseSuccess, isTrue);
    expect(provider.errorMessage, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('cancelled and pending purchases do not unlock the course', () async {
    final store = _FakePurchaseStore();
    final provider = IAPProvider(store: store);

    store.result = const IAPPurchaseResult(IAPResult.cancelled);
    await provider.purchase('course.product');
    expect(provider.purchaseSuccess, isFalse);
    expect(provider.errorMessage, isNull);

    store.result = const IAPPurchaseResult(IAPResult.pending);
    await provider.purchase('course.product');
    expect(provider.purchaseSuccess, isFalse);
    expect(provider.errorMessage, contains('subiri'));
  });

  test('failed purchase exposes the payment error and stays locked', () async {
    final store = _FakePurchaseStore()
      ..result = const IAPPurchaseResult(
        IAPResult.error,
        message: 'Store error',
      );
    final provider = IAPProvider(store: store);

    await provider.purchase('course.product');

    expect(provider.purchaseSuccess, isFalse);
    expect(provider.errorMessage, 'Store error');
    expect(provider.isLoading, isFalse);
  });
}
