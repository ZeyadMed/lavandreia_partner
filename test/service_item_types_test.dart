import 'package:flutter_test/flutter_test.dart';
import 'package:lavanderia_partner/features/services/data/models/my_service_item.dart';
import 'package:lavanderia_partner/features/services/data/models/service_category.dart';

/// نفس شكل items في GET /api/laundry/services/{serviceId}/items
const _shirtJson = {
  'id': 1,
  'parentItemId': null,
  'name': 'قميص',
  'imageUrl': null,
  'subItems': [
    {
      'id': 10101,
      'parentItemId': 1,
      'name': 'قميص قطن',
      'imageUrl': null,
      'subItems': [],
    },
    {
      'id': 10102,
      'parentItemId': 1,
      'name': 'قميص كتان',
      'imageUrl': null,
      'subItems': [],
    },
  ],
};

const _sneakersJson = {
  'id': 6,
  'parentItemId': null,
  'name': 'حذاء رياضي',
  'imageUrl': null,
  'subItems': [],
};

MyServiceItem _myItem(
  int serviceItemId, {
  int serviceId = 1,
  String serviceName = 'غسيل الملابس',
  int? parentItemId,
  String? parentItemName,
}) => MyServiceItem(
  id: serviceItemId,
  serviceItemId: serviceItemId,
  serviceItemName: 'Item $serviceItemId',
  serviceId: serviceId,
  serviceName: serviceName,
  price: 10,
  parentItemId: parentItemId,
  parentItemName: parentItemName,
);

void main() {
  group('ServiceItem.fromJson', () {
    test('parses nested types with their parent id', () {
      final shirt = ServiceItem.fromJson(_shirtJson);

      expect(shirt.parentItemId, isNull);
      expect(shirt.hasTypes, isTrue);
      expect(shirt.subItems.map((type) => type.id), [10101, 10102]);
      expect(shirt.subItems.map((type) => type.parentItemId), [1, 1]);
      expect(shirt.subItems.first.name, 'قميص قطن');
    });

    test('treats missing or null subItems as no types', () {
      expect(
        ServiceItem.fromJson({'id': 2, 'name': 'بنطلون'}).hasTypes,
        isFalse,
      );
      expect(
        ServiceItem.fromJson({'id': 2, 'name': 'بنطلون', 'subItems': null})
            .subItems,
        isEmpty,
      );
    });
  });

  group('ServiceItem.priceableItems', () {
    test('never includes an item that has types', () {
      final shirt = ServiceItem.fromJson(_shirtJson);

      expect(shirt.priceableItems.map((item) => item.id), [10101, 10102]);
      expect(shirt.priceableItems.map((item) => item.id), isNot(contains(1)));
    });

    test('is the item itself when it has no types', () {
      final sneakers = ServiceItem.fromJson(_sneakersJson);

      expect(sneakers.priceableItems.map((item) => item.id), [6]);
    });
  });

  group('MyServiceItem', () {
    test('reads parent fields when present', () {
      final item = MyServiceItem.fromJson({
        'id': 50,
        'serviceItemId': 10102,
        'serviceItemName': 'قميص كتان',
        'serviceId': 1,
        'serviceName': 'غسيل الملابس',
        'price': 15,
        'parentItemId': 1,
        'parentItemName': 'قميص',
      });

      expect(item.parentItemId, 1);
      expect(item.parentItemName, 'قميص');
    });

    test('parent fields are null when missing', () {
      final item = MyServiceItem.fromJson({
        'id': 51,
        'serviceItemId': 6,
        'serviceId': 1,
        'price': 20,
      });

      expect(item.parentItemId, isNull);
      expect(item.parentItemName, isNull);
    });

    test('copyWith keeps parent fields', () {
      final item = _myItem(10102, parentItemId: 1, parentItemName: 'قميص');
      final updated = item.copyWith(price: 30);

      expect(updated.price, 30);
      expect(updated.parentItemId, 1);
      expect(updated.parentItemName, 'قميص');
    });
  });

  group('groupByService', () {
    test('groups by service in first-appearance order', () {
      final groups = groupByService([
        _myItem(1, serviceId: 2, serviceName: 'كي'),
        _myItem(2),
        _myItem(3, serviceId: 2, serviceName: 'كي'),
      ]);

      expect(groups.map((group) => group.serviceName), ['كي', 'غسيل الملابس']);
      expect(groups.first.items.map((item) => item.serviceItemId), [1, 3]);
    });
  });

  group('groupByParent', () {
    test('gathers types under their parent and keeps plain items alone', () {
      final groups = groupByParent([
        _myItem(10101, parentItemId: 1, parentItemName: 'قميص'),
        _myItem(6),
        _myItem(10102, parentItemId: 1, parentItemName: 'قميص'),
        _myItem(7),
      ]);

      expect(groups.map((group) => group.parentName), ['قميص', null, null]);
      expect(groups[0].items.map((item) => item.serviceItemId), [10101, 10102]);
      expect(groups[1].items.map((item) => item.serviceItemId), [6]);
      expect(groups[2].items.map((item) => item.serviceItemId), [7]);
    });

    test('treats an empty parent name as no parent', () {
      final groups = groupByParent([
        _myItem(10101, parentItemId: 1, parentItemName: ''),
        _myItem(10102, parentItemId: 1, parentItemName: ''),
      ]);

      expect(groups, hasLength(2));
      expect(groups.every((group) => group.parentName == null), isTrue);
    });
  });
}
