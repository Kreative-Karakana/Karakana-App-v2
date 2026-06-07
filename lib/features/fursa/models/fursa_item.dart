class FursaItem {
  final int id;
  final String title;
  final String subtitle;
  final String deadlineText;
  final String summary;
  final String sourceLabel;
  final String sourceUrl;
  final String ctaText;
  final String category;
  final String badgeText;
  final String amountText;
  final String? imageUrl;
  final bool isFeatured;
  final String publishedAt;

  const FursaItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.deadlineText,
    required this.summary,
    required this.sourceLabel,
    required this.sourceUrl,
    required this.ctaText,
    required this.category,
    required this.badgeText,
    required this.amountText,
    required this.imageUrl,
    required this.isFeatured,
    required this.publishedAt,
  });

  factory FursaItem.fromJson(Map<String, dynamic> json) {
    return FursaItem(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      deadlineText: json['deadline_text']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      sourceLabel: json['source_label']?.toString() ?? '',
      sourceUrl: json['source_url']?.toString() ?? '',
      ctaText: json['cta_text']?.toString() ?? 'Fungua',
      category: json['category']?.toString() ?? '',
      badgeText: json['badge_text']?.toString() ?? '',
      amountText: json['amount_text']?.toString() ?? '',
      imageUrl: json['image']?.toString(),
      isFeatured: json['is_featured'] == true,
      publishedAt: json['published_at']?.toString() ?? '',
    );
  }
}
