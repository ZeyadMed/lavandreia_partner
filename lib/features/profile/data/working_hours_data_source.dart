import 'package:lavanderia_partner/core/helpers/generic_data_source.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';

/// ريكوستات مواعيد عمل المغسلة
class WorkingHoursDataSource {
  final GenericDataSource _genericDataSource;

  WorkingHoursDataSource(this._genericDataSource);

  /// الريسبونس: { "data": [{ "id", "dayOfWeek", "openTime", "closeTime", "isClosed" }] }
  Future<Either<Failure, List<WorkingDay>>> getWorkingHours() {
    return _genericDataSource.fetchData<WorkingDay>(
      endpoint: Endpoints.workingHours,
      fromJson: WorkingDay.fromJson,
    );
  }

  /// بيبعت الأيام كلها مرة واحدة
  /// الشكل: { "workingHours": [{ "dayOfWeek", "openTime", "closeTime", "isClosed" }] }
  Future<Either<Failure, void>> updateWorkingHours(List<WorkingDay> days) {
    return _genericDataSource.updateData<Null>(
      endpoint: Endpoints.workingHours,
      data: {'workingHours': days.map((day) => day.toJson()).toList()},
    );
  }
}
