import '../../../core/network/api_client.dart';
import '../models/fursa_item.dart';

class FursaService {
  // Emergency fallback content, owned by the Karakana mobile team.
  // Shown ONLY when the backend has no usable opportunities (down, empty,
  // or placeholder-only). Every entry must carry a real `deadlineText` —
  // once its deadline passes, `FursaItem.isExpired` removes it automatically
  // so it never lingers as stale content. Refresh these dates/entries
  // periodically; an empty result here simply falls through to the app's
  // empty state, which is the safe default.
  static const List<FursaItem> _emergencyFallbackItems = [
    FursaItem(
      id: -1,
      title: 'Applications for Tanzania Ventures Lab',
      subtitle: 'Tanzania Ventures Lab',
      deadlineText: '5th June 2026',
      summary:
          'The programme aims to support high-potential Tanzanian ventures driving innovation, industrialisation, technology, food security, and job creation. Don’t miss the opportunity to be part of a growing national innovation ecosystem.',
      sourceLabel: 'Application',
      sourceUrl: 'https://tinyurl.com/mvask7tz',
      ctaText: 'Apply Now',
      category: 'Ventures',
      badgeText: 'Featured',
      amountText: '',
      imageUrl: null,
      isFeatured: true,
      publishedAt: '',
    ),
    FursaItem(
      id: -2,
      title: 'Youth Empowerment Forum 2026',
      subtitle: '30 Fully Funded | 40 Partially Funded',
      deadlineText: '5th July 2026',
      summary:
          'Fully funded participation covers travel, hotel, meals, conference access, visa support, and UN & WTO visits.',
      sourceLabel: 'Application',
      sourceUrl: 'https://www.thecgdl.org/yef2026',
      ctaText: 'Apply Now',
      category: 'Forum',
      badgeText: 'Funding',
      amountText: '',
      imageUrl: null,
      isFeatured: false,
      publishedAt: '',
    ),
    FursaItem(
      id: -3,
      title: 'Green Catalyst Initiative',
      subtitle: 'Biashara ndogo na za kati',
      deadlineText: '15th June 2026',
      summary:
          'Tunatafuta biashara ndogo na za kati zinazobuni suluhisho katika mnyororo wa thamani wa misitu, ikiwemo bidhaa rafiki kwa mazingira, ufugaji nyuki, mianzi na malighafi za misitu, na teknolojia za kidijitali za misitu.',
      sourceLabel: 'Application',
      sourceUrl: 'https://funguo.org/updated/green-catalyst/',
      ctaText: 'Apply Now',
      category: 'Green Business',
      badgeText: 'Open',
      amountText: '',
      imageUrl: null,
      isFeatured: false,
      publishedAt: '',
    ),
  ];

  Future<List<FursaItem>> fetchItems() async {
    final response = await ApiClient().dio.get('/api/v1/communications/fursa/');
    final data = response.data;
    final List<dynamic> rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map && data['results'] is List) {
      rawList = data['results'] as List<dynamic>;
    } else {
      rawList = const [];
    }

    final items = rawList
        .whereType<Map>()
        .map((item) => FursaItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return selectItemsToShow(items);
  }

  /// Decides what to show given the raw backend result. Exposed for
  /// testing so the fallback/expiry decision can be verified without a
  /// live network call.
  List<FursaItem> selectItemsToShow(List<FursaItem> backendItems) {
    final looksUnusable = backendItems.isEmpty ||
        backendItems
            .every((item) => item.title.startsWith('Fursa ya Instagram'));

    final activeBackendItems =
        looksUnusable ? const <FursaItem>[] : _withoutExpired(backendItems);

    if (activeBackendItems.isNotEmpty) {
      return activeBackendItems;
    }

    // Backend has nothing usable right now — fall back to the emergency
    // list, still subject to the same expiry rule.
    return _withoutExpired(_emergencyFallbackItems);
  }

  List<FursaItem> _withoutExpired(List<FursaItem> items) =>
      items.where((item) => !item.isExpired).toList();
}
