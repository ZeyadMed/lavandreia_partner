import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_partner/core/helpers/generic_data_source.dart';
import 'package:lavanderia_partner/core/http/either.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/failure.dart';

/// ريكوست تسجيل دخول المغسلة
class LoginDataSource {
  final GenericDataSource _genericDataSource;

  LoginDataSource(this._genericDataSource);

  /// بيبعت { phoneNumber, password, rememberMe, deviceToken } وبيحفظ التوكنز
  /// rememberMe دايما true عشان الجلسة تفضل مستمرة
  /// deviceToken هو الـ FCM عشان السيرفر يبعت إشعارات للجهاز ده
  Future<Either<Failure, void>> login({
    required String phoneNumber,
    required String password,
  }) async {
    // لو الـ FCM ماتحفظش وقت فتح الأبلكيشن بنحاول نجيبه تاني
    final deviceToken = await CacheManager.getFcmToken() ??
        await CacheManager.fetchAndSaveFcmToken() ??
        '';

    final result = await _genericDataSource.postData<Map<String, dynamic>>(
      endpoint: Endpoints.login,
      data: {
        'phoneNumber': phoneNumber,
        'password': password,
        'rememberMe': true,
        'deviceToken': deviceToken,
      },
    );

    // بنستخدم isError بدل fold عشان fold متزامنة والحفظ محتاج await
    if (result.isError) return Left(result.throwError());

    final response = result.getOrThrow();
    // التوكنز ممكن تيجي في أول الريسبونس أو جوه data زي باقي الـ API
    final payload = response['data'] is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>
        : response;
    final accessToken = payload['accessToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      return Left(ParsingFailure(message: 'الاستجابة لا تحتوي على رمز الدخول'));
    }

    await CacheManager.saveTokens(
      accessToken: accessToken,
      refreshToken: payload['refreshToken'] as String? ?? '',
    );
    return const Right(null);
  }

  /// بيبعت { refreshToken } عشان السيرفر يلغي الجلسة
  /// التوكنز بتتمسح محلياً في كل الحالات، حتى لو الريكوست فشل،
  /// عشان اليوزر مايفضلش عالق جوه الأبلكيشن من غير نت
  Future<Either<Failure, void>> logout() async {
    final refreshToken = await CacheManager.getRefreshToken();

    final Either<Failure, void> result =
        refreshToken == null || refreshToken.isEmpty
        ? const Right(null)
        : await _genericDataSource.postData<Null>(
            endpoint: Endpoints.logOut,
            data: {'refreshToken': refreshToken},
          );

    await CacheManager.clearTokens();
    return result;
  }
}
