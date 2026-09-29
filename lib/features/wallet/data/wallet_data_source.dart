import 'package:lavanderia_partner/core/helpers/generic_data_source.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/http/paginated_response.dart';
import 'package:lavanderia_partner/features/wallet/data/models/wallet_transaction.dart';

/// ريكوستات محفظة المغسلة
class WalletDataSource {
  final GenericDataSource _genericDataSource;

  WalletDataSource(this._genericDataSource);

  /// الريسبونس: { "data": { "balance": 0 } }
  Future<Either<Failure, double>> getBalance() {
    return _genericDataSource.fetchResult<double>(
      endpoint: Endpoints.wallet,
      fromJson: (json) => (json['balance'] as num? ?? 0).toDouble(),
    );
  }

  /// الريسبونس: { "data": { "pageIndex", "pageSize", "count", "totalPages",
  /// "data": [{ "id", "amount", "type", "orderId", "deliveryTripId",
  /// "description", "createdAt" }] } }
  Future<Either<Failure, PaginatedResponse<WalletTransaction>>>
  getTransactions({required int page, int pageSize = 10}) {
    return _genericDataSource
        .fetchResult<PaginatedResponse<WalletTransaction>>(
          endpoint: Endpoints.walletTransactions,
          queryParameters: {'PageIndex': page, 'PageSize': pageSize},
          fromJson: (json) =>
              PaginatedResponse.fromJson(json, WalletTransaction.fromJson),
        );
  }
}
