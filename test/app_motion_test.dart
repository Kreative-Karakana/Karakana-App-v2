import 'package:flutter_test/flutter_test.dart';

import 'package:karakana_app/core/theme/app_spacing.dart';

void main() {
  test('shared motion tokens use short, consistent timings', () {
    expect(AppMotion.fast, const Duration(milliseconds: 180));
    expect(AppMotion.standard, const Duration(milliseconds: 280));
  });
}
