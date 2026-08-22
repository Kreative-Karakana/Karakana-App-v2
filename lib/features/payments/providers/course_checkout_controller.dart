import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../services/course_checkout_service.dart';
import '../utils/payment_url_launcher.dart';
import '../utils/payment_status.dart';

enum CourseCheckoutState {
  idle,
  recovering,
  initiating,
  waitingForPayment,
  settled,
  failed,
  timedOut,
}

class CourseCheckoutController extends ChangeNotifier {
  CourseCheckoutController({
    required this.courseId,
    CourseCheckoutApi? service,
    PaymentUrlLauncher? urlLauncher,
    Duration pollInterval = const Duration(seconds: 3),
    int maxPollAttempts = 20,
  })  : _service = service ?? ApiCourseCheckoutService(),
        _urlLauncher = urlLauncher ?? PaymentUrlLauncher(),
        _pollInterval = pollInterval,
        _maxPollAttempts = maxPollAttempts;

  final int courseId;
  final CourseCheckoutApi _service;
  final PaymentUrlLauncher _urlLauncher;
  final Duration _pollInterval;
  final int _maxPollAttempts;

  CourseCheckoutState _state = CourseCheckoutState.idle;
  String? _activeExternalId;
  String? _message;
  bool _initiationOutcomeUnknown = false;
  int _pollAttempts = 0;
  bool _pollRequestInFlight = false;
  Timer? _pollTimer;

  CourseCheckoutState get state => _state;
  String? get activeExternalId => _activeExternalId;
  String? get message => _message;
  bool get hasActiveAttempt =>
      _activeExternalId?.isNotEmpty == true || _initiationOutcomeUnknown;
  bool get isBusy => const {
        CourseCheckoutState.recovering,
        CourseCheckoutState.initiating,
        CourseCheckoutState.waitingForPayment,
      }.contains(_state);

  Future<void> recoverActiveAttempt() async {
    if (hasActiveAttempt || _state == CourseCheckoutState.recovering) return;
    _setState(CourseCheckoutState.recovering);
    try {
      final active = await _service.findActiveAttempt(courseId);
      if (active == null) {
        _initiationOutcomeUnknown = false;
        _setState(CourseCheckoutState.idle);
        return;
      }
      _adoptAttempt(active);
    } catch (_) {
      // Recovery is best-effort. A subsequent POST remains backend-idempotent.
      _setState(CourseCheckoutState.idle);
    }
  }

  Future<void> startCheckout({
    required String accountNumber,
    required String provider,
  }) async {
    if (hasActiveAttempt || isBusy) return;
    _setState(CourseCheckoutState.initiating);
    try {
      final response = await _service.createCheckout(
        courseId: courseId,
        accountNumber: accountNumber,
        provider: provider,
      );
      final checkoutUrl = response['checkout_url']?.toString() ?? '';
      if (checkoutUrl.isNotEmpty) {
        final externalId = response['external_id']?.toString() ?? '';
        final opened = await _urlLauncher.openCheckoutUrl(checkoutUrl);
        if (!opened && externalId.isNotEmpty) {
          _activeExternalId = externalId;
          _setState(
            CourseCheckoutState.timedOut,
            message: 'Ombi lipo hai lakini ukurasa haukufunguka. Usilipe tena.',
          );
          return;
        }
      }
      _adoptAttempt(response);
    } catch (error) {
      await _recoverAfterInitiationError(error);
    }
  }

  Future<void> _recoverAfterInitiationError(Object initiationError) async {
    _initiationOutcomeUnknown = true;
    _setState(
      CourseCheckoutState.timedOut,
      message: 'Jibu la kuanzisha malipo halijathibitishwa. Usilipe tena.',
    );
    try {
      final active = await _service.findActiveAttempt(courseId);
      if (active != null) {
        _initiationOutcomeUnknown = false;
        _adoptAttempt(active);
        return;
      }
      _initiationOutcomeUnknown = false;
      _activeExternalId = null;
      _stopPolling();
      _setState(
        CourseCheckoutState.failed,
        message: ApiClient().parseError(initiationError),
      );
    } catch (_) {
      // We cannot prove that the POST failed before reaching the backend.
      // Keep initiation disabled until course-scoped recovery succeeds.
    }
  }

