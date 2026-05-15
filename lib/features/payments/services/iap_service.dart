import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/secure_storage.dart';

enum IAPResult { success, error, pending, cancelled }

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

  Completer<IAPPurchaseResult>? _pendingCompleter;

  Future<bool> initialize() async {
    if (!Platform.isIOS) return false;

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

  Future<void> loadProducts(Set<String> productIds) async {
    if (productIds.isEmpty) return;
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(productIds);
    for (final product in response.productDetails) {
      _products[product.id] = product;
    }
  }

  ProductDetails? getProduct(String productId) => _products[productId];

  Future<IAPPurchaseResult> purchase(String productId) async {
    final product = _products[productId];
    if (product == null) {
      await loadProducts({productId});
      final retried = _products[productId];
      if (retried == null) {
        return const IAPPurchaseResult(
          IAPResult.error,
          message: 'Bidhaa hii haikupatikana kwenye App Store.',
        );
      }
    }

    final PurchaseParam param =
        PurchaseParam(productDetails: _products[productId]!);

    _pendingCompleter = Completer<IAPPurchaseResult>();

    try {
      await _iap.buyNonConsumable(purchaseParam: param);
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
          final result = await _verifyWithBackend(purchase);
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

  Future<IAPPurchaseResult> _verifyWithBackend(PurchaseDetails purchase) async {
    final receiptData = purchase.verificationData.serverVerificationData;
    final productId = purchase.productID;

    try {
      final token = await SecureStorage().getToken();
      final response = await ApiClient().dio.post(
        '/api/v1/payments/apple-iap/verify/',
        data: {
          'receipt_data': receiptData,
          'product_id': productId,
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
      } else {
        return const IAPPurchaseResult(
          IAPResult.error,
          message: 'Uthibitisho wa malipo umeshindwa. Wasiliana na msaada.',
        );
      }
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
