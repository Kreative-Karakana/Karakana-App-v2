import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/payments/providers/course_checkout_controller.dart';
import 'package:karakana_app/features/payments/screens/payment_screen.dart';
import 'package:karakana_app/features/payments/services/course_checkout_service.dart';
import 'package:karakana_app/features/payments/utils/payment_url_launcher.dart';

class FakeCourseCheckoutApi implements CourseCheckoutApi {
  Map<String, dynamic> checkoutResponse = {
    'external_id': 'local-attempt-1',
    'payment_state': 'PENDING',
    'initiation_state': 'AMBIGUOUS',
    'action': 'poll_status',
    'recoverable': true,
  };
  Map<String, dynamic>? activeResponse;
  Map<String, dynamic> statusResponse = {
    'external_id': 'local-attempt-1',
    'payment_state': 'PENDING',
    'recoverable': true,
  };
  Object? checkoutError;
  Object? recoveryError;
  int checkoutCalls = 0;
  int recoveryCalls = 0;
  final List<String> statusIds = [];

  @override
  Future<Map<String, dynamic>> createCheckout({
    required int courseId,
    required String accountNumber,
    required String provider,
  }) async {
    checkoutCalls += 1;
    final error = checkoutError;
    if (error != null) throw error;
    return checkoutResponse;
  }

  @override
  Future<Map<String, dynamic>?> findActiveAttempt(int courseId) async {
    recoveryCalls += 1;
    final error = recoveryError;
    if (error != null) throw error;
    return activeResponse;
  }

  @override
  Future<Map<String, dynamic>> getPaymentStatus(String externalId) async {
    statusIds.add(externalId);
    return statusResponse;
  }
}

CourseCheckoutController controller(FakeCourseCheckoutApi api) {
  return CourseCheckoutController(
    courseId: 29,
    service: api,
    urlLauncher: PaymentUrlLauncher(
      launchUrlDelegate: (uri, mode) async => true,
    ),
    pollInterval: const Duration(days: 1),
    maxPollAttempts: 1,
  );
}

