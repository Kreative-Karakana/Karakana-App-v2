class BusinessDebt {
  final int id;
  final String customerName;
  final String amount;
  final String itemService;
  final String note;
  final DateTime? dateGiven;
  final DateTime? dueDate;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusinessDebt({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.itemService,
    required this.note,
    required this.dateGiven,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaid => status == 'paid';
  bool get isOutstanding => !isPaid;
  double get amountValue => double.tryParse(amount) ?? 0;
  String get statusLabel => isPaid ? 'Imelipwa' : 'Haijalipwa';

  factory BusinessDebt.fromJson(Map<String, dynamic> json) {
    return BusinessDebt(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerName: (json['customer_name'] ?? '').toString(),
      amount: _parseAmount(json['amount']),
      itemService: (json['item_service'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      dateGiven: DateTime.tryParse((json['date_given'] ?? '').toString()),
      dueDate: DateTime.tryParse((json['due_date'] ?? '').toString()),
      status: (json['status'] ?? 'outstanding').toString(),
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
