import '../../../core/network/api_client.dart';
import '../models/fursa_item.dart';

class FursaService {
  static const List<FursaItem> _currentPreviewItems = [
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

    if (items.isEmpty ||
        items.every((item) => item.title.startsWith('Fursa ya Instagram'))) {
      return _currentPreviewItems;
    }

    return items;
  }
}
