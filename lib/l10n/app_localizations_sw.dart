// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get paymentSuccessTitle => 'Malipo Yamefanikiwa!';

  @override
  String get paymentSuccessSubtitle =>
      'Umeingia kwenye kozi yako. Anza kujifunza sasa hivi!';

  @override
  String get paymentSuccessStatusLabel => 'Hali';

  @override
  String get paymentSuccessStatusValue => 'Imefaulu';

  @override
  String get paymentSuccessDateLabel => 'Tarehe';

  @override
  String get paymentSuccessStartLearning => 'Anza Kujifunza';

  @override
  String get paymentSuccessBackHome => 'Rudi Nyumbani';
}
