import 'package:lavanderia_partner/core/helpers/generic_data_source.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/http/paginated_response.dart';
import 'package:lavanderia_partner/features/orders/data/models/order_adjustment.dart';
import 'package:lavanderia_partner/features/orders/data/models/partner_order.dart';

/// ريكوستات طلبات المغسلة
class OrdersDataSource {
  final GenericDataSource _genericDataSource;

  OrdersDataSource(this._genericDataSource);

  /// الريسبونس: { "data": { "pageIndex", "pageSize", "count", "totalPages",
  /// "data": [{ "id", "customerName", "status", "totalPrice", "items", .. }] } }
  Future<Either<Failure, PaginatedResponse<PartnerOrder>>> getOrders({
    required int page,
    int pageSize = 10,
  }) {
    return _genericDataSource.fetchResult<PaginatedResponse<PartnerOrder>>(
      endpoint: Endpoints.orders,
      queryParameters: {'PageIndex': page, 'PageSize': pageSize},
      fromJson: (json) =>
          PaginatedResponse.fromJson(json, PartnerOrder.fromJson),
    );
  }

  /// الريسبونس: { "data": { "id", "status", "items", "pickupTrip",
  /// "dropoffTrip", "pendingAdjustment", .. } }
  Future<Either<Failure, PartnerOrder>> getOrder(int orderId) {
    return _genericDataSource.fetchResult<PartnerOrder>(
      endpoint: Endpoints.order(orderId),
      fromJson: PartnerOrder.fromJson,
    );
  }

  Future<Either<Failure, void>> acceptOrder(int orderId) {
    return _genericDataSource.postData<Null>(
      endpoint: Endpoints.acceptOrder(orderId),
    );
  }

  Future<Either<Failure, void>> rejectOrder(int orderId) {
    return _genericDataSource.postData<Null>(
      endpoint: Endpoints.rejectOrder(orderId),
    );
  }

  /// الحالة بتبقى InProgress وإجمالي الأصناف بينزل في المحفظة
  Future<Either<Failure, void>> confirmMatch(int orderId) {
    return _genericDataSource.postData<Null>(
      endpoint: Endpoints.confirmOrderMatch(orderId),
    );
  }

  /// الحالة بتبقى AdjustmentPendingApproval لحد ما العميل يرد
  Future<Either<Failure, void>> submitAdjustment(
    int orderId,
    List<OrderAdjustmentEntry> entries,
  ) {
    return _genericDataSource.postData<Null>(
      endpoint: Endpoints.orderAdjustments(orderId),
      data: {'items': entries.map((entry) => entry.toJson()).toList()},
    );
  }

  /// [retry] بيعمل رحلة استلام جديدة، ومن غيره الطلب بيتلغي
  Future<Either<Failure, void>> resolveFailedPickup(
    int orderId, {
    required bool retry,
  }) {
    return _genericDataSource.postData<Null>(
      endpoint: Endpoints.resolveFailedPickup(orderId),
      data: {'retry': retry},
    );
  }

  /// الهدوم رجعت المغسلة بعد ما دليفري التسليم معرفش يسلّمها للعميل
  Future<Either<Failure, void>> confirmFailedDropoffReturn(int orderId) {
    return _genericDataSource.postData<Null>(
      endpoint: Endpoints.confirmFailedDropoffReturn(orderId),
    );
  }

  /// الحالة بتبقى Ready ورحلة التسليم بتتعمل
  Future<Either<Failure, void>> markReady(int orderId) {
    return _genericDataSource.postData<Null>(
      endpoint: Endpoints.markOrderReady(orderId),
    );
  }
}
