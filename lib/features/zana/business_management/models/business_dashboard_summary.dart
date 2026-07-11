import 'business.dart';
import 'business_transaction.dart';

class BusinessPeriodSummary {
  final String mauzo;
  final String matumizi;
  final String faidaHasara;
  final String status;
  final String statusText;
  final int miamala;
  final String currency;

  const BusinessPeriodSummary({
    required this.mauzo,
    required this.matumizi,
    required this.faidaHasara,
    required this.status,
    required this.statusText,
    required this.miamala,
    required this.currency,
  });

  double get mauzoValue => double.tryParse(mauzo) ?? 0;
  double get matumiziValue => double.tryParse(matumizi) ?? 0;
  double get faidaHasaraValue => double.tryParse(faidaHasara) ?? 0;
  bool get hasProfit => faidaHasaraValue > 0;
  bool get hasLoss => faidaHasaraValue < 0;

  static const zero = BusinessPeriodSummary(
    mauzo: '0.00',
    matumizi: '0.00',
    faidaHasara: '0.00',
    status: 'sawa',
    statusText: 'Sawa',
    miamala: 0,
    currency: 'TZS',
  );

  factory BusinessPeriodSummary.fromJson(Map<String, dynamic> json) {
    return BusinessPeriodSummary(
      mauzo: _parseAmount(json['mauzo']),
      matumizi: _parseAmount(json['matumizi']),
      faidaHasara: _parseAmount(json['faida_hasara']),
      status: (json['status'] ?? '').toString(),
      statusText: (json['status_text'] ?? '').toString(),
      miamala: (json['miamala'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] ?? 'TZS').toString(),
    );
  }

  static String _parseAmount(dynamic raw) {
    if (raw == null) return '0.00';
    if (raw is num) return raw.toStringAsFixed(2);
    final parsed = double.tryParse(raw.toString());
    return parsed?.toStringAsFixed(2) ?? '0.00';
  }
}

class BusinessDashboardSummary {
  final Business? business;
  final BusinessPeriodSummary allTime;
  final BusinessPeriodSummary today;
  final BusinessPeriodSummary month;
  final List<BusinessTransaction> recentTransactions;

  const BusinessDashboardSummary({
    required this.business,
    required this.allTime,
    required this.today,
    required this.month,
    required this.recentTransactions,
  });

  String get mauzo => allTime.mauzo;
  String get matumizi => allTime.matumizi;
  String get faidaHasara => allTime.faidaHasara;
  String get status => allTime.status;
  String get statusText => allTime.statusText;
  int get miamala => allTime.miamala;
  String get currency => allTime.currency;
  double get mauzoValue => allTime.mauzoValue;
  double get matumiziValue => allTime.matumiziValue;
  double get faidaHasaraValue => allTime.faidaHasaraValue;
  bool get hasProfit => allTime.hasProfit;
  bool get hasLoss => allTime.hasLoss;

  factory BusinessDashboardSummary.fromJson(Map<String, dynamic> json) {
    final businessJson = json['business'];
    final summaryJson =
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? {};
    final leoJson = (json['leo'] as Map?)?.cast<String, dynamic>();
    final mweziJson = (json['mwezi'] as Map?)?.cast<String, dynamic>();
    final recentRaw = json['recent_transactions'];
    final List recentList = recentRaw is List ? recentRaw : const [];

    return BusinessDashboardSummary(
      business: businessJson is Map
          ? Business.fromJson(businessJson.cast<String, dynamic>())
          : null,
      allTime: BusinessPeriodSummary.fromJson(summaryJson),
      today: leoJson != null
          ? BusinessPeriodSummary.fromJson(leoJson)
          : BusinessPeriodSummary.zero,
      month: mweziJson != null
          ? BusinessPeriodSummary.fromJson(mweziJson)
          : BusinessPeriodSummary.zero,
      recentTransactions: recentList
          .whereType<Map>()
          .map((item) =>
              BusinessTransaction.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}
