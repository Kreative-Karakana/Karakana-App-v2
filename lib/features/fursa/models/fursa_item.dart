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

  /// Parses [deadlineText] (e.g. "5th June 2026") into a [DateTime].
  /// Returns null when the text is empty or doesn't match the expected
  /// format — the backend has no structured deadline field, only this
  /// free-text one, so unparseable values are treated as "unknown" rather
  /// than expired.
  DateTime? get parsedDeadline => _parseDeadlineText(deadlineText);

  /// True only when the deadline is known and has passed. Items with no
  /// parseable deadline are never considered expired, since we can't
  /// verify their status from free text alone.
  bool isExpiredAsOf(DateTime now) {
    final deadline = parsedDeadline;
    if (deadline == null) return false;
    return deadline.isBefore(DateTime(now.year, now.month, now.day));
  }

  bool get isExpired => isExpiredAsOf(DateTime.now());
}

DateTime? _parseDeadlineText(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;

  final match = RegExp(
    r'^(\d{1,2})(?:st|nd|rd|th)?\s+([A-Za-z]+)\s+(\d{4})$',
    caseSensitive: false,
  ).firstMatch(text);
  if (match == null) return null;

  final day = int.tryParse(match.group(1)!);
  final month = _monthNumber(match.group(2)!);
  final year = int.tryParse(match.group(3)!);
  if (day == null || month == null || year == null) return null;

  return DateTime(year, month, day);
}

int? _monthNumber(String month) {
  const months = [
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
    'july',
    'august',
    'september',
    'october',
    'november',
    'december',
  ];
  final index = months.indexOf(month.toLowerCase());
  return index == -1 ? null : index + 1;
}
