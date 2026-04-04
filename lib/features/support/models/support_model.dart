class SupportTicket {
  final int id;
  final String subject;
  final String type;
  final String status;
  final String createdAt;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  bool get isResolved => status == 'resolved' || status == 'closed';

  String get formattedId => 'TKT-${id.toString().padLeft(4, '0')}';

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] ?? 0,
      subject: json['subject']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'type': type,
      'status': status,
      'created_at': createdAt,
    };
  }
}

class SupportMessage {
  final int id;
  final String message;
  final bool isStaff;
  final String createdAt;

  const SupportMessage({
    required this.id,
    required this.message,
    required this.isStaff,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] ?? 0,
      message: json['message']?.toString() ?? '',
      isStaff: json['is_staff'] ?? false,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'is_staff': isStaff,
      'created_at': createdAt,
    };
  }
}
