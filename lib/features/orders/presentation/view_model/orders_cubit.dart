import 'dart:async';

import 'package:lavanderia_partner/core/bloc/genaric_pagination.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';
import 'package:lavanderia_partner/features/orders/data/orders_data_source.dart';

/// طلبات المغسلة، الصفحة الجاية بتتجاب لوحدها لما اليوزر يوصل لآخر اللستة
/// في الرئيسية بنستخدمه بـ [pageSize] صغير ومن غير سكرول عشان آخر الطلبات بس
class OrdersCubit extends GenericPaginationCubit<PartnerOrder> {
  final OrdersDataSource _dataSource;
  final int pageSize;

  /// إجمالي الطلبات على السيرفر، مش بس اللي اتحملت
  int totalCount = 0;

  /// كل التعديلات على الطلبات بتعدي من هنا، عشان الرئيسية وطلباتي
  /// يتحدثوا مع بعض من غير ما حد فيهم يعرف التاني
  static final StreamController<PartnerOrder> _changes =
      StreamController<PartnerOrder>.broadcast();

  static Stream<PartnerOrder> get changes => _changes.stream;

  /// بتتنادى بعد أي تعديل على الطلب زي القبول أو الرفض أو تحديث الحالة
  static void notifyChanged(PartnerOrder order) => _changes.add(order);

  late final StreamSubscription<PartnerOrder> _changesSubscription;

  OrdersCubit(this._dataSource, {this.pageSize = 10}) {
    _changesSubscription = changes.listen(_applyChange);
  }

  @override
  Future<Either<Failure, dynamic>> loadPage(int page) async {
    final result = await _dataSource.getOrders(page: page, pageSize: pageSize);
    result.fold((_) {}, (response) => totalCount = response.pagination.total);
    return result;
  }

  /// المرفوض بيتشال من اللستة، وأي تعديل تاني بيبدّل الطلب بالنسخة الجديدة
  void _applyChange(PartnerOrder updated) {
    final items = [...state.items];
    final index = items.indexWhere((order) => order.id == updated.id);
    if (index == -1) return;

    if (updated.status == PartnerOrderStatus.rejected) {
      items.removeAt(index);
      if (totalCount > 0) totalCount--;
    } else {
      items[index] = updated;
    }
    emit(state.copyWith(items: items));
  }

  @override
  Future<void> close() {
    _changesSubscription.cancel();
    return super.close();
  }
}
