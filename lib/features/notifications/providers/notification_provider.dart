import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  final Set<int> _readNotificationIds = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool? _lastLoadedTrainerRole;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications({required bool isTrainer}) async {
    if (_lastLoadedTrainerRole != null &&
        _lastLoadedTrainerRole != isTrainer &&
        _notifications.isNotEmpty) {
      _notifications = [];
    }
    _lastLoadedTrainerRole = isTrainer;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient().dio.get(
        '/api/v1/communications/notifications/me/',
        queryParameters: {
          'role': isTrainer ? 'trainer' : 'user',
        },
      );
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
          .where((notification) => _matchesRole(notification, isTrainer))
          .map(
            (notification) => _readNotificationIds.contains(notification.id)
                ? notification.copyWith(isRead: true)
                : notification,
          )
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

  bool _matchesRole(NotificationModel notification, bool isTrainer) {
    final targetRole = notification.targetRole?.trim().toLowerCase();
    if (targetRole != null && targetRole.isNotEmpty) {
      if (targetRole == 'all' ||
          targetRole == 'both' ||
          targetRole == 'everyone' ||
          targetRole == 'broadcast') {
        return true;
      }
      if (isTrainer) {
        return targetRole == 'trainer' || targetRole == 'trainers';
      }
      return targetRole == 'user' ||
          targetRole == 'users' ||
          targetRole == 'student' ||
          targetRole == 'students' ||
          targetRole == 'learner' ||
          targetRole == 'learners';
    }

    final route = notification.route?.toLowerCase() ?? '';
    if (route.startsWith('/trainer')) return isTrainer;

    return true;
  }

  Future<void> markAllRead() async {
    _readNotificationIds.addAll(_notifications.map((n) => n.id));
    _notifications = _notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
    notifyListeners();

    try {
      await ApiClient()
          .dio
          .post('/api/v1/communications/notifications/me/read-all/');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationProvider] markAllRead: $e');
      }
    }
  }

  Future<void> markRead(int id) async {
    _readNotificationIds.add(id);
    _notifications = _notifications
        .map(
          (notification) => notification.id == id
              ? notification.copyWith(isRead: true)
              : notification,
        )
        .toList();
    notifyListeners();

    try {
      await ApiClient()
          .dio
          .post('/api/v1/communications/notifications/$id/read/');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationProvider] markRead: $e');
      }
    }
  }
}
