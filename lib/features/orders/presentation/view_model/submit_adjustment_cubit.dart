import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/features/orders/data/models/order_adjustment.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/data/orders_data_source.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/orders_cubit.dart';

/// بعت تعديل الأصناف للعميل عشان يوافق أو يرفض
/// لما الريكوست ينجح state.data بيبقى الطلب بحالته الجديدة
class SubmitAdjustmentCubit extends Cubit<BaseState<PartnerOrder>> {
  final OrdersDataSource _dataSource;

  SubmitAdjustmentCubit(this._dataSource)
    : super(const BaseState<PartnerOrder>());

  Future<void> submit(
    PartnerOrder order,
    List<OrderAdjustmentEntry> entries,
  ) async {
    if (state.isLoading || entries.isEmpty) return;
    emit(state.copyWith(status: Status.loading));

    final result = await _dataSource.submitAdjustment(order.id, entries);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: Status.failure,
          errorMessage: failure.message,
          failure: failure,
        ),
      ),
      (_) {
        final updated = order.copyWith(
          status: PartnerOrderStatus.adjustmentPendingApproval,
        );
        OrdersCubit.notifyChanged(updated);
        emit(state.copyWith(status: Status.success, data: updated));
      },
    );
  }
}
