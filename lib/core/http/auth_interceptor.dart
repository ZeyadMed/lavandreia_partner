import 'package:dio/dio.dart';
import 'package:lavanderia_partner/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_partner/core/helpers/logger.dart';
import 'package:lavanderia_partner/core/http/endpoints.dart';
import 'package:lavanderia_partner/core/http/token_refresh_service.dart';

/// بيحط الـ accessToken على كل ريكوست، ولما ييجي 401 بيجدده
/// بالـ refreshToken ويعيد الريكوست تاني من غير ما المستخدم يحس.
///
/// كده التوكن بيتقرا من الكاش وقت الطلب نفسه، مش وقت تسجيل الـ Dio،
/// فبعد اللوجين مش محتاجين نعمل reset للـ DI عشان الهيدر يتحدث.
///
/// عادي مش `QueuedInterceptor`: الـ retry بيعدي على نفس الانترسبتور، ولو فشل
/// الـ onError بتاعه هيستنى في الطابور ورا الـ onError اللي مستنيه → deadlock.
/// منع التجديد المتوازي موجود في [TokenRefreshService.refresh].
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenRefreshService refreshService,
  }) : _dio = dio,
       _refreshService = refreshService;

  final Dio _dio;
  final TokenRefreshService _refreshService;

  static const _retriedFlag = 'auth_interceptor_retried';

  /// بيتحط على الريكوست لما الجلسة تنتهي فعلاً، و`_handleDioError`
  /// بيوجّه للوجين بس لو لقاه — عشان 401 من اللوجين نفسه مثلاً مايطردش حد.
  static const sessionExpiredFlag = 'auth_session_expired';

  /// endpoints مش محتاجة توكن، فالـ 401 منها معناه بيانات غلط مش جلسة منتهية
  static const _publicPaths = [
    Endpoints.refreshToken,
    Endpoints.login,
    Endpoints.register,
    Endpoints.verifyPhone,
    Endpoints.cities,
    Endpoints.forgetPassword,
    Endpoints.resetPassword,
    Endpoints.forgetResendOtp,
    Endpoints.forgetVerifyOtp,
  ];

  static bool _isPublic(String path) => _publicPaths.any(path.contains);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // طلب التجديد نفسه بياخد التوكن في الـ body مش في الهيدر
    if (options.path.contains(Endpoints.refreshToken)) {
      return handler.next(options);
    }

    final accessToken = await CacheManager.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    } else {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final requestOptions = err.requestOptions;

    final isUnauthorized = statusCode == 401;
    final alreadyRetried = requestOptions.extra[_retriedFlag] == true;

    // بنجدد مرة واحدة بس لكل ريكوست، وماننجددش للـ endpoints العامة
    if (!isUnauthorized || _isPublic(requestOptions.path) || alreadyRetried) {
      return handler.next(err);
    }

    // لو ريكوست تاني جدد بعد ما الريكوست ده اتبعت، نعيد بالتوكن الجديد
    // على طول بدل ما نجدد تاني ونحرق الـ refresh token.
    final storedToken = await CacheManager.getAccessToken();
    final sentHeader = requestOptions.headers['Authorization'];
    if (storedToken != null &&
        storedToken.isNotEmpty &&
        sentHeader != 'Bearer $storedToken') {
      return _retryAndResolve(requestOptions, storedToken, handler);
    }

    if (!_refreshService.hasRefreshToken) {
      loggerWarn('Got 401 with no refresh token stored');
      await _expireSession(requestOptions);
      return handler.next(err);
    }

    switch (await _refreshService.refresh()) {
      case RefreshSuccess(:final accessToken):
        return _retryAndResolve(requestOptions, accessToken, handler);
      case RefreshInvalid():
        loggerWarn('Refresh rejected, session expired');
        await _expireSession(requestOptions);
        return handler.next(err);
      case RefreshTransientFailure():
        // النت أو السيرفر وقع، التوكنز لسه سليمة فبنرجع الـ error زي ما هو
        loggerWarn('Refresh failed temporarily, keeping session');
        return handler.next(err);
    }
  }

  Future<void> _retryAndResolve(
    RequestOptions requestOptions,
    String accessToken,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      final retried = await _retry(requestOptions, accessToken);
      handler.resolve(retried);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<Response<dynamic>> _retry(
    RequestOptions requestOptions,
    String accessToken,
  ) {
    // الـ FormData بيتقفل بعد أول إرسال، فلازم نسخة جديدة للإعادة
    final data = requestOptions.data;
    if (data is FormData) requestOptions.data = data.clone();

    return _dio.fetch(
      requestOptions
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..extra[_retriedFlag] = true,
    );
  }

  /// بنمسح التوكنز بس، والتوجيه للوجين بيحصل في `_handleDioError`
  /// لما الـ 401 يوصله بعد ما التجديد فشل — عشان مايبقاش فيه مسارين
  /// بيبعتوا المستخدم على اللوجين في نفس الوقت.
  Future<void> _expireSession(RequestOptions requestOptions) async {
    requestOptions.extra[sessionExpiredFlag] = true;
    await CacheManager.clearTokens();
  }
}
