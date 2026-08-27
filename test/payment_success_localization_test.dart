import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:karakana_app/features/payments/screens/payment_success_screen.dart';
import 'package:karakana_app/l10n/app_localizations.dart';

void main() {
  testWidgets('payment success screen resolves Swahili strings',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('sw'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: PaymentSuccessScreen(),
    ));

    expect(find.text('Malipo Yamefanikiwa!'), findsOneWidget);
    expect(find.text('Anza Kujifunza'), findsOneWidget);
    expect(find.text('Rudi Nyumbani'), findsOneWidget);
  });
}
