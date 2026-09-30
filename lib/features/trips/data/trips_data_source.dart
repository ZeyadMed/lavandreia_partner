import 'package:lavanderia_partner/core/helpers/generic_data_source.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/features/trips/data/models/trip_request.dart';

/// ريكوستات رحلات الاستلام والتسليم من ناحية المغسلة
class TripsDataSource {
  final GenericDataSource _genericDataSource;

  TripsDataSource(this._genericDataSource);

  /// الريسبونس: { "data": [{ "id", "status", "driverName", .. }] }
  Future<Either<Failure, List<TripRequest>>> getRequests(int tripId) {
    return _genericDataSource.fetchData<TripRequest>(
      endpoint: Endpoints.tripRequests(tripId),
      fromJson: TripRequest.fromJson,
    );
  }

  /// الدليفري بيتعيّن على الرحلة وباقي الطلبات بتترفض لوحدها
  Future<Either<Failure, void>> approveRequest(int tripId, int requestId) {
    return _genericDataSource.postData<Null>(
      endpoint: Endpoints.approveTripRequest(tripId, requestId),
    );
  }

  Future<Either<Failure, void>> rejectRequest(int tripId, int requestId) {
    return _genericDataSource.postData<Null>(
      endpoint: Endpoints.rejectTripRequest(tripId, requestId),
    );
  }

  /// الكود اللي الدليفري بيوريه للمغسلة لما يوصل بالهدوم
  /// الحالة بتبقى AtLaundryPendingMatch ورسوم الاستلام بتنزل في محفظة الدليفري
  Future<Either<Failure, void>> confirmPickup(int tripId, String otpCode) {
    return _genericDataSource.postData<Null>(
      endpoint: Endpoints.confirmPickupTrip(tripId),
      data: {'otpCode': otpCode},
    );
  }
}
