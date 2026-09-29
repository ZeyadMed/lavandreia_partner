import 'package:lavanderia_partner/core/helpers/generic_data_source.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/http/paginated_response.dart';
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
}
