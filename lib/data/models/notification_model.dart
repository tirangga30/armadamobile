/// In-app notification model returned by GET /v1/notifications
class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final String status; // SENT, DELIVERED, READ
  final Map<String, dynamic>? data;
  final DateTime? createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.status = 'SENT',
    this.data,
    this.createdAt,
    this.readAt,
  });

  bool get isRead => status == 'READ' || readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'SYSTEM',
      title: json['title']?.toString() ?? 'Notifikasi',
      body: json['body']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'SENT').toUpperCase(),
      data: json['payloadJson'] is Map<String, dynamic>
          ? json['payloadJson'] as Map<String, dynamic>
          : (json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'status': status,
      if (data != null) 'payloadJson': data,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (readAt != null) 'readAt': readAt!.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? status,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      status: status ?? this.status,
      data: data,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

/// Collection wrapper for GET /v1/notifications response
class NotificationListResponse {
  final List<NotificationModel> items;
  final int total;
  final int unreadCount;

  NotificationListResponse({
    required this.items,
    required this.total,
    required this.unreadCount,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    List<NotificationModel> list = [];
    if (json['notifications'] != null && json['notifications'] is List) {
      list = (json['notifications'] as List)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList();
    } else if (json['items'] != null && json['items'] is List) {
      list = (json['items'] as List)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList();
    }

    final totalCount = (json['pagination']?['total'] is num)
        ? (json['pagination']['total'] as num).toInt()
        : (json['total'] is num)
            ? (json['total'] as num).toInt()
            : list.length;

    final unread = list.where((n) => !n.isRead).length;

    return NotificationListResponse(
      items: list,
      total: totalCount,
      unreadCount: unread,
    );
  }
}
