enum NotificationType {
  order,
  promo,
  system,
}

class NotificationModel {
  final String id;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final DateTime timestamp;
  bool isRead;
  final NotificationType type;
  final String? relatedOrderId;

  NotificationModel({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.relatedOrderId,
  });

  String localizedTitle(bool isArabic) => isArabic ? titleAr : titleEn;
  String localizedBody(bool isArabic) => isArabic ? bodyAr : bodyEn;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType parsedType;
    switch (json['type']?.toString()) {
      case 'order':
        parsedType = NotificationType.order;
        break;
      case 'promo':
        parsedType = NotificationType.promo;
        break;
      default:
        parsedType = NotificationType.system;
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? '',
      bodyAr: json['body_ar']?.toString() ?? '',
      bodyEn: json['body_en']?.toString() ?? '',
      timestamp: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
      type: parsedType,
      relatedOrderId: json['related_order_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_ar': titleAr,
      'title_en': titleEn,
      'body_ar': bodyAr,
      'body_en': bodyEn,
      'type': type.name,
      'is_read': isRead,
    };
  }
}
