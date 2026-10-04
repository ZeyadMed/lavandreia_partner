import 'package:flutter_test/flutter_test.dart';
import 'package:lavanderia_partner/core/realtime/realtime_events.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/orders_cubit.dart';
import 'package:lavanderia_partner/features/trips/data/models/delivery_trip.dart';
import 'package:lavanderia_partner/features/trips/data/models/trip_request.dart';
import 'package:lavanderia_partner/features/trips/data/models/vehicle_kind.dart';
import 'package:lavanderia_partner/features/trips/presentation/view_model/driver_offers_cubit.dart';

TripRequest _request(
  int id, {
  int tripId = 10,
  String status = 'Pending',
  double? distanceKm,
  String vehicleType = 'Car',
}) => TripRequest(
  id: id,
  deliveryTripId: tripId,
  driverName: 'Driver $id',
  status: status,
  distanceKm: distanceKm,
  vehicleType: vehicleType,
);

PartnerOrder _order({
  required PartnerOrderStatus status,
  required DeliveryTrip pickupTrip,
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
);

void main() {
  group('VehicleKind.fromApi', () {
    test('matches names in any case', () {
      expect(VehicleKind.fromApi('car'), VehicleKind.car);
      expect(VehicleKind.fromApi('Car'), VehicleKind.car);
      expect(VehicleKind.fromApi('MOTORCYCLE'), VehicleKind.motorcycle);
      expect(VehicleKind.fromApi(' Scooter '), VehicleKind.scooter);
    });

    test('unknown or empty is other', () {
      expect(VehicleKind.fromApi('bike'), VehicleKind.other);
      expect(VehicleKind.fromApi(''), VehicleKind.other);
    });
  });

  group('TripRequest.etaMinutes', () {
    test('uses the vehicle speed plus two minutes', () {
      // 1 كم بعربية 25 كم/س = 2.4 دقيقة تتقرّب لـ 3 + 2
      expect(_request(1, distanceKm: 1).etaMinutes, 5);
      // 1 كم بموتوسيكل 30 كم/س = 2 دقيقة + 2
      expect(
        _request(1, distanceKm: 1, vehicleType: 'motorcycle').etaMinutes,
        4,
      );
      expect(_request(1, distanceKm: 0).etaMinutes, 2);
    });

    test('is null without a distance', () {
      expect(_request(1).etaMinutes, isNull);
    });

    test('compareByArrival puts the closest first and unknown last', () {
      final requests = [
        _request(1),
        _request(2, distanceKm: 5),
        _request(3, distanceKm: 1),
      ]..sort(TripRequest.compareByArrival);
      expect(requests.map((r) => r.id), [3, 2, 1]);
    });

    test('empty status still counts as open', () {
      expect(_request(1, status: '').isOpen, isTrue);
      expect(_request(1, status: 'Cancelled').isOpen, isFalse);
    });
  });

  group('DriverOffersCubit', () {
    late DriverOffersCubit cubit;

    setUp(() => cubit = DriverOffersCubit());
    tearDown(() => cubit.close());

    test('groups open requests by trip, closest first', () async {
      RealtimeEvents.notifyTripRequest(_request(1, distanceKm: 4));
      RealtimeEvents.notifyTripRequest(_request(2, distanceKm: 1));
      RealtimeEvents.notifyTripRequest(_request(3, tripId: 11));
      await pumpEventQueue();

      expect(cubit.state.map((offers) => offers.tripId), [10, 11]);
      expect(cubit.offersFor(10)!.requests.map((r) => r.id), [2, 1]);
      expect(cubit.pendingCount, 3);
    });

    test('a repeated request replaces the old one', () async {
      RealtimeEvents.notifyTripRequest(_request(1, distanceKm: 4));
      RealtimeEvents.notifyTripRequest(_request(1, distanceKm: 2));
      await pumpEventQueue();

      expect(cubit.pendingCount, 1);
      expect(cubit.offersFor(10)!.requests.single.distanceKm, 2);
    });

    test(
      'cancelled and rejected requests are removed with empty trips',
      () async {
        RealtimeEvents.notifyTripRequest(_request(1));
        RealtimeEvents.notifyTripRequest(_request(2));
        RealtimeEvents.notifyTripRequest(_request(1, status: 'Cancelled'));
        await pumpEventQueue();
        expect(cubit.offersFor(10)!.requests.map((r) => r.id), [2]);

        RealtimeEvents.notifyTripRequest(_request(2, status: 'Rejected'));
        await pumpEventQueue();
        expect(cubit.state, isEmpty);
      },
    );

    test('an approved request removes the whole trip', () async {
      RealtimeEvents.notifyTripRequest(_request(1));
      RealtimeEvents.notifyTripRequest(_request(2));
      RealtimeEvents.notifyTripRequest(_request(3, tripId: 11));
      RealtimeEvents.notifyTripRequest(_request(1, status: 'Approved'));
      await pumpEventQueue();

      expect(cubit.state.map((offers) => offers.tripId), [11]);
    });

    test(
      'an order still waiting for a driver is attached to its trip',
      () async {
        RealtimeEvents.notifyTripRequest(_request(1));
        await pumpEventQueue();
        OrdersCubit.notifyChanged(
          _order(
            status: PartnerOrderStatus.awaitingPickup,
            pickupTrip: const DeliveryTrip(
              id: 10,
              type: DeliveryTripType.pickup,
            ),
          ),
        );
        await pumpEventQueue();

        final offers = cubit.offersFor(10)!;
        expect(offers.order?.id, 99);
        expect(offers.type, DeliveryTripType.pickup);
      },
    );

    test('a trip that got a driver is removed', () async {
      RealtimeEvents.notifyTripRequest(_request(1));
      await pumpEventQueue();
      OrdersCubit.notifyChanged(
        _order(
          status: PartnerOrderStatus.awaitingPickup,
          pickupTrip: const DeliveryTrip(
            id: 10,
            type: DeliveryTripType.pickup,
            driverId: 5,
          ),
        ),
      );
      await pumpEventQueue();

      expect(cubit.state, isEmpty);
    });

    test('a known order is used for the first offer on its trip', () async {
      OrdersCubit.notifyChanged(
        _order(
          status: PartnerOrderStatus.awaitingPickup,
          pickupTrip: const DeliveryTrip(id: 10, type: DeliveryTripType.pickup),
        ),
      );
      await pumpEventQueue();
      RealtimeEvents.notifyTripRequest(_request(1));
      await pumpEventQueue();

      expect(cubit.offersFor(10)!.order?.id, 99);
    });

    test('clear empties everything', () async {
      RealtimeEvents.notifyTripRequest(_request(1));
      await pumpEventQueue();
      cubit.clear();

      expect(cubit.state, isEmpty);
    });
  });
}
