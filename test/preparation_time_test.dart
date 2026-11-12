import 'package:flutter_test/flutter_test.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/presentation/view/widgets/preparation_time.dart';

Map<String, dynamic> _json(Map<String, dynamic> extra) => {
  'id': 7,
  'status': 'InProgress',
  'createdAt': '2026-11-12T08:00:00Z',
  ...extra,
};

void main() {
  group('PartnerOrder preparation fields', () {
    test('are null before the order is accepted', () {
      final order = PartnerOrder.fromJson(_json({'status': 'New'}));
      expect(order.preparationDurationMinutes, isNull);
      expect(order.laundryReceivedAt, isNull);
      expect(order.promisedReadyAt, isNull);
      expect(order.isPreparing, isFalse);
    });

    test('parse the ready time as UTC', () {
      final order = PartnerOrder.fromJson(
        _json({
          'preparationDurationMinutes': 240,
          'laundryReceivedAt': '2026-11-12T10:00:00Z',
          'promisedReadyAt': '2026-11-12T14:00:00Z',
        }),
      );
      expect(order.preparationDurationMinutes, 240);
      expect(order.laundryReceivedAt, DateTime.utc(2026, 11, 12, 10));
      expect(order.promisedReadyAt!.isUtc, isTrue);
      expect(order.promisedReadyAt, DateTime.utc(2026, 11, 12, 14));
      expect(order.isPreparing, isTrue);
    });

    test('treat a ready time without Z as UTC', () {
      final order = PartnerOrder.fromJson(
        _json({'promisedReadyAt': '2026-11-12T14:00:00'}),
      );
      expect(order.promisedReadyAt, DateTime.utc(2026, 11, 12, 14));
    });

    test('accepted duration is kept by copyWith until the server responds', () {
      final order = PartnerOrder.fromJson(
        _json({'status': 'New'}),
      ).copyWith(preparationDurationMinutes: 1440);
      expect(order.preparationDurationMinutes, 1440);
      expect(order.copyWith().preparationDurationMinutes, 1440);
    });

    test('countdown stops once the order is ready', () {
      final order = PartnerOrder.fromJson(
        _json({'status': 'Ready', 'promisedReadyAt': '2026-11-12T14:00:00Z'}),
      );
      expect(order.isPreparing, isFalse);
    });
  });

  test('formatCountdown shows hh:mm:ss under a day', () {
    expect(
      formatCountdown(const Duration(hours: 3, minutes: 5, seconds: 9)),
      '03:05:09',
    );
    expect(formatCountdown(const Duration(minutes: -75)), '01:15:00');
  });
}
