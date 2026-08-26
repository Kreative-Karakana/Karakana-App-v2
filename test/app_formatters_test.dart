import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/core/utils/formatters.dart';

void main() {
  group('AppFormatters.currency', () {
    test('formats whole and decimal amounts with TZS by default', () {
      expect(AppFormatters.currency(12500), 'TZS 12,500');
      expect(AppFormatters.currency(12500.4), 'TZS 12,500');
    });

    test('accepts numeric strings with existing separators', () {
      expect(AppFormatters.currency('12,500.00'), 'TZS 12,500');
    });

    test('formats large amounts fully unless compact is requested', () {
      expect(AppFormatters.currency(1250000), 'TZS 1,250,000');
      expect(
        AppFormatters.currency(1250000, compact: true),
        'TZS 1.3M',
      );
      expect(AppFormatters.currency(12000, compact: true), 'TZS 12K');
    });

    test('uses an explicit free label only for zero', () {
      expect(AppFormatters.currency(0), 'TZS 0');
      expect(AppFormatters.currency(0, zeroLabel: 'Bure'), 'Bure');
    });

    test('preserves legitimate negative financial values', () {
      expect(AppFormatters.currency(-5000), 'TZS -5,000');
      expect(AppFormatters.currency(-1250000, compact: true), 'TZS -1.3M');
    });

    test('uses a stable zero value for invalid amounts', () {
      expect(AppFormatters.currency(null), 'TZS 0');
      expect(AppFormatters.currency('not-a-number'), 'TZS 0');
      expect(AppFormatters.currency(double.nan), 'TZS 0');
    });

    test('supports backend-provided currency codes', () {
      expect(
        AppFormatters.currency(12500, currencyCode: 'USD'),
        'USD 12,500',
      );
    });
  });

  group('AppDateFormat', () {
    final date = DateTime(2026, 8, 26, 14, 5);

    test('formats the standard display date', () {
      expect(AppDateFormat.display.format(date), '26 Aug 2026');
    });

    test('formats the standard date and time', () {
      expect(AppDateFormat.displayWithTime.format(date), '26 Aug 2026, 14:05');
    });

    test('keeps a long format for certificates', () {
      expect(AppDateFormat.longDisplay.format(date), '26 August 2026');
    });
  });
}
