/// التعديل زي ما السيرفر بيرجّعه، في pendingAdjustment جوه الطلب
/// وفي حدث AdjustmentResolved لما العميل يرد عليه
library;

enum OrderAdjustmentStatus {
  pending(apiName: 'Pending'),
  approved(apiName: 'Approved'),
  rejected(apiName: 'Rejected');

  final String apiName;

  const OrderAdjustmentStatus({required this.apiName});

  static OrderAdjustmentStatus fromApi(Object? value) {
    final name = '${value ?? ''}'.toLowerCase();
    for (final status in values) {
      if (status.apiName.toLowerCase() == name) return status;
    }
    return OrderAdjustmentStatus.pending;
  }
}

/// سطر واحد في التعديل
class OrderAdjustmentResultItem {
  /// القطعة اللي في الطلب، null في الإضافة
  final int? orderItemId;
  final String originalServiceItemName;

  /// Replace أو Add أو Remove زي ما السيرفر بيبعتها
  final String action;
  final String newServiceItemName;
  final double newPrice;
  final int newQuantity;

  const OrderAdjustmentResultItem({
    this.orderItemId,
    this.originalServiceItemName = '',
    this.action = '',
    this.newServiceItemName = '',
    this.newPrice = 0,
    this.newQuantity = 0,
  });

  /// { "orderItemId", "originalServiceItemName", "action",
  /// "newServiceItemName", "newPrice", "newQuantity" }
  factory OrderAdjustmentResultItem.fromJson(Map<String, dynamic> json) =>
      OrderAdjustmentResultItem(
        orderItemId: (json['orderItemId'] as num?)?.toInt(),
        originalServiceItemName:
            json['originalServiceItemName'] as String? ?? '',
        action: '${json['action'] ?? ''}',
        newServiceItemName: json['newServiceItemName'] as String? ?? '',
        newPrice: (json['newPrice'] as num? ?? 0).toDouble(),
        newQuantity: (json['newQuantity'] as num? ?? 0).toInt(),
      );
}

class OrderAdjustmentResult {
  final int id;
  final OrderAdjustmentStatus status;

  /// الفرق في السعر بعد التعديل، ممكن يبقى بالسالب
  final double priceDifference;
  final DateTime? createdAt;
  final List<OrderAdjustmentResultItem> items;

  const OrderAdjustmentResult({
    required this.id,
    required this.status,
    this.priceDifference = 0,
    this.createdAt,
    this.items = const [],
  });

  /// { "id", "status", "priceDifference", "createdAt", "items": [..] }
  factory OrderAdjustmentResult.fromJson(Map<String, dynamic> json) =>
      OrderAdjustmentResult(
        id: (json['id'] as num? ?? 0).toInt(),
        status: OrderAdjustmentStatus.fromApi(json['status']),
        priceDifference: (json['priceDifference'] as num? ?? 0).toDouble(),
        createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
        items: [
          for (final item in json['items'] as List? ?? const [])
            if (item is Map<String, dynamic>)
              OrderAdjustmentResultItem.fromJson(item),
        ],
      );
}
