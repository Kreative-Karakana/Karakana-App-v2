import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/secure_storage.dart';

enum IAPResult { success, error, pending, cancelled }

/// What a product id purchased through [IAPService] should be verified as.
/// [course] and [ebook] hit their one-time Apple purchase endpoints;
/// [subscription] hits the Apple/Google subscription verify endpoints.
enum IAPProductKind { course, ebook, subscription }

class IAPPurchaseResult {
  final IAPResult result;
  final String? message;
  const IAPPurchaseResult(this.result, {this.message});
}

class IAPService {
  IAPService._();
  static final IAPService instance = IAPService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  final Map<String, ProductDetails> _products = {};

  // purchaseStream delivers PurchaseDetails, not whatever call site started
  // it — this is how _onPurchaseUpdate recovers "was this a course or a
  // subscription purchase" to pick the right backend verify endpoint. Set
  // by purchase() or typed product loading. Restore deliveries that were not
  // registered this session still default to subscriptions; the eBook restore
  // follow-up must preload the complete eBook catalog before restore.
  final Map<String, IAPProductKind> _productKinds = {};

  Completer<IAPPurchaseResult>? _pendingCompleter;

  Future<bool> initialize() async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;

    final bool available = await _iap.isAvailable();
    if (!available) return false;

    _subscription ??= _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        _pendingCompleter?.complete(
          IAPPurchaseResult(IAPResult.error, message: error.toString()),
        );
        _pendingCompleter = null;
      },
    );

    return true;
  }

  Future<void> loadProducts(
    Set<String> productIds, {
    IAPProductKind? kind,
  }) async {
    if (productIds.isEmpty) return;
    if (kind != null) {
      for (final productId in productIds) {
        _productKinds[productId] = kind;
      }
    }
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(productIds);
    for (final product in response.productDetails) {
      _products[product.id] = product;
    }
  }

  ProductDetails? getProduct(String productId) => _products[productId];

  Future<IAPPurchaseResult> purchase(
    String productId, {
    IAPProductKind kind = IAPProductKind.course,
  }) async {
    final product = _products[productId];
    if (product == null) {
      await loadProducts({productId}, kind: kind);
      final retried = _products[productId];
      if (retried == null) {
        return IAPPurchaseResult(
          IAPResult.error,
          message: kind == IAPProductKind.subscription
              ? 'Bidhaa hii haikupatikana. Jaribu tena baadaye.'
              : 'Bidhaa hii haikupatikana kwenye App Store.',
        );
      }
    }

    _productKinds[productId] = kind;

    final PurchaseParam param =
        PurchaseParam(productDetails: _products[productId]!);

    _pendingCompleter = Completer<IAPPurchaseResult>();

    try {
      // Play Billing/StoreKit both purchase auto-renewable subscriptions
      // through the same non-consumable entry point as a one-time
      // purchase — there is no separate "buy subscription" call.
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      _pendingCompleter = null;
      return IAPPurchaseResult(IAPResult.error, message: e.toString());
    }

    return _pendingCompleter!.future;
  }

  /// Replays the user's existing store purchases through [purchaseStream]
  /// (each arrives as [PurchaseStatus.restored]) so a reinstalled app or a
  /// new device can recover an active subscription. There is no separate
  /// backend "restore" call — a restored purchase is verified exactly like
  /// a fresh one (see docs/apps/subscriptions.md, Payment provider
  /// integration), which is naturally idempotent on the backend.
  Future<IAPPurchaseResult> restorePurchases() async {
    _pendingCompleter = Completer<IAPPurchaseResult>();
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _pendingCompleter = null;
      return IAPPurchaseResult(IAPResult.error, message: e.toString());
    }
    return _pendingCompleter!.future;
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _pendingCompleter?.complete(
            const IAPPurchaseResult(IAPResult.pending),
          );
          _pendingCompleter = null;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final kind =
              _productKinds[purchase.productID] ?? IAPProductKind.subscription;
          final result = await _verifyWithBackend(purchase, kind);
          await _iap.completePurchase(purchase);
          _pendingCompleter?.complete(result);
          _pendingCompleter = null;
          break;

        case PurchaseStatus.error:
          await _iap.completePurchase(purchase);
          _pendingCompleter?.complete(
            IAPPurchaseResult(
              IAPResult.error,
              message: purchase.error?.message ?? 'Hitilafu ya malipo.',
            ),
          );
          _pendingCompleter = null;
          break;

        case PurchaseStatus.canceled:
          _pendingCompleter?.complete(
            const IAPPurchaseResult(IAPResult.cancelled),
          );
          _pendingCompleter = null;
          break;
      }
    }
  }

  Future<IAPPurchaseResult> _verifyWithBackend(
    PurchaseDetails purchase,
    IAPProductKind kind,
  ) {
    if (kind == IAPProductKind.subscription) {
      return _verifySubscriptionWithBackend(purchase);
    }
    if (kind == IAPProductKind.ebook) {
      return _verifyEbookWithBackend(purchase);
    }
    return _verifyCourseWithBackend(purchase);
  }

  Future<IAPPurchaseResult> _verifyEbookWithBackend(
    PurchaseDetails purchase,
  ) async {
    return _verifyOneTimeApplePurchase(
      purchase,
      path: '/api/v1/payments/apple-iap/ebooks/verify/',
    );
  }

  /// One-time course purchase verification — unchanged from before issue
  /// #32, kept under its own name now that [_verifyWithBackend] branches
  /// on product kind. Apple-only, matching `AppleIAPVerifyView` on the
  /// backend (course purchases are not sold as Google Play subscriptions).
  Future<IAPPurchaseResult> _verifyCourseWithBackend(
    PurchaseDetails purchase,
  ) {
    return _verifyOneTimeApplePurchase(
      purchase,
      path: '/api/v1/payments/apple-iap/verify/',
    );
  }

  Future<IAPPurchaseResult> _verifyOneTimeApplePurchase(
    PurchaseDetails purchase, {
    required String path,
  }) async {
    try {
      final token = await SecureStorage().getToken();
      final response = await ApiClient().dio.post(
            path,
            data: {
              'receipt_data': purchase.verificationData.serverVerificationData,
              'product_id': purchase.productID,
            },
            options: Options(
              headers: {
                'Authorization': 'Token $token',
                'Content-Type': 'application/json',
              },
            ),
          );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return const IAPPurchaseResult(IAPResult.success);
      }
      return const IAPPurchaseResult(
        IAPResult.error,
        message: 'Uthibitisho wa malipo umeshindwa. Wasiliana na msaada.',
      );
    } catch (e) {
      return const IAPPurchaseResult(
        IAPResult.error,
        message: 'Hitilafu ya mtandao. Jaribu tena baadaye.',
      );
    }
  }

  /// Subscription purchase/restore verification (issue #32) — posts to
  /// the Apple or Google subscription verify endpoint depending on
  /// platform. The backend is the only party that decides entitlement
  /// (see docs/apps/subscriptions.md, Security): this call reports
  /// success only once the backend has itself verified the purchase with
  /// Apple/Google and updated `UserSubscription`.
  Future<IAPPurchaseResult> _verifySubscriptionWithBackend(
    PurchaseDetails purchase,
  ) async {
    final bool isIOS = Platform.isIOS;
    final String path = isIOS
        ? '/api/v1/subscriptions/verify/apple/'
        : '/api/v1/subscriptions/verify/google/';
    final Map<String, dynamic> data = isIOS
        ? {'receipt_data': purchase.verificationData.serverVerificationData}
        : {
            'purchase_token': purchase.verificationData.serverVerificationData,
            'product_id': purchase.productID,
          };

    try {
      final token = await SecureStorage().getToken();
      final response = await ApiClient().dio.post(
            path,
            data: data,
            options: Options(
              headers: {
                'Authorization': 'Token $token',
                'Content-Type': 'application/json',
              },
            ),
          );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return const IAPPurchaseResult(IAPResult.success);
      }
      return const IAPPurchaseResult(
        IAPResult.error,
        message: 'Uthibitisho wa usajili umeshindwa. Wasiliana na msaada.',
      );
    } catch (e) {
      return const IAPPurchaseResult(
        IAPResult.error,
        message: 'Hitilafu ya mtandao. Jaribu tena baadaye.',
      );
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
