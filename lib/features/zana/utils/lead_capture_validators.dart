abstract final class LeadCaptureValidators {
  static const invalidPhoneMessage = 'Weka nambari sahihi, mfano 0712345678.';

  static String? name(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Weka jina lako.';
    if (name.runes.length > 255) {
      return 'Jina ni refu sana. Tumia herufi zisizozidi 255.';
    }
    return null;
  }

  static String? phone(String? value) {
    final rawPhone = value?.trim() ?? '';
    if (rawPhone.isEmpty) return 'Weka nambari ya simu.';

    final phone = normalizePhone(rawPhone);
    final isLocal = RegExp(r'^0\d{9}$').hasMatch(phone);
    final isInternational = RegExp(r'^\+?255\d{9}$').hasMatch(phone);
    return isLocal || isInternational ? null : invalidPhoneMessage;
  }

  static String normalizePhone(String value) {
    return value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
  }
}
