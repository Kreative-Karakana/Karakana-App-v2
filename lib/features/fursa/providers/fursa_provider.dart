import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/fursa_item.dart';
import '../services/fursa_service.dart';

class FursaProvider extends ChangeNotifier {
  final FursaService _service = FursaService();

  List<FursaItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FursaItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<FursaItem> get featuredItems =>
      _items.where((item) => item.isFeatured).toList();

  Future<void> loadItems() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _service.fetchItems();
    } catch (e) {
      _errorMessage = ApiClient().parseError(e);
      if (kDebugMode) {
        debugPrint('[FursaProvider] loadItems: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}
