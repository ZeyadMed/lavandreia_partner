import 'package:lavanderia_partner/core/bloc/genaric_pagination.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/features/profile/data/models/laundry_review.dart';
import 'package:lavanderia_partner/features/profile/data/reviews_data_source.dart';

/// تقييمات المغسلة، الصفحة الجاية بتتجاب لوحدها لما اليوزر يوصل لآخر اللستة
class ReviewsCubit extends GenericPaginationCubit<LaundryReview> {
  final ReviewsDataSource _dataSource;

  ReviewsCubit(this._dataSource);

  @override
  Future<Either<Failure, dynamic>> loadPage(int page) =>
      _dataSource.getReviews(page: page);
}
