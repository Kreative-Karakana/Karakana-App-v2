// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get paymentSuccessTitle => 'Payment successful!';

  @override
  String get paymentSuccessSubtitle =>
      'You now have access to your course. Start learning now!';

  @override
  String get paymentSuccessStatusLabel => 'Status';

  @override
  String get paymentSuccessStatusValue => 'Successful';

  @override
  String get paymentSuccessDateLabel => 'Date';

  @override
  String get paymentSuccessStartLearning => 'Start Learning';

  @override
  String get paymentSuccessBackHome => 'Back Home';
}
