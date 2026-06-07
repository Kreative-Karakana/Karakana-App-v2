import 'business.dart';
import 'business_transaction.dart';

class BusinessDashboardSummary {
  final Business? business;
  final String mauzo;
  final String matumizi;
  final String faidaHasara;
  final String status;
  final String statusText;
  final int miamala;
  final String currency;
  final List<BusinessTransaction> recentTransactions;

  const BusinessDashboardSummary({
    required this.business,
    required this.mauzo,
    required this.matumizi,
    required this.faidaHasara,
    required this.status,
    required this.statusText,
    required this.miamala,
    required this.currency,
    required this.recentTransactions,
  });

  double get mauzoValue => double.tryParse(mauzo) ?? 0;
  double get matumiziValue => double.tryParse(matumizi) ?? 0;
  double get faidaHasaraValue => double.tryParse(faidaHasara) ?? 0;
  bool get hasProfit => faidaHasaraValue > 0;
  bool get hasLoss => faidaHasaraValue < 0;

  factory BusinessDashboardSummary.fromJson(Map<String, dynamic> json) {
    final businessJson = json['business'];
    final summaryJson =
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? {};
    final recentRaw = json['recent_transactions'];
    final List recentList = recentRaw is List ? recentRaw : const [];

    return BusinessDashboardSummary(
      business: businessJson is Map
          ? Business.fromJson(businessJson.cast<String, dynamic>())
          : null,
      mauzo: _parseAmount(summaryJson['mauzo']),
      matumizi: _parseAmount(summaryJson['matumizi']),
      faidaHasara: _parseAmount(summaryJson['faida_hasara']),
      status: (summaryJson['status'] ?? '').toString(),
      statusText: (summaryJson['status_text'] ?? '').toString(),
      miamala: (summaryJson['miamala'] as num?)?.toInt() ?? 0,
      currency: (summaryJson['currency'] ?? 'TZS').toString(),
      recentTransactions: recentList
          .whereType<Map>()
          .map((item) =>
              BusinessTransaction.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }

  static String _parseAmount(dynamic raw) {
    if (raw == null) return '0.00';
    if (raw is num) return raw.toStringAsFixed(2);
    final parsed = double.tryParse(raw.toString());
    return parsed?.toStringAsFixed(2) ?? '0.00';
  }
}
