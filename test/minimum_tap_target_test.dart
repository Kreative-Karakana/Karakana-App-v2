import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/widgets/common/minimum_tap_target.dart';

void main() {
  testWidgets('provides a 44 by 48 tap area without enlarging the icon',
      (tester) async {
    var taps = 0;
    const targetKey = Key('delete-target');

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: MinimumTapTarget(
            key: targetKey,
            semanticsLabel: 'Futa',
            onTap: () => taps += 1,
            child: const Icon(Icons.delete_outline, size: 18),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(targetKey)),
      const Size(
        MinimumTapTarget.minimumWidth,
        MinimumTapTarget.minimumHeight,
      ),
    );
    expect(tester.widget<Icon>(find.byIcon(Icons.delete_outline)).size, 18);

    await tester.tap(find.byKey(targetKey));
    expect(taps, 1);
  });
}
