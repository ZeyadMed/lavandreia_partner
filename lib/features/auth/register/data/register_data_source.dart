import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_partner/core/helpers/generic_data_source.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/city_model.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';

/// ريكوستات شاشة التسجيل: المدن وإنشاء حساب المغسلة وتأكيد الرقم
class RegisterDataSource {
  final GenericDataSource _genericDataSource;

  RegisterDataSource(this._genericDataSource);

  /// الريسبونس: { "statusCode": 200, "message": "...", "data": [{ "id", "name" }] }
  Future<Either<Failure, List<CityModel>>> getCities() {
    return _genericDataSource.fetchData<CityModel>(
      endpoint: Endpoints.cities,
      fromJson: CityModel.fromJson,
    );
  }

  /// بيبعت بيانات التسجيل كـ multipart عشان صورة المغسلة
  Future<Either<Failure, void>> register(RegisterData data) {
    return _genericDataSource.postFormData<Null>(
      endpoint: Endpoints.register,
      data: data.toFormData(),
    );
  }

  /// بيأكد رقم المغسلة بالكود اللي وصل في رسالة
  /// لو الريسبونس فيه توكنز بيحفظها وبيرجّع true، يعني اليوزر دخل على طول
  /// ولو مفيش بيرجّع false واليوزر يسجل دخول بنفسه
  Future<Either<Failure, bool>> verifyPhone({
    required String phoneNumber,
    required String code,
  }) async {
    final result = await _genericDataSource.postData<Map<String, dynamic>>(
      endpoint: Endpoints.verifyPhone,
      data: {'phoneNumber': phoneNumber, 'code': code},
    );

    // بنستخدم isError بدل fold عشان fold متزامنة والحفظ محتاج await
    if (result.isError) return Left(result.throwError());

    final response = result.getOrThrow();
    // التوكنز ممكن تيجي في أول الريسبونس أو جوه data زي باقي الـ API
    final payload = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    final accessToken = payload['accessToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) return const Right(false);

    await CacheManager.saveTokens(
      accessToken: accessToken,
      refreshToken: payload['refreshToken'] as String? ?? '',
    );
    return const Right(true);
  }
}
