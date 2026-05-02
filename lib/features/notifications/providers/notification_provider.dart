import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response =
          await ApiClient().dio.get('/api/v1/communications/notifications/me/');
      final data = response.data;
      final List<dynamic> rawList;
      if (data is List) {
        rawList = data;
      } else if (data is Map && data['results'] is List) {
        rawList = data['results'] as List<dynamic>;
      } else {
        rawList = const [];
      }

      _notifications = rawList
          .whereType<Map>()
          .map((item) => NotificationModel.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    } catch (e) {
      _errorMessage = ApiClient().parseError(e);
      if (kDebugMode) {
        debugPrint('[NotificationProvider] loadNotifications: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void markAllRead() {
    _notifications = _notifications
        .map(
          (n) => NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
            route: n.route,
          ),
        )
        .toList();
    notifyListeners();
  }

  void markRead(int id) {
    _notifications = _notifications
        .map(
          (n) => n.id == id
              ? NotificationModel(
                  id: n.id,
                  title: n.title,
                  message: n.message,
                  type: n.type,
                  isRead: true,
                  createdAt: n.createdAt,
                  route: n.route,
                )
              : n,
        )
        .toList();
    notifyListeners();
  }
}
