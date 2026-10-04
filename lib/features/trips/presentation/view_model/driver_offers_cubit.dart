import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_partner/core/realtime/realtime_events.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/data/orders_data_source.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/orders_cubit.dart';
import 'package:lavanderia_partner/features/trips/data/models/delivery_trip.dart';
import 'package:lavanderia_partner/features/trips/data/models/trip_request.dart';
import 'package:lavanderia_partner/features/trips/data/trips_data_source.dart';

/// عروض الدليفرية على رحلة واحدة لسه المغسلة مااختارتش منهم
class TripOffers {
  final int tripId;

  /// null لحد ما نعرف الرحلة تبع أنهي طلب، لأن طلب الدليفري مفيهوش orderId
  final PartnerOrder? order;

  /// الطلبات اللي لسه مستنية رد بس، الأقرب الأول
  final List<TripRequest> requests;

  const TripOffers({
    required this.tripId,
    this.order,
    this.requests = const [],
  });

  DeliveryTripType? get type => order?.tripById(tripId)?.type;

  TripOffers copyWith({PartnerOrder? order, List<TripRequest>? requests}) =>
      TripOffers(
        tripId: tripId,
        order: order ?? this.order,
        requests: requests ?? this.requests,
      );
}

/// كل عروض الدليفرية اللي مستنية المغسلة على مستوى الأبلكيشن كله
/// الشيت والشريط اللي فوق البار بيسمعوا عليه، وبيتحدث لحظياً من
/// [RealtimeEvents.tripRequests] ومن تغييرات الطلبات، و [sync] بيجيبه من السيرفر
/// مش في getIt عشان resetGetItAndInit مايقفلوش، زي RealtimeService
class DriverOffersCubit extends Cubit<List<TripOffers>> {
  /// أول صفحة طلبات كفاية، اللي مستني دليفري طلب شغال وأكيد من الأحدث
  static const int _ordersPageSize = 30;

  static final DriverOffersCubit instance = DriverOffersCubit();

  late final StreamSubscription<TripRequest> _requestsSubscription;
  late final StreamSubscription<PartnerOrder> _ordersSubscription;

  /// آخر طلب عرفناه لكل رحلة، عشان العروض الجاية ماتستناش ريكوست
  final Map<int, PartnerOrder> _ordersByTrip = {};

  /// الرحلات اللي بندوّر على طلبها دلوقتي
  final Set<int> _resolving = {};

  /// كل sync جديد بيلغي اللي قبله، وكذلك clear
  int _syncGeneration = 0;

  /// الأحداث اللي وصلت والـ sync شغال، بتتطبق تاني بعد ما نتيجته تظهر
  List<TripRequest>? _receivedDuringSync;

  @visibleForTesting
  DriverOffersCubit() : super(const []) {
    _requestsSubscription = RealtimeEvents.tripRequests.listen(_applyRequest);
    _ordersSubscription = OrdersCubit.changes.listen(_applyOrder);
  }

  /// عدد العروض كلها على كل الرحلات
  int get pendingCount => countOf(state);

  static int countOf(List<TripOffers> offers) =>
      offers.fold(0, (sum, item) => sum + item.requests.length);

  TripOffers? offersFor(int tripId) =>
      state.where((offers) => offers.tripId == tripId).firstOrNull;

  /// المقبول بيشيل الرحلة كلها لأن الباقي بيترفض لوحده،
  /// والمرفوض والملغي بيتشالوا، والجديد بيتضاف أو يتبدّل
  void _applyRequest(TripRequest request) {
    final tripId = request.deliveryTripId;
    if (tripId == 0) return;
    _receivedDuringSync?.add(request);

    if (request.isApproved) {
      _remove(tripId);
      return;
    }

    final current = offersFor(tripId);
    final others = [
      for (final item in current?.requests ?? const <TripRequest>[])
        if (item.id != request.id) item,
    ];
    if (!request.isOpen) {
      if (current != null) _put(current.copyWith(requests: others));
      return;
    }

    final offers =
        current ?? TripOffers(tripId: tripId, order: _ordersByTrip[tripId]);
    _put(
      offers.copyWith(
        requests: [...others, request]..sort(TripRequest.compareByArrival),
      ),
    );
    if (offers.order == null) _resolveOrder(tripId);
  }

