import 'package:lavanderia_partner/core/helpers/generic_data_source.dart';
import 'package:lavanderia_partner/core/helpers/logger.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/features/accredited_drivers/data/models/accredited_driver.dart';

/// ريكوستات الدليفرية المعتمدين عند المغسلة
/// المغسلة بس هي اللي بتعتمد أو تلغي، والدليفري مالوش تحكم
class AccreditedDriversDataSource {
  final GenericDataSource _genericDataSource;

  AccreditedDriversDataSource(this._genericDataSource);

  /// الريسبونس: { "data": [AccreditedDriver] } من الأحدث للأقدم
  Future<Either<Failure, List<AccreditedDriver>>> getAccreditedDrivers() {
    return _genericDataSource.fetchData<AccreditedDriver>(
      endpoint: Endpoints.accreditedDrivers,
      fromJson: AccreditedDriver.fromJson,
    );
  }

  /// بيبعت { phoneNumber } وبيرجّع الدليفري اللي اتعتمد
  /// 404 لو مفيش دليفري بالرقم، و 400 لو مش مفعّل أو معتمد بالفعل
  Future<Either<Failure, AccreditedDriver>> accreditDriver(
    String phoneNumber,
  ) async {
    final result = await _genericDataSource.postData<Map<String, dynamic>>(
      endpoint: Endpoints.accreditedDrivers,
      data: {'phoneNumber': phoneNumber},
    );
    if (result.isError) return Left(result.throwError());

    final data = result.getOrThrow()['data'];
    if (data is! Map<String, dynamic>) {
      return Left(ParsingFailure(message: 'الاستجابة لا تحتوي على بيانات السائق'));
    }
    try {
      return Right(AccreditedDriver.fromJson(data));
    } catch (e, stackTrace) {
      loggerError(stackTrace);
      return Left(ParsingFailure(message: e.toString()));
    }
  }

  /// 404 لو الدليفري مش معتمد عند المغسلة
  Future<Either<Failure, void>> unaccreditDriver(int driverId) {
    return _genericDataSource.deleteData<Null>(
      endpoint: Endpoints.accreditedDriver(driverId),
    );
  }
}
