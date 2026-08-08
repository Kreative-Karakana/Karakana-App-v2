import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../payments/utils/mobile_money.dart';
import '../../payments/utils/payment_url_launcher.dart';
import '../models/subscription_checkout.dart';
import '../models/subscription_plan.dart';
import '../services/subscription_service.dart';

enum SubscriptionCheckoutState {
  idle,
  creatingCheckout,
  waitingForPayment,
  successful,
  failed,
  timedOut,
}

typedef EntitlementRefreshCallback = Future<void> Function();

class SubscriptionCheckoutProvider extends ChangeNotifier {
  SubscriptionCheckoutProvider({
    SubscriptionApi? service,
    PaymentUrlLauncher? urlLauncher,
    Duration pollInterval = const Duration(seconds: 3),
    int maxPollAttempts = 20,
  }) : _service = service ?? SubscriptionService(),
       _urlLauncher = urlLauncher ?? PaymentUrlLauncher(),
       _pollInterval = pollInterval,
       _maxPollAttempts = maxPollAttempts;

  final SubscriptionApi _service;
  final PaymentUrlLauncher _urlLauncher;
  final Duration _pollInterval;
  final int _maxPollAttempts;

  SubscriptionCheckoutState _state = SubscriptionCheckoutState.idle;
  String? _errorMessage;
  String? _pendingExternalId;
  String? _pendingPlanSlug;
  int _pollAttempts = 0;
  bool _isPolling = false;
  Timer? _pollTimer;

  SubscriptionCheckoutState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get pendingExternalId => _pendingExternalId;
  String? get pendingPlanSlug => _pendingPlanSlug;
  bool get isBusy =>
      _state == SubscriptionCheckoutState.creatingCheckout ||
      _state == SubscriptionCheckoutState.waitingForPayment;
  bool get isWaitingForPayment =>
      _state == SubscriptionCheckoutState.waitingForPayment;
  bool get hasPendingCheckout => _pendingExternalId?.isNotEmpty == true;

  Future<void> startCheckout({
    required SubscriptionPlan plan,
    required String rawPhoneNumber,
    required String provider,
    required EntitlementRefreshCallback refreshEntitlement,
  }) async {
    if (isBusy) return;

    final normalizedPhone = MobileMoney.normalizePhone(rawPhoneNumber);
    if (!MobileMoney.isValidTanzaniaPhone(normalizedPhone)) {
      _state = SubscriptionCheckoutState.failed;
      _errorMessage = 'Weka nambari sahihi ya simu (mfano: 0712345678)';
      notifyListeners();
      return;
    }

    _setState(SubscriptionCheckoutState.creatingCheckout);
    try {
      final result = await _service.createCheckout(
        SubscriptionCheckoutRequest(
          planSlug: plan.slug,
          accountNumber: normalizedPhone,
          provider: provider,
        ),
      );
      final payment = result.payment;
      if (payment.externalId.isEmpty) {
        _fail('Hitilafu ya kuanzisha malipo. Jaribu tena.');
        return;
      }

      _pendingExternalId = payment.externalId;
      _pendingPlanSlug = plan.slug;
      _pollAttempts = 0;

      if (payment.checkoutUrl != null && payment.checkoutUrl!.isNotEmpty) {
        final opened = await _urlLauncher.openCheckoutUrl(payment.checkoutUrl!);
        if (!opened) {
          _fail('Imeshindikana kufungua ukurasa wa malipo. Jaribu tena.');
          return;
        }
      } else if (payment.action != 'await_ussd' &&
          payment.gateway != 'evmak_mno' &&
          payment.success != true) {
        _fail('Kiungo cha malipo hakikupatikana. Jaribu tena.');
        return;
      }

      _setState(SubscriptionCheckoutState.waitingForPayment);
      startPolling(refreshEntitlement: refreshEntitlement);
    } catch (e) {
      _fail(ApiClient().parseError(e));
    }
  }

  void startPolling({required EntitlementRefreshCallback refreshEntitlement}) {
    if (!hasPendingCheckout || _isPolling) return;
    _isPolling = true;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      checkPendingPayment(refreshEntitlement: refreshEntitlement);
    });
  }

  Future<void> checkPendingPayment({
    required EntitlementRefreshCallback refreshEntitlement,
  }) async {
    final externalId = _pendingExternalId;
    if (externalId == null || externalId.isEmpty) return;

    try {
      final status = await _service.getPaymentStatus(externalId);
      if (status.isSuccessful) {
        _stopPolling();
        await refreshEntitlement();
        _pendingExternalId = null;
        _pendingPlanSlug = null;
        _setState(SubscriptionCheckoutState.successful);
        return;
      }

      if (status.isFailed) {
        _stopPolling();
        _setState(
          SubscriptionCheckoutState.failed,
          message: 'Malipo hayakukamilika. Tafadhali jaribu tena.',
        );
        return;
      }

      _pollAttempts += 1;
      if (_pollAttempts >= _maxPollAttempts) {
        _stopPolling();
        _setState(
          SubscriptionCheckoutState.timedOut,
          message:
              'Malipo bado yanasubiri. Unaweza kuangalia hali tena baada ya kuthibitisha.',
        );
      }
    } catch (e) {
      _pollAttempts += 1;
      if (kDebugMode) {
        debugPrint('[SubscriptionCheckoutProvider] poll: $e');
      }
      if (_pollAttempts >= _maxPollAttempts) {
        _stopPolling();
        _setState(
          SubscriptionCheckoutState.timedOut,
          message:
              'Hatukuweza kuthibitisha malipo sasa. Angalia hali tena baada ya muda.',
        );
      }
    }
  }

  Future<void> handleAppResumed({
    required EntitlementRefreshCallback refreshEntitlement,
  }) async {
    if (!hasPendingCheckout) {
      await refreshEntitlement();
      return;
    }
    await checkPendingPayment(refreshEntitlement: refreshEntitlement);
    await refreshEntitlement();
    if (hasPendingCheckout &&
        _state == SubscriptionCheckoutState.waitingForPayment) {
      startPolling(refreshEntitlement: refreshEntitlement);
    }
  }

  void reset() {
    _stopPolling();
    _state = SubscriptionCheckoutState.idle;
    _errorMessage = null;
    _pendingExternalId = null;
    _pendingPlanSlug = null;
    _pollAttempts = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  void _fail(String message) {
    _pendingExternalId = null;
    _pendingPlanSlug = null;
    _stopPolling();
    _setState(SubscriptionCheckoutState.failed, message: message);
  }

  void _setState(SubscriptionCheckoutState state, {String? message}) {
    _state = state;
    _errorMessage = message;
    notifyListeners();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
  }
}
