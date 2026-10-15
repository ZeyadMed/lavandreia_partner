/// صنف من أصناف المغسلة جاي من GET my-services، زي "قميص" جوه "غسيل الملابس"
/// أو نوع زي "قميص كتان" وأبوه "قميص"
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

  /// الصنف الأب لو ده نوع، و null لو صنف ملوش أنواع
  final int? parentItemId;
  final String? parentItemName;

  const MyServiceItem({
    required this.id,
    required this.serviceItemId,
    required this.serviceItemName,
    this.serviceItemImageUrl,
    required this.serviceId,
    required this.serviceName,
    this.serviceImageUrl,
    required this.price,
    this.parentItemId,
    this.parentItemName,
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
    parentItemId: (json['parentItemId'] as num?)?.toInt(),
    parentItemName: json['parentItemName']?.toString(),
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
    parentItemId: parentItemId,
    parentItemName: parentItemName,
  );
}

/// أصناف خدمة واحدة من أصناف المغسلة
class MyServiceGroup {
  final int serviceId;
  final String serviceName;
  final List<MyServiceItem> items = [];

  MyServiceGroup({required this.serviceId, required this.serviceName});
}

/// صنف ملوش أنواع لوحده، أو أنواع صنف واحد متجمعة تحت اسمه
class MyServiceItemGroup {
  /// اسم الصنف الأب، و null لو ده صنف ملوش أنواع
  final String? parentName;
  final List<MyServiceItem> items = [];

  MyServiceItemGroup({this.parentName});
}

/// الريسبونس لستة واحدة، فبنجمّعها بالخدمة بنفس ترتيب أول ظهور ليها
List<MyServiceGroup> groupByService(Iterable<MyServiceItem> items) {
  final groups = <int, MyServiceGroup>{};
  for (final item in items) {
    groups
        .putIfAbsent(
          item.serviceId,
          () => MyServiceGroup(
            serviceId: item.serviceId,
            serviceName: item.serviceName,
          ),
        )
        .items
        .add(item);
  }
  return groups.values.toList();
}

/// بيجمّع الأنواع تحت الصنف الأب بنفس ترتيب أول ظهور
/// العنصر اللي ملوش اسم أب بيبقى group لوحده
List<MyServiceItemGroup> groupByParent(Iterable<MyServiceItem> items) {
  final groups = <String, MyServiceItemGroup>{};
  for (final item in items) {
    final parentName = item.parentItemName;
    final hasParent = parentName != null && parentName.isNotEmpty;
    final key = hasParent
        ? 'parent:${item.parentItemId ?? parentName}'
        : 'item:${item.serviceItemId}';
    groups
        .putIfAbsent(
          key,
          () => MyServiceItemGroup(parentName: hasParent ? parentName : null),
        )
        .items
        .add(item);
  }
  return groups.values.toList();
}

/// السعر من غير ".0" لو رقم صحيح، عشان يتعرض 5 مش 5.0
String formatPrice(double price) =>
    price == price.truncateToDouble() ? price.toInt().toString() : '$price';
