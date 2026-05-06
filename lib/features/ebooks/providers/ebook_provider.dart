import 'package:flutter/foundation.dart';

import '../models/ebook.dart';
import '../services/ebook_service.dart';

class EbookProvider extends ChangeNotifier {
  final EbookService _service = EbookService();

  bool isLoadingStore = false;
  bool isLoadingLibrary = false;
  bool isLoadingMyEbooks = false;
  bool isPurchasing = false;

  String? storeError;
  String? libraryError;
  String? myEbooksError;
  String? purchaseError;

  List<Ebook> store = [];
  List<EbookPurchase> library = [];
  List<Ebook> myEbooks = [];

  Future<void> fetchStore() async {
    isLoadingStore = true;
    storeError = null;
    notifyListeners();
    try {
      store = await _service.fetchStore();
    } catch (e) {
      storeError = e.toString();
    } finally {
      isLoadingStore = false;
      notifyListeners();
    }
  }

  Future<void> fetchLibrary() async {
    isLoadingLibrary = true;
    libraryError = null;
    notifyListeners();
    try {
      library = await _service.fetchLibrary();
    } catch (e) {
      libraryError = e.toString();
    } finally {
      isLoadingLibrary = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyEbooks() async {
    isLoadingMyEbooks = true;
    myEbooksError = null;
    notifyListeners();
    try {
      myEbooks = await _service.fetchMyEbooks();
    } catch (e) {
      myEbooksError = e.toString();
    } finally {
      isLoadingMyEbooks = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> purchaseEbook({
    required int ebookId,
    required String accountNumber,
    required String provider,
  }) async {
    isPurchasing = true;
    purchaseError = null;
    notifyListeners();
    try {
      final result = await _service.purchaseEbook(
        ebookId: ebookId,
        accountNumber: accountNumber,
        provider: provider,
      );
      await fetchLibrary();
      await fetchStore();
      return result;
    } catch (e) {
      purchaseError = e.toString();
      return null;
    } finally {
      isPurchasing = false;
      notifyListeners();
    }
  }

  Future<void> deleteEbook(int id) async {
    await _service.deleteEbook(id);
    await fetchMyEbooks();
  }

  bool isOwned(int ebookId) {
    return library.any((p) => p.ebook.id == ebookId && p.isSuccessful) ||
        store.any((e) => e.id == ebookId && e.isPurchased);
  }
}
