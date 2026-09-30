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

  /// مفيش GET orders/{id} للمغسلة، فبندوّر على الطلب في الليستة صفحة صفحة
  /// بيرجّع null لو الطلب مش موجود، زي المرفوض اللي السيرفر بيشيله من الليستة
  Future<Either<Failure, PartnerOrder?>> findOrder(int orderId) async {
    for (var page = 1; ; page++) {
      final result = await getOrders(page: page, pageSize: 50);
      if (result.isError) return Left(result.throwError());

      final response = result.getOrThrow();
      for (final order in response.items) {
        if (order.id == orderId) return Right(order);
      }
      if (page >= response.pagination.pagesCount) return const Right(null);
    }
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

  /// الحالة بتبقى Ready ورحلة التسليم بتتعمل
  Future<Either<Failure, void>> markReady(int orderId) {
    return _genericDataSource.postData<Null>(
      endpoint: Endpoints.markOrderReady(orderId),
    );
  }
}
