/// صنف من أصناف المغسلة جاي من GET my-services، زي "قميص" جوه "غسيل الملابس"
/// الـ serviceItemId هو اللي بيتبعت في التعديل والحذف مش الـ id
class MyServiceItem {
  final int id;
  final int serviceItemId;
  final String serviceItemName;
  final String? serviceItemImageUrl;
  final int serviceId;
  final String serviceName;
  final String? serviceImageUrl;
  final double price;

  const MyServiceItem({
    required this.id,
    required this.serviceItemId,
    required this.serviceItemName,
    this.serviceItemImageUrl,
    required this.serviceId,
    required this.serviceName,
    this.serviceImageUrl,
    required this.price,
  });

  factory MyServiceItem.fromJson(Map<String, dynamic> json) => MyServiceItem(
    id: (json['id'] as num).toInt(),
    serviceItemId: (json['serviceItemId'] as num).toInt(),
    serviceItemName: json['serviceItemName']?.toString() ?? '',
    serviceItemImageUrl: json['serviceItemImageUrl'] as String?,
    serviceId: (json['serviceId'] as num).toInt(),
    serviceName: json['serviceName']?.toString() ?? '',
    serviceImageUrl: json['serviceImageUrl'] as String?,
    price: (json['price'] as num?)?.toDouble() ?? 0,
  );

  MyServiceItem copyWith({double? price}) => MyServiceItem(
    id: id,
    serviceItemId: serviceItemId,
    serviceItemName: serviceItemName,
    serviceItemImageUrl: serviceItemImageUrl,
    serviceId: serviceId,
    serviceName: serviceName,
    serviceImageUrl: serviceImageUrl,
    price: price ?? this.price,
  );
}

/// السعر من غير ".0" لو رقم صحيح، عشان يتعرض 5 مش 5.0
String formatPrice(double price) =>
    price == price.truncateToDouble() ? price.toInt().toString() : '$price';
