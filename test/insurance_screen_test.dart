import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/core/theme/app_colors.dart';
import 'package:karakana_app/features/zana/screens/insurance_screen.dart';

void main() {
  testWidgets('hero uses the same deep gradient as the Zana cards',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: InsuranceScreen()),
    );

    final hero = tester.widget<Container>(
      find.byKey(const Key('insurance-hero')),
    );
    final decoration = hero.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;

    expect(gradient.colors, AppColors.zanaGradient);
    expect(
      gradient.colors,
      const [
        Color(0xFF1A0A00),
        Color(0xFF3D1800),
        Color(0xFF7B3A10),
      ],
    );
    expect(tester.takeException(), isNull);
  });
}
