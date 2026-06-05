import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../models/ebook.dart';

class EbookService {
  final _dio = ApiClient().dio;

  Future<List<Ebook>> fetchStore() async {
    final res = await _dio.get('/api/v1/ebooks/store/');
    final data = res.data;
    final List results;
    if (data is Map && data['results'] is List) {
      results = data['results'] as List;
    } else if (data is List) {
      results = data;
    } else {
      results = const [];
    }
    return results
        .whereType<Map>()
        .map((e) => Ebook.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<Ebook> fetchDetail(int id) async {
    final res = await _dio.get('/api/v1/ebooks/$id/');
    return Ebook.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<List<EbookPurchase>> fetchLibrary() async {
    final res = await _dio.get('/api/v1/ebooks/library/');
    final data = res.data;
    final List results;
    if (data is Map && data['results'] is List) {
      results = data['results'] as List;
    } else if (data is List) {
      results = data;
    } else {
      results = const [];
    }

    return results
        .whereType<Map>()
        .map((e) => EbookPurchase.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<List<Ebook>> fetchMyEbooks() async {
    final res = await _dio.get('/api/v1/ebooks/my/');
    final data = res.data;
    final List results;
    if (data is Map && data['results'] is List) {
      results = data['results'] as List;
    } else if (data is List) {
      results = data;
    } else {
      results = const [];
    }
    return results
        .whereType<Map>()
        .map((e) => Ebook.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<Map<String, dynamic>> purchaseEbook({
    required int ebookId,
    required String accountNumber,
    required String provider,
  }) async {
    final res = await _dio.post(
      '/api/v1/ebooks/$ebookId/purchase/',
      data: {
        'accountNumber': accountNumber,
        'provider': provider,
      },
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createEbook({
    required String title,
    required String description,
    required String price,
    required String coverImagePath,
    required Uint8List ebookFileBytes,
    required String ebookFileName,
  }) async {
    final form = FormData.fromMap({
      'title': title,
      'description': description,
      'price': price,
      'cover_image': await MultipartFile.fromFile(coverImagePath),
      'epub_file': MultipartFile.fromBytes(
        ebookFileBytes,
        filename: ebookFileName,
      ),
      'status': 'published',
    });
    final res = await _dio.post('/api/v1/ebooks/', data: form);
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updateEbook({
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final res = await _dio.patch('/api/v1/ebooks/manage/$id/', data: data);
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<void> deleteEbook(int id) async {
    await _dio.delete('/api/v1/ebooks/manage/$id/');
  }

  Future<Map<String, dynamic>> fetchPage({
    required int ebookId,
    required int pageNumber,
  }) async {
    final res = await _dio.get('/api/v1/ebooks/$ebookId/pages/$pageNumber/');
    final data = (res.data as Map).cast<String, dynamic>();
    final base64Data = (data['page_data'] ?? '').toString();
    final bytes = base64Decode(base64Data);
    return {
      'bytes': bytes,
      'total_pages': (data['total_pages'] as num?)?.toInt() ?? 1,
      'watermark_text': (data['watermark_text'] ?? '').toString(),
      'page': (data['page'] as num?)?.toInt() ?? pageNumber,
    };
  }
}
