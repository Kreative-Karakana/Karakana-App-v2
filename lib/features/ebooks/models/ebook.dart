class Ebook {
  final int id;
  final String title;
  final String description;
  final String authorName;
  final String? coverImageUrl;
  final int priceInTzs;
  final int totalPages;
  final bool isPurchased;
  final DateTime? createdAt;

  const Ebook({
    required this.id,
    required this.title,
    required this.description,
    required this.authorName,
    required this.coverImageUrl,
    required this.priceInTzs,
    required this.totalPages,
    required this.isPurchased,
    required this.createdAt,
  });

  bool get isFree => priceInTzs <= 0;

  factory Ebook.fromJson(Map<String, dynamic> json) {
    int parsePrice(dynamic raw) {
      if (raw == null) return 0;
      if (raw is int) return raw;
      if (raw is double) return raw.round();
      return double.tryParse(raw.toString())?.round() ?? 0;
    }

    return Ebook(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      authorName: (json['author_name'] ?? '').toString(),
      coverImageUrl: json['cover_image']?.toString(),
      priceInTzs: parsePrice(json['price']),
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
      isPurchased: json['is_purchased'] == true,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }
}

class EbookPurchase {
  final int id;
  final Ebook ebook;
  final String externalId;
  final bool isSuccessful;
  final Map<String, dynamic>? checkoutResponse;

  const EbookPurchase({
    required this.id,
    required this.ebook,
    required this.externalId,
    required this.isSuccessful,
    required this.checkoutResponse,
  });

  factory EbookPurchase.fromJson(Map<String, dynamic> json) {
    return EbookPurchase(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ebook: Ebook.fromJson((json['ebook'] as Map?)?.cast<String, dynamic>() ?? {}),
      externalId: (json['external_id'] ?? '').toString(),
      isSuccessful: json['is_successful'] == true,
      checkoutResponse: (json['checkout_response'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
