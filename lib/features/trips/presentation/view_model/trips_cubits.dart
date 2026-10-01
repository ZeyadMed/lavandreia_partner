import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/realtime/realtime_events.dart';
import 'package:lavanderia_partner/features/trips/data/models/delivery_trip.dart';
import 'package:lavanderia_partner/features/trips/data/models/trip_request.dart';
import 'package:lavanderia_partner/features/trips/data/trips_data_source.dart';

/// الدليفرية اللي طلبوا رحلة واحدة، الداتا في state.items وبتتجاب بـ fetchData
/// وبتتحدث لحظياً لما دليفري يطلب الرحلة أو يلغي طلبه
class TripRequestsCubit extends BaseCubit<TripRequest> {
  final int tripId;

  late final StreamSubscription<TripRequest> _realtimeSubscription;

  TripRequestsCubit(TripsDataSource dataSource, this.tripId)
    : super(fetchFunction: () => dataSource.getRequests(tripId)) {
    _realtimeSubscription = RealtimeEvents.tripRequests
        .where((request) => request.deliveryTripId == tripId)
        .listen(_applyRealtime);
  }

  /// الملغي بيتشال، والجديد بيتضاف تحت أو بيتبدّل لو موجود
  void _applyRealtime(TripRequest request) {
    if (!state.isSuccess) return;
    final others = state.items.where((item) => item.id != request.id);
    final items = request.isCancelled
        ? others.toList()
        : state.items.any((item) => item.id == request.id)
        ? [
            for (final item in state.items)
              item.id == request.id ? request : item,
          ]
        : [...state.items, request];
    emit(state.copyWith(items: items));
  }

  @override
  Future<void> close() {
    _realtimeSubscription.cancel();
    return super.close();
  }

  /// بيبدّل الطلب في الليستة بعد القبول أو الرفض من غير ما نجيبها تاني
  void replace(TripRequest updated) {
    final items = [
      for (final request in state.items)
        request.id == updated.id ? updated : request,
    ];
    emit(state.copyWith(items: items));
  }
}

enum TripRequestAction { approve, reject }

/// قبول أو رفض طلب دليفري على الرحلة
/// لما الريكوست ينجح state.data بيبقى الطلب بحالته الجديدة
class TripRequestActionCubit extends Cubit<BaseState<TripRequest>> {
  final TripsDataSource _dataSource;
  final int tripId;

  /// الطلب والزرار اللي اتداس، عشان اللودينج يظهر عليه هو بس
  int? pendingRequestId;
  TripRequestAction? pendingAction;

  TripRequestActionCubit(this._dataSource, this.tripId)
    : super(const BaseState<TripRequest>());

  Future<void> approve(TripRequest request) => _run(
    request,
    TripRequestAction.approve,
    () => _dataSource.approveRequest(tripId, request.id),
    request.copyWith(status: 'Approved'),
  );

  Future<void> reject(TripRequest request) => _run(
    request,
    TripRequestAction.reject,
    () => _dataSource.rejectRequest(tripId, request.id),
    request.copyWith(status: 'Rejected'),
  );

  Future<void> _run(
    TripRequest request,
    TripRequestAction action,
    Future<Either<Failure, void>> Function() call,
    TripRequest updated,
  ) async {
    if (state.isLoading) return;
    pendingRequestId = request.id;
    pendingAction = action;
    emit(state.copyWith(status: Status.loading));

    final result = await call();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: Status.failure,
          errorMessage: failure.message,
          failure: failure,
        ),
      ),
      (_) => emit(state.copyWith(status: Status.success, data: updated)),
    );
  }
}

/// تأكيد الكود اللي الدليفري بيوريه للمغسلة:
/// في الاستلام وهو جايب الهدوم، وفي التسليم وهو واخدها
class ConfirmTripOtpCubit extends Cubit<BaseState<void>> {
  final TripsDataSource _dataSource;
  final DeliveryTrip trip;

  ConfirmTripOtpCubit(this._dataSource, this.trip)
    : super(const BaseState<void>());

  Future<void> confirm(String otpCode) async {
    if (state.isLoading) return;
    emit(state.copyWith(status: Status.loading));

    final result = trip.type == DeliveryTripType.pickup
        ? await _dataSource.confirmPickup(trip.id, otpCode)
        : await _dataSource.confirmHandover(trip.id, otpCode);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: Status.failure,
          errorMessage: failure.message,
          failure: failure,
        ),
      ),
      (_) => emit(state.copyWith(status: Status.success)),
    );
  }
}
