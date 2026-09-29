import 'package:lavanderia_partner/core/helpers/generic_data_source.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/http/paginated_response.dart';
import 'package:lavanderia_partner/features/notifications/data/models/partner_notification.dart';

/// ريكوستات إشعارات المغسلة
class NotificationsDataSource {
  final GenericDataSource _genericDataSource;

  NotificationsDataSource(this._genericDataSource);

  /// الريسبونس: { "data": { "pageIndex", "pageSize", "count", "totalPages",
  /// "data": [{ "id", "type", "title", "body", "orderId", "deliveryTripId",
  /// "isRead", "createdAt" }] } }
  Future<Either<Failure, PaginatedResponse<PartnerNotification>>>
  getNotifications({required int page, int pageSize = 10}) {
    return _genericDataSource
        .fetchResult<PaginatedResponse<PartnerNotification>>(
          endpoint: Endpoints.notifications,
          queryParameters: {'PageIndex': page, 'PageSize': pageSize},
          fromJson: (json) =>
              PaginatedResponse.fromJson(json, PartnerNotification.fromJson),
        );
  }

  Future<Either<Failure, void>> markAsRead(int notificationId) {
    return _genericDataSource.updateData<Null>(
      endpoint: Endpoints.readNotification(notificationId),
    );
  }

  Future<Either<Failure, void>> markAllAsRead() {
    return _genericDataSource.updateData<Null>(
      endpoint: Endpoints.readAllNotifications,
    );
  }

  Future<Either<Failure, void>> deleteNotification(int notificationId) {
    return _genericDataSource.deleteData<Null>(
      endpoint: Endpoints.notification(notificationId),
    );
  }

  Future<Either<Failure, void>> deleteAll() {
    return _genericDataSource.deleteData<Null>(
      endpoint: Endpoints.notifications,
    );
  }
}
