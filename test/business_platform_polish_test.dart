import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:karakana_app/core/theme/app_spacing.dart';
import 'package:karakana_app/features/zana/business_management/widgets/business_confirmation_dialog.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:karakana_app/widgets/common/top_popup.dart';

void main() {
  testWidgets('business confirmation dialog uses the shared design treatment',
      (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showBusinessConfirmationDialog(
                context,
                title: 'Futa Muamala?',
                message: 'Hatua hii haiwezi kutenduliwa.',
                confirmLabel: 'Futa',
                isDestructive: true,
              );
            },
            child: const Text('Fungua'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Fungua'));
    await tester.pumpAndSettle();

    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    final shape = dialog.shape! as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(AppRadius.cardLg));
    expect(find.text('Ghairi'), findsOneWidget);
    expect(find.text('Futa'), findsOneWidget);

    await tester.tap(find.text('Futa'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('loader exposes its supplied progress announcement',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: KarakanaWaveLoader(
          semanticsLabel: 'Inapakia taarifa za biashara',
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Inapakia taarifa za biashara'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('top popup announces status and dismisses on schedule',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showTopPopup(
              context,
              'Muamala umehifadhiwa.',
              type: TopPopupType.success,
              duration: const Duration(milliseconds: 500),
            ),
            child: const Text('Onyesha'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Onyesha'));
    await tester.pump();
    expect(
      find.bySemanticsLabel('Muamala umehifadhiwa.'),
      findsOneWidget,
    );

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Muamala umehifadhiwa.'), findsNothing);
    semantics.dispose();
  });
}
