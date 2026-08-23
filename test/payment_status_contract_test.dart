import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/payments/utils/payment_status.dart';
import 'package:karakana_app/features/subscriptions/models/subscription_checkout.dart';

void main() {
  test('SUCCESS is approved but not settled', () {
    final payload = {'payment_state': 'SUCCESS', 'is_successful': true};

    expect(PaymentStatusContract.isSettled(payload), isFalse);
    expect(PaymentStatus.fromJson(payload).isSuccessful, isFalse);
  });

  test('SETTLED is the only normalized successful state', () {
    final payload = {'payment_state': 'SETTLED', 'is_successful': true};

    expect(PaymentStatusContract.isSettled(payload), isTrue);
    expect(PaymentStatus.fromJson(payload).isSuccessful, isTrue);
  });

  test('legacy responses retain is_successful fallback', () {
    final payload = {'is_successful': true};

    expect(PaymentStatusContract.isSettled(payload), isTrue);
    expect(PaymentStatus.fromJson(payload).isSuccessful, isTrue);
  });

  test('official EVPay initiation waits for USSD without a URL', () {
    expect(
      PaymentStatusContract.awaitsUssd({
        'gateway': 'evpay',
        'action': 'await_ussd',
      }),
      isTrue,
    );
  });

  test('ambiguous accepted acknowledgement is recoverable but not settled', () {
    final payload = {
      'external_id': 'local-attempt-1',
      'payment_state': 'PENDING',
      'initiation_state': 'AMBIGUOUS',
      'action': 'poll_status',
      'recoverable': true,
    };

    expect(PaymentStatusContract.isAmbiguous(payload), isTrue);
    expect(PaymentStatusContract.isRecoverable(payload), isTrue);
    expect(PaymentStatusContract.isSettled(payload), isFalse);
  });
}
