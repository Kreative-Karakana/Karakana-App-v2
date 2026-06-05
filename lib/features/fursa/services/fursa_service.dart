import '../../../core/network/api_client.dart';
import '../models/fursa_item.dart';

class FursaService {
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

    return rawList
        .whereType<Map>()
        .map((item) => FursaItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
