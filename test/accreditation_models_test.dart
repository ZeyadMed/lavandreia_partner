import 'package:flutter_test/flutter_test.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/models/accredited_driver.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/models/accrediting_laundry.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/trips/data/models/delivery_trip.dart';
import 'package:lavanderia_partner/features/trips/data/models/trip_request.dart';

const _mine = AccreditingLaundry(laundryId: 1, laundryName: 'My Laundry');
const _other = AccreditingLaundry(laundryId: 2, laundryName: 'Other Laundry');

TripRequest _request(
  int id, {
  double? distanceKm,
  List<AccreditingLaundry> accreditedBy = const [],
}) => TripRequest(
  id: id,
  deliveryTripId: 10,
  driverName: 'Driver $id',
  status: 'Pending',
  vehicleType: 'Car',
  distanceKm: distanceKm,
  driverAccreditedBy: accreditedBy,
);

const _pickup = DeliveryTrip(
  id: 1,
  type: DeliveryTripType.pickup,
  driverId: 5,
  driverName: 'Pickup driver',
);
const _dropoff = DeliveryTrip(
  id: 2,
  type: DeliveryTripType.dropoff,
  driverId: 6,
  driverName: 'Dropoff driver',
);

PartnerOrder _order(
  PartnerOrderStatus status, {
  DeliveryTrip? pickupTrip = _pickup,
  DeliveryTrip? dropoffTrip,
}) => PartnerOrder(
  id: 99,
  number: '99',
  customerName: 'Customer',
  items: const [],
  address: '',
  createdAt: DateTime(2026),
  total: 0,
  status: status,
  pickupTrip: pickupTrip,
  dropoffTrip: dropoffTrip,
);

void main() {
  group('PartnerOrder.finishedTrips', () {
    List<int> finishedIds(PartnerOrder order) =>
        [for (final trip in order.finishedTrips) trip.id];

    test('pickup is not finished while the driver is still on the way', () {
      expect(finishedIds(_order(PartnerOrderStatus.awaitingPickup)), isEmpty);
      expect(finishedIds(_order(PartnerOrderStatus.pickupFailed)), isEmpty);
    });

    test('pickup finishes once the clothes reach the laundry', () {
      expect(finishedIds(_order(PartnerOrderStatus.atLaundryPendingMatch)), [
        1,
      ]);
      expect(
        finishedIds(
          _order(PartnerOrderStatus.outForDelivery, dropoffTrip: _dropoff),
        ),
        [1],
      );
    });

    test('dropoff finishes once the customer receives the order', () {
      expect(
        finishedIds(_order(PartnerOrderStatus.delivered, dropoffTrip: _dropoff)),
        [1, 2],
      );
    });

    test('trips without a driver are skipped', () {
      const noDriver = DeliveryTrip(id: 3, type: DeliveryTripType.pickup);
      expect(
        finishedIds(_order(PartnerOrderStatus.inProgress, pickupTrip: noDriver)),
        isEmpty,
      );
    });
  });

  group('AccreditingLaundry.listFromJson', () {
    test('missing or null field becomes an empty list', () {
      expect(AccreditingLaundry.listFromJson(null), isEmpty);
      expect(AccreditingLaundry.listFromJson('oops'), isEmpty);
    });

    test('reads every laundry in the list', () {
      final laundries = AccreditingLaundry.listFromJson([
        {'laundryId': 1, 'laundryName': 'A'},
        {'laundryId': 2, 'laundryName': 'B'},
      ]);
      expect(laundries.map((l) => l.laundryId), [1, 2]);
      expect(laundries.map((l) => l.laundryName), ['A', 'B']);
    });
  });

  test('isAccreditedBy is false while the current laundry is unknown', () {
    expect([_mine].isAccreditedBy(1), isTrue);
    expect([_other].isAccreditedBy(1), isFalse);
    expect([_mine].isAccreditedBy(null), isFalse);
  });

  group('TripRequest', () {
    test('fromJson defaults driverAccreditedBy to empty when missing', () {
      final request = TripRequest.fromJson({'id': 1, 'driverName': 'D'});
      expect(request.driverAccreditedBy, isEmpty);
    });

    test('fromJson reads driverAccreditedBy', () {
      final request = TripRequest.fromJson({
        'id': 1,
        'driverName': 'D',
        'driverAccreditedBy': [
          {'laundryId': 7, 'laundryName': 'Seven'},
        ],
      });
      expect(request.driverAccreditedBy.single.laundryId, 7);
    });

    test('copyWith(status) keeps the accreditations', () {
      final request = _request(1, accreditedBy: [_mine, _other]);
      final cancelled = request.copyWith(status: 'Cancelled');
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.driverAccreditedBy, [_mine, _other]);
    });

    test('compareForLaundry puts drivers accredited by you first', () {
      final far = _request(1, distanceKm: 9, accreditedBy: [_mine]);
      final near = _request(2, distanceKm: 1, accreditedBy: [_other]);
      final middle = _request(3, distanceKm: 4);

      final sorted = [near, middle, far]
        ..sort(TripRequest.compareForLaundry(1));
      expect(sorted.map((r) => r.id), [1, 2, 3]);
    });

    test('compareForLaundry falls back to arrival order without a laundry', () {
      final far = _request(1, distanceKm: 9, accreditedBy: [_mine]);
      final near = _request(2, distanceKm: 1);

      final sorted = [far, near]..sort(TripRequest.compareForLaundry(null));
      expect(sorted.map((r) => r.id), [2, 1]);
    });

    test('closestOf ignores the display order', () {
      final far = _request(1, distanceKm: 9, accreditedBy: [_mine]);
      final near = _request(2, distanceKm: 1);

      expect(TripRequest.closestOf([far, near])?.id, 2);
      expect(TripRequest.closestOf([far]), isNull);
    });
  });

  test('DeliveryTrip reads driverAccreditedBy and keeps it in copyWith', () {
    final trip = DeliveryTrip.fromJson({
      'id': 5,
      'driverAccreditedBy': [
        {'laundryId': 1, 'laundryName': 'My Laundry'},
      ],
    }, type: DeliveryTripType.pickup);
    expect(trip.driverAccreditedBy.single.laundryId, 1);
    expect(
      trip.copyWith(pendingRequestsCount: 3).driverAccreditedBy.single.laundryId,
      1,
    );

    final withoutDriver = DeliveryTrip.fromJson({
      'id': 6,
    }, type: DeliveryTripType.dropoff);
    expect(withoutDriver.driverAccreditedBy, isEmpty);
  });

  test('AccreditedDriver treats accreditedAt as UTC', () {
    final driver = AccreditedDriver.fromJson({
      'driverId': 3,
      'fullName': 'Driver',
      'phoneNumber': '+218912345678',
      'profileImageUrl': null,
      'accreditedAt': '2026-10-13T08:30:00',
    });
    expect(driver.profileImageUrl, isNull);
    expect(driver.accreditedAt, DateTime.utc(2026, 10, 13, 8, 30).toLocal());
  });
}
