class Business {
  final int id;
  final String name;
  final String businessType;
  final String currency;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Business({
    required this.id,
    required this.name,
    required this.businessType,
    required this.currency,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      businessType: (json['business_type'] ?? '').toString(),
      currency: (json['currency'] ?? 'TZS').toString(),
      isActive: json['is_active'] == true,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()),
    );
  }
}
