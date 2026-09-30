import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/features/trips/data/models/trip_request.dart';
import 'package:lavanderia_partner/features/trips/data/trips_data_source.dart';

/// الدليفرية اللي طلبوا رحلة واحدة، الداتا في state.items وبتتجاب بـ fetchData
class TripRequestsCubit extends BaseCubit<TripRequest> {
  TripRequestsCubit(TripsDataSource dataSource, int tripId)
    : super(fetchFunction: () => dataSource.getRequests(tripId));

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

/// تأكيد استلام الهدوم من دليفري الاستلام بالكود
class ConfirmPickupCubit extends Cubit<BaseState<void>> {
  final TripsDataSource _dataSource;
  final int tripId;

  ConfirmPickupCubit(this._dataSource, this.tripId)
    : super(const BaseState<void>());

  Future<void> confirm(String otpCode) async {
    if (state.isLoading) return;
    emit(state.copyWith(status: Status.loading));

    final result = await _dataSource.confirmPickup(tripId, otpCode);
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
