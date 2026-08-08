class PaymentStatusContract {
  const PaymentStatusContract._();

  static String normalizedState(Map<dynamic, dynamic> json) {
    return (json['payment_state'] ?? json['status'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
  }

  static bool isSettled(Map<dynamic, dynamic> json) {
    final state = normalizedState(json);
    if (state.isNotEmpty) return state == 'SETTLED';
    return json['is_successful'] == true;
  }

  static bool isFailed(Map<dynamic, dynamic> json) {
    final state = normalizedState(json);
    if (state.isNotEmpty) {
      return const {'FAILED', 'REFUNDED', 'REVERSED'}.contains(state);
    }
    return json['is_failed'] == true || json['status'] == 'failed';
  }

  static bool awaitsUssd(Map<dynamic, dynamic> json) {
    return json['action'] == 'await_ussd' || json['gateway'] == 'evmak_mno';
  }
}
