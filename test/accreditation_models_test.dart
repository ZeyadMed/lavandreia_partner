import 'package:flutter_test/flutter_test.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/models/accredited_driver.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/models/accrediting_laundry.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/trips/data/models/delivery_trip.dart';
import 'package:lavanderia_partner/features/trips/data/models/driver_stats.dart';
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
    List<int> finishedIds(PartnerOrder order) => [
      for (final trip in order.finishedTrips) trip.id,
    ];

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
        finishedIds(
          _order(PartnerOrderStatus.delivered, dropoffTrip: _dropoff),
        ),
        [1, 2],
      );
    });

    test('trips without a driver are skipped', () {
      const noDriver = DeliveryTrip(id: 3, type: DeliveryTripType.pickup);
      expect(
        finishedIds(
          _order(PartnerOrderStatus.inProgress, pickupTrip: noDriver),
        ),
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

    test('fromJson reads the driver photo and vehicle details', () {
      final request = TripRequest.fromJson({
        'id': 1,
        'driverName': 'D',
        'driverProfileImageUrl': 'https://x/p.jpg',
        'vehicleType': 'Car',
        'vehicleMake': 'Kia',
        'vehicleModel': 'Picanto',
        'vehicleYear': 2018,
      });
      expect(request.driverImageUrl, 'https://x/p.jpg');
      expect(request.vehicleDescription, 'Kia Picanto • 2018');
      final approved = request.copyWith(status: 'Approved');
      expect(approved.driverImageUrl, 'https://x/p.jpg');
      expect(approved.vehicleDescription, 'Kia Picanto • 2018');
    });

    test('fromJson reads vehicle details nested under driver', () {
      final request = TripRequest.fromJson({
        'id': 1,
        'driver': {
          'fullName': 'D',
          'profileImageUrl': '',
          'vehicleModel': 'Picanto',
          'vehicleYear': 0,
        },
      });
      expect(request.driverImageUrl, isNull);
      expect(request.vehicleYear, isNull);
      expect(request.vehicleDescription, 'Picanto');
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
      trip
          .copyWith(pendingRequestsCount: 3)
          .driverAccreditedBy
          .single
          .laundryId,
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

  group('DriverStats', () {
    test('reads the flat driver fields', () {
      final stats = DriverStats.fromJson({
        'driverAverageRating': 4.75,
        'driverReviewsCount': 23,
        'driverTotalTrips': 120,
        'driverJoinedAt': '2025-03-04T10:00:00Z',
      });
      expect(stats.rating, 4.75);
      expect(stats.reviewsCount, 23);
      expect(stats.totalTrips, 120);
      expect(stats.joinedAt, DateTime.utc(2025, 3, 4, 10));
      expect(stats.isEmpty, isFalse);
      expect(stats.isNew, isFalse);
    });

    test('reads the fields nested under driver', () {
      final stats = DriverStats.fromJson({
        'driver': {
          'averageRating': 5,
          'reviewsCount': 2,
          'completedTripsCount': 9,
          'createdAt': '2024-12-01T00:00:00Z',
        },
      });
      expect(stats.rating, 5.0);
      expect(stats.reviewsCount, 2);
      expect(stats.totalTrips, 9);
      expect(stats.joinedAt, DateTime.utc(2024, 12));
    });

    test('the request createdAt is not the driver join date', () {
      final stats = DriverStats.fromJson({'createdAt': '2026-11-09T09:18:15Z'});
      expect(stats.joinedAt, isNull);
      expect(stats.isEmpty, isTrue);
    });

    test('a driver with no reviews is new', () {
      final stats = DriverStats.fromJson({
        'driverAverageRating': 0,
        'driverReviewsCount': 0,
      });
      expect(stats.hasRating, isTrue);
      expect(stats.isNew, isTrue);
    });
  });

  test('TripRequest keeps the driver stats through fromJson and copyWith', () {
    final request = TripRequest.fromJson({
      'id': 1,
      'driverName': 'D',
      'driverTotalTrips': 40,
      'driverAverageRating': 4.2,
    });
    expect(request.driverStats.totalTrips, 40);
    final updated = request.copyWith(status: 'Approved');
    expect(updated.driverStats.totalTrips, 40);
    expect(updated.driverStats.rating, 4.2);
  });

  test('DeliveryTrip reads the assigned driver photo, vehicle and stats', () {
    final trip = DeliveryTrip.fromJson({
      'id': 7,
      'driverId': 15,
      'driverName': 'D',
      'driverProfileImageUrl': 'https://x/15.jpg',
      'vehicleType': 'Car',
      'vehicleMake': 'Kia',
      'vehicleModel': 'Picanto',
      'vehicleYear': 2018,
      'driverReviewsCount': 3,
      'driverAverageRating': 4.5,
      'driverJoinedAt': '2025-01-01T00:00:00Z',
    }, type: DeliveryTripType.pickup);
    expect(trip.driverImageUrl, 'https://x/15.jpg');
    expect(trip.vehicleType, 'Car');
    expect(trip.vehicleDescription, 'Kia Picanto • 2018');
    expect(trip.driverStats.reviewsCount, 3);

    final copied = trip.copyWith(pendingRequestsCount: 1);
    expect(copied.vehicleDescription, 'Kia Picanto • 2018');
    expect(copied.driverStats.rating, 4.5);
    expect(copied.driverImageUrl, 'https://x/15.jpg');
  });
}
