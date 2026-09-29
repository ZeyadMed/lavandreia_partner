import 'package:flutter/material.dart';

/// إشعار واحد من إشعارات المغسلة
class PartnerNotification {
  final int id;

  /// زي ما السيرفر بيبعته، زي OrderUpdated
  final String type;
  final String title;
  final String body;
  final int? orderId;
  final int? deliveryTripId;
  final bool isRead;
  final DateTime? createdAt;

  const PartnerNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.orderId,
    this.deliveryTripId,
    this.createdAt,
  });

  factory PartnerNotification.fromJson(Map<String, dynamic> json) {
    return PartnerNotification(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      title: (json['title'] as String? ?? '').trim(),
      body: (json['body'] as String? ?? '').trim(),
      orderId: json['orderId'] as int?,
      deliveryTripId: json['deliveryTripId'] as int?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')
          ?.toLocal(),
    );
  }

  PartnerNotification copyWith({bool? isRead}) {
    return PartnerNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      orderId: orderId,
      deliveryTripId: deliveryTripId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  /// أيقونة حسب نوع الإشعار: طلب أو توصيل أو غيرهم
  IconData get icon {
    if (orderId != null || type.startsWith('Order')) {
      return Icons.receipt_long_outlined;
    }
    if (deliveryTripId != null) return Icons.local_shipping_outlined;
    return Icons.notifications_none_rounded;
  }
}