  void _adoptAttempt(Map<String, dynamic> response) {
    final externalId = response['external_id']?.toString() ?? '';
    if (externalId.isEmpty) {
      _initiationOutcomeUnknown = true;
      _setState(
        CourseCheckoutState.timedOut,
        message: 'Ombi la malipo halijathibitishwa. Usilipe tena.',
      );
      return;
    }
    _initiationOutcomeUnknown = false;
    if (PaymentStatusContract.isSettled(response)) {
      _activeExternalId = null;
      _stopPolling();
      _setState(CourseCheckoutState.settled);
      return;
    }
    if (PaymentStatusContract.isFailed(response)) {
      _activeExternalId = null;
      _stopPolling();
      _setState(
        CourseCheckoutState.failed,
        message: 'Malipo hayakukamilika. Unaweza kuanzisha malipo mapya.',
      );
      return;
    }
    _activeExternalId = externalId;
    _pollAttempts = 0;
    _setState(
      CourseCheckoutState.waitingForPayment,
      message: PaymentStatusContract.isAmbiguous(response)
          ? 'Ombi la malipo linathibitishwa. Usilipe tena.'
          : 'Thibitisha malipo kwenye simu yako. Usilipe tena.',
    );
    _startPolling();
  }

  void _startPolling() {
    if (!hasActiveAttempt || _pollTimer != null) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => checkPaymentStatus());
  }

  Future<void> checkPaymentStatus() async {
    final externalId = _activeExternalId;
    if (externalId == null || _pollRequestInFlight) return;
    _pollRequestInFlight = true;
    try {
      final response = await _service.getPaymentStatus(externalId);
      if (PaymentStatusContract.isSettled(response)) {
        _activeExternalId = null;
        _stopPolling();
        _setState(CourseCheckoutState.settled);
        return;
      }
      if (PaymentStatusContract.isFailed(response)) {
        _activeExternalId = null;
        _stopPolling();
        _setState(
          CourseCheckoutState.failed,
          message: 'Malipo hayakukamilika. Unaweza kuanzisha malipo mapya.',
        );
        return;
      }
      _pollAttempts += 1;
      if (_pollAttempts >= _maxPollAttempts) {
        _stopPolling();
        _setState(
          CourseCheckoutState.timedOut,
          message:
              'Malipo bado yanathibitishwa. Usilipe tena; angalia hali tena.',
        );
      }
    } catch (_) {
      _pollAttempts += 1;
      if (_pollAttempts >= _maxPollAttempts) {
        _stopPolling();
        _setState(
          CourseCheckoutState.timedOut,
          message:
              'Hatujapata hali ya mwisho. Usilipe tena; angalia hali tena.',
        );
      }
    } finally {
      _pollRequestInFlight = false;
    }
  }

  Future<void> handleAppResumed() async {
    if (_initiationOutcomeUnknown) {
      await _recoverUnknownAttempt();
      return;
    }
    if (!hasActiveAttempt) {
      await recoverActiveAttempt();
      return;
    }
    await checkPaymentStatus();
    if (hasActiveAttempt && _state != CourseCheckoutState.timedOut) {
      _startPolling();
    }
  }

  Future<void> retryStatusCheck() async {
    if (_initiationOutcomeUnknown) {
      await _recoverUnknownAttempt();
      return;
    }
    if (!hasActiveAttempt) return;
    _pollAttempts = 0;
    _setState(
      CourseCheckoutState.waitingForPayment,
      message: 'Malipo yanathibitishwa. Usilipe tena.',
    );
    await checkPaymentStatus();
    if (hasActiveAttempt && _state == CourseCheckoutState.waitingForPayment) {
      _startPolling();
    }
  }

  Future<void> _recoverUnknownAttempt() async {
    _setState(CourseCheckoutState.recovering);
    try {
      final active = await _service.findActiveAttempt(courseId);
      if (active == null) {
        _initiationOutcomeUnknown = false;
        _activeExternalId = null;
        _setState(CourseCheckoutState.idle);
        return;
      }
      _initiationOutcomeUnknown = false;
      _adoptAttempt(active);
    } catch (_) {
      _initiationOutcomeUnknown = true;
      _setState(
        CourseCheckoutState.timedOut,
        message:
            'Hatujaweza kuthibitisha ombi. Usilipe tena; angalia hali tena.',
      );
    }
  }

  void _setState(CourseCheckoutState state, {String? message}) {
    _state = state;
    _message = message;
    notifyListeners();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
