import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/widgets/buttons/gradient_button.dart';

void main() {
  testWidgets('supports every button variant', (tester) async {
    for (final variant in AppButtonVariant.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradientButton(
              text: variant.name,
              variant: variant,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text(variant.name), findsOneWidget);
    }
  });

  testWidgets('disabled and loading buttons cannot be activated', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const GradientButton(text: 'Disabled', onTap: null),
              GradientButton(
                text: 'Loading',
                isLoading: true,
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Disabled'), warnIfMissed: false);
    await tester.tap(
      find.byType(CircularProgressIndicator),
      warnIfMissed: false,
    );
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
