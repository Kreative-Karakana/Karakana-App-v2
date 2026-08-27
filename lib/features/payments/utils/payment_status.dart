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

  static bool isAmbiguous(Map<dynamic, dynamic> json) {
    return json['initiation_state']?.toString().toUpperCase() == 'AMBIGUOUS' ||
        json['action'] == 'poll_status';
  }

  static bool isRecoverable(Map<dynamic, dynamic> json) {
    if (isSettled(json) || isFailed(json)) return true;
    final state = normalizedState(json);
    return json['recoverable'] == true ||
        awaitsUssd(json) ||
        isAmbiguous(json) ||
        const {'PENDING', 'PROCESSING', 'SUCCESS', 'ON_HOLD'}.contains(state);
  }
}
