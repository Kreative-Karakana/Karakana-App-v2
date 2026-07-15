import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/features/subscriptions/models/subscription_checkout.dart';

void main() {
  test('checkout request sends only backend-owned subscription fields', () {
    const request = SubscriptionCheckoutRequest(
      planSlug: 'monthly',
      accountNumber: '255712345678',
      provider: 'mpesa',
    );

    expect(request.toJson(), {
      'plan_slug': 'monthly',
      'accountNumber': '255712345678',
      'provider': 'mpesa',
    });
    expect(request.toJson().containsKey('amount'), isFalse);
    expect(request.toJson().containsKey('duration'), isFalse);
    expect(request.toJson().containsKey('expiry'), isFalse);
    expect(request.toJson().containsKey('callbackUrl'), isFalse);
    expect(request.toJson().containsKey('status'), isFalse);
  });

  test('nested payment response parses correctly', () {
    final response = SubscriptionCheckoutResponse.fromJson({
      'payment': {
        'external_id': 'pay-123',
        'amount': '5000.00',
        'expected_amount': '5000.00',
        'currency': 'TZS',
        'purpose': 'subscription',
        'checkout_url': 'https://pay.example.test/checkout',
        'gateway': 'evpay',
        'success': true,
        'reference': 'EVP-1',
        'response_code': '200',
        'response_desc': 'Accepted',
        'order_id': 'ORD-1',
        'source': 'evpay',
        'plan': {
          'id': 7,
          'name': 'Monthly',
          'slug': 'monthly',
          'billing_period': 'monthly',
          'duration_days': 30,
          'price': '5000.00',
          'currency': 'TZS',
          'features': [],
        },
      },
    });

    expect(response.payment.externalId, 'pay-123');
    expect(response.payment.checkoutUrl, contains('pay.example.test'));
    expect(response.payment.plan?.slug, 'monthly');
  });
}
