class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String createdAt;
  final String? route;
  final String? targetRole;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.route,
    this.targetRole,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: (json['type'] ?? json['notification_type'] ?? 'general')
          .toString()
          .toLowerCase(),
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at']?.toString() ?? '',
      route: json['route']?.toString(),
      targetRole: (json['target_role'] ??
              json['audience'] ??
              json['recipient_role'] ??
              json['role'] ??
              json['user_type'])
          ?.toString()
          .toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt,
      'route': route,
      'target_role': targetRole,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    String? createdAt,
    String? route,
    String? targetRole,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      route: route ?? this.route,
      targetRole: targetRole ?? this.targetRole,
    );
  }
}
