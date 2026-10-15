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

/// صنف جوه الخدمة زي "قميص"، أو نوع تحت صنف زي "قميص كتان"
/// الصنف اللي ليه أنواع مبيتسعّرش، الأنواع بس هي اللي ليها سعر
class ServiceItem {
  final int id;
  final String name;

  /// الصنف الأب لو ده نوع، و null لو صنف رئيسي
  final int? parentItemId;

  /// أنواع الصنف، فاضية لو الصنف نفسه هو اللي بيتسعّر
  final List<ServiceItem> subItems;

  const ServiceItem({
    required this.id,
    required this.name,
    this.parentItemId,
    this.subItems = const [],
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
    id: (json['id'] as num).toInt(),
    name: json['name']?.toString() ?? '',
    parentItemId: (json['parentItemId'] as num?)?.toInt(),
    subItems:
        (json['subItems'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ServiceItem.fromJson)
            .toList() ??
        const [],
  );

  bool get hasTypes => subItems.isNotEmpty;

  /// اللي ينفع يتحط له سعر: الأنواع لو موجودة، غير كده الصنف نفسه
  /// السيرفر بيرفض id صنف ليه أنواع، فده الطريق الوحيد للتسعير
  List<ServiceItem> get priceableItems => hasTypes ? subItems : [this];
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
