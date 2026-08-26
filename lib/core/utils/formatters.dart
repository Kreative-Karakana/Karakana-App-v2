import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _wholeNumber = NumberFormat('#,##0', 'en_US');

  static String currency(
    Object? value, {
    String currencyCode = 'TZS',
    bool compact = false,
    String? zeroLabel,
  }) {
    final amount = _parseAmount(value);
    final code = currencyCode.trim().isEmpty ? 'TZS' : currencyCode.trim();

    if (amount == null) return '$code 0';
    if (amount == 0 && zeroLabel != null) return zeroLabel;

    final formatted =
        compact ? _formatCompact(amount) : _wholeNumber.format(amount);
    return '$code $formatted';
  }

  static num? _parseAmount(Object? value) {
    final parsed = switch (value) {
      num amount => amount,
      String amount => num.tryParse(amount.replaceAll(',', '').trim()),
      _ => null,
    };

    return parsed != null && parsed.isFinite ? parsed : null;
  }

  static String _formatCompact(num amount) {
    final absolute = amount.abs();
    if (absolute >= 1000000) return '${_compactValue(amount / 1000000)}M';
    if (absolute >= 1000) return '${_compactValue(amount / 1000)}K';
    return _wholeNumber.format(amount);
  }

  static String _compactValue(num value) {
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }
}
