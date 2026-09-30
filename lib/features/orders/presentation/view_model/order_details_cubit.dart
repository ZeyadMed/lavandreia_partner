import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/data/orders_data_source.dart';
import 'package:lavanderia_partner/features/orders/presentation/view_model/orders_cubit.dart';

/// الطلب المفتوح في صفحة التفاصيل، state.data فيه دايماً آخر نسخة
/// أي أكشن بيبعت النسخة المتوقعة على [OrdersCubit.changes] فبتظهر على طول،
/// وبعدها [refresh] بيجيب النسخة الحقيقية من السيرفر بالرحلات والدليفري
class OrderDetailsCubit extends Cubit<BaseState<PartnerOrder>> {
  final OrdersDataSource _dataSource;

  late final StreamSubscription<PartnerOrder> _changesSubscription;
  late final StreamSubscription<int?> _serverChangesSubscription;

  OrderDetailsCubit(this._dataSource, PartnerOrder order)
    : super(BaseState<PartnerOrder>(status: Status.success, data: order)) {
    _changesSubscription = OrdersCubit.changes.listen((updated) {
      if (updated.id == this.order.id) emit(state.copyWith(data: updated));
    });
    // إشعار عن الطلب ده، زي دليفري طلب الرحلة أو العميل رد على التعديل
    _serverChangesSubscription = OrdersCubit.serverChanges.listen((orderId) {
      if (orderId == this.order.id) refresh();
    });
  }

  PartnerOrder get order => state.data!;

  /// [BaseState.lastUpdated] بيتغير مع كل تحديث من السيرفر،
  /// وكروت طلبات الدليفري بتستخدمه عشان تجيب ليستتها تاني
  Future<void> refresh() async {
    final result = await _dataSource.getOrder(order.id);
    if (isClosed) return;
    result.fold((_) {}, (found) {
      emit(state.copyWith(data: found, lastUpdated: DateTime.now()));
      OrdersCubit.notifyChanged(found);
    });
  }

  @override
  Future<void> close() {
    _changesSubscription.cancel();
    _serverChangesSubscription.cancel();
    return super.close();
  }
}
