import 'subscription_plan.dart';

class SubscriptionCheckoutRequest {
  final String planSlug;
  final String accountNumber;
  final String provider;

  const SubscriptionCheckoutRequest({
    required this.planSlug,
    required this.accountNumber,
    required this.provider,
  });

  Map<String, dynamic> toJson() {
    return {
      'plan_slug': planSlug,
      'accountNumber': accountNumber,
      'provider': provider,
    };
  }
}

class SubscriptionCheckoutResponse {
  final SubscriptionCheckoutPayment payment;

  const SubscriptionCheckoutResponse({required this.payment});

  factory SubscriptionCheckoutResponse.fromJson(Map<String, dynamic> json) {
    final rawPayment = json['payment'];
    return SubscriptionCheckoutResponse(
      payment: SubscriptionCheckoutPayment.fromJson(
        rawPayment is Map ? rawPayment.cast<String, dynamic>() : const {},
      ),
    );
  }
}

class SubscriptionCheckoutPayment {
  final String externalId;
  final String amount;
  final String expectedAmount;
  final String currency;
  final String purpose;
  final SubscriptionPlan? plan;
  final String? checkoutUrl;
  final String? gateway;
  final bool? success;
  final String? reference;
  final String? responseCode;
  final String? responseDesc;
  final String? orderId;
  final String? source;

  const SubscriptionCheckoutPayment({
    required this.externalId,
    required this.amount,
    required this.expectedAmount,
    required this.currency,
    required this.purpose,
    required this.plan,
    required this.checkoutUrl,
    required this.gateway,
    required this.success,
    required this.reference,
    required this.responseCode,
    required this.responseDesc,
    required this.orderId,
    required this.source,
  });

  factory SubscriptionCheckoutPayment.fromJson(Map<String, dynamic> json) {
    final rawPlan = json['plan'];
    return SubscriptionCheckoutPayment(
      externalId: (json['external_id'] ?? '').toString(),
      amount: (json['amount'] ?? '').toString(),
      expectedAmount: (json['expected_amount'] ?? '').toString(),
      currency: (json['currency'] ?? '').toString(),
      purpose: (json['purpose'] ?? '').toString(),
      plan: rawPlan is Map
          ? SubscriptionPlan.fromJson(rawPlan.cast<String, dynamic>())
          : null,
      checkoutUrl: json['checkout_url']?.toString(),
      gateway: json['gateway']?.toString(),
      success: json['success'] is bool ? json['success'] as bool : null,
      reference: json['reference']?.toString(),
      responseCode: json['response_code']?.toString(),
      responseDesc: json['response_desc']?.toString(),
      orderId: json['order_id']?.toString(),
      source: json['source']?.toString(),
    );
  }
}

class PaymentStatus {
  final bool isSuccessful;
  final bool isFailed;
  final String status;

  const PaymentStatus({
    required this.isSuccessful,
    required this.isFailed,
    required this.status,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] ?? '').toString();
    return PaymentStatus(
      isSuccessful: json['is_successful'] == true,
      isFailed: json['is_failed'] == true || status == 'failed',
      status: status,
    );
  }
}
