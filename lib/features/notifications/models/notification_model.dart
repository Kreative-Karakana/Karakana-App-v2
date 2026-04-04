class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String createdAt;
  final String? route;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.route,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at']?.toString() ?? '',
      route: json['route']?.toString(),
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
    };
  }
}