void main() {
  test(
    'ambiguous acceptance retains identity and blocks duplicate initiation',
    () async {
      final api = FakeCourseCheckoutApi();
      final checkout = controller(api);

      await checkout.startCheckout(
        accountNumber: '255710000000',
        provider: 'Airtel',
      );
      await checkout.startCheckout(
        accountNumber: '255710000000',
        provider: 'Airtel',
      );

      expect(api.checkoutCalls, 1);
      expect(checkout.activeExternalId, 'local-attempt-1');
      expect(checkout.hasActiveAttempt, isTrue);
      expect(checkout.state, CourseCheckoutState.waitingForPayment);
      expect(checkout.message, contains('Usilipe tena'));
      checkout.dispose();
    },
  );

  test('SUCCESS remains pending until backend reports SETTLED', () async {
    final api = FakeCourseCheckoutApi()
      ..checkoutResponse = {
        'external_id': 'local-attempt-1',
        'payment_state': 'SUCCESS',
        'recoverable': true,
      };
    final checkout = controller(api);

    await checkout.startCheckout(
      accountNumber: '255710000000',
      provider: 'Airtel',
    );
    expect(checkout.state, CourseCheckoutState.waitingForPayment);

    api.statusResponse = {
      'external_id': 'local-attempt-1',
      'payment_state': 'SETTLED',
    };
    await checkout.checkPaymentStatus();

    expect(api.statusIds, ['local-attempt-1']);
    expect(checkout.state, CourseCheckoutState.settled);
    expect(checkout.hasActiveAttempt, isFalse);
    checkout.dispose();
  });

  test('restart recovery adopts the same course-scoped attempt', () async {
    final api = FakeCourseCheckoutApi()
      ..activeResponse = {
        'external_id': 'recovered-attempt',
        'payment_state': 'PROCESSING',
        'recoverable': true,
      };
    final checkout = controller(api);

    await checkout.recoverActiveAttempt();
    await checkout.checkPaymentStatus();

    expect(api.checkoutCalls, 0);
    expect(api.statusIds, ['recovered-attempt']);
    expect(checkout.activeExternalId, 'recovered-attempt');
    checkout.dispose();
  });

  test(
    'uncertain POST response recovers backend attempt before allowing retry',
    () async {
      final api = FakeCourseCheckoutApi()
        ..checkoutError = StateError('connection lost')
        ..activeResponse = {
          'external_id': 'accepted-before-disconnect',
          'payment_state': 'PENDING',
          'initiation_state': 'AMBIGUOUS',
          'recoverable': true,
        };
      final checkout = controller(api);

      await checkout.startCheckout(
        accountNumber: '255710000000',
        provider: 'Airtel',
      );
      await checkout.startCheckout(
        accountNumber: '255710000000',
        provider: 'Airtel',
      );

      expect(api.checkoutCalls, 1);
      expect(api.recoveryCalls, 1);
      expect(checkout.activeExternalId, 'accepted-before-disconnect');
      expect(checkout.state, CourseCheckoutState.waitingForPayment);
      checkout.dispose();
    },
  );

  test(
    'failed recovery keeps initiation locked while outcome is unknown',
    () async {
      final api = FakeCourseCheckoutApi()
        ..checkoutError = StateError('connection lost')
        ..recoveryError = StateError('recovery unavailable');
      final checkout = controller(api);

      await checkout.startCheckout(
        accountNumber: '255710000000',
        provider: 'Airtel',
      );
      await checkout.startCheckout(
        accountNumber: '255710000000',
        provider: 'Airtel',
      );

      expect(api.checkoutCalls, 1);
      expect(checkout.hasActiveAttempt, isTrue);
      expect(checkout.state, CourseCheckoutState.timedOut);
      expect(checkout.message, contains('Usilipe tena'));

      await checkout.retryStatusCheck();
      expect(api.recoveryCalls, 2);
      expect(checkout.hasActiveAttempt, isTrue);
      expect(checkout.state, CourseCheckoutState.timedOut);
      checkout.dispose();
    },
  );

  test('nonterminal response with identity fails safe into polling', () async {
    final api = FakeCourseCheckoutApi()
      ..checkoutResponse = {'external_id': 'unclassified-attempt'};
    final checkout = controller(api);

    await checkout.startCheckout(
      accountNumber: '255710000000',
      provider: 'Airtel',
    );

    expect(checkout.activeExternalId, 'unclassified-attempt');
    expect(checkout.hasActiveAttempt, isTrue);
    expect(checkout.state, CourseCheckoutState.waitingForPayment);
    checkout.dispose();
  });

  test(
    'terminal failure releases the controller for a deliberate new attempt',
    () async {
      final api = FakeCourseCheckoutApi();
      final checkout = controller(api);
      await checkout.startCheckout(
        accountNumber: '255710000000',
        provider: 'Airtel',
      );

      api.statusResponse = {
        'external_id': 'local-attempt-1',
        'payment_state': 'FAILED',
      };
      await checkout.checkPaymentStatus();
      await checkout.startCheckout(
        accountNumber: '255710000000',
        provider: 'Airtel',
      );

      expect(api.checkoutCalls, 2);
      checkout.dispose();
    },
  );

  testWidgets('recovered attempt disables the Purchase button', (tester) async {
    final api = FakeCourseCheckoutApi()
      ..activeResponse = {
        'external_id': 'recovered-attempt',
        'payment_state': 'PENDING',
        'recoverable': true,
      };
    final checkout = controller(api);

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentScreen(
          courseId: 29,
          courseTitle: 'Controlled course',
          coursePrice: 1000,
          checkoutController: checkout,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Malipo yanaendelea kuthibitishwa'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);

    await tester.pumpWidget(const SizedBox());
    checkout.dispose();
  });
}
