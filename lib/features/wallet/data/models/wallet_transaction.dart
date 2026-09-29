import 'package:easy_localization/easy_localization.dart';

/// "85 د.ل" — المبلغ من غير كسور لو رقم صحيح
String formatWalletAmount(double amount) {
  final isWhole = amount == amount.roundToDouble();
  final value = isWhole ? amount.toInt().toString() : amount.toStringAsFixed(2);
  return '$value ${'currency'.tr()}';
}

/// حركة واحدة في محفظة المغسلة
class WalletTransaction {
  final int id;
  final double amount;

  /// بيتعرض زي ما السيرفر بيبعته من غير ترجمة، زي DeliveryFee و OrderRevenue
  final String type;
  final int? orderId;
  final int? deliveryTripId;
  final String description;
  final DateTime? createdAt;

  const WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    this.orderId,
    this.deliveryTripId,
    this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as int? ?? 0,
      amount: (json['amount'] as num? ?? 0).toDouble(),
      type: json['type'] as String? ?? '',
      orderId: json['orderId'] as int?,
      deliveryTripId: json['deliveryTripId'] as int?,
      description: (json['description'] as String? ?? '').trim(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal(),
    );
  }

  bool get isCredit => amount >= 0;

  /// "+20 د.ل" أو "-5 د.ل"
  String get displayAmount =>
      '${isCredit ? '+' : '-'}${formatWalletAmount(amount.abs())}';
}
