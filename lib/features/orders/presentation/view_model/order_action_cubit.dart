import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/data/orders_data_source.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/orders_cubit.dart';

enum OrderAction {
  accept,
  reject,
  confirmMatch,
  markReady,
  retryPickup,
  cancelAfterFailedPickup,
  confirmReturn,
}

/// الأكشنز اللي المغسلة بتعملها على الطلب من غير body
/// لما الريكوست ينجح state.data بيبقى الطلب بحالته الجديدة
class OrderActionCubit extends Cubit<BaseState<PartnerOrder>> {
  final OrdersDataSource _dataSource;

  /// الزرار اللي اتداس، عشان اللودينج يظهر عليه هو بس
  OrderAction? pendingAction;

  OrderActionCubit(this._dataSource) : super(const BaseState<PartnerOrder>());

  Future<void> accept(PartnerOrder order) => _run(
    OrderAction.accept,
    () => _dataSource.acceptOrder(order.id),
    order.copyWith(status: PartnerOrderStatus.awaitingPickup),
  );

  Future<void> reject(PartnerOrder order) => _run(
    OrderAction.reject,
    () => _dataSource.rejectOrder(order.id),
    order.copyWith(status: PartnerOrderStatus.rejected),
  );

  /// الهدوم اللي وصلت مطابقة للطلب
  Future<void> confirmMatch(PartnerOrder order) => _run(
    OrderAction.confirmMatch,
    () => _dataSource.confirmMatch(order.id),
    order.copyWith(status: PartnerOrderStatus.inProgress),
  );

  /// الغسيل خلص
  Future<void> markReady(PartnerOrder order) => _run(
    OrderAction.markReady,
    () => _dataSource.markReady(order.id),
    order.copyWith(status: PartnerOrderStatus.ready),
  );

  /// بعد فشل الاستلام: رحلة استلام جديدة
  Future<void> retryPickup(PartnerOrder order) => _run(
    OrderAction.retryPickup,
    () => _dataSource.resolveFailedPickup(order.id, retry: true),
    order.copyWith(status: PartnerOrderStatus.awaitingPickup),
  );

  /// بعد فشل الاستلام: الطلب بيتلغي
  Future<void> cancelAfterFailedPickup(PartnerOrder order) => _run(
    OrderAction.cancelAfterFailedPickup,
    () => _dataSource.resolveFailedPickup(order.id, retry: false),
    order.copyWith(status: PartnerOrderStatus.cancelled),
  );

  /// الهدوم رجعت المغسلة بعد فشل التوصيل
  /// الحالة الجاية مش معروفة من الـ Swagger، فبتيجي من السيرفر بعد التحديث
  Future<void> confirmReturn(PartnerOrder order) => _run(
    OrderAction.confirmReturn,
    () => _dataSource.confirmFailedDropoffReturn(order.id),
    order,
  );

  Future<void> _run(
    OrderAction action,
    Future<Either<Failure, void>> Function() request,
    PartnerOrder updated,
  ) async {
    if (state.isLoading) return;
    pendingAction = action;
    emit(state.copyWith(status: Status.loading));

    final result = await request();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: Status.failure,
          errorMessage: failure.message,
          failure: failure,
        ),
      ),
      (_) {
        OrdersCubit.notifyChanged(updated);
        emit(state.copyWith(status: Status.success, data: updated));
      },
    );
  }
}
