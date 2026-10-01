import 'dart:async';

import 'package:lavanderia_partner/core/bloc/base_bloc.dart';
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

  /// الإشعارات بتبعت هنا رقم الطلب اللي اتغير على السيرفر من ناحية حد تاني
  /// زي العميل أو الدليفري، وnull لو مش معروف زي طلب جديد لسه ماتحملش
  static final StreamController<int?> _serverChanges =
      StreamController<int?>.broadcast();

  static Stream<int?> get serverChanges => _serverChanges.stream;

  static void notifyServerChanged(int? orderId) => _serverChanges.add(orderId);

  /// طلب جديد وصل لحظياً من OrderCreated، بيتضاف أول الليستة
  static final StreamController<PartnerOrder> _created =
      StreamController<PartnerOrder>.broadcast();

  static Stream<PartnerOrder> get created => _created.stream;

  static void notifyCreated(PartnerOrder order) => _created.add(order);

  /// دليفري طلب رحلة أو لغى طلبه، [delta] بـ 1 أو -1
  /// الطلب بيتعرف من الرحلة لأن طلب الدليفري مفيهوش orderId
  static final StreamController<({int tripId, int delta})>
  _tripRequestCountChanges =
      StreamController<({int tripId, int delta})>.broadcast();

  static Stream<({int tripId, int delta})> get tripRequestCountChanges =>
      _tripRequestCountChanges.stream;

  static void notifyTripRequestCountChanged(int tripId, int delta) =>
      _tripRequestCountChanges.add((tripId: tripId, delta: delta));

  /// الطلب بعدد طلبات الدليفرية الجديد، أو null لو الرحلة مش تبعه
  static PartnerOrder? withTripRequestDelta(
    PartnerOrder order,
    int tripId,
    int delta,
  ) {
    final trip = order.tripById(tripId);
    if (trip == null) return null;
    final count = trip.pendingRequestsCount + delta;
    final updated = trip.copyWith(pendingRequestsCount: count < 0 ? 0 : count);
    return identical(trip, order.pickupTrip)
        ? order.copyWith(pickupTrip: updated)
        : order.copyWith(dropoffTrip: updated);
  }

  late final StreamSubscription<PartnerOrder> _changesSubscription;
  late final StreamSubscription<int?> _serverChangesSubscription;
  late final StreamSubscription<PartnerOrder> _createdSubscription;
  late final StreamSubscription<({int tripId, int delta})>
  _tripRequestCountSubscription;

  OrdersCubit(this._dataSource, {this.pageSize = 10}) {
    _changesSubscription = changes.listen(_applyChange);
    _serverChangesSubscription = serverChanges.listen((_) => refresh());
    _createdSubscription = created.listen(_insertCreated);
    _tripRequestCountSubscription = tripRequestCountChanges.listen(
      (change) => _applyTripRequestDelta(change.tripId, change.delta),
    );
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

  /// لو الطلب موجود أصلاً (زي بعد refresh) بيتبدّل بس من غير ما يتكرر
  /// ولو الليستة لسه بتتحمل من الأول، الطلب هييجي معاها
  void _insertCreated(PartnerOrder order) {
    if (state.isInitial || state.isLoading || state.isFailure) return;
    if (state.items.any((item) => item.id == order.id)) {
      _applyChange(order);
      return;
    }
    totalCount++;
    emit(state.copyWith(items: [order, ...state.items]));
  }

  void _applyTripRequestDelta(int tripId, int delta) {
    final items = [...state.items];
    final index = items.indexWhere((order) => order.tripById(tripId) != null);
    if (index == -1) return;
    items[index] = withTripRequestDelta(items[index], tripId, delta)!;
    emit(state.copyWith(items: items));
  }

  @override
  Future<void> close() {
    _changesSubscription.cancel();
    _serverChangesSubscription.cancel();
    _createdSubscription.cancel();
    _tripRequestCountSubscription.cancel();
    return super.close();
  }
}
