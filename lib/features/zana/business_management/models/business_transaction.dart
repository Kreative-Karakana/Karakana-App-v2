class BusinessTransaction {
  final int id;
  final String transactionType;
  final String amount;
  final String category;
  final String description;
  final DateTime? transactionDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusinessTransaction({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.category,
    required this.description,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSale => transactionType == 'sale';
  bool get isExpense => transactionType == 'expense';
  double get amountValue => double.tryParse(amount) ?? 0;
  String get typeLabel => isSale ? 'Mauzo' : 'Matumizi';

  factory BusinessTransaction.fromJson(Map<String, dynamic> json) {
    return BusinessTransaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      transactionType: (json['transaction_type'] ?? '').toString(),
      amount: _parseAmount(json['amount']),
      category: (json['category'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      transactionDate:
          DateTime.tryParse((json['transaction_date'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
    );
  }

  static String _parseAmount(dynamic raw) {
    if (raw == null) return '0.00';
    if (raw is num) return raw.toStringAsFixed(2);
    final parsed = double.tryParse(raw.toString());
    return parsed?.toStringAsFixed(2) ?? '0.00';
  }
}
