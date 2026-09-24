/// خدمة من /api/laundry/services زي "غسيل الملابس"
/// الأصناف بتاعتها بتيجي من ريكوست لوحده لما اليوزر يفتح الخدمة
class ServiceCategory {
  final int id;
  final String name;

  /// إيموچي جاي من السيرفر، بيتعرض جنب الاسم
  final String icon;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) =>
      ServiceCategory(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        icon: json['icon']?.toString() ?? '',
      );
}

/// صنف جوه الخدمة زي "قميص"، وهو اللي المغسلة بتحط له سعر
class ServiceItem {
  final int id;
  final String name;

  const ServiceItem({required this.id, required this.name});

  factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
    id: (json['id'] as num).toInt(),
    name: json['name']?.toString() ?? '',
  );
}

/// سعر صنف واحد، ده شكل العنصر اللي بيتبعت لـ my-services
class ServiceItemPrice {
  final int serviceItemId;
  final double price;

  const ServiceItemPrice({required this.serviceItemId, required this.price});

  Map<String, dynamic> toJson() => {
    'serviceItemId': serviceItemId,
    'price': price,
  };
}
