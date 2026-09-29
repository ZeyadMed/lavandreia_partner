import 'package:lavanderia_partner/core/helpers/generic_data_source.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/http/paginated_response.dart';
import 'package:lavanderia_partner/features/profile/data/models/laundry_review.dart';

/// ريكوستات تقييمات المغسلة
class ReviewsDataSource {
  final GenericDataSource _genericDataSource;

  ReviewsDataSource(this._genericDataSource);

  /// الريسبونس: { "data": { "pageIndex", "pageSize", "count", "totalPages",
  /// "data": [{ "id", "rating", "comment", "customerName", "createdAt" }] } }
  Future<Either<Failure, PaginatedResponse<LaundryReview>>> getReviews({
    required int page,
    int pageSize = 10,
  }) {
    return _genericDataSource.fetchResult<PaginatedResponse<LaundryReview>>(
      endpoint: Endpoints.laundryReviews,
      queryParameters: {'PageIndex': page, 'PageSize': pageSize},
      fromJson: (json) =>
          PaginatedResponse.fromJson(json, LaundryReview.fromJson),
    );
  }
}