  /// الرحلة اللي بقى عليها دليفري أو الطلب اللي خرج من مرحلة الاختيار بيتشالوا
  /// وأي طلب بيعدّي بنحفظ رحلاته، عشان أول عرض عليها يعرف طلبه على طول
  void _applyOrder(PartnerOrder order) {
    _rememberTrips(order);
    for (final offers in state) {
      final trip = order.tripById(offers.tripId);
      if (trip == null) continue;
      if (order.tripAwaitingDriver?.id == offers.tripId) {
        _put(offers.copyWith(order: order));
      } else {
        _remove(offers.tripId);
      }
    }
  }

  /// بيبدّل الرحلة أو يضيفها في الآخر، ولو مفيهاش عروض بيشيلها
  void _put(TripOffers offers) {
    if (isClosed) return;
    if (offers.requests.isEmpty) {
      _remove(offers.tripId);
      return;
    }
    final exists = state.any((item) => item.tripId == offers.tripId);
    emit(
      exists
          ? [
              for (final item in state)
                item.tripId == offers.tripId ? offers : item,
            ]
          : [...state, offers],
    );
  }

  void _remove(int tripId) {
    if (isClosed || !state.any((item) => item.tripId == tripId)) return;
    emit([
      for (final item in state)
        if (item.tripId != tripId) item,
    ]);
  }

  /// بيجيب العروض من السيرفر: بعد الاتصال أو الرجوع للأبلكيشن أو من إشعار
  /// لو الطلبات فشلت بنسيب اللي معانا زي ما هو
  Future<void> sync() async {
    if (!_hasDataSources) return;
    final generation = ++_syncGeneration;
    _receivedDuringSync = [];

    final orders = await _fetchOrders();
    if (orders == null || generation != _syncGeneration || isClosed) {
      if (generation == _syncGeneration) _receivedDuringSync = null;
      return;
    }

    final candidates = [
      for (final order in orders)
        if (order.tripAwaitingDriver case final trip?)
          if (trip.pendingRequestsCount > 0 || offersFor(trip.id) != null)
            (order: order, trip: trip),
    ];
    final results = await Future.wait(
      candidates.map((candidate) async {
        final result = await getIt<TripsDataSource>().getRequests(
          candidate.trip.id,
        );
        return result.fold(
          // الرحلة دي بس فشلت، فبنسيب عروضها اللي معانا
          (_) => offersFor(candidate.trip.id)?.copyWith(order: candidate.order),
          (requests) => TripOffers(
            tripId: candidate.trip.id,
            order: candidate.order,
            requests: requests.where((request) => request.isOpen).toList()
              ..sort(TripRequest.compareByArrival),
          ),
        );
      }),
    );
    if (generation != _syncGeneration || isClosed) return;

    final received = _receivedDuringSync ?? const [];
    _receivedDuringSync = null;
    emit([
      for (final offers in results)
        if (offers != null && offers.requests.isNotEmpty) offers,
    ]);
    received.forEach(_applyRequest);
  }

  /// بيدوّر على الطلب اللي الرحلة تبعه في أول صفحة طلبات
  Future<void> _resolveOrder(int tripId) async {
    if (!_hasDataSources || !_resolving.add(tripId)) return;
    await _fetchOrders();
    _resolving.remove(tripId);
    final order = _ordersByTrip[tripId];
    final offers = offersFor(tripId);
    if (order != null && offers != null) _put(offers.copyWith(order: order));
  }

  /// أول صفحة طلبات، وكل رحلة فيها بتتحفظ مع طلبها
  Future<List<PartnerOrder>?> _fetchOrders() async {
    final result = await getIt<OrdersDataSource>().getOrders(
      page: 1,
      pageSize: _ordersPageSize,
    );
    return result.fold((_) => null, (response) {
      response.items.forEach(_rememberTrips);
      return response.items;
    });
  }

  void _rememberTrips(PartnerOrder order) {
    if (order.pickupTrip case final trip?) _ordersByTrip[trip.id] = order;
    if (order.dropoffTrip case final trip?) _ordersByTrip[trip.id] = order;
  }

  /// في الـ tests الـ data sources مش متسجلة
  bool get _hasDataSources =>
      getIt.isRegistered<OrdersDataSource>() &&
      getIt.isRegistered<TripsDataSource>();

  /// في تسجيل الخروج أو لما الجلسة تنتهي
  void clear() {
    _syncGeneration++;
    _receivedDuringSync = null;
    _ordersByTrip.clear();
    if (!isClosed) emit(const []);
  }

  @override
  Future<void> close() {
    _requestsSubscription.cancel();
    _ordersSubscription.cancel();
    return super.close();
  }
}
